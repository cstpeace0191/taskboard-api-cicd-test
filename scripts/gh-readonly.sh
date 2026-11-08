#!/usr/bin/env bash
# gh CLI 읽기 전용 래퍼 (GitHub Actions의 이슈 분류 에이전트용).
# 허용: issue view, issue list, label list. 현재 저장소로만 범위를 제한한다.
#   ./scripts/gh-readonly.sh issue view 3
#   ./scripts/gh-readonly.sh issue list --state open --limit 30
#   ./scripts/gh-readonly.sh label list
set -euo pipefail

REPO="${GH_REPO:-${GITHUB_REPOSITORY:-}}"
if [[ ! "$REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  echo "Error: GITHUB_REPOSITORY must be owner/repo" >&2
  exit 1
fi
export GH_REPO="$REPO" GH_HOST=github.com

case "${1:-} ${2:-}" in
  "issue view" | "issue list" | "label list") ;;
  *)
    echo "Error: only 'issue view', 'issue list', 'label list' are allowed" >&2
    exit 1
    ;;
esac
SUB1="$1" SUB2="$2"
shift 2

ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --comments) ARGS+=("$1"); shift ;;
    --state | --limit | --label)
      [[ $# -ge 2 ]] || { echo "Error: $1 needs a value" >&2; exit 1; }
      ARGS+=("$1" "$2"); shift 2 ;;
    -*) echo "Error: flag $1 is not allowed" >&2; exit 1 ;;
    *)
      [[ "$1" =~ ^[0-9]+$ ]] || { echo "Error: positional argument must be an issue number" >&2; exit 1; }
      ARGS+=("$1"); shift ;;
  esac
done

exec gh "$SUB1" "$SUB2" "${ARGS[@]}"
