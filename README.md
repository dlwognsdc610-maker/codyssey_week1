# AI/SW 개발 워크스테이션 구축

## 1. 프로젝트 개요
이 저장소는 터미널, 권한, Docker, Git/GitHub, Docker Compose를 사용해 개발 워크스테이션을 직접 구축하는 실습 결과물이다.

핵심 목표는 아래 흐름을 실제 명령으로 확인하는 것이다.
- 터미널 기본 조작과 디렉토리/파일 정리
- 파일 및 디렉토리 권한 실습
- Docker 설치 점검 및 기본 운영 명령 확인
- hello-world, ubuntu 컨테이너 실행/관리
- Nginx 기반 커스텀 웹 서버 이미지 제작
- 포트 매핑, 바인드 마운트, Docker 볼륨 검증
- Git 설정 및 GitHub 연동
- Docker Compose 기초 및 멀티 컨테이너 실습

## 2. 실행 환경
| 항목 | 내용 |
|------|------|
| OS | Ubuntu 24.04 계열 Linux (`uname -a` 기준) |
| Shell | `/bin/bash` |
| Bash | `GNU bash, version 5.2.21` |
| Docker | `Docker version 28.2.2` |
| Git | `git version 2.43.0` |
| 비고 | 캠퍼스 정책상 `sudo` 제한 시 OrbStack 또는 동등한 Docker 실행 환경을 사용 |

## 3. 저장소 구조
| 파일 | 역할 |
|------|------|
| [01_terminal_basics.sh](01_terminal_basics.sh) | `pwd`, `ls -la`, `mkdir`, `cp`, `mv`, `rm`, `touch`, 절대/상대 경로 실습 |
| [02_permissions.sh](02_permissions.sh) | `chmod`로 파일/디렉토리 권한 비교 실습 |
| [03_docker_setup.sh](03_docker_setup.sh) | `docker --version`, `docker info`, `docker ps`, `docker images` 점검 |
| [04_docker_run.sh](04_docker_run.sh) | `hello-world`, `ubuntu` 컨테이너 실행, `exec`, `logs`, `stats` 확인 |
| [05_build_webserver.sh](05_build_webserver.sh) | Nginx 기반 커스텀 이미지 빌드, 포트 매핑(8080:80, 8081:80) |
| [06_bind_mount.sh](06_bind_mount.sh) | 바인드 마운트 변경 반영 확인 |
| [07_volumes.sh](07_volumes.sh) | Docker 볼륨 생성/재연결/영속성 검증 |
| [08_git_setup.sh](08_git_setup.sh) | Git 전역 설정, 저장소 초기화, README 생성, 첫 커밋 안내 |
| [09_docker_compose.sh](09_docker_compose.sh) | Docker Compose 단일/멀티 서비스, Redis 연동, 환경 변수 주입 |
| [run_all.sh](run_all.sh) | 전체 단계 일괄 실행용 오케스트레이션 스크립트 |
| [work_station/logs/](work_station/logs/) | 실습 로그 보관용 디렉토리 |

## 4. 수행 체크리스트
- [x] 터미널 현재 위치/목록 확인, 생성, 복사, 이동, 이름 변경, 삭제
- [x] 파일 내용 확인 및 빈 파일 생성
- [x] 절대 경로와 상대 경로 차이 확인
- [x] 파일 1개, 디렉토리 1개 권한 변경 실험
- [x] `docker --version` 및 `docker info` 점검
- [x] `hello-world` 실행
- [x] `ubuntu` 컨테이너 실행, `exec`/`stop`/`rm` 확인
- [x] `docker images`, `docker ps`, `docker ps -a`, `docker logs`, `docker stats` 확인
- [x] Nginx 기반 커스텀 Docker 이미지 제작
- [x] `-p 8080:80`, `-p 8081:80` 포트 매핑 확인
- [x] 바인드 마운트로 호스트 변경 즉시 반영 확인
- [x] Docker 볼륨 생성 및 삭제 후 데이터 유지 확인
- [x] Git 사용자 정보/기본 브랜치 설정
- [x] GitHub 연동 준비 및 저장소 초기화
- [x] Docker Compose 단일/멀티 서비스 실습
- [x] 트러블슈팅 2건 이상 정리

## 5. 터미널 조작 로그
아래 명령은 [01_terminal_basics.sh](01_terminal_basics.sh)에서 수행된다.

```bash
pwd
ls -la
mkdir -p practice/docs practice/scripts practice/backup
cp practice/docs/hello.txt practice/backup/hello_backup.txt
mv practice/docs/old_name.txt practice/docs/new_name.txt
rm practice/docs/new_name.txt
cat practice/docs/hello.txt
touch practice/docs/empty.txt
cd practice/docs
cd "$WORKDIR"
```

핵심 확인 포인트:
- `pwd`로 현재 작업 위치를 확인
- `ls -la`로 숨김 파일 포함 목록을 확인
- `mkdir -p`로 다중 디렉토리 생성
- `cp`, `mv`, `rm`으로 파일 생명주기를 확인
- `cd practice/docs`와 `cd "$WORKDIR"`로 상대/절대 경로를 비교

