#!/bin/bash
# =============================================================
# STEP 03: Docker 설치 확인 및 기본 점검
# 목적: docker --version, docker info, daemon 동작 여부 확인
# 실행: bash 03_docker_setup.sh
# =============================================================

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
err()   { echo -e "${RED}[ERROR]${NC} $1"; }
title() { echo -e "\n${YELLOW}========== $1 ==========${NC}"; }

# -------------------------------------------------------
# 1. Docker 설치 여부 확인
# -------------------------------------------------------
title "1. Docker 설치 여부 확인"
if ! command -v docker &> /dev/null; then
  err "Docker가 설치되어 있지 않습니다."
  echo ""
  echo "설치 방법 (Ubuntu/Debian):"
  echo "  curl -fsSL https://get.docker.com | sh"
  echo "  sudo usermod -aG docker \$USER"
  echo "  (재로그인 필요)"
  echo ""
  echo "설치 방법 (Mac - Docker Desktop):"
  echo "  https://www.docker.com/products/docker-desktop"
  exit 1
fi
ok "Docker 설치 확인 완료"

# -------------------------------------------------------
# 2. Docker 버전 확인
# -------------------------------------------------------
title "2. Docker 버전 확인 (docker --version)"
docker --version
echo ""
info "상세 버전 정보:"
docker version 2>/dev/null || echo "(daemon 미구동 시 client 정보만 표시)"

# -------------------------------------------------------
# 3. Docker 데몬 동작 확인
# -------------------------------------------------------
title "3. Docker 데몬 동작 확인 (docker info)"
if docker info &> /dev/null; then
  ok "Docker 데몬 정상 실행 중"
  echo ""
  docker info | grep -E "Server Version|Storage Driver|Total Memory|CPUs|Operating System|Docker Root Dir"
else
  err "Docker 데몬이 실행 중이지 않습니다."
  echo ""
  echo "데몬 시작 방법:"
  echo "  Linux:  sudo systemctl start docker"
  echo "  Mac:    Docker Desktop 앱 실행"
  exit 1
fi

# -------------------------------------------------------
# 4. 현재 이미지/컨테이너 상태 점검
# -------------------------------------------------------
title "4. 현재 이미지 목록 (docker images)"
docker images

title "5. 실행 중인 컨테이너 (docker ps)"
docker ps

title "6. 전체 컨테이너 (docker ps -a)"
docker ps -a

# -------------------------------------------------------
# 5. docker info 전체 저장 (문서화용)
# -------------------------------------------------------
LOGDIR="$HOME/dev-workstation/logs"
mkdir -p "$LOGDIR"

{
  echo "=== Docker 환경 점검 결과 ==="
  echo "일시: $(date)"
  echo ""
  echo "--- docker --version ---"
  docker --version
  echo ""
  echo "--- docker version ---"
  docker version 2>&1
  echo ""
  echo "--- docker info ---"
  docker info 2>&1
} > "$LOGDIR/docker_info.log"

ok "로그 저장 완료: $LOGDIR/docker_info.log"
echo ""
ok "03_docker_setup.sh 완료!"
echo "  다음 단계: bash 04_docker_run.sh"
