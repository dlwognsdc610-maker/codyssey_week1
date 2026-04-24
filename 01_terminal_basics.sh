#!/bin/bash
# =============================================================
# STEP 01: 터미널 기본 조작 실습
# 목적: pwd, ls, mkdir, cp, mv, rm, cat, touch 등 기본 명령 연습
# 실행: bash 01_terminal_basics.sh
# =============================================================

set -e  # 에러 발생 시 중단

# 색상 출력용
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
title() { echo -e "\n${YELLOW}========== $1 ==========${NC}"; }

# -------------------------------------------------------
# 0. 작업 루트 디렉토리 설정
# -------------------------------------------------------
WORKDIR="$HOME/dev-workstation"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

title "1. 현재 위치 확인"
pwd
ok "현재 디렉토리: $(pwd)"

# -------------------------------------------------------
# 1. 디렉토리 구조 생성
# -------------------------------------------------------
title "2. 디렉토리 생성 (mkdir -p)"
mkdir -p practice/docs practice/scripts practice/backup
ls -la practice/
ok "디렉토리 생성 완료"

# -------------------------------------------------------
# 2. 파일 생성 및 내용 확인
# -------------------------------------------------------
title "3. 파일 생성 및 내용 확인"

# 내용 있는 파일 생성
cat > practice/docs/hello.txt << 'EOF'
안녕하세요!
이 파일은 터미널 실습을 위해 생성되었습니다.
작성일: $(date)
EOF

# 실제 날짜 삽입
echo "작성일: $(date)" >> practice/docs/hello.txt

# 빈 파일 생성 (touch)
touch practice/docs/empty.txt

info "hello.txt 내용:"
cat practice/docs/hello.txt

info "빈 파일 확인 (touch):"
ls -la practice/docs/empty.txt
ok "파일 생성 완료"

# -------------------------------------------------------
# 3. 숨김 파일 포함 목록 확인
# -------------------------------------------------------
title "4. 숨김 파일 포함 ls -la"

# 숨김 파일 생성
echo "# 숨김 설정 파일" > practice/.hidden_config
echo "DEBUG=true" >> practice/.hidden_config

ls -la practice/
ok "숨김 파일(.hidden_config) 포함 목록 확인"

# -------------------------------------------------------
# 4. 파일 복사 (cp)
# -------------------------------------------------------
title "5. 파일 복사 (cp)"
cp practice/docs/hello.txt practice/backup/hello_backup.txt
info "복사 결과:"
ls -la practice/backup/
ok "복사 완료: hello.txt → backup/hello_backup.txt"

# -------------------------------------------------------
# 5. 파일 이동 / 이름 변경 (mv)
# -------------------------------------------------------
title "6. 파일 이름 변경 (mv)"
cp practice/docs/hello.txt practice/docs/old_name.txt
mv practice/docs/old_name.txt practice/docs/new_name.txt
info "이름 변경 결과:"
ls -la practice/docs/
ok "이름 변경 완료: old_name.txt → new_name.txt"

# -------------------------------------------------------
# 6. 파일 삭제 (rm)
# -------------------------------------------------------
title "7. 파일 삭제 (rm)"
info "삭제 전:"
ls practice/docs/
rm practice/docs/new_name.txt
rm practice/docs/empty.txt
info "삭제 후:"
ls practice/docs/
ok "파일 삭제 완료"

# -------------------------------------------------------
# 7. 디렉토리 이동 (cd)
# -------------------------------------------------------
title "8. 디렉토리 이동 (절대/상대 경로)"
info "현재 위치: $(pwd)"
cd practice/docs
info "cd practice/docs 후: $(pwd)  ← 상대 경로"
cd "$WORKDIR"
info "cd \$WORKDIR 후: $(pwd)      ← 절대 경로"
ok "이동 완료"

# -------------------------------------------------------
# 8. 결과 요약
# -------------------------------------------------------
title "실습 완료 - 최종 디렉토리 구조"
find "$WORKDIR/practice" | sort
echo ""
ok "01_terminal_basics.sh 완료!"
echo "  결과 위치: $WORKDIR/practice"
echo "  다음 단계: bash 02_permissions.sh"