## 6. 권한 실습 로그
아래 명령은 [02_permissions.sh](02_permissions.sh)에서 수행된다.

```bash
chmod 644 test_file.txt
chmod 755 test_script.sh
chmod 600 secret.txt
chmod 755 test_dir_public
chmod 700 test_dir_private
chmod +x symbolic_test.txt
chmod -x symbolic_test.txt
chmod o-r symbolic_test.txt
```

권한 해석 요약:
- `644` → `rw-r--r--`
- `755` → `rwxr-xr-x`
- `700` → `rwx------`
- `600` → `rw-------`

검증 방법:
```bash
ls -la test_file.txt test_script.sh secret.txt
ls -ld test_dir_public test_dir_private
stat -c %a test_file.txt
```

## 7. Docker 설치 및 기본 점검
아래 명령은 [03_docker_setup.sh](03_docker_setup.sh)에서 수행된다.

```bash
docker --version
docker version
docker info
docker images
docker ps
docker ps -a
```

실행 결과 요약:
- Docker 클라이언트 버전은 `28.2.2`로 확인됨
- `docker info`를 통해 데몬 응답 가능 여부를 확인함
- 이미지/컨테이너 목록 명령으로 현재 상태를 점검함

## 8. Docker 기본 실행
아래 명령은 [04_docker_run.sh](04_docker_run.sh)에서 수행된다.

```bash
docker run hello-world
docker pull ubuntu:22.04
docker run -d --name ubuntu-practice ubuntu:22.04 sleep infinity
docker exec ubuntu-practice ls /
docker exec ubuntu-practice echo '안녕하세요 Docker!'
docker stop ubuntu-practice
docker rm ubuntu-practice
docker logs log-test
docker stats --no-stream stats-test
```

관찰한 차이:
- `docker exec`는 기존 컨테이너 안에 새 프로세스를 실행하므로 컨테이너가 유지된다.
- `docker attach`는 PID 1 프로세스에 연결되므로 종료 방식에 따라 컨테이너도 함께 끝날 수 있다.

## 9. 커스텀 Docker 이미지
선택한 베이스는 Nginx 계열이다.

### 베이스 선택
- 베이스 이미지: `nginx:alpine`
- 이유: 가볍고 정적 웹 서버 실습에 적합함

### 적용한 커스텀 포인트
- `LABEL`: 이미지 메타데이터 추가
- `ENV`: 실행 환경 변수 분리
- `COPY`: 커스텀 `index.html`, `health.html`, `default.conf` 반영
- `EXPOSE`: 컨테이너 포트 문서화
- `HEALTHCHECK`: `/health` 엔드포인트 상태 점검

### 빌드/실행 명령
```bash
docker build -t my-web:1.0 .
docker run -d --name my-web-8080 -p 8080:80 my-web:1.0
docker run -d --name my-web-8081 -p 8081:80 my-web:1.0
curl http://localhost:8080
curl http://localhost:8081
curl http://localhost:8080/health
```

### 검증 포인트
- `http://localhost:8080`에서 커스텀 HTML 확인
- `http://localhost:8081`에서 동일 이미지의 다른 포트 실행 확인
- `/health` 응답으로 헬스체크 엔드포인트 확인

### 관련 파일
- [05_build_webserver.sh](05_build_webserver.sh)
- [work_station/logs/](work_station/logs/)

## 10. 포트 매핑 증거
포트 매핑은 컨테이너 내부 포트를 호스트로 노출하기 위해 필요하다.

예시 명령:
```bash
docker run -d --name my-web-8080 -p 8080:80 my-web:1.0
curl http://localhost:8080
```

설명:
- 컨테이너는 격리된 네트워크를 사용한다.
- `-p 8080:80`은 호스트 8080 포트를 컨테이너 80 포트와 연결한다.
- 포트 매핑이 없으면 브라우저에서 직접 접근할 수 없다.

## 11. 바인드 마운트 검증
아래 명령은 [06_bind_mount.sh](06_bind_mount.sh)에서 수행된다.

```bash
docker run -d --name bind-test -p 8082:80 -v "$MOUNT_ABS":/usr/share/nginx/html:ro nginx:alpine
curl http://localhost:8082
```

검증 절차:
1. 호스트의 `index.html`을 `VERSION 1.0` 상태로 준비
2. 컨테이너 실행 후 응답 확인
3. 호스트 파일을 `VERSION 2.0`으로 수정
4. 컨테이너 재시작 없이 다시 접근해서 변경 반영 확인
5. 컨테이너 삭제 후에도 호스트 파일이 남아 있는지 확인

핵심 결론:
- 바인드 마운트는 개발 중 소스 변경을 즉시 반영하는 데 유리하다.
- 컨테이너 삭제와 호스트 파일 유지가 분리되어 있다.

## 12. Docker 볼륨 영속성 검증
아래 명령은 [07_volumes.sh](07_volumes.sh)에서 수행된다.

