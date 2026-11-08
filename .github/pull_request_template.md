## Why
<!-- 어떤 이슈를 해결하나요? 키워드로 연결하면 병합 시 이슈가 자동으로 닫힙니다 -->
Closes #

## What
<!-- 바꾼 내용을 파일 단위로 짧게 -->
-

## Verification
<!-- 실제로 실행한 명령과 결과 요약 -->
```
pytest --cov=app --cov-fail-under=80   →  N passed, coverage NN%
ruff check . && ruff format --check .  →  OK
```

## Risk
<!-- 응답 형식 변경(Breaking change), 경계값, 남은 TODO -->
- Breaking change: 없음

## Checklist
- [ ] 실패하는 테스트를 먼저 추가했다
- [ ] 정상·오류 경로 테스트가 모두 있다
- [ ] 작성자: 사람 / Claude (해당 항목 남기기)
