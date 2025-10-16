from __future__ import annotations

import json
import logging
from typing import Any, Dict

try:  # pragma: no cover - optional dependency
    from google.cloud import pubsub_v1  # type: ignore
except Exception:  # pragma: no cover - optional dependency
    pubsub_v1 = None  # type: ignore

from ..config import get_settings

logger = logging.getLogger(__name__)

_publisher: Any = None


def _get_publisher() -> Any:
    if pubsub_v1 is None:
        raise RuntimeError("google-cloud-pubsub is not installed or configured")
    global _publisher
    if _publisher is None:
        _publisher = pubsub_v1.PublisherClient()
    return _publisher


def publish_generate_request(payload: Dict[str, Any]) -> str:
    settings = get_settings()
    if not settings.vertex_project or not settings.pubsub_topic_generate:
        raise RuntimeError("Pub/Sub topic not configured for generation tasks")

    topic_path = _get_publisher().topic_path(settings.vertex_project, settings.pubsub_topic_generate)
    data = json.dumps(payload).encode("utf-8")
    future = _get_publisher().publish(topic_path, data)
    message_id = future.result(timeout=15)
    logger.debug("Published generate job %s to topic %s", payload.get("jobId"), topic_path)
    return message_id


__all__ = ["publish_generate_request"]
