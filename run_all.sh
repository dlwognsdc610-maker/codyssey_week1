#!/bin/bash
# =============================================================
# RUN ALL: 전체 과제 스크립트 순서대로 실행
# 실행: bash run_all.sh [--skip-compose]
# 옵션:
#   --skip-compose  보너스 과제(09) 건너뜀
#   --step N        N번 스크립트부터 시작
# =============================================================

SKIP_COMPOSE=false
START_STEP=1

for arg in "$@"; do
  case $arg in
    --skip-compose) SKIP_COMPOSE=true ;;
    --step) shift; START_STEP="$1" ;;
    --step=*) START_STEP="${arg#*=}" ;;
  esac
done

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/dev-workstation/logs/run_all_$(date '+%Y%m%d_%H%M%S').log"
mkdir -p "$HOME/dev-workstation/logs"

run_step() {
  local step=$1
  local script=$2
  local desc=$3

  if [ "$step" -lt "$START_STEP" ]; then
    echo -e "${CYAN}[SKIP]${NC} STEP $step: $desc (--step=$START_STEP 이후부터 시작)"
    return 0
  fi

  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}  STEP $step: $desc${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  if bash "$SCRIPT_DIR/$script" 2>&1 | tee -a "$LOG_FILE"; then
    echo -e "${GREEN}[완료] STEP $step: $desc${NC}"
  else
    echo -e "${RED}[실패] STEP $step: $desc — 계속하려면 Enter, 중단하려면 Ctrl+C${NC}"
    read -r
  fi
}

# 헤더 출력
echo -e "${CYAN}"
cat << 'EOF'
  ╔══════════════════════════════════════════════╗
  ║   Dev Workstation 구축 과제 — 전체 실행      ║
  ╚══════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo "로그 저장 위치: $LOG_FILE"
echo ""

# 실행 전 요약
echo "실행 예정 단계:"
echo "  STEP 1: 터미널 기본 조작"
echo "  STEP 2: 파일 권한 실습"
echo "  STEP 3: Docker 설치 점검"
echo "  STEP 4: Docker 기본 실행"
echo "  STEP 5: 커스텀 웹 서버 빌드"
echo "  STEP 6: 바인드 마운트"
echo "  STEP 7: 볼륨 영속성"
echo "  STEP 8: Git/GitHub 설정"
[ "$SKIP_COMPOSE" = false ] && echo "  STEP 9: Docker Compose (보너스)"
echo ""

if [ "$START_STEP" -le 8 ]; then
  echo -e "${YELLOW}Git 설정이 필요합니다. 환경변수를 미리 설정하세요:${NC}"
  echo '  export GIT_USER="Your Name"'
  echo '  export GIT_EMAIL="you@example.com"'
  echo '  export GIT_REPO="https://github.com/username/repo.git"  # 선택'
  echo ""
fi

echo "계속하려면 Enter, 취소하려면 Ctrl+C..."
read -r

# ── 단계별 실행 ─────────────────────────────────────────────
START_TIME=$(date +%s)

run_step 1 "01_terminal_basics.sh" "터미널 기본 조작"
run_step 2 "02_permissions.sh"     "파일 권한 실습"
run_step 3 "03_docker_setup.sh"    "Docker 설치 점검"
run_step 4 "04_docker_run.sh"      "Docker 기본 실행"
run_step 5 "05_build_webserver.sh" "커스텀 웹 서버 빌드"
run_step 6 "06_bind_mount.sh"      "바인드 마운트"
run_step 7 "07_volumes.sh"         "볼륨 영속성"
run_step 8 "08_git_setup.sh"       "Git/GitHub 설정"

if [ "$SKIP_COMPOSE" = false ]; then
  run_step 9 "09_docker_compose.sh" "Docker Compose (보너스)"
fi

# ── 완료 요약 ────────────────────────────────────────────────
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  전체 완료! (소요시간: ${ELAPSED}초)${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "확인 사항:"
echo "  1. 브라우저: http://localhost:8080 (웹 서버)"
echo "  2. 로그:     $HOME/dev-workstation/logs/"
echo "  3. README:   $HOME/dev-workstation/README.md"
echo "  4. Git:      git -C ~/dev-workstation log --oneline"
echo ""
echo "전체 로그: $LOG_FILE"
