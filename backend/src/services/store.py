
from __future__ import annotations

import logging
from collections import defaultdict, deque
from dataclasses import dataclass
from typing import Deque, Dict, List, Optional, Union

from ..config import get_settings
from ..models.schemas import FeedItem, Post

logger = logging.getLogger(__name__)


DEFAULT_SESSION_BUDGET = {"images": 3, "videos": 1}


@dataclass
class FeedEntry:
    postId: str
    score: float
    reason: List[str]


class InMemoryStore:
    """A simple in-memory implementation that mimics Firestore collections."""

    def __init__(self) -> None:
        self.posts: Dict[str, Post] = {}
        self.jobs: Dict[str, Dict] = {}
        self.user_feeds: Dict[str, Deque[FeedEntry]] = defaultdict(deque)
        self.user_views: Dict[str, int] = defaultdict(int)
        self.session_budgets: Dict[str, Dict[str, int]] = defaultdict(
            lambda: DEFAULT_SESSION_BUDGET.copy()
        )
        self.trending_buffer: Deque[str] = deque()
        self.users: Dict[str, Dict] = {}  # User data including profile images

    # --- Posts ---
    def save_post(self, post: Union[Post, Dict]) -> Post:
        if not isinstance(post, Post):
            post = Post.model_validate(post)
        self.posts[post.id] = post
        if post.status == "ready":
            self.trending_buffer.appendleft(post.id)
            # Keep trending buffer manageable
            while len(self.trending_buffer) > 50:
                self.trending_buffer.pop()
        return post

    def get_post(self, post_id: str) -> Optional[Post]:
        return self.posts.get(post_id)

    def list_ready_posts(self, limit: int = 12) -> List[Post]:
        return [p for p in self.posts.values() if p.status == "ready"][:limit]

    # --- Feed ---
    def attach_to_feed(self, uid: str, post: Post, score: float, reason: List[str]) -> None:
        feed = self.user_feeds[uid]
        feed.appendleft(FeedEntry(postId=post.id, score=score, reason=reason))
        while len(feed) > 100:
            feed.pop()

    def get_feed_ready(self, uid: str, limit: int, feed_type: Optional[str] = "hot", page: int = 0) -> tuple[List[FeedItem], bool]:
        import random
        feed = self.user_feeds.get(uid, deque())
        skip_count = page * limit
        items: List[FeedItem] = []
        skipped = 0
        has_more = False
        
        for entry in list(feed):
            post = self.posts.get(entry.postId)
            if not post or post.status != "ready":
                continue
            
            # Filter by feed type
            # "private" feed type is now "Your Feed" - shows ALL user's content (public + private)
            # Other feeds (hot, interests, random) skip private posts
            if feed_type in ["hot", "interests", "random"] and post.isPrivate:
                continue  # Public feeds skip private posts
            
            # Skip items for pagination
            if skipped < skip_count:
                skipped += 1
                continue
            
            # Check if we have more items beyond the limit
            if len(items) >= limit:
                has_more = True
                break
            
            items.append(FeedItem(slot="READY", post=post, reason=entry.reason))
        
        # Randomize order for random feed (only the current page)
        if feed_type == "random" and items:
            random.shuffle(items)
        
        return items, has_more

    def add_fallback(self, post: Post) -> None:
        # Ensure fallback content exists by saving ready post with a low score.
        self.save_post(post)

    def pick_fallback(self) -> Optional[Post]:
        while self.trending_buffer:
            pid = self.trending_buffer[0]
            post = self.posts.get(pid)
            if post and post.status == "ready":
                return post
            self.trending_buffer.popleft()
        return None

    # --- Jobs ---
    def save_job(self, job_id: str, payload: Dict) -> None:
        self.jobs[job_id] = payload

    def get_job(self, job_id: str) -> Optional[Dict]:
        return self.jobs.get(job_id)

    # --- Budgets & gating ---
    def get_view_count(self, uid: str) -> int:
        return self.user_views[uid]

    def increment_view(self, uid: str) -> int:
        self.user_views[uid] += 1
        return self.user_views[uid]

    def get_budget(self, uid: str) -> Dict[str, int]:
        return self.session_budgets[uid]

    def consume_budget(self, uid: str, media_type: str) -> bool:
        budget = self.session_budgets[uid]
        remaining = budget.get(media_type, 0)
        if remaining <= 0:
            return False
        budget[media_type] = remaining - 1
        return True
    
    # --- User Profile ---
    def get_user(self, uid: str) -> Optional[Dict]:
        """Get user data including profile images"""
        return self.users.get(uid)
    
    def update_user_profile_images(
        self, 
        uid: str, 
        capture_images=None,
        base_image=None,
        base_image_public_url=None,
        base_image_approved=None,
        base_image_created_at=None,
    ) -> None:
        """Update user's profile images"""
        if uid not in self.users:
            self.users[uid] = {"profileImages": {}}
        if "profileImages" not in self.users[uid]:
            self.users[uid]["profileImages"] = {}
        
        profile = self.users[uid]["profileImages"]
        
        if capture_images is not None:
            profile["captureImages"] = {
                "front": capture_images.front,
                "left": capture_images.left,
                "right": capture_images.right,
            }
        if base_image is not None:
            profile["baseImage"] = base_image
        if base_image_public_url is not None:
            profile["baseImagePublicUrl"] = base_image_public_url
        if base_image_approved is not None:
            profile["baseImageApproved"] = base_image_approved
        if base_image_created_at is not None:
            profile["baseImageCreatedAt"] = base_image_created_at


def _create_store() -> Union[InMemoryStore, "FirestoreStore"]:  # type: ignore
    settings = get_settings()
    if settings.enable_mocks:
        return InMemoryStore()
    try:  # pragma: no cover - requires Firestore credentials
        from .store_firestore import FirestoreStore

        logger.info("Using Firestore store backend")
        return FirestoreStore(default_budget=DEFAULT_SESSION_BUDGET)
    except Exception as exc:  # pragma: no cover - fallback path
        logger.warning("Falling back to in-memory store: %s", exc, exc_info=True)
        return InMemoryStore()


STORE = _create_store()


def get_store() -> Union[InMemoryStore, "FirestoreStore"]:  # type: ignore
    return STORE


def reset_store() -> InMemoryStore:
    global STORE
    STORE = InMemoryStore()
    return STORE
