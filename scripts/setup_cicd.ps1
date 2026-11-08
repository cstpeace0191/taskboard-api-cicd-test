# CI/CD 실습 준비 (Windows PowerShell): main 브랜치 ruleset + staging/production 환경 생성.
#   .\scripts\setup_cicd.ps1              # 승인 인원 0 (혼자 실습)
#   .\scripts\setup_cicd.ps1 -Approvals 1 # 팀 실습
param([int]$Approvals = 0)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$repo = gh repo view --json nameWithOwner --jq .nameWithOwner
$me = gh api user --jq .id
"repo=$repo approvals=$Approvals"

function Invoke-GhJson([string]$Method, [string]$Path, [string]$Json) {
    $tmp = New-TemporaryFile
    [IO.File]::WriteAllText($tmp, $Json, (New-Object Text.UTF8Encoding $false))
    try { gh api -X $Method $Path --input $tmp.FullName --jq '.name // .id' }
    finally { Remove-Item $tmp }
    if ($LASTEXITCODE -ne 0) { throw "gh api $Method $Path failed" }
}

# 1) ruleset
$body = Get-Content -Raw -Encoding UTF8 (Join-Path $root ".github\rulesets\main-protection.json")
$body = $body -replace '"required_approving_review_count": 0', ('"required_approving_review_count": ' + $Approvals)
$existing = gh api "repos/$repo/rulesets" --jq '.[] | select(.name=="main-protection") | .id'
if ($existing) { Invoke-GhJson PUT "repos/$repo/rulesets/$existing" $body }
else { Invoke-GhJson POST "repos/$repo/rulesets" $body }

# 2) environments
foreach ($envName in "staging", "production") {
    $reviewers = if ($envName -eq "production") { "[{`"type`":`"User`",`"id`":$me}]" } else { "[]" }
    $json = "{`"reviewers`": $reviewers, `"deployment_branch_policy`": {`"protected_branches`": false, `"custom_branch_policies`": true}}"
    Invoke-GhJson PUT "repos/$repo/environments/$envName" $json
    gh api -X POST "repos/$repo/environments/$envName/deployment-branch-policies" -f name=main -f type=branch --jq .name 2>$null
    if ($LASTEXITCODE -ne 0) { "  branch policy: main (already set)" }
}
"done. 확인: Settings -> Rules / Environments"
