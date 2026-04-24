#!/bin/bash
# =============================================================
# STEP 06: 바인드 마운트 실습 (호스트 변경 → 컨테이너 반영)
# 목적: -v 호스트경로:컨테이너경로 로 실시간 파일 공유 확인
# 실행: bash 06_bind_mount.sh
# 전제: 05_build_webserver.sh 실행 완료 (my-web:1.0 이미지 필요)
# =============================================================

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
title() { echo -e "\n${YELLOW}========== $1 ==========${NC}"; }

WORKDIR="$HOME/dev-workstation"
MOUNTDIR="$WORKDIR/bind_site"
LOGDIR="$WORKDIR/logs"
mkdir -p "$MOUNTDIR" "$LOGDIR"

# -------------------------------------------------------
# 1. 바인드 마운트 개념 설명
# -------------------------------------------------------
title "바인드 마운트란?"
cat << 'EOF'
  바인드 마운트: 호스트 디렉토리를 컨테이너 내부 경로에 직접 연결
  
  docker run -v /host/path:/container/path ...
  
  특징:
  - 호스트 파일 변경 → 컨테이너에서 즉시 반영
  - 컨테이너 파일 변경 → 호스트에도 반영
  - 개발 환경에서 코드 수정 시 컨테이너 재시작 불필요
  - 컨테이너 삭제 후에도 호스트 파일은 유지됨

  포트 매핑이 필요한 이유:
  - 컨테이너는 격리된 네트워크를 사용 (docker0 브리지)
  - 호스트 포트와 연결하지 않으면 외부에서 접근 불가
  - -p 8080:80 → 호스트:8080 → 컨테이너:80 으로 트래픽 전달
EOF

# -------------------------------------------------------
# 2. 마운트할 초기 HTML 파일 생성
# -------------------------------------------------------
title "1. 호스트 파일 준비 (변경 전)"
cat > "$MOUNTDIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <title>바인드 마운트 테스트</title>
  <style>
    body { font-family: system-ui; background: #1a1a2e; color: #eee;
           display: flex; align-items: center; justify-content: center; min-height: 100vh; }
    .card { background: #16213e; border-radius: 12px; padding: 40px; text-align: center; }
    h1 { color: #e94560; font-size: 2rem; }
    .version { background: #e94560; color: #fff; padding: 4px 12px;
                border-radius: 99px; font-size: 12px; margin-top: 12px; display: inline-block; }
  </style>
</head>
<body>
  <div class="card">
    <h1>바인드 마운트 - 변경 전</h1>
    <p>호스트 파일이 컨테이너에 마운트되었습니다</p>
    <span class="version">VERSION 1.0</span>
  </div>
</body>
</html>
EOF

info "변경 전 파일 생성: $MOUNTDIR/index.html"
cat "$MOUNTDIR/index.html" | head -10
ok "변경 전 파일 준비 완료"

# -------------------------------------------------------
# 3. 바인드 마운트로 컨테이너 실행
# -------------------------------------------------------
title "2. 바인드 마운트 컨테이너 실행"
docker rm -f bind-test 2>/dev/null || true

MOUNT_ABS=$(realpath "$MOUNTDIR")
echo "호스트 경로: $MOUNT_ABS"
echo "마운트 대상: /usr/share/nginx/html"
echo ""

docker run -d \
  --name bind-test \
  -p 8082:80 \
  -v "$MOUNT_ABS":/usr/share/nginx/html:ro \
  nginx:alpine

info "컨테이너 실행 확인:"
docker ps --filter name=bind-test
sleep 1

# -------------------------------------------------------
# 4. 변경 전 응답 확인
# -------------------------------------------------------
title "3. 변경 전 응답 (컨테이너 재시작 없음)"
info "curl http://localhost:8082 (변경 전):"
curl -s http://localhost:8082 | grep -E "(VERSION|변경)"
ok "변경 전 상태 확인 완료"

# -------------------------------------------------------
# 5. 호스트 파일 변경 (컨테이너 재시작 없음)
# -------------------------------------------------------
title "4. 호스트 파일 변경 (컨테이너 재시작 없이)"
info "index.html 수정 중..."

cat > "$MOUNTDIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <title>바인드 마운트 테스트</title>
  <style>
    body { font-family: system-ui; background: #0d1117; color: #eee;
           display: flex; align-items: center; justify-content: center; min-height: 100vh; }
    .card { background: #161b22; border-radius: 12px; padding: 40px; text-align: center;
            border: 1px solid #30a46c; }
    h1 { color: #30a46c; font-size: 2rem; }
    .version { background: #30a46c; color: #fff; padding: 4px 12px;
                border-radius: 99px; font-size: 12px; margin-top: 12px; display: inline-block; }
    .changed { color: #f59e0b; font-size: 0.9rem; margin-top: 8px; }
  </style>
</head>
<body>
  <div class="card">
    <h1>바인드 마운트 - 변경 후!</h1>
    <p>호스트에서 파일을 수정했습니다</p>
    <p class="changed">컨테이너 재시작 없이 반영됨!</p>
    <span class="version">VERSION 2.0 (UPDATED)</span>
  </div>
</body>
</html>
EOF

ok "호스트 파일 수정 완료 (VERSION 1.0 → 2.0)"

# -------------------------------------------------------
# 6. 변경 후 응답 확인 (컨테이너 재시작 없음)
# -------------------------------------------------------
title "5. 변경 후 응답 확인 (컨테이너 재시작 없음)"
info "curl http://localhost:8082 (변경 후):"
curl -s http://localhost:8082 | grep -E "(VERSION|변경|UPDATED)"
ok "바인드 마운트 반영 확인 완료 - 컨테이너 재시작 없이 즉시 반영됨!"

# -------------------------------------------------------
# 7. 컨테이너 내부에서 파일 확인
# -------------------------------------------------------
title "6. 컨테이너 내부 파일 확인"
info "컨테이너 내부 /usr/share/nginx/html:"
docker exec bind-test ls -la /usr/share/nginx/html/

info "컨테이너 내부에서 index.html 내용 확인:"
docker exec bind-test cat /usr/share/nginx/html/index.html | grep -E "(VERSION|변경)"

# -------------------------------------------------------
# 8. 컨테이너 삭제 후 호스트 파일 유지 확인
# -------------------------------------------------------
title "7. 컨테이너 삭제 후 호스트 파일 유지 확인"
docker rm -f bind-test
info "컨테이너 삭제 후 호스트 파일 상태:"
ls -la "$MOUNTDIR/"
ok "호스트 파일 유지 확인 완료 (컨테이너 삭제와 무관)"

# -------------------------------------------------------
# 9. 로그 저장
# -------------------------------------------------------
{
  echo "=== 바인드 마운트 실습 로그 ==="
  echo "일시: $(date)"
  echo ""
  echo "호스트 마운트 경로: $MOUNT_ABS"
  echo ""
  echo "--- 변경 후 호스트 파일 목록 ---"
  ls -la "$MOUNTDIR/"
  echo ""
  echo "--- 최종 index.html ---"
  cat "$MOUNTDIR/index.html"
} > "$LOGDIR/bind_mount.log"

echo ""
ok "로그 저장: $LOGDIR/bind_mount.log"
echo ""
ok "06_bind_mount.sh 완료!"
echo "  브라우저 확인 시점: 변경 전(v1) 및 변경 후(v2) 비교"
echo "  다음 단계: bash 07_volumes.sh"
