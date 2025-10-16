from __future__ import annotations

import os
from dataclasses import dataclass
from functools import lru_cache
from typing import Sequence

from dotenv import load_dotenv


load_dotenv()


@dataclass(frozen=True)
class Settings:
    app_name: str = "My Way API"
    api_version: str = "0.1"

    enable_mocks: bool = os.getenv("ENABLE_MOCKS", "true").lower() == "true"
    generate_timeout_ms: int = int(os.getenv("GENERATE_TIMEOUT_MS", "800"))
    feed_size: int = int(os.getenv("FEED_SIZE", "50"))

    feed_share_interest: float = float(os.getenv("FEED_SHARE_INTEREST", "0.60"))
    feed_share_explore: float = float(os.getenv("FEED_SHARE_EXPLORE", "0.25"))
    feed_share_trending: float = float(os.getenv("FEED_SHARE_TRENDING", "0.15"))

    max_free_views: int = int(os.getenv("MAX_FREE_VIEWS", "8"))
    max_free_depth: int = int(os.getenv("MAX_FREE_DEPTH", "2"))

    trending_seed_prompts: Sequence[str] = tuple(
        p.strip() for p in os.getenv(
            "TRENDING_PROMPTS",
            "neon cyberpunk streets,cozy rainy cafe,surreal underwater city",
        ).split(",")
        if p.strip()
    )

    vertex_project: str | None = os.getenv("GCP_PROJECT_ID")
    vertex_region: str | None = os.getenv("REGION_VERTEX")
    firestore_location: str | None = os.getenv("LOCATION_FIRESTORE")

    storage_bucket: str | None = os.getenv("FIREBASE_STORAGE_BUCKET")
    cloud_storage_media_prefix: str = os.getenv("CLOUD_STORAGE_MEDIA_PREFIX", "media")
    pubsub_topic_generate: str | None = os.getenv("PUBSUB_TOPIC_GENERATE")
    pubsub_subscription_generate: str | None = os.getenv("PUBSUB_SUBSCRIPTION_GENERATE")
    cloud_run_service: str | None = os.getenv("CLOUD_RUN_SERVICE")


_settings: Settings | None = None

def get_settings() -> Settings:
    """Get settings singleton."""
    global _settings
    if _settings is None:
        _settings = Settings()
    return _settings
