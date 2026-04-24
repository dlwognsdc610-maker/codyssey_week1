#!/bin/bash
# =============================================================
# STEP 04: Docker 기본 실행 실습
# 목적: hello-world, ubuntu 컨테이너 실행/내부 진입/종료 차이 확인
# 실행: bash 04_docker_run.sh
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

LOGDIR="$HOME/dev-workstation/logs"
mkdir -p "$LOGDIR"

# -------------------------------------------------------
# 1. hello-world 실행
# -------------------------------------------------------
title "1. hello-world 컨테이너 실행"
info "docker run hello-world 실행 중..."
docker run hello-world 2>&1 | tee "$LOGDIR/hello_world.log"
ok "hello-world 실행 성공 → 로그: $LOGDIR/hello_world.log"

# -------------------------------------------------------
# 2. ubuntu 이미지 pull
# -------------------------------------------------------
title "2. ubuntu 이미지 pull"
info "docker pull ubuntu:22.04 실행 중..."
docker pull ubuntu:22.04
echo ""
docker images ubuntu
ok "ubuntu:22.04 이미지 준비 완료"

# -------------------------------------------------------
# 3. ubuntu 컨테이너: exec로 명령 실행 (컨테이너 유지됨)
# -------------------------------------------------------
title "3. ubuntu 컨테이너 실행 + exec로 명령 실행"

# 백그라운드로 컨테이너 실행 (sleep infinity → 유지)
docker rm -f ubuntu-practice 2>/dev/null || true
docker run -d --name ubuntu-practice ubuntu:22.04 sleep infinity
ok "컨테이너 시작됨 (백그라운드)"

info "docker ps → 실행 중인 컨테이너 확인:"
docker ps --filter name=ubuntu-practice

echo ""
info "docker exec로 명령 실행 (컨테이너 유지됨):"
echo "--- ls / ---"
docker exec ubuntu-practice ls /

echo ""
echo "--- echo '안녕하세요 Docker!' ---"
docker exec ubuntu-practice echo '안녕하세요 Docker!'

echo ""
echo "--- cat /etc/os-release ---"
docker exec ubuntu-practice cat /etc/os-release

echo ""
echo "--- uname -a ---"
docker exec ubuntu-practice uname -a

# exec 후에도 컨테이너가 유지되는지 확인
echo ""
info "exec 후 컨테이너 상태 (여전히 실행 중이어야 함):"
docker ps --filter name=ubuntu-practice
ok "exec 사용 시 → 컨테이너가 종료되지 않음"

# -------------------------------------------------------
# 4. attach vs exec 차이 설명 (비대화형 환경에서 시뮬레이션)
# -------------------------------------------------------
title "4. attach / exec 차이 정리"
cat << 'EOF'
  ┌──────────────────────────────────────────────────────────────┐
  │  docker exec  vs  docker attach                               │
  ├────────────────────┬─────────────────────────────────────────┤
  │  exec               │  attach                                 │
  ├────────────────────┼─────────────────────────────────────────┤
  │  새 프로세스 실행   │  기존 PID 1 프로세스에 연결             │
  │  컨테이너 유지됨    │  exit 입력 시 컨테이너 종료 가능        │
  │  권장 방식          │  PID 1이 bash가 아니면 쓰기 어려움      │
  ├────────────────────┼─────────────────────────────────────────┤
  │  docker exec -it   │  docker attach <이름>                   │
  │    <이름> bash     │  (Ctrl+P, Ctrl+Q → detach, 컨테이너 유지)│
  └────────────────────┴─────────────────────────────────────────┘

  ※ 대화형 진입 예시:
     docker exec -it ubuntu-practice bash
     → 컨테이너 내 bash 실행, exit 해도 컨테이너는 살아있음
EOF

# -------------------------------------------------------
# 5. 컨테이너 중지 / 삭제
# -------------------------------------------------------
title "5. 컨테이너 중지 및 삭제"
info "docker stop ubuntu-practice"
docker stop ubuntu-practice

info "docker ps -a (중지됨 확인):"
docker ps -a --filter name=ubuntu-practice

info "docker rm ubuntu-practice"
docker rm ubuntu-practice

info "docker ps -a (삭제됨 확인):"
docker ps -a --filter name=ubuntu-practice
ok "컨테이너 정리 완료"

# -------------------------------------------------------
# 6. 이미지/컨테이너 운영 명령 실습
# -------------------------------------------------------
title "6. 운영 명령 실습 (images, ps, logs, stats)"

info "docker images (현재 이미지 목록):"
docker images

info "docker ps -a (전체 컨테이너, 현재는 없음):"
docker ps -a

# logs 확인용 임시 컨테이너
docker run --name log-test ubuntu:22.04 bash -c "echo 'log line 1'; echo 'log line 2'; echo 'log line 3'"
echo ""
info "docker logs log-test:"
docker logs log-test
docker rm log-test

# stats는 백그라운드 컨테이너 필요
docker run -d --name stats-test ubuntu:22.04 sleep 10
echo ""
info "docker stats --no-stream stats-test:"
docker stats --no-stream stats-test
docker rm -f stats-test

# -------------------------------------------------------
# 7. 로그 저장
# -------------------------------------------------------
{
  echo "=== Docker 기본 실행 로그 ==="
  echo "일시: $(date)"
  echo ""
  echo "--- docker images ---"
  docker images
  echo ""
  echo "--- docker ps -a ---"
  docker ps -a
} > "$LOGDIR/docker_run.log"

ok "로그 저장: $LOGDIR/docker_run.log"
echo ""
ok "04_docker_run.sh 완료!"
echo "  다음 단계: bash 05_build_webserver.sh"
