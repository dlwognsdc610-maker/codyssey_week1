#!/bin/bash
# =============================================================
# STEP 08: Git 설정 및 GitHub 연동
# 목적: git config 설정, 로컬 저장소 초기화, 커밋, 원격 연결
# 실행: bash 08_git_setup.sh
# 주의: GIT_USER, GIT_EMAIL, GIT_REPO 환경변수 미리 설정 필요
#       export GIT_USER="이름"
#       export GIT_EMAIL="이메일"
#       export GIT_REPO="https://github.com/username/repo.git"
# =============================================================

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${RED}[WARN]${NC} $1"; }
title() { echo -e "\n${YELLOW}========== $1 ==========${NC}"; }

WORKDIR="$HOME/dev-workstation"

# -------------------------------------------------------
# 0. 환경변수 확인
# -------------------------------------------------------
title "0. 환경변수 확인"
if [ -z "$GIT_USER" ] || [ -z "$GIT_EMAIL" ]; then
  warn "GIT_USER 또는 GIT_EMAIL이 설정되지 않았습니다."
  warn "아래 명령으로 설정 후 다시 실행하세요:"
  echo ""
  echo '  export GIT_USER="Your Name"'
  echo '  export GIT_EMAIL="you@example.com"'
  echo '  export GIT_REPO="https://github.com/username/repo.git"  # 선택'
  echo ""
  warn "시연용으로 임시값을 사용합니다. 실제 정보로 교체하세요."
  GIT_USER="${GIT_USER:-"Dev User"}"
  GIT_EMAIL="${GIT_EMAIL:-"dev@example.com"}"
fi

info "설정 예정 정보:"
echo "  이름:  $GIT_USER"
echo "  이메일: $GIT_EMAIL"
echo "  원격:  ${GIT_REPO:-'(설정 안됨 - 로컬만 실습)'}"

# -------------------------------------------------------
# 1. Git 설치 확인
# -------------------------------------------------------
title "1. Git 설치 확인"
if ! command -v git &> /dev/null; then
  warn "Git이 설치되지 않았습니다."
  echo "설치 방법:"
  echo "  Ubuntu: sudo apt install git"
  echo "  Mac:    brew install git"
  exit 1
fi
git --version
ok "Git 설치 확인 완료"

# -------------------------------------------------------
# 2. Git 전역 설정
# -------------------------------------------------------
title "2. Git 전역 설정 (git config --global)"

git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main
git config --global core.editor "code --wait" 2>/dev/null || \
git config --global core.editor "vi"

# 한글 파일명 깨짐 방지
git config --global core.quotepath false

# 줄바꿈 설정 (OS별 자동)
case "$(uname -s)" in
  Linux*)  git config --global core.autocrlf input ;;
  Darwin*) git config --global core.autocrlf input ;;
  *)       git config --global core.autocrlf true ;;
esac

info "git config --list 결과:"
git config --list | grep -E "user\.|init\.|core\."
ok "Git 전역 설정 완료"

# -------------------------------------------------------
# 3. 로컬 저장소 초기화
# -------------------------------------------------------
title "3. 로컬 저장소 초기화"
cd "$WORKDIR"

if [ -d ".git" ]; then
  info "이미 Git 저장소입니다"
else
  git init
  ok "git init 완료"
fi

info "현재 저장소 상태:"
git status

