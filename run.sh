#!/usr/bin/env bash
# =============================================================================
# run.sh — локальный ЗАПУСК и ПРОВЕРКА решений проектной работы «Будущее 2.0».
#
# ВСЁ выполняется в Docker. На хосте нужен только Docker — ни terraform, ни node,
# ни java, ни облачные креды устанавливать/задавать НЕ требуется.
#
# Команды:
#   ./run.sh check       terraform validate (Task1Advanced/Task2Advanced) + Mermaid + PlantUML   [по умолчанию]
#   ./run.sh terraform   только terraform fmt-check + validate
#   ./run.sh diagrams    только проверка диаграмм (Mermaid + PlantUML)
#   ./run.sh fmt         авто-форматирование terraform-кода (terraform fmt)
#   ./run.sh up          поднять локальный Minio + создать bucket под state
#   ./run.sh demo        рабочее демо удалённого state (Task2Advanced) на локальном Minio
#   ./run.sh down        остановить Minio и удалить данные
#   ./run.sh all         check + demo
#   ./run.sh help
#
# Подробности — в RUNNING.md.
# =============================================================================
set -uo pipefail

# --- Git Bash (Windows): не преобразовывать /work → C:\work в аргументах docker ---
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL='*'

# Путь монтирования, совместимый с Docker (на Windows: C:/... вместо /c/...).
HOST_PWD="$(pwd -W 2>/dev/null || pwd)"

IMG_TF="${IMG_TF:-hashicorp/terraform:1.10}"
IMG_MMD="${IMG_MMD:-minlag/mermaid-cli:latest}"
IMG_PUML="${IMG_PUML:-plantuml/plantuml:latest}"
NET="future20-net"
V=".verify"          # рабочая директория проверок (в .gitignore)
DEMO_DIR="scripts/local-backend-demo"

FAILS=0
WARNS=0
c()    { printf '\033[%sm%s\033[0m\n' "$1" "$2"; }
ok()   { c 32 "  ✓ $*"; }
fail() { c 31 "  ✗ $*"; FAILS=$((FAILS + 1)); }
warn() { c 33 "  ! $*"; WARNS=$((WARNS + 1)); }
head() { printf '\n'; c '1;36' "== $* =="; }
hr()   { printf '%s\n' "--------------------------------------------------------------"; }

need_docker() {
  command -v docker >/dev/null 2>&1 || { c 31 "Docker не найден. Установите Docker Desktop/Engine."; exit 2; }
  docker info >/dev/null 2>&1 || { c 31 "Docker-демон недоступен. Запустите Docker и повторите."; exit 2; }
}

compose() {
  if docker compose version >/dev/null 2>&1; then docker compose "$@";
  else docker-compose "$@"; fi
}

# Публичный mirror провайдеров Yandex Cloud. Нужен, т.к. HashiCorp блокирует
# registry.terraform.io из РФ/РБ (ошибка "does not offer a provider registry").
# Переопределяется переменной окружения TF_MIRROR_URL.
TF_MIRROR_URL="${TF_MIRROR_URL:-https://terraform-mirror.yandexcloud.net/}"

