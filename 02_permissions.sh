#!/bin/bash
# =============================================================
# STEP 02: 파일 권한 실습 (r/w/x, chmod, 755, 644)
# 목적: 파일·디렉토리 권한 변경 전/후 비교 기록
# 실행: bash 02_permissions.sh
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

WORKDIR="$HOME/dev-workstation/practice"
mkdir -p "$WORKDIR/permissions_test"
cd "$WORKDIR/permissions_test"

# -------------------------------------------------------
# 1. 권한 표기 이론 출력
# -------------------------------------------------------
title "권한 표기 이론 (r/w/x)"
cat << 'EOF'
  권한 표기: rwxrwxrwx
             ↑↑↑ ↑↑↑ ↑↑↑
             소유자 그룹 기타

  r (read)    = 4 : 읽기
  w (write)   = 2 : 쓰기
  x (execute) = 1 : 실행

  예시)
    755 = rwxr-xr-x  (소유자: 7=rwx, 그룹: 5=r-x, 기타: 5=r-x)
    644 = rw-r--r--  (소유자: 6=rw-, 그룹: 4=r--, 기타: 4=r--)
    600 = rw-------  (소유자만 읽기/쓰기)
    777 = rwxrwxrwx  (모두 모든 권한 - 보안 취약, 피할 것)
EOF

# -------------------------------------------------------
# 2. 파일 권한 실습
# -------------------------------------------------------
title "1. 파일 권한 변경 실습"

# 테스트 파일 생성
echo "권한 테스트 파일입니다." > test_file.txt
echo "스크립트 테스트" > test_script.sh

info "--- 기본 생성 직후 권한 ---"
ls -la test_file.txt test_script.sh

# 644로 변경 (일반 텍스트 파일 표준)
echo ""
info "chmod 644 test_file.txt 실행 (rw-r--r--)"
chmod 644 test_file.txt
ls -la test_file.txt
ok "→ 소유자: 읽기/쓰기, 그룹/기타: 읽기만"

# 755로 변경 (실행 파일 표준)
echo ""
info "chmod 755 test_script.sh 실행 (rwxr-xr-x)"
chmod 755 test_script.sh
ls -la test_script.sh
ok "→ 소유자: 모든 권한, 그룹/기타: 읽기/실행"

# 600으로 변경 (비밀 파일)
echo ""
echo "SECRET_KEY=my_secret_value" > secret.txt
info "chmod 600 secret.txt 실행 (rw-------)"
chmod 600 secret.txt
ls -la secret.txt
ok "→ 소유자만 읽기/쓰기, 그룹/기타 접근 불가 (비밀 파일에 적합)"

# -------------------------------------------------------
# 3. 디렉토리 권한 실습
# -------------------------------------------------------
title "2. 디렉토리 권한 변경 실습"

mkdir -p test_dir_public
mkdir -p test_dir_private

info "--- 기본 생성 직후 디렉토리 권한 ---"
ls -ld test_dir_public test_dir_private

# 755 (표준 디렉토리)
echo ""
info "chmod 755 test_dir_public (rwxr-xr-x)"
chmod 755 test_dir_public
ls -ld test_dir_public
ok "→ 모두 진입(x)/읽기(r) 가능, 쓰기는 소유자만"

# 700 (개인 디렉토리)
echo ""
info "chmod 700 test_dir_private (rwx------)"
chmod 700 test_dir_private
ls -ld test_dir_private
ok "→ 소유자만 진입/읽기/쓰기 가능"

# -------------------------------------------------------
# 4. 심볼릭 모드 (+x, -w)
# -------------------------------------------------------
title "3. 심볼릭 모드 chmod 실습"
touch symbolic_test.txt
chmod 644 symbolic_test.txt
info "초기: $(ls -la symbolic_test.txt)"

chmod +x symbolic_test.txt
info "chmod +x 후: $(ls -la symbolic_test.txt)"

chmod -x symbolic_test.txt
info "chmod -x 후: $(ls -la symbolic_test.txt)"

chmod o-r symbolic_test.txt
info "chmod o-r 후 (기타 읽기 제거): $(ls -la symbolic_test.txt)"
ok "심볼릭 모드 실습 완료"

# -------------------------------------------------------
# 5. 전/후 비교 요약
# -------------------------------------------------------
title "권한 변경 전/후 비교 요약"
printf "%-30s %-15s %-30s\n" "파일명" "최종 권한" "설명"
printf "%-30s %-15s %-30s\n" "------" "--------" "----"
printf "%-30s %-15s %-30s\n" "test_file.txt"     "$(stat -c %a test_file.txt 2>/dev/null || stat -f %p test_file.txt)"     "일반 텍스트 (644)"
printf "%-30s %-15s %-30s\n" "test_script.sh"    "$(stat -c %a test_script.sh 2>/dev/null || stat -f %p test_script.sh)"   "실행 스크립트 (755)"
printf "%-30s %-15s %-30s\n" "secret.txt"        "$(stat -c %a secret.txt 2>/dev/null || stat -f %p secret.txt)"           "비밀 파일 (600)"
printf "%-30s %-15s %-30s\n" "test_dir_public/"  "$(stat -c %a test_dir_public 2>/dev/null || stat -f %p test_dir_public)" "공개 디렉토리 (755)"
printf "%-30s %-15s %-30s\n" "test_dir_private/" "$(stat -c %a test_dir_private 2>/dev/null || stat -f %p test_dir_private)" "개인 디렉토리 (700)"

echo ""
ok "02_permissions.sh 완료!"
echo "  결과 위치: $WORKDIR/permissions_test"
echo "  다음 단계: bash 03_docker_setup.sh"
