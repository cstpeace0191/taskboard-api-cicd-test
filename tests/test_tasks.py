import pytest
from fastapi.testclient import TestClient

from app.main import TASKS, app

client = TestClient(app)


@pytest.fixture(autouse=True)
def clear_tasks():
    TASKS.clear()
    yield
    TASKS.clear()


def make(task_id: int, title: str = "task", **extra) -> None:
    r = client.post("/tasks", json={"id": task_id, "title": title, **extra})
    assert r.status_code == 201


def test_health():
    assert client.get("/health").json() == {"status": "ok"}


def test_create_and_get_task():
    r = client.post("/tasks", json={"id": 1, "title": "write tests"})
    assert r.status_code == 201
    body = client.get("/tasks/1").json()
    assert body["title"] == "write tests"
    assert body["done"] is False
    assert body["priority"] == "medium"


def test_duplicate_id_returns_409():
    make(1, "a")
    r = client.post("/tasks", json={"id": 1, "title": "b"})
    assert r.status_code == 409


def test_empty_title_on_create_returns_422():
    r = client.post("/tasks", json={"id": 1, "title": ""})
    assert r.status_code == 422


def test_missing_task_returns_404():
    assert client.get("/tasks/999").status_code == 404


def test_list_tasks_sorted_by_id():
    make(3)
    make(1)
    make(2)
    ids = [t["id"] for t in client.get("/tasks").json()]
    assert ids == [1, 2, 3]


def test_list_filter_done_true():
    make(1)
    make(2)
    client.patch("/tasks/2", json={"done": True})
    ids = [t["id"] for t in client.get("/tasks", params={"done": "true"}).json()]
    assert ids == [2]


def test_list_filter_priority():
    make(1, priority="high")
    make(2, priority="low")
    ids = [t["id"] for t in client.get("/tasks", params={"priority": "high"}).json()]
    assert ids == [1]


def test_update_task():
    make(1, "old")
    r = client.patch("/tasks/1", json={"title": "new", "done": True})
    assert r.status_code == 200
    assert r.json() == {"id": 1, "title": "new", "done": True, "priority": "medium"}


def test_update_missing_task_returns_404():
    assert client.patch("/tasks/42", json={"done": True}).status_code == 404


def test_delete_task():
    make(1)
    assert client.delete("/tasks/1").status_code == 204
    assert client.get("/tasks/1").status_code == 404