```bash
docker volume create workstation-data
docker run -d --name vol-writer -v workstation-data:/data ubuntu:22.04 sleep 30
docker exec vol-writer bash -c "echo hi > /data/hello.txt"
docker rm -f vol-writer
docker run -d --name vol-reader -v workstation-data:/data ubuntu:22.04 sleep 30
docker exec vol-reader cat /data/hello.txt
```

검증 포인트:
- 컨테이너 1이 작성한 `/data/hello.txt`가 컨테이너 삭제 이후에도 남아야 한다.
- 같은 볼륨을 새 컨테이너에 재연결했을 때 데이터가 보이면 영속성이 확인된다.

## 13. Git 설정 및 GitHub 연동
아래 명령은 [08_git_setup.sh](08_git_setup.sh)에서 수행된다.

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
git config --list
git init
git add .
git commit -m "feat: 개발 워크스테이션 초기 구성"
```

주의 사항:
- 개인키, 토큰, 비밀번호, 인증 코드는 문서에 남기지 않는다.
- GitHub 연동은 HTTPS 또는 SSH 중 하나를 선택해 사용할 수 있다.

## 14. Docker Compose 보너스
아래 명령은 [09_docker_compose.sh](09_docker_compose.sh)에서 수행된다.

```bash
docker compose -f docker-compose.single.yml up -d --build
docker compose -f docker-compose.single.yml ps
docker compose -f docker-compose.single.yml logs --tail=5
docker compose up -d --build
docker compose ps
docker compose logs --tail=10
docker compose down
```

Compose에서 확인한 점:
- 실행 명령이 YAML 문서로 고정되어 재현성이 높아진다.
- 웹 서버와 Redis를 분리해 네트워크 통신을 확인할 수 있다.
- 환경 변수와 볼륨을 한 파일에 모아 관리할 수 있다.

## 15. 검증 방법과 결과 위치
| 검증 항목 | 확인 명령 | 결과 위치 |
|----------|----------|----------|
| 터미널 기본 조작 | `bash 01_terminal_basics.sh` | [01_terminal_basics.sh](01_terminal_basics.sh), [run_all.sh](run_all.sh) |
| 권한 실습 | `bash 02_permissions.sh` | [02_permissions.sh](02_permissions.sh) |
| Docker 점검 | `bash 03_docker_setup.sh` | [03_docker_setup.sh](03_docker_setup.sh) |
| 컨테이너 실행 | `bash 04_docker_run.sh` | [04_docker_run.sh](04_docker_run.sh) |
| 웹 서버 빌드 | `bash 05_build_webserver.sh` | [05_build_webserver.sh](05_build_webserver.sh) |
| 바인드 마운트 | `bash 06_bind_mount.sh` | [06_bind_mount.sh](06_bind_mount.sh) |
| 볼륨 영속성 | `bash 07_volumes.sh` | [07_volumes.sh](07_volumes.sh) |
| Git 설정 | `bash 08_git_setup.sh` | [08_git_setup.sh](08_git_setup.sh) |
| Compose | `bash 09_docker_compose.sh` | [09_docker_compose.sh](09_docker_compose.sh) |

## 16. 트러블슈팅 2건
### 문제 1: Docker 데몬이 응답하지 않음
- 문제: `docker info`가 실패하거나 서버 정보를 출력하지 못함
- 원인 가설: Docker 엔진이 실행되지 않았거나, OrbStack/Docker Desktop이 꺼져 있음
- 확인: `docker --version`은 나오지만 `docker info`가 실패하는지 확인
- 해결/대안: OrbStack을 실행하거나 Docker Desktop을 켠 뒤 다시 `docker info` 실행

### 문제 2: 바인드 마운트 경로가 기대와 다르게 동작함
- 문제: 호스트 파일 수정이 컨테이너에 반영되지 않거나 마운트가 실패함
- 원인 가설: 상대 경로를 잘못 사용했거나, 컨테이너가 읽기 전용/절대 경로 기준으로 접근해야 함
- 확인: `realpath`로 실제 호스트 절대 경로를 출력하고 `docker run -v ...` 구성을 점검
- 해결/대안: 절대 경로를 사용하고, 개발용은 `:ro`를 붙여 안전하게 연결한 뒤 `curl`로 즉시 반영 여부를 검증

## 17. 제출 시 주의사항
- 스크린샷이나 로그에 토큰, 비밀번호, SSH 개인키가 보이면 제거한다.
- GitHub 저장소 링크만으로 평가자가 명령 흐름을 따라갈 수 있도록 문서와 스크립트를 함께 유지한다.
- 로컬 실행 로그를 추가로 첨부하면 가독성이 좋아진다.

## 18. 실행 순서
전체 실습은 다음처럼 실행할 수 있다.

```bash
bash run_all.sh
```

보너스 Compose를 제외하려면:

```bash
bash run_all.sh --skip-compose
```

> 참고: 각 단계 스크립트는 `~/dev-workstation/` 아래에 실습 산출물과 로그를 생성하도록 설계되어 있다.
