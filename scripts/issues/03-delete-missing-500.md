## 문제
존재하지 않는 작업을 삭제하면 404가 아니라 **500 Internal Server Error**가 납니다.

## 재현 절차
```bash
curl -i -X DELETE localhost:8000/tasks/999
```

## 기대 결과
`404 Not Found`, 본문 `{"detail": "not found"}` (GET·PATCH와 같은 형식)

## 실제 결과
`500 Internal Server Error` (서버 로그에 `KeyError: 999`)

## 완료 조건
- [ ] 없는 id 삭제 시 404와 `{"detail": "not found"}`
- [ ] 같은 id를 두 번 삭제하면 두 번째는 404임을 테스트로 확인