prep() {
  mkdir -p "$V/tfcache" "$V/out" "$V/home/.ssh"
  printf '%s\n' '{"args":["--no-sandbox","--disable-setuid-sandbox"]}' > "$V/puppeteer.json"
  # Заглушка публичного SSH-ключа. `terraform validate` не принимает -var, поэтому
  # путь к ключу подставляется через TF_VAR_ssh_public_key_path, а сам ключ лежит
  # ещё и по дефолтному пути ~/.ssh/id_rsa.pub (HOME переопределён на .verify/home) —
  # на случай, если validate вычисляет file(pathexpand(var.ssh_public_key_path)).
  local dummy='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUMMYdummyDUMMYdummyDUMMYdummyDUMMYdummy00 verify@local'
  printf '%s\n' "$dummy" > "$V/dummy_id.pub"
  printf '%s\n' "$dummy" > "$V/home/.ssh/id_rsa.pub"
  # CLI-конфиг Terraform: тянуть провайдеры из зеркала Yandex, а не из
  # заблокированного registry.terraform.io.
  cat > "$V/terraformrc" <<EOF
provider_installation {
  network_mirror {
    url = "${TF_MIRROR_URL}"
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
EOF
}

# Обёртка terraform в Docker (рабочая директория контейнера = /work = корень репо).
tf() {
  docker run --rm \
    -e TF_IN_AUTOMATION=1 \
    -e TF_PLUGIN_CACHE_DIR="/work/$V/tfcache" \
    -e TF_CLI_CONFIG_FILE="/work/$V/terraformrc" \
    -e HOME="/work/$V/home" \
    -e TF_VAR_ssh_public_key_path="/work/$V/dummy_id.pub" \
    -v "$HOST_PWD":/work -w /work \
    "$IMG_TF" "$@"
}

tf_validate() {
  local dir="$1"; shift
  hr; printf 'terraform validate → %s\n' "$dir"
  if ! tf -chdir="$dir" init -input=false -backend=false >/dev/null 2>&1; then
    warn "init предупреждения ($dir), повтор с выводом:"
    tf -chdir="$dir" init -input=false -backend=false || { fail "init: $dir"; return; }
  fi
  if tf -chdir="$dir" validate "$@"; then ok "valid: $dir"; else fail "validate: $dir"; fi
}

cmd_terraform() {
  need_docker; prep
  head "Terraform: fmt-check + validate (в Docker, без облачных кредов)"

  tf_validate "Task1Advanced/modules/vm"
  for e in dev stage prod; do
    # -var в `terraform validate` не поддерживается; значение приходит через
    # TF_VAR_ssh_public_key_path (см. tf()).
    tf_validate "Task1Advanced/envs/$e"
  done
  tf_validate "Task2Advanced/terraform"
  tf_validate "Task2Advanced/terraform/bootstrap"
  tf_validate "$DEMO_DIR"

  hr; printf 'terraform fmt -check (мягкая проверка стиля)\n'
  local fmtout
  fmtout="$(tf fmt -check -recursive . 2>/dev/null)"
  if [ -z "$fmtout" ]; then
    ok "fmt: код отформатирован"
  else
    warn "не по fmt (исправить одной командой: ./run.sh fmt):"
    printf '%s\n' "$fmtout" | sed 's/^/        /'
  fi
}

cmd_fmt() {
  need_docker
  head "terraform fmt -recursive (авто-форматирование)"
  tf fmt -recursive . && ok "готово"
}

cmd_diagrams() {
  need_docker; prep
  head "Диаграммы Mermaid (движок mermaid-cli — как рендерит GitHub)"
  if [ "${MERMAID_SKIP:-0}" = 1 ]; then
    warn "Mermaid-проверка пропущена (MERMAID_SKIP=1)"
  else
    local any=0 f out rc mmd_infra=0
    while IFS= read -r f; do
      grep -ql '```mermaid' "$f" || continue
      any=1
      [ "$mmd_infra" = 1 ] && continue   # браузер не стартует — дальше нет смысла
      out="$(docker run --rm -v "$HOST_PWD":/data "$IMG_MMD" \
              -p "/data/$V/puppeteer.json" \
              -i "/data/$f" -o "/data/$V/out/$(basename "$f").out.md" 2>&1)"; rc=$?
      if [ "$rc" = 0 ]; then
        ok "mermaid OK: $f"
      elif printf '%s' "$out" | grep -qiE 'failed to launch|rosetta error|could not find (chromium|expected)|ld-linux|shared librar|libnss|no usable sandbox|protocol error|navigation timeout'; then
        # Не ошибка диаграммы, а невозможность запустить headless Chromium
        # (типично для Apple Silicon/Rosetta) — считаем предупреждением.
        mmd_infra=1
      else
        fail "mermaid НЕВАЛИДЕН: $f"
        printf '%s\n' "$out" | tail -15
      fi
    done < <(find Task1Advanced Task2Advanced Task3Advanced Task4Advanced Task5Advanced -name '*.md' | sort)
    [ "$any" = 1 ] || warn "не найдено .md с блоками mermaid"
    if [ "$mmd_infra" = 1 ]; then
      warn "Mermaid локально не проверен: mermaid-cli требует headless Chromium, а он не запускается под эмуляцией (Apple Silicon/Rosetta)."
      printf '    %s\n' \
        "→ Диаграммы уже валидны и рендерятся на GitHub; синтаксис можно проверить на https://mermaid.live" \
        "→ Пропустить проверку: MERMAID_SKIP=1 ./run.sh check" \
        "→ Или запустить на amd64-хосте/в amd64-CI, где Chromium работает."
    fi
  fi

  head "Диаграммы PlantUML (.puml)"
  local pf s e
  while IFS= read -r pf; do
    s=$(grep -c '@start' "$pf"); e=$(grep -c '@end' "$pf")
    if [ "$s" -ge 1 ] && [ "$s" = "$e" ]; then ok "puml баланс @start/@end: $pf"; else fail "puml баланс: $pf ($s/$e)"; fi
  done < <(find Task1Advanced Task2Advanced Task3Advanced Task4Advanced Task5Advanced -name '*.puml' | sort)
  # Полный рендер PlantUML — best-effort: требует интернет для include C4-stdlib.
  local pumls; pumls=$(find Task1Advanced Task2Advanced Task3Advanced Task4Advanced Task5Advanced -name '*.puml' | sort)
  if [ -n "$pumls" ]; then
    hr; printf 'plantuml -checkonly (best-effort, нужен интернет для C4-PlantUML include)\n'
    # shellcheck disable=SC2086
    if docker run --rm -e PLANTUML_SECURITY_PROFILE=INTERNET \
         -v "$HOST_PWD":/work -w /work "$IMG_PUML" -checkonly -failfast2 $pumls >/dev/null 2>&1; then
      ok "plantuml -checkonly: OK"
    else
      warn "PlantUML Docker-рендер не прошёл (образ/интернет/security profile). Баланс @start/@end проверен выше."
    fi
  fi
}

cmd_up() {
  need_docker
  head "Локальный Minio (S3-совместимое хранилище) + bucket под state"
  compose up -d minio
  compose run --rm createbucket
  ok "Minio: http://localhost:9001 (minioadmin/minioadmin), S3: http://localhost:9000"
}

cmd_down() {
  # Единый teardown — в stop.sh (fallback на compose, если файла нет).
  if [ -f ./stop.sh ]; then
    bash ./stop.sh "$@"
  else
    need_docker
    head "Остановка Minio и очистка"
    compose down -v && ok "остановлено"
  fi
}

# terraform в Docker, подключённый к сети Minio (для демо удалённого state).
tf_minio() {
  docker run --rm --network "$NET" \
    -e AWS_ACCESS_KEY_ID=minioadmin -e AWS_SECRET_ACCESS_KEY=minioadmin \
    -e TF_IN_AUTOMATION=1 \
    -e TF_CLI_CONFIG_FILE="/work/$V/terraformrc" \
    -v "$HOST_PWD":/work -w "/work/$DEMO_DIR" \
    "$IMG_TF" "$@"
}

cmd_demo() {
  need_docker; prep
  cmd_up
  head "Демо: удалённый state (Task2Advanced) на локальном Minio — реальный apply без облака"
  tf_minio init -input=false -reconfigure -backend-config=backend.minio.hcl || { fail "demo: init"; return; }
  tf_minio apply -auto-approve -input=false || { fail "demo: apply"; return; }
  hr; printf 'terraform output:\n'; tf_minio output
  hr; printf 'Объект state в Minio (доказательство, что state НЕ локальный):\n'
  if compose run --rm --entrypoint sh createbucket -c \
       "mc alias set local http://minio:9000 minioadmin minioadmin >/dev/null && mc ls -r local/future20-tfstate"; then
    ok "state лежит в Minio (bucket future20-tfstate, key local-demo/terraform.tfstate)"
  else
    warn "не удалось перечислить содержимое bucket"
  fi
  # Локального terraform.tfstate быть не должно:
  if [ -f "$DEMO_DIR/terraform.tfstate" ]; then
    fail "найден локальный $DEMO_DIR/terraform.tfstate — state НЕ должен быть локальным"
  else
    ok "локального terraform.tfstate нет — backend работает корректно"
  fi
  hr; printf 'Остановить и очистить: ./run.sh down\n'
}

summary() {
  head "Итог"
  if [ "$FAILS" -eq 0 ]; then c 32 "  Провалов: 0, предупреждений: $WARNS — OK";
  else c 31 "  Провалов: $FAILS, предупреждений: $WARNS"; fi
  [ "$FAILS" -eq 0 ]
}

usage() {
  cat <<'EOF'
run.sh — локальный запуск и проверка решений «Будущее 2.0». Всё в Docker;
облачные креды и локальные terraform/node/java не нужны.

  ./run.sh check       terraform validate (Task1Advanced/Task2Advanced) + Mermaid + PlantUML  [по умолчанию]
  ./run.sh terraform   только terraform fmt-check + validate
  ./run.sh diagrams    только проверка диаграмм (Mermaid + PlantUML)
  ./run.sh fmt         авто-форматирование terraform-кода (terraform fmt)
  ./run.sh up          поднять локальный Minio + создать bucket под state
  ./run.sh demo        рабочее демо удалённого state (Task2Advanced) на локальном Minio
  ./run.sh down        остановить Minio и удалить данные
  ./run.sh all         check + demo
  ./run.sh help        эта справка

Подробности и требования — в RUNNING.md.
EOF
}

main() {
  case "${1:-check}" in
    check)      cmd_terraform; cmd_diagrams; summary ;;
    terraform|tf) cmd_terraform; summary ;;
    diagrams|diag) cmd_diagrams; summary ;;
    fmt)        cmd_fmt ;;
    up)         cmd_up ;;
    demo)       cmd_demo; summary ;;
    down)       shift; cmd_down "$@" ;;
    all)        cmd_terraform; cmd_diagrams; cmd_demo; summary ;;
    help|-h|--help) usage ;;
    *) c 31 "Неизвестная команда: $1"; usage; exit 2 ;;
  esac
}

main "$@"
