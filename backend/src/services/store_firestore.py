from __future__ import annotations

import logging
from datetime import datetime
from typing import Dict, List, Optional, Union

from google.cloud import firestore  # type: ignore
from google.cloud.firestore_v1 import Increment, Transaction  # type: ignore

from ..config import get_settings
from ..models.schemas import FeedItem, Post

logger = logging.getLogger(__name__)


class FirestoreStore:
    """Firestore-backed store for production deployments."""

    def __init__(self, *, default_budget: Optional[Dict[str, int]] = None,
                 client: Optional[firestore.Client] = None,
                 project: Optional[str] = None) -> None:
        if client is None:
            settings = get_settings()
            project_id = project or settings.vertex_project
            if not project_id:
                raise ValueError("GCP_PROJECT_ID must be set in environment or config")
            logger.info(f"Initializing Firestore with project: {project_id}, database: (default)")
            # Must specify database='(default)' to connect to the correct Firestore instance
            self.client = firestore.Client(project=project_id, database='(default)')
        else:
            self.client = client
        self._posts = self.client.collection("posts")
        self._feeds = self.client.collection("feeds")
        self._jobs = self.client.collection("feed_jobs")
        self._users = self.client.collection("users")
        self._trending = self.client.collection("trending")
        self._default_budget = dict(default_budget or {"images": 3, "videos": 1})

    # --- Posts -----------------------------------------------------------------
    def save_post(self, post: Union[Post, Dict]) -> Post:
        if not isinstance(post, Post):
            post = Post.model_validate(post)
        payload = post.model_dump()
        created_at = payload.get("createdAt") or datetime.utcnow()
        payload["createdAt"] = created_at
        payload["updatedAt"] = datetime.utcnow()
        self._posts.document(post.id).set(payload)
        logger.debug("Saved post %s", post.id)
        return post

    def get_post(self, post_id: str) -> Optional[Post]:
        doc = self._posts.document(post_id).get()
        if not doc.exists:
            return None
        data = doc.to_dict() or {}
        data.setdefault("id", doc.id)
        return Post.model_validate(data)

    def list_ready_posts(self, limit: int = 12) -> List[Post]:
        query = (
            self._posts.where("status", "==", "ready")
            .order_by("createdAt", direction=firestore.Query.DESCENDING)
            .limit(limit)
        )
        posts: List[Post] = []
        for doc in query.stream():
            data = doc.to_dict() or {}
            data.setdefault("id", doc.id)
            try:
                posts.append(Post.model_validate(data))
            except Exception as exc:  # pragma: no cover - defensive path
                logger.warning("Failed to parse post %s: %s", doc.id, exc)
        return posts

    # --- Feed ------------------------------------------------------------------
    def attach_to_feed(self, uid: str, post: Post, score: float, reason: List[str]) -> None:
        feed_doc = (
            self._feeds.document(uid)
            .collection("items")
            .document(post.id)
        )
        feed_doc.set(
            {
                "postId": post.id,
                "score": score,
                "reason": reason,
                "createdAt": datetime.utcnow(),
            },
            merge=True,
        )
        logger.debug("Attached post %s to feed %s", post.id, uid)
        # Mirror in trending collection for fallback use
        if post.status == "ready":
            self._trending.document(post.id).set(
                {
                    "postId": post.id,
                    "score": score,
                    "createdAt": datetime.utcnow(),
                },
                merge=True,
            )

    def get_feed_ready(self, uid: str, limit: int, feed_type: Optional[str] = "hot", page: int = 0) -> tuple[List[FeedItem], bool]:
        import random
        # Order by createdAt DESC to show newest posts first
        # (score was always 1.0 for all posts, making order unpredictable)
        
        # Calculate how many items we need to fetch:
        # - Skip items from previous pages: page * limit
        # - Items for current page: limit
        # - Extra to check if more pages exist: 1
        # - Multiply by 2 to account for privacy filtering
        skip_count = page * limit
        fetch_count = (skip_count + limit + 1) * 2
        
        # For random feed, we'll fetch ALL posts and shuffle them
        if feed_type == "random":
            # Fetch ALL ready posts (no limit) for true randomness
            fetch_count = 1000  # Large number to get all posts
        
        # Public feeds query global posts collection, private feed queries user's personal feed
        if feed_type in ["hot", "interests", "random"]:
            query_base = (
                self._posts
                .where("status", "==", "ready")
                .where("isPrivate", "==", False)
            )
            
            # For random feed, don't order by anything - just get all posts
            if feed_type == "random":
                query = query_base.limit(fetch_count)
            else:
                query = query_base.order_by("createdAt", direction=firestore.Query.DESCENDING).limit(fetch_count)
        else:  # private/your feed
            query = (
                self._feeds.document(uid)
                .collection("items")
                .order_by("createdAt", direction=firestore.Query.DESCENDING)
                .limit(fetch_count)
            )
        
        items: List[FeedItem] = []
        skipped = 0
        has_more = False
        total_docs = 0
        filtered_docs = 0
        logger.warning(f"FEED DEBUG: Fetching feed for user {uid} (feed_type={feed_type}, page={page}, limit={limit}, skip_count={skip_count}, fetch_count={fetch_count})")
        
        # For random feed, collect ALL posts first, then shuffle, then paginate
        if feed_type == "random":
            all_items = []
            for doc in query.stream():
                total_docs += 1
                data = doc.to_dict() or {}
                post = Post(**data)
                post.id = doc.id
                logger.warning(f"RANDOM FEED POST: doc.id={doc.id}, post.id={post.id}, data.id={data.get('id', 'MISSING')}, prompt={post.prompt[:30]}")
                all_items.append(
                    FeedItem(
                        slot="READY",
                        post=post,
                        reason=list(data.get("reason", [])),
                    )
                )
            
            # Shuffle ALL items with a time-based seed for true randomness on each request
            import time
            random.seed(time.time())
            random.shuffle(all_items)
            
            # Apply pagination AFTER shuffle
            start_idx = skip_count
            end_idx = skip_count + limit
            items = all_items[start_idx:end_idx]
            has_more = end_idx < len(all_items)
            
            logger.warning(f"RANDOM FEED: Total posts={len(all_items)}, after pagination={len(items)}, has_more={has_more}, seed={time.time()}")
        else:
            # For other feeds, use original pagination logic
            for doc in query.stream():
                total_docs += 1
                data = doc.to_dict() or {}
                
                # For public feeds, doc IS the post; for private feed, doc contains postId reference
                if feed_type in ["hot", "interests"]:
                    post = Post(**data)
                    post.id = doc.id
                else:
                    post_id = data.get("postId")
                    if not post_id:
                        continue
                    post = self.get_post(post_id)
                    if not post or post.status != "ready":
                        filtered_docs += 1
                        continue
                
                # Skip items for pagination
                if skipped < skip_count:
                    skipped += 1
                    continue
                
                # Check if we have more items beyond the limit
                if len(items) >= limit:
                    has_more = True
                    break
                
                is_private = getattr(post, "isPrivate", False)
                logger.info(f"Adding post {post.id} to {feed_type} feed (private={is_private}, prompt: {post.prompt[:50]}...)")
                items.append(
                    FeedItem(
                        slot="READY",
                        post=post,
                        reason=list(data.get("reason", [])),
                    )
                )
        
        logger.warning(f"FEED DEBUG: Pagination summary for {feed_type}: total_docs={total_docs}, filtered={filtered_docs}, skipped={skipped}, returned={len(items)}, has_more={has_more}")
        return items, has_more

    def add_fallback(self, post: Post) -> None:
        saved = self.save_post(post)
        self._trending.document(saved.id).set(
            {
                "postId": saved.id,
                "score": 1.0,
                "createdAt": datetime.utcnow(),
            },
            merge=True,
        )

    def pick_fallback(self) -> Optional[Post]:
        query = (
            self._trending.order_by("createdAt", direction=firestore.Query.DESCENDING)
            .limit(20)
        )
        for doc in query.stream():
            data = doc.to_dict() or {}
            post_id = data.get("postId")
            if not post_id:
                continue
            post = self.get_post(post_id)
            if post and post.status == "ready":
                return post
        return None

    # --- Jobs ------------------------------------------------------------------
    def save_job(self, job_id: str, payload: Dict) -> None:
        data = dict(payload)
        now = datetime.utcnow()
        data.setdefault("createdAt", now)
        data["updatedAt"] = now
        self._jobs.document(job_id).set(data, merge=True)
        logger.debug("Saved job %s", job_id)

    def get_job(self, job_id: str) -> Optional[Dict]:
        doc = self._jobs.document(job_id).get()
        if not doc.exists:
            return None
        data = doc.to_dict() or {}
        data.setdefault("jobId", doc.id)
        return data

    # --- Budgets & gating ------------------------------------------------------
    def get_view_count(self, uid: str) -> int:
        doc = self._users.document(uid).get()
        if not doc.exists:
            return 0
        return int((doc.to_dict() or {}).get("viewCount", 0))

    def increment_view(self, uid: str) -> int:
        ref = self._users.document(uid)

        @firestore.transactional
        def _txn(transaction: Transaction) -> int:
            snapshot = ref.get(transaction=transaction)
            current = 0
            if snapshot.exists:
                current = int((snapshot.to_dict() or {}).get("viewCount", 0))
            transaction.set(ref, {"viewCount": Increment(1)}, merge=True)
            return current + 1

        transaction: Transaction = self.client.transaction()
        return _txn(transaction)

    def get_budget(self, uid: str) -> Dict[str, int]:
        doc = self._users.document(uid).get()
        budget = dict(self._default_budget)
        if doc.exists:
            data = doc.to_dict() or {}
            budget.update(data.get("sessionBudget", {}))
        return budget

    def consume_budget(self, uid: str, media_type: str) -> bool:
        ref = self._users.document(uid)

        @firestore.transactional
        def _txn(transaction: Transaction) -> bool:
            snapshot = ref.get(transaction=transaction)
            budget = dict(self._default_budget)
            if snapshot.exists:
                data = snapshot.to_dict() or {}
                budget.update(data.get("sessionBudget", {}))
            remaining = int(budget.get(media_type, 0))
            if remaining <= 0:
                return False
            budget[media_type] = remaining - 1
            transaction.set(ref, {"sessionBudget": budget}, merge=True)
            return True

        transaction: Transaction = self.client.transaction()
        return _txn(transaction)
    
    # --- User Profile ----------------------------------------------------------
    def get_user(self, uid: str) -> Optional[Dict]:
        """Get user data including profile images"""
        doc = self._users.document(uid).get()
        if not doc.exists:
            return None
        return doc.to_dict()
    
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
        ref = self._users.document(uid)
        
        # Build nested structure properly
        profile_images = {}
        
        if capture_images is not None:
            profile_images["captureImages"] = {
                "front": capture_images.front,
                "left": capture_images.left,
                "right": capture_images.right,
            }
        if base_image is not None:
            profile_images["baseImage"] = base_image
        if base_image_public_url is not None:
            profile_images["baseImagePublicUrl"] = base_image_public_url
        if base_image_approved is not None:
            profile_images["baseImageApproved"] = base_image_approved
        if base_image_created_at is not None:
            profile_images["baseImageCreatedAt"] = base_image_created_at
        
        if profile_images:
            # Use nested structure with merge to preserve existing fields
            ref.set({"profileImages": profile_images}, merge=True)
            logger.debug("Updated profile images for user %s: %s", uid, profile_images)


__all__ = ["FirestoreStore"]
