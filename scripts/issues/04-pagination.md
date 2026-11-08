## 배경
작업이 많아지면 `GET /tasks` 응답이 너무 커집니다. 페이지네이션이 필요합니다.

## 요구사항
- 쿼리: `limit` (기본 20, 1~100), `offset` (기본 0, 0 이상)
- 응답: `{"items": [...], "total": N}` — total은 필터 적용 후, 페이지 적용 전 개수
- `limit > 100`, `limit < 1`, `offset < 0` 이면 422
- 기존 `done`, `priority` 필터와 함께 동작

## 주의
응답 형식이 배열에서 객체로 바뀌는 **Breaking change** 입니다.
PR 본문에 명시하고, 기존 목록 테스트도 새 형식에 맞게 고쳐야 합니다.

## 완료 조건
- [ ] limit/offset 동작 테스트 (첫 페이지, 마지막 페이지, 범위 밖 offset → 빈 items)
- [ ] 422 경계값 테스트 (limit 0, 101, offset -1)
- [ ] 필터 + 페이지네이션 조합 테스트
- [ ] PR 본문에 Breaking change 섹션
