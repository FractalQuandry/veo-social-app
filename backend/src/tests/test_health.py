
from fastapi.testclient import TestClient
from src.main import app

def test_health():
    c = TestClient(app)
    r = c.get('/health')
    assert r.status_code == 200
    assert 'ok' in r.json()
