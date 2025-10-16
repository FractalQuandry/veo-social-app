from __future__ import annotations

import random
from typing import Dict, Iterable, List, Tuple

InterestVector = Dict[str, float]


INTEREST_GRAPH: Dict[str, List[str]] = {
    "street food": ["travel", "home cooking", "boba"],
    "sci-fi": ["fantasy", "cyberpunk", "space"],
    "cozy": ["interior", "cottagecore", "tea"],
    "cyberpunk": ["sci-fi", "noir", "android"],
    "travel": ["landscape", "street food", "photography"],
    "art": ["surreal", "watercolor", "digital"],
}

DEFAULT_INTERESTS: InterestVector = {
    "street food": 0.6,
    "sci-fi": 0.5,
    "cozy": 0.4,
}


def normalize(interests: InterestVector) -> InterestVector:
    total = sum(interests.values()) or 1.0
    return {k: v / total for k, v in interests.items()}


def select_topics(interests: InterestVector | None, k: int) -> List[str]:
    interests = normalize(interests or DEFAULT_INTERESTS)
    topics = list(interests.keys())
    weights = [interests[t] for t in topics]
    selection = random.choices(topics, weights=weights, k=min(k, len(topics)))
    return selection


def neighbors_for(topic: str) -> List[str]:
    return INTEREST_GRAPH.get(topic, [])


def explore_topics(interests: InterestVector | None, k: int) -> List[str]:
    bases = select_topics(interests, k)
    candidates: List[str] = []
    for base in bases:
        neigh = neighbors_for(base)
        if not neigh:
            continue
        candidates.append(random.choice(neigh))
    if len(candidates) < k:
        all_neighbors = [n for n in INTEREST_GRAPH if n not in candidates]
        candidates.extend(random.sample(all_neighbors, min(k - len(candidates), len(all_neighbors))))
    return candidates[:k]


def trending_topics(seed_prompts: Iterable[str], k: int) -> List[str]:
    prompts = list(seed_prompts)
    if not prompts:
        return []
    return random.sample(prompts, min(k, len(prompts)))


def build_prompt(topic: str) -> str:
    templates = [
        f"Ultra-detailed {topic} scene, cinematic lighting",
        f"A short cinematic of {topic}, shot on vintage film",
        f"AI art of {topic}, vibrant colors"
    ]
    return random.choice(templates)
