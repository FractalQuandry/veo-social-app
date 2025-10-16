from __future__ import annotations

import logging
from dataclasses import dataclass

from google.cloud import storage  # type: ignore

from ..config import get_settings

logger = logging.getLogger(__name__)

_client: storage.Client | None = None


def _get_client() -> storage.Client:
    global _client
    if _client is None:
        settings = get_settings()
        project_id = settings.vertex_project
        if not project_id:
            raise ValueError("GCP_PROJECT_ID must be set in environment")
        logger.info(f"Initializing Cloud Storage with project: {project_id}")
        _client = storage.Client(project=project_id)
    return _client


def _get_bucket() -> storage.Bucket:
    settings = get_settings()
    if not settings.storage_bucket:
        raise RuntimeError("Cloud Storage bucket not configured")
    return _get_client().bucket(settings.storage_bucket)


@dataclass
class UploadResult:
    storage_path: str
    public_url: str | None


def upload_media_bytes(*, post_id: str, media_type: str, data: bytes, content_type: str, extension: str) -> UploadResult:
    prefix = get_settings().cloud_storage_media_prefix.rstrip("/")
    folder = "images" if media_type == "image" else "videos"
    object_name = f"{prefix}/{folder}/{post_id}.{extension}"
    bucket = _get_bucket()
    blob = bucket.blob(object_name)
    blob.upload_from_string(data, content_type=content_type)
    logger.info(f"Uploaded media for {post_id} to gs://{bucket.name}/{object_name}")
    
    # Use public URL since bucket is publicly accessible
    public_url = blob.public_url
    logger.info(f"Public URL: {public_url}")
    return UploadResult(storage_path=object_name, public_url=public_url)


__all__ = ["upload_media_bytes", "UploadResult"]
