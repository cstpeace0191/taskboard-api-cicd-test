# .github/labels.json 의 라벨을 현재 저장소에 만들거나 갱신한다 (Windows PowerShell).
# 사용: .\scripts\setup_labels.ps1   (gh auth login, 저장소 루트에서 실행)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$labels = Get-Content -Raw -Encoding UTF8 (Join-Path $root ".github\labels.json") | ConvertFrom-Json
foreach ($l in $labels) {
    gh label create $l.name --color $l.color --description $l.description --force
    if ($LASTEXITCODE -ne 0) { throw "label create failed: $($l.name)" }
}
gh label list --limit 50
