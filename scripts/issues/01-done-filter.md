## 문제
`GET /tasks?done=false` 가 미완료 작업만이 아니라 **모든 작업**을 돌려줍니다.
`done=true` 는 정상입니다.

## 재현 절차
```bash
curl -X POST localhost:8000/tasks -H "Content-Type: application/json" -d '{"id": 1, "title": "a"}'
curl -X POST localhost:8000/tasks -H "Content-Type: application/json" -d '{"id": 2, "title": "b"}'
curl -X PATCH localhost:8000/tasks/2 -H "Content-Type: application/json" -d '{"done": true}'
curl "localhost:8000/tasks?done=false"
```

## 기대 결과
`[{"id": 1, ...}]` — id 1 하나만

## 실제 결과
id 1, 2 두 개 모두 반환

## 완료 조건
- [ ] `done=false` 이면 미완료 작업만 반환
- [ ] `done` 생략 시 기존처럼 전체 반환
- [ ] 위 두 경우에 대한 테스트 추가
