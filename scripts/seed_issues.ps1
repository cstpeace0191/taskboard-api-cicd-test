# 실습용 이슈 5개를 순서대로 등록한다 (Windows PowerShell). 새 저장소라면 #1~#5가 된다.
# 사용: .\scripts\seed_issues.ps1   (라벨 생성 후, 저장소 루트에서 실행)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$issues = @(
    @("GET /tasks?done=false 필터가 무시되고 전체 목록이 반환됨", "01-done-filter.md"),
    @("PATCH /tasks/{id} 로 제목을 빈 문자열로 바꿀 수 있음", "02-empty-title-patch.md"),
    @("없는 작업을 DELETE 하면 500 오류", "03-delete-missing-500.md"),
    @("GET /tasks 페이지네이션 (limit, offset) 추가", "04-pagination.md"),
    @("GET /tasks/stats 통계 엔드포인트 추가", "05-stats-endpoint.md")
)
foreach ($i in $issues) {
    $body = Join-Path $root "scripts\issues\$($i[1])"
    gh issue create --title $i[0] --body-file $body --label needs-triage
    if ($LASTEXITCODE -ne 0) { throw "issue create failed: $($i[0])" }
}
gh issue list --limit 10
