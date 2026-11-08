#!/usr/bin/env bash
# CI/CD 실습 준비: main 브랜치 ruleset + staging/production 환경 생성.
#   ./scripts/setup_cicd.sh            # 승인 인원 0 (혼자 실습)
#   APPROVALS=1 ./scripts/setup_cicd.sh  # 팀 실습: PR 승인 1명 필요
# 공개 저장소 기준 (비공개 저장소의 ruleset·환경 승인은 유료 플랜 필요).
set -euo pipefail
cd "$(dirname "$0")/.."
APPROVALS="${APPROVALS:-0}"

REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
ME=$(gh api user --jq .id)
echo "repo=$REPO approvals=$APPROVALS"

# 1) ruleset: PR 필수, 필수 검사 ci-ok, 강제 push·삭제 금지 (같은 이름이 있으면 갱신)
BODY=$(sed "s/\"required_approving_review_count\": 0/\"required_approving_review_count\": $APPROVALS/" \
  .github/rulesets/main-protection.json)
EXISTING=$(gh api "repos/$REPO/rulesets" --jq '.[] | select(.name=="main-protection") | .id')
if [[ -n "$EXISTING" ]]; then
  gh api -X PUT "repos/$REPO/rulesets/$EXISTING" --input - <<<"$BODY" --jq '"updated ruleset " + (.id|tostring)'
else
  gh api -X POST "repos/$REPO/rulesets" --input - <<<"$BODY" --jq '"created ruleset " + (.id|tostring)'
fi

# 2) 환경: staging (main 브랜치만 배포), production (main + 본인 승인 필요)
for ENV in staging production; do
  if [[ "$ENV" == production ]]; then
    REVIEWERS="[{\"type\":\"User\",\"id\":$ME}]"
  else
    REVIEWERS="[]"
  fi
  gh api -X PUT "repos/$REPO/environments/$ENV" --input - --jq '"environment " + .name' <<JSON
{
  "reviewers": $REVIEWERS,
  "deployment_branch_policy": { "protected_branches": false, "custom_branch_policies": true }
}
JSON
  # 배포 가능한 브랜치: main
  gh api -X POST "repos/$REPO/environments/$ENV/deployment-branch-policies" \
    -f name=main -f type=branch --jq '"  branch policy: " + .name' 2>/dev/null \
    || echo "  branch policy: main (already set)"
done

# 3) Dependabot alerts 켜기 → dependency graph 활성화 (없으면 security.yml의 dependency-review가
#    "Dependency review is not supported on this repository"로 실패)
gh api -X PUT "repos/$REPO/vulnerability-alerts" --silent && echo "vulnerability alerts + dependency graph: on"

echo "done. 확인: Settings → Rules / Environments / Code security"
