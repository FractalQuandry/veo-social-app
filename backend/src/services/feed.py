from __future__ import annotations

import logging
import random
import time
from typing import List

from ..config import get_settings
from ..models.schemas import FeedItem, FeedRequest, FeedResponse, ModerationRequest, Post
from . import generation, moderation, reco, store

logger = logging.getLogger(__name__)


def build_feed(req: FeedRequest) -> FeedResponse:
    settings = get_settings()
    db = store.get_store()

    logger.warning(f"🔄 FEED REQUEST RECEIVED: user={req.uid}, feed_type={req.feedType}, page={req.page}, timestamp={time.time()}")
    
    items, has_more = db.get_feed_ready(req.uid, settings.feed_size, feed_type=req.feedType, page=req.page)
    
    # CRITICAL: Only show user's explicit creations - no auto-generation
    # Auto-generation would waste Vertex AI quota and run up costs
    # Users must explicitly use the composer to create content
    logger.warning(f"FEED DEBUG: Returning {len(items)} posts for user {req.uid} (feed_type={req.feedType}, page={req.page}), has_more={has_more}")
    
    return FeedResponse(
        items=items,
        hasMore=has_more,
        nextPage=req.page + 1 if has_more else req.page
    )
    
    # AUTO-GENERATION DISABLED - Code below is commented out to prevent costs
    # Uncomment if you want to re-enable automatic feed filling
    #
    # missing = settings.feed_size - len(items)
    # if missing <= 0:
    #     return items
    #
    # plan = _build_slot_plan(missing, settings)
    # for reason in plan:
    #     media_type = "video" if random.random() < 0.2 else "image"
    #     budget_key = "videos" if media_type == "video" else "images"
    #
    #     if not db.consume_budget(req.uid, budget_key):
    #         fallback = db.pick_fallback()
    #         if fallback:
    #             items.append(FeedItem(slot="FALLBACK", post=fallback, reason=["budget"]))
    #         else:
    #             items.append(FeedItem(slot="FALLBACK", reason=["budget"]))
    #         continue
    #
    #     topic = _choose_topic_for_reason(req.uid, reason)
    #     prompt = reco.build_prompt(topic)
    #     moderation_result = moderation.moderate(ModerationRequest(prompt=prompt))
    #     if not moderation_result.allowed:
    #         fallback = db.pick_fallback()
    #         reason_list = ["moderation", *moderation_result.reasons] if fallback else ["moderation"]
    #         items.append(FeedItem(slot="FALLBACK", post=fallback, reason=reason_list))
    #         continue
    #
    #     job_id, post_payload, delay_ms = generation.enqueue_generation(
    #         req.uid,
    #         prompt,
    #         media_type,
    #         aspect="9:16",
    #         seed=None,
    #     )
    #     
    #     logger.info(f"Generation result: job_id={job_id}, delay_ms={delay_ms}, status={post_payload.get('status')}")
    #     
    #     if delay_ms == 0 and post_payload.get("status") == "ready":
    #         logger.info(f"Saving ready post immediately: {post_payload.get('id')}")
    #         saved_post = db.save_post(post_payload)
    #         db.attach_to_feed(req.uid, saved_post, score=1.0, reason=[reason])
    #         post_obj = Post(**post_payload)
    #         items.append(FeedItem(slot="READY", post=post_obj, reason=[reason]))
    #         logger.info(f"Added READY item to feed and attached to user {req.uid}")
    #     else:
    #         logger.info(f"Saving as pending job: {job_id}")
    #         ready_at = time.time() + (delay_ms / 1000.0)
    #         db.save_job(job_id, {
    #             "jobId": job_id,
    #             "userId": req.uid,
    #             "status": "pending",
    #             "post": post_payload,
    #             "ready_at": ready_at,
    #             "reasons": [reason],
    #         })
    #         items.append(FeedItem(slot="PENDING", jobId=job_id, reason=[reason]))
    #
    # if len(items) < settings.feed_size:
    #     fallback = db.pick_fallback()
    #     if fallback:
    #         items.append(FeedItem(slot="FALLBACK", post=fallback, reason=["fallback"]))
    #
    # return items[: settings.feed_size]


def _build_slot_plan(missing: int, settings) -> List[str]:
    plan: List[str] = []
    shares = {
        "interest": settings.feed_share_interest,
        "explore": settings.feed_share_explore,
        "trending": settings.feed_share_trending,
    }
    for reason, share in shares.items():
        plan.extend([reason] * max(0, round(missing * share)))
    while len(plan) < missing:
        plan.append(random.choice(list(shares.keys())))
    return plan[:missing]


def _choose_topic_for_reason(uid: str, reason: str) -> str:
    if reason == "trending":
        return random.choice(reco.trending_topics(get_settings().trending_seed_prompts, 1) or ["trending visuals"])
    if reason == "explore":
        return random.choice(reco.explore_topics(None, 1) or ["experimental art"])
    return random.choice(reco.select_topics(None, 1) or ["creative scene"])
