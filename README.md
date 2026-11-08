# TaskBoard API — Claude × GitHub Issue·PR·CI/CD 실습 저장소

이 폴더를 그대로 **새 GitHub 저장소**로 올려 실습합니다.
작은 FastAPI 서비스에 버그 3개와 기능 요청 2개가 이슈로 준비되어 있고,
Claude Code(로컬 CLI·GitHub Actions)로 이슈를 분류하고, 고치고, PR을 리뷰한 뒤
GitHub Actions CI/CD로 검증·배포·릴리스까지 진행합니다.

## 구성

| 경로 | 역할 |
|---|---|
| `app/main.py` | TaskBoard API (메모리 저장소). 이슈 #1~#3의 버그가 일부러 남아 있음 |
| `tests/test_tasks.py` | pytest 11개. 현재 모두 통과 (버그는 테스트에 안 잡힘) |
| `requirements-runtime.txt` / `requirements.txt` | 이미지용 런타임 의존성 / 개발·CI용 (런타임 포함) |
| `Dockerfile` · `.dockerignore` | 컨테이너 이미지 (비루트 사용자, HEALTHCHECK) |
| `CLAUDE.md` | Claude가 매 세션 읽는 규칙: 명령, 이슈→PR 절차, 리뷰 기준, CI/CD, 금지 사항 |
| `.claude/commands/` | `/fix-issue`(이슈→PR), `/label-issue`(분류), `/fix-ci`(CI 실패 수정) |
| `.claude/settings.json` | 로컬 권한 규칙 (force push·merge 금지 등) |
| `.github/ISSUE_TEMPLATE/` · `pull_request_template.md` | 이슈 폼, PR 템플릿 |
| `.github/labels.json` | 라벨 14개 (`agent-ready`, `ci-autofix` 포함) |
| `.github/rulesets/main-protection.json` | main 보호 규칙: PR 필수, 필수 검사 `ci-ok` |
| `.github/dependabot.yml` | pip · GitHub Actions · Docker 주간 업데이트 |
| `scripts/setup_labels.*` · `seed_issues.*` | 라벨 생성, 실습 이슈 5개 등록 |
| `scripts/setup_cicd.*` | ruleset + staging/production 환경 생성 |
| `scripts/smoke_test.sh` | 배포된 API 스모크 테스트 (CI·CD·로컬 공용) |
| `scripts/gh-readonly.sh` · `edit-issue-labels.sh` | 분류 에이전트가 쓸 수 있는 유일한 명령 (권한 최소화) |

### 워크플로

| 파일 | 트리거 | 하는 일 |
|---|---|---|
| `ci.yml` | PR, main push | lint → test(3.11/3.12/3.13) · image 빌드+스모크 → **`ci-ok`** (필수 검사) |
| `security.yml` | PR, main, 매주 월 | pip-audit · dependency review · CodeQL (뒤의 둘은 공개 저장소) |
| `cd.yml` | main push | GHCR 이미지 push → staging 스모크 → production 승인 후 같은 digest 승격 |
| `release.yml` | `v*.*.*` 태그 | 버전 확인 → 테스트 → 버전 태그 이미지 → GitHub Release (선택: Claude 노트) |
| `claude.yml` | `@claude` 멘션 | 대화형 실행 |
| `claude-triage.yml` | 이슈 열림 | 자동 라벨 |
| `claude-implement.yml` | `agent-ready` 라벨 | `/fix-issue` → draft PR |
| `claude-review.yml` | PR 열림·갱신 (draft·봇 제외) | 리뷰 기준대로 인라인 리뷰 |
| `claude-ci-autofix.yml` | CI 실패 + PR에 `ci-autofix` 라벨 | `/fix-ci` → `[autofix]` 커밋 (1회) |

## 실습 순서

| Lab | 대상 | 내용 |
|---|---|---|
| 1–2 | #1–#5 | 저장소·App·시크릿·라벨·이슈, 자동 분류 |
| 3 | #1 `done=false` 필터 무시 | 로컬 CLI `/fix-issue 1` |
| 4 | #2 PATCH로 빈 제목 허용 | 이슈 댓글 `@claude` |
| 5 | #3 없는 작업 DELETE → 500 | `agent-ready` 라벨 → 자동 PR |
| 6 | #5 `GET /tasks/stats` | PR 자동 리뷰 → `@claude` 수정 |
| 7 | #4 페이지네이션 | 도전 과제 (Plan 모드, Breaking change) |
| 8 | 데모 PR | ruleset·`ci-ok` 게이트, `ci-autofix` 자동 수정 |
| 9 | main · `v0.3.0` | CD (GHCR → staging → production 승인), 릴리스 |

## 빠른 시작

```bash
# 0) 로컬 확인
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
ruff check . && ruff format --check . && pytest --cov=app

# 1) GitHub 저장소 만들기 (워크플로 파일이 첫 커밋에 포함됨)
#    공개 저장소 권장: 무료 플랜에서 ruleset·환경 승인·CodeQL 사용 가능 (시크릿은 공개되지 않음)
git init -b main && git add -A && git commit -m "chore: initial taskboard-api"
gh repo create taskboard-api --public --source . --push

# 2) Claude GitHub App 설치 + 시크릿 (수동 설치 권장)
#    https://github.com/apps/claude 에서 이 저장소에 App 설치 후:
gh secret set ANTHROPIC_API_KEY          # 또는 claude setup-token → CLAUDE_CODE_OAUTH_TOKEN
#    /install-github-app 은 workflow PR을 만들어 번호를 하나 차지하므로, 쓴다면 PR은 만들지 않는다

# 3) 라벨 → 이슈 (이슈가 열릴 때마다 claude-triage.yml 이 라벨을 붙임)
./scripts/setup_labels.sh      # Windows: .\scripts\setup_labels.ps1
./scripts/seed_issues.sh       # Windows: .\scripts\seed_issues.ps1

# 4) (Lab 8 전에) main 보호 규칙과 배포 환경
./scripts/setup_cicd.sh        # Windows: .\scripts\setup_cicd.ps1   팀 실습: APPROVALS=1
```

이슈 번호를 #1~#5로 맞추려면 **이슈를 만들기 전에 PR을 열지 마세요** (이슈와 PR은 번호를 공유합니다).
`setup_cicd`를 실행하면 main에 직접 push할 수 없으므로, 그 뒤의 변경은 모두 PR로 진행합니다.

## 완료 기준
- `pytest --cov=app --cov-fail-under=80`, `ruff check .`, `ruff format --check .` 통과 (= `ci-ok` 녹색)
- 모든 PR이 `Closes #N`으로 이슈와 연결되고, 병합 시 이슈가 자동으로 닫힘
- Claude가 만든 PR·커밋도 `ci-ok` 통과 + 리뷰 스레드 해결 후에만 병합
- production 배포는 환경 승인 후 staging에서 검증한 같은 이미지 digest로만
