#!/usr/bin/env bash
# 워크플로를 트리거한 이슈에만 라벨을 추가·제거한다.
# 이슈 번호는 인자로 받지 않고 이벤트 페이로드에서 읽는다 (다른 이슈 조작 방지).
#   ./scripts/edit-issue-labels.sh --add-label bug --add-label P2 --remove-label needs-triage
set -euo pipefail

ISSUE=$(jq -r '.issue.number // empty' "${GITHUB_EVENT_PATH:?GITHUB_EVENT_PATH not set}")
[[ "$ISSUE" =~ ^[0-9]+$ ]] || { echo "Error: no issue number in event payload" >&2; exit 1; }

ADD=() REMOVE=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --add-label) ADD+=("$2"); shift 2 ;;
    --remove-label) REMOVE+=("$2"); shift 2 ;;
    *) echo "Error: only --add-label and --remove-label are accepted" >&2; exit 1 ;;
  esac
done

VALID=$(gh label list --limit 200 --json name --jq '.[].name')
ARGS=()
for l in "${ADD[@]}"; do
  # agent-ready는 사람만 붙인다 (구현 워크플로 트리거이므로)
  [[ "$l" == "agent-ready" ]] && continue
  grep -qxF "$l" <<<"$VALID" && ARGS+=(--add-label "$l")
done
for l in "${REMOVE[@]}"; do
  grep -qxF "$l" <<<"$VALID" && ARGS+=(--remove-label "$l")
done

if [[ ${#ARGS[@]} -eq 0 ]]; then
  echo "No valid labels to change"
  exit 0
fi
gh issue edit "$ISSUE" "${ARGS[@]}"
echo "Updated issue #$ISSUE: ${ARGS[*]}"
