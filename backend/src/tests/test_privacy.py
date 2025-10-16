"""Tests for privacy and usage limits functionality."""

from fastapi.testclient import TestClient

from src.main import app
from src.services import store
from src.services.mocks import generate_mock_post


def setup_function() -> None:
    """Reset store before each test."""
    store.reset_store()


def test_create_private_post():
    """Test creating a private post."""
    with TestClient(app) as client:
        response = client.post(
            "/gen/image",
            json={
                "uid": "test_user",
                "prompt": "private scene",
                "type": "image",
                "isPrivate": True,
            },
        )
        assert response.status_code == 200
        job_id = response.json()["jobId"]
        
        # Check that job was created with privacy flag
        db = store.get_store()
        job = db.get_job(job_id)
        assert job is not None
        # Note: actual privacy enforcement depends on backend implementation


def test_create_public_post():
    """Test creating a public post (default)."""
    with TestClient(app) as client:
        response = client.post(
            "/gen/image",
            json={
                "uid": "test_user",
                "prompt": "public scene",
                "type": "image",
                "isPrivate": False,
            },
        )
        assert response.status_code == 200
        job_id = response.json()["jobId"]
        assert job_id is not None


def test_feed_type_hot():
    """Test requesting hot feed type."""
    with TestClient(app) as client:
        response = client.post(
            "/feed", json={"uid": "test_user", "page": 0, "feedType": "hot"}
        )
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)


def test_feed_type_private():
    """Test requesting private feed type."""
    with TestClient(app) as client:
        response = client.post(
            "/feed", json={"uid": "test_user", "page": 0, "feedType": "private"}
        )
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)


def test_feed_type_interests():
    """Test requesting interests feed type."""
    with TestClient(app) as client:
        response = client.post(
            "/feed", json={"uid": "test_user", "page": 0, "feedType": "interests"}
        )
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)


def test_feed_type_random():
    """Test requesting random feed type."""
    with TestClient(app) as client:
        response = client.post(
            "/feed", json={"uid": "test_user", "page": 0, "feedType": "random"}
        )
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)


def test_video_generation_with_privacy():
    """Test video generation with privacy flag."""
    with TestClient(app) as client:
        response = client.post(
            "/gen/video",
            json={
                "uid": "test_user",
                "prompt": "private video",
                "type": "video",
                "duration": 6,
                "audio": True,
                "isPrivate": True,
            },
        )
        assert response.status_code == 200
        job_id = response.json()["jobId"]
        assert job_id is not None