# -------------------------------------------------------
# 4. .gitignore 생성
# -------------------------------------------------------
title "4. .gitignore 생성"
cat > "$WORKDIR/.gitignore" << 'EOF'
# 로그 디렉토리 (일부 예외)
logs/*.log
!logs/.gitkeep

# 민감 정보 절대 제외
*.pem
*.key
*.env
.env
.env.*
secrets/
credentials/

# Docker 관련
.docker-data/

# OS 파일
.DS_Store
Thumbs.db

# 에디터
.vscode/settings.json
*.swp
*~

# Node.js (보너스 과제 대비)
node_modules/
EOF

ok ".gitignore 생성 완료"
cat "$WORKDIR/.gitignore"

# -------------------------------------------------------
# 5. logs 디렉토리 추적용 .gitkeep
# -------------------------------------------------------
mkdir -p "$WORKDIR/logs"
touch "$WORKDIR/logs/.gitkeep"

# -------------------------------------------------------
# 6. README.md 생성 (기술 문서 뼈대)
# -------------------------------------------------------
title "5. README.md 생성 (기술 문서 뼈대)"
if [ -f "$WORKDIR/README.md" ]; then
  warn "README.md가 이미 존재하여 덮어쓰지 않습니다."
  echo "  위치: $WORKDIR/README.md"
else
  cat > "$WORKDIR/README.md" << EOREADME
# Dev Workstation 구축 과제

## 1. 프로젝트 개요
개발 워크스테이션 환경 구축 실습 — 터미널, 권한, Docker, Git/GitHub 연동

## 2. 실행 환경
| 항목 | 내용 |
|------|------|
| OS | $(uname -s) $(uname -r) |
| Shell | $SHELL |
| Docker | $(docker --version 2>/dev/null || echo '확인 필요') |
| Git | $(git --version) |
| 작성일 | $(date '+%Y-%m-%d') |

## 3. 수행 항목 체크리스트
- [ ] 터미널 기본 조작 (pwd, ls, mkdir, cp, mv, rm)
- [ ] 파일 권한 실습 (chmod 644/755/700)
- [ ] Docker 설치 및 점검 (docker --version, docker info)
- [ ] hello-world 및 ubuntu 컨테이너 실행
- [ ] Dockerfile 기반 커스텀 이미지 빌드
- [ ] 포트 매핑 접속 확인 (8080:80, 8081:80)
- [ ] 바인드 마운트 반영 확인
- [ ] Docker 볼륨 영속성 검증
- [ ] Git 설정 및 GitHub 연동

## 4. 스크립트 구성
| 스크립트 | 내용 |
|----------|------|
| 01_terminal_basics.sh | 터미널 기본 조작 실습 |
| 02_permissions.sh | 파일/디렉토리 권한 실습 |
| 03_docker_setup.sh | Docker 설치 점검 |
| 04_docker_run.sh | Docker 기본 실행 실습 |
| 05_build_webserver.sh | 커스텀 웹 서버 이미지 빌드 |
| 06_bind_mount.sh | 바인드 마운트 실습 |
| 07_volumes.sh | 볼륨 영속성 검증 |
| 08_git_setup.sh | Git/GitHub 설정 |
| 09_docker_compose.sh | (보너스) Docker Compose |

## 5. 검증 방법
각 스크립트 실행 후 \`logs/\` 디렉토리에 결과 저장됨

\`\`\`bash
# 웹 서버 접속 확인
curl http://localhost:8080

# 볼륨 확인
docker volume ls

# Git 설정 확인
git config --list
\`\`\`

## 6. 트러블슈팅
> 실습 중 발생한 문제와 해결 방법을 여기에 기록

### 문제 1: (제목)
- 문제: 
- 원인 가설:
- 확인:
- 해결:

### 문제 2: (제목)
- 문제:
- 원인 가설:
- 확인:
- 해결:
EOREADME

  ok "README.md 생성 완료"
fi

# -------------------------------------------------------
# 7. 첫 커밋
# -------------------------------------------------------
title "6. 첫 커밋"
cd "$WORKDIR"
git add .
git status

info "git commit 실행:"
git commit -m "feat: 개발 워크스테이션 초기 구성

- 터미널 기본 조작 실습 스크립트
- 권한 실습 스크립트
- Docker 설치 점검 스크립트
- 커스텀 웹 서버 Dockerfile 및 소스
- 바인드 마운트 / 볼륨 실습 스크립트
- Git 설정 스크립트
- README.md 기술 문서 뼈대"

info "커밋 로그:"
git log --oneline
ok "첫 커밋 완료"

# -------------------------------------------------------
# 8. 원격 저장소 연결 (선택)
# -------------------------------------------------------
title "7. GitHub 원격 저장소 연결 (선택)"
if [ -n "$GIT_REPO" ]; then
  info "원격 저장소 연결: $GIT_REPO"
  git remote add origin "$GIT_REPO" 2>/dev/null || \
  git remote set-url origin "$GIT_REPO"

  info "원격 저장소 확인:"
  git remote -v

  info "main 브랜치 push..."
  git push -u origin main && ok "GitHub push 완료!" || \
  warn "push 실패 - 인증 정보를 확인하세요 (GitHub token 또는 SSH 설정 필요)"
else
  warn "GIT_REPO가 설정되지 않아 원격 연결을 건너뜁니다."
  echo "  나중에 연결하려면:"
  echo "  git remote add origin https://github.com/username/repo.git"
  echo "  git push -u origin main"
fi

# -------------------------------------------------------
# 9. git config --list 전체 저장
# -------------------------------------------------------
LOGDIR="$WORKDIR/logs"
mkdir -p "$LOGDIR"
{
  echo "=== Git 설정 로그 ==="
  echo "일시: $(date)"
  echo ""
  echo "--- git --version ---"
  git --version
  echo ""
  echo "--- git config --list ---"
  git config --list
  echo ""
  echo "--- git log --oneline ---"
  git log --oneline
  echo ""
  echo "--- git remote -v ---"
  git remote -v 2>/dev/null || echo "(원격 저장소 없음)"
} > "$LOGDIR/git_setup.log"

ok "로그 저장: $LOGDIR/git_setup.log"
echo ""
ok "08_git_setup.sh 완료!"
echo ""
echo "  VSCode GitHub 연동 방법:"
echo "  1. VSCode 실행 → 소스 제어(Ctrl+Shift+G)"
echo "  2. 'GitHub에 게시' 또는 기존 원격 저장소 clone"
echo "  3. 좌하단 계정 아이콘 → GitHub 계정 로그인"
echo ""
echo "  다음 단계 (선택): bash 09_docker_compose.sh"
