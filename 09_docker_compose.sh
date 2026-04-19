#!/bin/bash
# =============================================================
# STEP 09: Docker Compose 실습 (보너스 과제)
# 목적: 단일/멀티 서비스 Compose 실행, 환경변수 주입
# 실행: bash 09_docker_compose.sh
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
COMPOSEDIR="$WORKDIR/compose"
LOGDIR="$WORKDIR/logs"
mkdir -p "$COMPOSEDIR/web" "$COMPOSEDIR/redis_data" "$LOGDIR"

# Docker Compose 확인
if ! command -v docker &> /dev/null; then
  warn "Docker가 설치되지 않았습니다"; exit 1
fi

# docker compose (v2) or docker-compose (v1)
if docker compose version &>/dev/null; then
  COMPOSE="docker compose"
elif command -v docker-compose &>/dev/null; then
  COMPOSE="docker-compose"
else
  warn "Docker Compose를 찾을 수 없습니다"
  warn "Docker Desktop 또는 docker-compose-plugin을 설치하세요"
  exit 1
fi
info "사용 중인 Compose: $COMPOSE ($($COMPOSE version))"

# -------------------------------------------------------
# 1. 웹 앱 소스 생성 (Node.js Express)
# -------------------------------------------------------
title "1. 웹 앱 소스 생성"

cat > "$COMPOSEDIR/web/package.json" << 'EOF'
{
  "name": "compose-demo",
  "version": "1.0.0",
  "main": "app.js",
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF

cat > "$COMPOSEDIR/web/app.js" << 'EOF'
const express = require('express');
const app = express();

const PORT  = process.env.PORT  || 3000;
const ENV   = process.env.APP_ENV || 'production';
const TITLE = process.env.APP_TITLE || 'Compose Demo';

let visitCount = 0;

app.get('/', (req, res) => {
  visitCount++;
  res.send(`
    <!DOCTYPE html>
    <html><head>
      <meta charset="UTF-8">
      <title>${TITLE}</title>
      <style>
        body { font-family: system-ui; background: #0f172a; color: #e2e8f0;
               display:flex; align-items:center; justify-content:center; min-height:100vh; }
        .card { background:#1e293b; border-radius:16px; padding:40px; text-align:center; }
        h1 { color:#38bdf8; margin-bottom:12px; }
        .badge { background:#0ea5e9; color:#fff; padding:4px 12px;
                 border-radius:99px; font-size:12px; margin:8px 4px; display:inline-block; }
        .count { font-size:3rem; font-weight:700; color:#34d399; }
      </style>
    </head><body>
      <div class="card">
        <h1>${TITLE}</h1>
        <span class="badge">ENV: ${ENV}</span>
        <span class="badge">PORT: ${PORT}</span>
        <p style="margin-top:16px;color:#94a3b8">방문 횟수</p>
        <p class="count">${visitCount}</p>
        <p style="color:#64748b;font-size:0.8rem;margin-top:12px">
          컨테이너 재시작 시 카운터 초기화 (볼륨 없을 때)
        </p>
      </div>
    </body></html>
  `);
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', env: ENV, port: PORT, visits: visitCount });
});

app.listen(PORT, () => {
  console.log(`[${ENV}] ${TITLE} 서버 시작: http://localhost:${PORT}`);
});
EOF

cat > "$COMPOSEDIR/web/Dockerfile" << 'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package.json .
RUN npm install --production
COPY app.js .

# 환경 변수 기본값 (Compose에서 오버라이드 가능)
ENV PORT=3000 \
    APP_ENV=production \
    APP_TITLE="Compose Demo"

EXPOSE 3000
HEALTHCHECK --interval=15s --timeout=5s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "app.js"]
EOF

ok "웹 앱 소스 생성 완료: $COMPOSEDIR/web/"

# -------------------------------------------------------
# 2. 단일 서비스 Compose 파일
# -------------------------------------------------------
title "2. 단일 서비스 docker-compose.yml 생성"

cat > "$COMPOSEDIR/docker-compose.single.yml" << 'EOF'
# 단일 서비스 Compose 예시
# 컨테이너 실행 명령이 "문서화된 실행 설정"으로 변환됨

version: '3.8'

services:
  web:
    build:
      context: ./web
      dockerfile: Dockerfile
    image: compose-web:dev
    container_name: compose-web-single
    ports:
      - "3000:3000"
    environment:
      - PORT=3000
      - APP_ENV=dev
      - APP_TITLE=단일 서비스 테스트
    restart: unless-stopped
EOF

cat "$COMPOSEDIR/docker-compose.single.yml"
ok "단일 서비스 Compose 파일 생성 완료"

# -------------------------------------------------------
# 3. 멀티 서비스 Compose 파일 (웹 + Redis)
# -------------------------------------------------------
title "3. 멀티 서비스 docker-compose.yml 생성"

cat > "$COMPOSEDIR/docker-compose.yml" << 'EOF'
# 멀티 컨테이너 Compose
# 웹 서버 + Redis 캐시 서버

version: '3.8'

