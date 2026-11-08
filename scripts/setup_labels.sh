#!/usr/bin/env bash
# .github/labels.json 의 라벨을 현재 저장소에 만들거나 갱신한다.
# 사용: ./scripts/setup_labels.sh   (gh auth login, 저장소 루트에서 실행)
set -euo pipefail
cd "$(dirname "$0")/.."

# python3 / python 중 실제로 실행되는 것 (Windows의 python3 스토어 바로가기 회피)
PY_BIN=""
for c in python3 python; do
  if "$c" -c "" >/dev/null 2>&1; then PY_BIN="$c"; break; fi
done
[[ -n "$PY_BIN" ]] || { echo "Error: python not found" >&2; exit 1; }

PYTHONIOENCODING=utf-8 "$PY_BIN" - <<'PY' | while IFS=$'\t' read -r name color desc; do
import json
for l in json.load(open(".github/labels.json", encoding="utf-8")):
    print(f"{l['name']}\t{l['color']}\t{l['description']}")
PY
  desc="${desc%$'\r'}" # Windows 줄바꿈 제거
  gh label create "$name" --color "$color" --description "$desc" --force
done
gh label list --limit 50
