#!/usr/bin/env bash
# 배포된 TaskBoard API 스모크 테스트 (CD 파이프라인과 로컬에서 공용).
#   ./scripts/smoke_test.sh http://127.0.0.1:8000
# 확인: /health 응답 대기 → 작업 생성 → 조회 → 삭제
set -euo pipefail
BASE="${1:-http://127.0.0.1:8000}"
ID=$(( (RANDOM % 9000) + 1000 ))

echo "== waiting for $BASE/health"
for i in $(seq 1 30); do
  if curl -fsS "$BASE/health" >/dev/null 2>&1; then break; fi
  [[ $i -eq 30 ]] && { echo "FAIL: /health did not respond in 30s" >&2; exit 1; }
  sleep 1
done

check() { # <설명> <기대 상태코드> <curl 인자...>
  local desc="$1" want="$2"; shift 2
  local got
  got=$(curl -s -o /dev/null -w '%{http_code}' "$@")
  if [[ "$got" != "$want" ]]; then
    echo "FAIL: $desc (expected $want, got $got)" >&2
    exit 1
  fi
  echo "ok   $desc -> $got"
}

check "GET /health" 200 "$BASE/health"
check "POST /tasks" 201 -X POST "$BASE/tasks" -H "Content-Type: application/json" \
  -d "{\"id\": $ID, \"title\": \"smoke test\"}"
check "GET /tasks/$ID" 200 "$BASE/tasks/$ID"
check "POST duplicate -> 409" 409 -X POST "$BASE/tasks" -H "Content-Type: application/json" \
  -d "{\"id\": $ID, \"title\": \"dup\"}"
check "DELETE /tasks/$ID" 204 -X DELETE "$BASE/tasks/$ID"
echo "smoke test passed"