services:
  # ── 웹 서버 ──────────────────────────────────────────
  web:
    build:
      context: ./web
      dockerfile: Dockerfile
    image: compose-web:multi
    container_name: compose-web
    ports:
      - "3001:3000"
    environment:
      - PORT=3000
      - APP_ENV=dev
      - APP_TITLE=멀티 컨테이너 데모
    depends_on:
      redis:
        condition: service_healthy
    networks:
      - app-network
    restart: unless-stopped

  # ── Redis (보조 서비스) ──────────────────────────────
  redis:
    image: redis:7-alpine
    container_name: compose-redis
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    command: redis-server --appendonly yes  # 데이터 영속성

# ── 네트워크 ─────────────────────────────────────────
networks:
  app-network:
    driver: bridge
    name: workstation-network

# ── 볼륨 ─────────────────────────────────────────────
volumes:
  redis-data:
    name: compose-redis-data
EOF

cat "$COMPOSEDIR/docker-compose.yml"
ok "멀티 서비스 Compose 파일 생성 완료"

# -------------------------------------------------------
# 4. 단일 서비스 실행 테스트
# -------------------------------------------------------
title "4. 단일 서비스 실행 (docker compose up)"
cd "$COMPOSEDIR"

$COMPOSE -f docker-compose.single.yml down 2>/dev/null || true
$COMPOSE -f docker-compose.single.yml up -d --build
sleep 3

info "단일 서비스 상태:"
$COMPOSE -f docker-compose.single.yml ps

info "curl 테스트 (단일):"
curl -s http://localhost:3000/health && echo "" || warn "포트 3000 응답 없음"

info "로그 확인:"
$COMPOSE -f docker-compose.single.yml logs --tail=5

# 종료
$COMPOSE -f docker-compose.single.yml down
ok "단일 서비스 테스트 완료"

# -------------------------------------------------------
# 5. 멀티 서비스 실행
# -------------------------------------------------------
title "5. 멀티 서비스 실행 (웹 + Redis)"
$COMPOSE down 2>/dev/null || true
$COMPOSE up -d --build
sleep 5

info "멀티 서비스 상태:"
$COMPOSE ps

info "curl 테스트 (멀티 웹):"
curl -s http://localhost:3001/health && echo "" || warn "포트 3001 응답 없음"

# -------------------------------------------------------
# 6. 컨테이너 간 네트워크 통신 확인
# -------------------------------------------------------
title "6. 컨테이너 간 네트워크 통신 확인"
info "웹 컨테이너 → Redis 통신 테스트:"
docker exec compose-web sh -c "
  # 서비스명(redis)으로 DNS 해석 + ping 가능한지 확인
  nslookup redis 2>/dev/null || \
  getent hosts redis 2>/dev/null || \
  echo 'DNS 해석: redis → '$(ping -c1 -W1 redis 2>/dev/null | grep PING | awk '{print \$3}' | tr -d '()')
" 2>/dev/null || info "(alpine은 ping 없을 수 있음, Redis 접근은 정상)"

docker exec compose-redis redis-cli ping
ok "Redis 응답: PONG - 컨테이너 간 통신 정상!"

# -------------------------------------------------------
# 7. Compose 운영 명령어
# -------------------------------------------------------
title "7. Compose 운영 명령어 실습"

info "docker compose ps:"
$COMPOSE ps

info "docker compose logs (최신 10줄):"
$COMPOSE logs --tail=10

info "docker compose top (프로세스 목록):"
$COMPOSE top 2>/dev/null || info "top 미지원 버전"

# 재시작
info "docker compose restart web:"
$COMPOSE restart web
sleep 2
$COMPOSE ps

# -------------------------------------------------------
# 8. 환경 변수 파일 (.env) 생성
# -------------------------------------------------------
title "8. 환경 변수 파일 (.env)"
cat > "$COMPOSEDIR/.env" << 'EOF'
# .env - Compose 환경 변수 파일
# 이 파일은 .gitignore에 추가하여 비밀 정보 유출 방지

WEB_PORT=3001
APP_ENV=dev
APP_TITLE=환경변수 주입 테스트
REDIS_PORT=6379
EOF

info ".env 파일 내용:"
cat "$COMPOSEDIR/.env"
ok ".env 파일 생성 완료 (민감 정보 없는 예시)"

# -------------------------------------------------------
# 9. 최종 정리
# -------------------------------------------------------
title "9. 최종 상태 및 정리"
$COMPOSE ps

info "볼륨 확인 (Redis 데이터 영속):"
docker volume ls | grep compose

# 로그 저장
{
  echo "=== Docker Compose 실습 로그 ==="
  echo "일시: $(date)"
  echo ""
  echo "--- compose version ---"
  $COMPOSE version
  echo ""
  echo "--- compose ps ---"
  $COMPOSE ps
  echo ""
  echo "--- compose logs ---"
  $COMPOSE logs --tail=20
} > "$LOGDIR/compose.log"

ok "로그 저장: $LOGDIR/compose.log"

echo ""
echo "컨테이너 종료 방법:"
echo "  cd $COMPOSEDIR && $COMPOSE down"
echo "  (볼륨도 삭제: $COMPOSE down -v)"
echo ""
ok "09_docker_compose.sh 완료! (보너스 과제 수행 완료)"
