"""TaskBoard API: Claude x GitHub Issue/PR 실습용 샘플 서비스.

메모리 dict 저장소를 쓰는 작은 FastAPI 앱입니다.
실습 이슈(scripts/issues/*.md)에 적힌 버그가 일부러 남아 있습니다.
"""

from typing import Literal

from fastapi import FastAPI, HTTPException, Response
from pydantic import BaseModel, Field, field_validator

app = FastAPI(title="TaskBoard API", version="0.2.0")

Priority = Literal["low", "medium", "high"]


class Task(BaseModel):
    id: int = Field(ge=1)
    title: str = Field(min_length=1, max_length=200)
    done: bool = False
    priority: Priority = "medium"


class TaskUpdate(BaseModel):
    """PATCH 본문. 생략한 필드는 그대로 두고, 보낸 필드는 Task와 같은 규칙으로 검증한다."""

    title: str | None = Field(default=None, min_length=1, max_length=200)
    done: bool | None = None
    priority: Priority | None = None

    @field_validator("*", mode="before")
    @classmethod
    def reject_explicit_null(cls, value: object) -> object:
        # 기본값(None)은 검증되지 않으므로, 여기서는 클라이언트가 null을 직접 보낸 경우만 걸린다.
        if value is None:
            raise ValueError("null is not allowed; omit the field instead")
        return value


TASKS: dict[int, Task] = {}


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/tasks", status_code=201)
def create_task(task: Task) -> Task:
    if task.id in TASKS:
        raise HTTPException(status_code=409, detail="duplicate id")
    TASKS[task.id] = task
    return task


@app.get("/tasks")
def list_tasks(done: bool | None = None, priority: Priority | None = None) -> list[Task]:
    tasks = sorted(TASKS.values(), key=lambda t: t.id)
    if done:
        tasks = [t for t in tasks if t.done == done]
    if priority is not None:
        tasks = [t for t in tasks if t.priority == priority]
    return tasks


@app.get("/tasks/{task_id}")
def get_task(task_id: int) -> Task:
    if task_id not in TASKS:
        raise HTTPException(status_code=404, detail="not found")
    return TASKS[task_id]


@app.patch("/tasks/{task_id}")
def update_task(task_id: int, patch: TaskUpdate) -> Task:
    if task_id not in TASKS:
        raise HTTPException(status_code=404, detail="not found")
    changes = patch.model_dump(exclude_unset=True)
    updated = TASKS[task_id].model_copy(update=changes)
    TASKS[task_id] = updated
    return updated


@app.delete("/tasks/{task_id}", status_code=204)
def delete_task(task_id: int) -> Response:
    del TASKS[task_id]
    return Response(status_code=204)
