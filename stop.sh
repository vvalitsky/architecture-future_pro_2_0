#!/usr/bin/env bash
# =============================================================================
# stop.sh — остановка локальной Docker-среды «Будущее 2.0», поднятой через
# ./run.sh up | ./run.sh demo | docker compose.
#
#   ./stop.sh          остановить Minio, удалить контейнеры, том и сеть
#   ./stop.sh --clean  то же + удалить локальные артефакты (.verify, .terraform, state демо)
#   ./stop.sh --help   справка
#
# Идемпотентно: безопасно запускать, даже если ничего не запущено.
# =============================================================================
set -uo pipefail

# Git Bash (Windows): не преобразовывать имена/пути в аргументах docker.
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL='*'

NET="future20-net"
MINIO_CONTAINER="future20-minio"
DEMO_DIR="scripts/local-backend-demo"

c()    { printf '\033[%sm%s\033[0m\n' "$1" "$2"; }
ok()   { c 32 "  ✓ $*"; }
warn() { c 33 "  ! $*"; }
head() { printf '\n'; c '1;36' "== $* =="; }

usage() {
  cat <<'EOF'
stop.sh — остановка локальной Docker-среды «Будущее 2.0».

  ./stop.sh          остановить Minio и удалить контейнеры/том/сеть
  ./stop.sh --clean  то же + удалить локальные артефакты (.verify, .terraform, state демо)
  ./stop.sh --help   эта справка
EOF
}

compose() {
  if docker compose version >/dev/null 2>&1; then docker compose "$@";
  else docker-compose "$@"; fi
}

CLEAN=0
case "${1:-}" in
  --clean|-c) CLEAN=1 ;;
  --help|-h)  usage; exit 0 ;;
  "")         ;;
  *)          c 31 "Неизвестный аргумент: $1"; usage; exit 2 ;;
esac

command -v docker >/dev/null 2>&1 || { warn "Docker не найден — останавливать нечего."; }

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  head "Остановка Minio и очистка Docker-ресурсов"

  # Основной путь — docker compose (удаляет контейнеры, том и сеть проекта).
  if [ -f docker-compose.yml ]; then
    if compose down -v --remove-orphans >/dev/null 2>&1; then
      ok "docker compose down выполнен"
    else
      warn "compose down ничего не остановил (возможно, среда не запущена)"
    fi
  fi

  # Подстраховка: снести контейнер Minio по имени, если остался.
  if docker ps -aq -f "name=^${MINIO_CONTAINER}$" | grep -q .; then
    docker rm -f "$MINIO_CONTAINER" >/dev/null 2>&1 && ok "контейнер $MINIO_CONTAINER удалён"
  fi

  # Подстраховка: снести сеть (и любые висящие на ней контейнеры).
  if docker network inspect "$NET" >/dev/null 2>&1; then
    for cid in $(docker network inspect "$NET" -f '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null); do
      docker rm -f "$cid" >/dev/null 2>&1 || true
    done
    docker network rm "$NET" >/dev/null 2>&1 && ok "сеть $NET удалена" || warn "сеть $NET не удалить"
  else
    ok "сеть $NET отсутствует"
  fi
else
  warn "Docker-демон недоступен — пропускаю остановку контейнеров."
fi

if [ "$CLEAN" = 1 ]; then
  head "Очистка локальных артефактов"
  rm -rf .verify && ok "удалено: .verify/"
  rm -rf "$DEMO_DIR/.terraform" "$DEMO_DIR/.terraform.lock.hcl" 2>/dev/null || true
  rm -f "$DEMO_DIR"/terraform.tfstate* 2>/dev/null || true
  ok "удалены артефакты Terraform в $DEMO_DIR (если были)"
fi

head "Готово"
c 32 "  Локальная среда остановлена."
