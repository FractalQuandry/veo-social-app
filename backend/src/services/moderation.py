from __future__ import annotations

import logging
from typing import List

from ..config import get_settings
from ..models.schemas import ModerationRequest, ModerationResponse

logger = logging.getLogger(__name__)


BLOCKLIST = ["weapon", "politics", "explicit"]


def moderate(req: ModerationRequest) -> ModerationResponse:
    settings = get_settings()
    if settings.enable_mocks:
        text = (req.prompt or "").lower()
        blocked_terms: List[str] = [term for term in BLOCKLIST if term in text]
        allowed = not blocked_terms
        if not allowed:
            logger.warning("Prompt blocked by mock moderation: %s", blocked_terms)
        return ModerationResponse(
            allowed=allowed,
            reasons=blocked_terms,
            safety={"blocked": 1.0 if not allowed else 0.0},
        )

    # Placeholder for Vertex safety API integration
    logger.warning("Vertex moderation not implemented in sample; allowing by default")
    return ModerationResponse(allowed=True, reasons=[], safety=None)
