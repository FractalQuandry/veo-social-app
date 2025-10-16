from fastapi.testclient import TestClient

from src.main import app
from src.services import store
from src.services.mocks import generate_mock_post


def setup_function() -> None:
    store.reset_store()


def test_feed_returns_ready_and_pending_slots():
    with TestClient(app) as client:
        db = store.get_store()
        post = generate_mock_post("street food", "image")
        post["status"] = "ready"
        saved = db.save_post(post)
        db.attach_to_feed("tester", saved, score=0.9, reason=["interest"])

        response = client.post("/feed", json={"uid": "tester", "page": 0})
        assert response.status_code == 200
        data = response.json()
        assert any(item["slot"] == "READY" for item in data)
        assert any(item["slot"] == "PENDING" for item in data)


def test_job_status_flips_to_ready():
    with TestClient(app) as client:
        created = client.post(
            "/gen/image",
            json={"uid": "tester", "prompt": "cafe scene", "type": "image"},
        )
        assert created.status_code == 200
        job_id = created.json()["jobId"]

        db = store.get_store()
        job = db.get_job(job_id)
        assert job is not None
        job["ready_at"] = 0  # force ready
        db.save_job(job_id, job)

        status = client.get("/gen/status", params={"jobId": job_id})
        assert status.status_code == 200
        payload = status.json()
        assert payload["status"] == "ready"
        assert payload["postId"] is not None
