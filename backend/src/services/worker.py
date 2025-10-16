from __future__ import annotations

import logging
import time

from ..models.schemas import GenerateTask, Post, SafetyInfo
from . import store
from .storage import upload_media_bytes
from .vertex import generate_image, generate_video

logger = logging.getLogger(__name__)


def process_generate_task(task: GenerateTask) -> None:
    db = store.get_store()
    logger.info("Processing generation job %s for user %s", task.jobId, task.uid)

    try:
        if task.mediaType == "image":
            result = generate_image(prompt=task.prompt, aspect=task.aspect, seed=task.seed)
        else:
            result = generate_video(prompt=task.prompt, aspect=task.aspect, seed=task.seed)

        upload = upload_media_bytes(
            post_id=task.jobId,
            media_type=task.mediaType,
            data=result.bytes_payload,
            content_type=result.mime_type,
            extension=result.extension,
        )

        post_payload = Post(
            id=task.jobId,
            type=task.mediaType,
            status="ready",
            storagePath=upload.storage_path,
            duration=result.duration,
            aspect=task.aspect,
            model=result.model,
            prompt=task.prompt,
            seed=task.seed,
            safety=SafetyInfo(blocked=False, scores=result.safety),
            authorUid=task.uid,
        )
        saved = db.save_post(post_payload)
        db.attach_to_feed(task.uid, saved, score=1.0, reason=["generated"])
        db.save_job(
            task.jobId,
            {
                "jobId": task.jobId,
                "userId": task.uid,
                "status": "ready",
                "postId": saved.id,
                "updated_at": time.time(),
            },
        )
        logger.info("Completed generation job %s", task.jobId)
    except Exception as exc:  # pragma: no cover - production path
        logger.exception("Generation job %s failed: %s", task.jobId, exc)
        db.save_job(
            task.jobId,
            {
                "jobId": task.jobId,
                "userId": task.uid,
                "status": "failed",
                "updated_at": time.time(),
                "error": str(exc),
            },
        )


__all__ = ["process_generate_task"]
