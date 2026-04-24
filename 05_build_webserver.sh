#!/bin/bash
# =============================================================
# STEP 05: 커스텀 웹 서버 이미지 빌드 및 포트 매핑
# 목적: Nginx 기반 커스텀 이미지 빌드, 8080→80 포트 매핑 확인
# 실행: bash 05_build_webserver.sh
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

WORKDIR="$HOME/dev-workstation"
WEBDIR="$WORKDIR/webapp"
LOGDIR="$WORKDIR/logs"
mkdir -p "$WEBDIR/site" "$LOGDIR"

# -------------------------------------------------------
# 1. 웹 서버 소스 파일 생성 (site/)
# -------------------------------------------------------
title "1. 웹 서버 소스 파일 생성"

cat > "$WEBDIR/site/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Dev Workstation</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Segoe UI', system-ui, sans-serif;
      background: #0f172a;
      color: #e2e8f0;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
    }
    .card {
      background: #1e293b;
      border: 1px solid #334155;
      border-radius: 16px;
      padding: 48px 64px;
      text-align: center;
      max-width: 520px;
    }
    .badge {
      display: inline-block;
      background: #0ea5e9;
      color: #fff;
      font-size: 12px;
      font-weight: 600;
      padding: 4px 12px;
      border-radius: 99px;
      margin-bottom: 20px;
      letter-spacing: 0.05em;
    }
    h1 { font-size: 2rem; font-weight: 700; color: #f8fafc; margin-bottom: 12px; }
    p  { color: #94a3b8; line-height: 1.6; margin-bottom: 24px; }
    .info-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
      text-align: left;
    }
    .info-item {
      background: #0f172a;
      border-radius: 8px;
      padding: 12px 16px;
    }
    .info-label { font-size: 11px; color: #64748b; text-transform: uppercase; letter-spacing: 0.08em; }
    .info-value { font-size: 14px; color: #38bdf8; font-weight: 600; margin-top: 2px; }
  </style>
</head>
<body>
  <div class="card">
    <span class="badge">DOCKER RUNNING</span>
    <h1>Dev Workstation</h1>
    <p>Nginx 기반 커스텀 Docker 이미지<br>포트 매핑: 8080 → 80</p>
    <div class="info-grid">
      <div class="info-item">
        <div class="info-label">Base Image</div>
        <div class="info-value">nginx:alpine</div>
      </div>
      <div class="info-item">
        <div class="info-label">Port</div>
        <div class="info-value">8080 → 80</div>
      </div>
      <div class="info-item">
        <div class="info-label">Environment</div>
        <div class="info-value">APP_ENV=dev</div>
      </div>
      <div class="info-item">
        <div class="info-label">Server</div>
        <div class="info-value">nginx/alpine</div>
      </div>
    </div>
  </div>
</body>
</html>
EOF

cat > "$WEBDIR/site/health.html" << 'EOF'
OK - healthy
EOF

ok "site/index.html, site/health.html 생성 완료"

# -------------------------------------------------------
# 2. nginx 커스텀 설정 파일
# -------------------------------------------------------
mkdir -p "$WEBDIR/nginx"
cat > "$WEBDIR/nginx/default.conf" << 'EOF'
server {
    listen       80;
    server_name  localhost;
    root         /usr/share/nginx/html;
    index        index.html;

    # 헬스체크 엔드포인트
    location /health {
        alias /usr/share/nginx/html/health.html;
        access_log off;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }

    # 에러 페이지
    error_page 404 /index.html;

    # 응답 헤더에 커스텀 서버명 추가
    add_header X-Custom-Server "dev-workstation" always;

    # gzip 압축
    gzip on;
    gzip_types text/html text/css application/javascript;
}
EOF

ok "nginx/default.conf 생성 완료"

# -------------------------------------------------------
# 3. Dockerfile 작성
# -------------------------------------------------------
title "2. Dockerfile 작성"

cat > "$WEBDIR/Dockerfile" << 'EOF'
# ============================================================
# 베이스: nginx:alpine (경량 웹 서버)
# 커스텀 포인트:
#   1. LABEL  - 이미지 메타데이터 추가
#   2. ENV    - 환경 변수로 실행 환경 구분
#   3. COPY   - 커스텀 정적 콘텐츠/설정 주입
#   4. EXPOSE - 컨테이너 포트 명시 (문서화 역할)
#   5. HEALTHCHECK - 컨테이너 상태 자동 점검
# ============================================================

FROM nginx:alpine

# 1. 이미지 메타데이터 (OCI 표준 라벨)
LABEL org.opencontainers.image.title="dev-workstation-web" \
      org.opencontainers.image.description="커스텀 Nginx 웹 서버" \
      org.opencontainers.image.version="1.0.0"

# 2. 환경 변수 설정 (코드와 설정 분리)
ENV APP_ENV=dev \
    APP_NAME="Dev Workstation" \
    NGINX_PORT=80

# 3-a. 커스텀 Nginx 설정 복사 (기본 설정 교체)
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# 3-b. 정적 콘텐츠 복사
COPY site/ /usr/share/nginx/html/

# 4. 컨테이너 사용 포트 명시 (docker run -p의 대상)
EXPOSE 80

# 5. 헬스체크: 30초마다 /health 엔드포인트 확인
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost/health || exit 1

# 기본 실행 명령 (nginx:alpine 기본값 유지)
CMD ["nginx", "-g", "daemon off;"]
EOF

info "Dockerfile 내용:"
cat "$WEBDIR/Dockerfile"
ok "Dockerfile 생성 완료"

# -------------------------------------------------------
# 4. 이미지 빌드
# -------------------------------------------------------
title "3. 이미지 빌드 (docker build)"
cd "$WEBDIR"
info "빌드 시작: my-web:1.0"
docker build -t my-web:1.0 . 2>&1 | tee "$LOGDIR/build.log"

echo ""
info "빌드된 이미지 확인:"
docker images my-web
ok "이미지 빌드 완료"

# -------------------------------------------------------
# 5. 포트 매핑으로 컨테이너 실행 (8080:80)
# -------------------------------------------------------
title "4. 컨테이너 실행 - 포트 매핑 8080:80"

# 기존 컨테이너 정리
docker rm -f my-web-8080 2>/dev/null || true

docker run -d \
  --name my-web-8080 \
  -p 8080:80 \
  my-web:1.0

info "실행 중인 컨테이너:"
docker ps --filter name=my-web-8080

echo ""
info "포트 매핑 확인:"
docker port my-web-8080

echo ""
info "컨테이너 접속 테스트 (curl):"
sleep 1
curl -s -w "\n\nHTTP Status: %{http_code}\nServer: %{header_server}\n" http://localhost:8080
ok "포트 8080 접속 성공"

# -------------------------------------------------------
# 6. 두 번째 컨테이너 - 포트 8081:80
# -------------------------------------------------------
title "5. 두 번째 컨테이너 실행 - 포트 8081:80"

docker rm -f my-web-8081 2>/dev/null || true

docker run -d \
  --name my-web-8081 \
  -p 8081:80 \
  my-web:1.0

sleep 1
info "두 번째 컨테이너 curl 응답:"
curl -s -w "\nHTTP Status: %{http_code}\n" http://localhost:8081 | head -20
ok "포트 8081 접속 성공"

info "헬스체크 엔드포인트:"
curl -s http://localhost:8080/health
echo ""

# -------------------------------------------------------
# 7. 컨테이너 로그 확인
# -------------------------------------------------------
title "6. 컨테이너 로그 확인 (docker logs)"
docker logs my-web-8080

# -------------------------------------------------------
# 8. 로그 저장
# -------------------------------------------------------
{
  echo "=== 웹 서버 빌드/실행 로그 ==="
  echo "일시: $(date)"
  echo ""
  echo "--- 이미지 목록 ---"
  docker images my-web
  echo ""
  echo "--- 실행 중인 컨테이너 ---"
  docker ps --filter name=my-web
  echo ""
  echo "--- 포트 매핑 ---"
  echo "my-web-8080: $(docker port my-web-8080)"
  echo "my-web-8081: $(docker port my-web-8081)"
  echo ""
  echo "--- curl 응답 ---"
  curl -s -w "\nHTTP Status: %{http_code}" http://localhost:8080
} > "$LOGDIR/webserver.log"

echo ""
ok "로그 저장: $LOGDIR/webserver.log"
echo ""
ok "05_build_webserver.sh 완료!"
echo "  브라우저에서 확인: http://localhost:8080"
echo "  다음 단계: bash 06_bind_mount.sh"
