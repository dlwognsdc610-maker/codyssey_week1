#!/bin/bash
# =============================================================
# STEP 07: Docker 볼륨 영속성 검증
# 목적: 볼륨 생성 → 컨테이너 연결 → 데이터 기록 → 컨테이너 삭제
#       → 새 컨테이너 재연결 → 데이터 유지 확인
# 실행: bash 07_volumes.sh
# =============================================================

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
title() { echo -e "\n${YELLOW}========== $1 ==========${NC}"; }

LOGDIR="$HOME/dev-workstation/logs"
VOLUME_NAME="workstation-data"

# -------------------------------------------------------
# 1. 볼륨 개념 설명
# -------------------------------------------------------
title "Docker 볼륨이란?"
cat << 'EOF'
  Docker 볼륨 vs 바인드 마운트 비교:
  
  ┌─────────────────┬────────────────────┬────────────────────┐
  │                 │ 바인드 마운트       │ Docker 볼륨         │
  ├─────────────────┼────────────────────┼────────────────────┤
  │ 호스트 경로     │ 지정 필요          │ Docker가 관리       │
  │ 이식성          │ 호스트 종속        │ 플랫폼 독립적       │
  │ 권한 관리       │ 호스트 파일시스템  │ Docker가 처리       │
  │ 성능            │ 일반              │ 최적화됨            │
  │ 용도            │ 개발(코드 공유)    │ 운영(DB, 로그)      │
  └─────────────────┴────────────────────┴────────────────────┘
  
  볼륨 위치: /var/lib/docker/volumes/<volume-name>/_data
EOF

# -------------------------------------------------------
# 2. 볼륨 생성
# -------------------------------------------------------
title "1. 볼륨 생성 (docker volume create)"
docker volume rm "$VOLUME_NAME" 2>/dev/null || true
docker volume create "$VOLUME_NAME"

info "볼륨 목록 확인:"
docker volume ls | grep -E "DRIVER|$VOLUME_NAME"

info "볼륨 상세 정보:"
docker volume inspect "$VOLUME_NAME"
ok "볼륨 '$VOLUME_NAME' 생성 완료"

# -------------------------------------------------------
# 3. 첫 번째 컨테이너로 데이터 기록
# -------------------------------------------------------
title "2. 컨테이너 1: 볼륨에 데이터 기록"
docker rm -f vol-writer 2>/dev/null || true

docker run -d \
  --name vol-writer \
  -v "$VOLUME_NAME":/data \
  ubuntu:22.04 \
  sleep 30

info "컨테이너 1 실행 확인:"
docker ps --filter name=vol-writer

# 볼륨에 여러 파일 기록
info "볼륨(/data)에 데이터 기록 중..."

docker exec vol-writer bash -c "
  mkdir -p /data/records
  echo 'Hello, Docker Volume!' > /data/hello.txt
  echo 'This data persists across containers' >> /data/hello.txt
  echo '========================================' >> /data/hello.txt

  # 타임스탬프 포함 로그 파일
  echo \"[$(date)] 컨테이너-1: 첫 번째 기록\" > /data/records/app.log
  echo \"[$(date)] 컨테이너-1: 데이터 저장 완료\" >> /data/records/app.log

  # 구조화된 데이터
  echo '{\"container\":\"vol-writer\",\"message\":\"volume test\",\"status\":\"written\"}' > /data/records/data.json

  echo '--- /data 내용 ---'
  ls -la /data/
  echo ''
  echo '--- hello.txt ---'
  cat /data/hello.txt
  echo ''
  echo '--- records/ ---'
  ls -la /data/records/
"

ok "컨테이너 1에서 데이터 기록 완료"

# -------------------------------------------------------
# 4. 컨테이너 삭제 (강제 삭제)
# -------------------------------------------------------
title "3. 컨테이너 1 삭제 (데이터는 볼륨에 유지)"
info "컨테이너 삭제 전 상태:"
docker ps -a --filter name=vol-writer

docker rm -f vol-writer

info "컨테이너 삭제 후:"
docker ps -a --filter name=vol-writer
ok "컨테이너 'vol-writer' 삭제 완료"

info "볼륨은 여전히 존재하는가?"
docker volume ls | grep "$VOLUME_NAME"
ok "볼륨은 컨테이너 삭제와 무관하게 유지됨!"

# -------------------------------------------------------
# 5. 두 번째 컨테이너로 데이터 유지 확인
# -------------------------------------------------------
title "4. 컨테이너 2: 동일 볼륨 재연결 → 데이터 유지 확인"
docker rm -f vol-reader 2>/dev/null || true

docker run -d \
  --name vol-reader \
  -v "$VOLUME_NAME":/data \
  ubuntu:22.04 \
  sleep 30

info "컨테이너 2 실행 확인:"
docker ps --filter name=vol-reader

info "볼륨 데이터 확인 (컨테이너 1이 기록한 데이터가 있어야 함):"
docker exec vol-reader bash -c "
  echo '=== 볼륨 데이터 영속성 확인 ==='
  echo ''
  echo '--- /data 파일 목록 ---'
  ls -la /data/
  echo ''
  echo '--- hello.txt (컨테이너 1이 작성) ---'
  cat /data/hello.txt
  echo ''
  echo '--- records/app.log (컨테이너 1이 작성) ---'
  cat /data/records/app.log
  echo ''
  echo '--- records/data.json (컨테이너 1이 작성) ---'
  cat /data/records/data.json
  echo ''
  echo '=== 영속성 검증: 컨테이너 1 삭제 후에도 데이터 유지 확인 ==='
"

# 컨테이너 2도 데이터 추가
docker exec vol-reader bash -c "
  echo \"[$(date)] 컨테이너-2: 데이터 확인 완료\" >> /data/records/app.log
  echo \"[$(date)] 컨테이너-2: 새 데이터 추가\" >> /data/records/app.log
  cat /data/records/app.log
"

ok "볼륨 영속성 검증 완료!"
ok "컨테이너 1이 기록한 데이터가 컨테이너 2에서도 정상 확인됨"

# -------------------------------------------------------
# 6. 컨테이너 2 삭제 후 볼륨 최종 확인
# -------------------------------------------------------
title "5. 컨테이너 2 삭제 후 볼륨 최종 상태"
docker rm -f vol-reader

info "최종 볼륨 목록:"
docker volume ls | grep -E "DRIVER|$VOLUME_NAME"
ok "볼륨 '$VOLUME_NAME' 유지 확인"

# -------------------------------------------------------
# 7. 볼륨 inspect로 호스트 경로 확인
# -------------------------------------------------------
title "6. 볼륨 실제 저장 위치"
MOUNT_POINT=$(docker volume inspect "$VOLUME_NAME" --format '{{.Mountpoint}}')
info "Docker 볼륨 호스트 저장 경로: $MOUNT_POINT"
info "(Linux: /var/lib/docker/volumes/... - root 권한 필요)"

# -------------------------------------------------------
# 8. 로그 저장
# -------------------------------------------------------
{
  echo "=== Docker 볼륨 영속성 검증 로그 ==="
  echo "일시: $(date)"
  echo ""
  echo "볼륨명: $VOLUME_NAME"
  echo ""
  echo "--- docker volume ls ---"
  docker volume ls
  echo ""
  echo "--- docker volume inspect ---"
  docker volume inspect "$VOLUME_NAME"
} > "$LOGDIR/volumes.log"

echo ""
ok "로그 저장: $LOGDIR/volumes.log"
echo ""
ok "07_volumes.sh 완료!"
echo "  볼륨 이름: $VOLUME_NAME (유지 중)"
echo "  다음 단계: bash 08_git_setup.sh"
