from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Dict, Optional

from google.cloud import aiplatform  # type: ignore

try:  # pragma: no cover - optional import depending on SDK version
    from google.cloud.aiplatform import generation  # type: ignore
except Exception:  # pragma: no cover - optional import
    generation = None

from ..config import get_settings

logger = logging.getLogger(__name__)

_IMAGE_MODEL = "imagen-3.0-generate-img"
_VIDEO_MODEL = "long-form-video@001"

_INITIALIZED = False


def _ensure_init() -> None:
    global _INITIALIZED
    if _INITIALIZED:
        return
    settings = get_settings()
    if not settings.vertex_project or not settings.vertex_region:
        raise RuntimeError("Vertex AI project/region not configured")
    aiplatform.init(project=settings.vertex_project, location=settings.vertex_region)
    _INITIALIZED = True


@dataclass
class VertexGenerationResult:
    bytes_payload: bytes
    duration: Optional[float]
    model: str
    mime_type: str
    extension: str
    safety: Dict[str, float]


def generate_image(*, prompt: str, aspect: str, seed: Optional[int]) -> VertexGenerationResult:
    _ensure_init()
    if generation is None:
        raise RuntimeError("Vertex AI generation SDK not available")
    model = generation.ImageGenerationModel.from_pretrained(_IMAGE_MODEL)
    response = model.generate_images(
        prompt=prompt,
        number_of_images=1,
        aspect_ratio=aspect,
        seed=seed,
        safety_filter_level="standard",
    )
    image = response.images[0]
    metadata = image.safety_ratings or {}
    return VertexGenerationResult(
        bytes_payload=image.bytes,
        duration=None,
        model=_IMAGE_MODEL,
        mime_type="image/jpeg",
        extension="jpg",
        safety={k: float(v) for k, v in metadata.items()},
    )


def generate_video(*, prompt: str, aspect: str, seed: Optional[int]) -> VertexGenerationResult:
    _ensure_init()
    if generation is None:
        raise RuntimeError("Vertex AI generation SDK not available")
    video_model = generation.VideoGenerationModel.from_pretrained(_VIDEO_MODEL)
    response = video_model.generate_videos(
        prompt=prompt,
        aspect_ratio=aspect,
        seed=seed,
        safety_filter_level="standard",
    )
    video = response.videos[0]
    metadata = video.safety_ratings or {}
    return VertexGenerationResult(
        bytes_payload=video.bytes,
        duration=float(video.metadata.get("durationSeconds", 7.0)) if video.metadata else 7.0,
        model=_VIDEO_MODEL,
        mime_type="video/mp4",
        extension="mp4",
        safety={k: float(v) for k, v in metadata.items()},
    )


__all__ = ["generate_image", "generate_video", "VertexGenerationResult"]
