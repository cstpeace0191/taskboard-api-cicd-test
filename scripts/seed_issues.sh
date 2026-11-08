#!/usr/bin/env bash
# 실습용 이슈 5개를 순서대로 등록한다. 새 저장소라면 #1~#5가 된다.
# 사용: ./scripts/seed_issues.sh   (라벨 생성 후, 저장소 루트에서 실행)
set -euo pipefail
cd "$(dirname "$0")/.."

create() {
  gh issue create --title "$1" --body-file "scripts/issues/$2" --label needs-triage
}

create "GET /tasks?done=false 필터가 무시되고 전체 목록이 반환됨" 01-done-filter.md
create "PATCH /tasks/{id} 로 제목을 빈 문자열로 바꿀 수 있음" 02-empty-title-patch.md
create "없는 작업을 DELETE 하면 500 오류" 03-delete-missing-500.md
create "GET /tasks 페이지네이션 (limit, offset) 추가" 04-pagination.md
create "GET /tasks/stats 통계 엔드포인트 추가" 05-stats-endpoint.md

gh issue list --limit 10
