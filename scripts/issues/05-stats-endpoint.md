## 배경
대시보드에서 작업 현황을 한 번에 보고 싶습니다.

## 요구사항
`GET /tasks/stats` 응답:
```json
{"total": 3, "done": 1, "open": 2, "by_priority": {"low": 0, "medium": 2, "high": 1}}
```
- 작업이 없으면 모든 값 0 (by_priority 의 세 키는 항상 존재)

## 완료 조건
- [ ] 빈 저장소, 여러 작업이 있는 경우 테스트
- [ ] 기존 `GET /tasks/{task_id}` 동작에 영향 없음
