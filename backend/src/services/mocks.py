
import time, random, uuid
from typing import Dict, Any

PLACEHOLDER_IMAGES = [
    "https://picsum.photos/720/1280",
    "https://picsum.photos/800/1200",
    "https://picsum.photos/1080/1920"
]

PLACEHOLDER_VIDEOS = [
    # Short, public domain sample MP4s can be swapped in by the developer.
    "https://samplelib.com/lib/preview/mp4/sample-5s.mp4",
    "https://samplelib.com/lib/preview/mp4/sample-10s.mp4"
]

def generate_mock_post(prompt: str, kind: str) -> Dict[str, Any]:
    pid = str(uuid.uuid4())
    if kind == "image":
        media = random.choice(PLACEHOLDER_IMAGES)
        duration = None
    else:
        media = random.choice(PLACEHOLDER_VIDEOS)
        duration = 6.0
    return {
        "id": pid,
        "type": kind,
        "status": "ready",
        "storagePath": media,
        "duration": duration,
        "aspect": "9:16",
        "model": "mock-model",
        "prompt": prompt[:180],
        "seed": random.randint(0, 10_000),
        "safety": {"blocked": False, "scores": {"harm": 0.0}},
        "synthId": True,
        "authorUid": "system"
    }

def slow_pending_then_ready(prompt: str, kind: str, delay_ms: int = 600):
    # Simulate a pending job that will be ready after delay.
    job_id = str(uuid.uuid4())
    post = generate_mock_post(prompt, kind)
    return job_id, post, delay_ms
