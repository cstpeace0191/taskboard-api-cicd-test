## 문제
`POST /tasks` 는 빈 제목을 422로 거부하는데, `PATCH /tasks/{id}` 로는 제목을 빈 문자열로 바꿀 수 있습니다.

## 재현 절차
```bash
curl -X POST localhost:8000/tasks -H "Content-Type: application/json" -d '{"id": 1, "title": "a"}'
curl -X PATCH localhost:8000/tasks/1 -H "Content-Type: application/json" -d '{"title": ""}'
```

## 기대 결과
422 Unprocessable Entity, 저장된 제목은 그대로 `"a"`

## 실제 결과
200 OK, 제목이 `""` 로 바뀜

## 완료 조건
- [ ] PATCH의 title도 POST와 같은 규칙(1~200자) 적용
- [ ] `"priority": "urgent"` 처럼 허용되지 않은 값도 422
- [ ] 실패한 PATCH 뒤에도 기존 데이터가 바뀌지 않음을 테스트로 확인
