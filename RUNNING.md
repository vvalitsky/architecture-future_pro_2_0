# Локальный запуск и проверка в Docker

Все проверки и демо запускаются **в Docker**. На хосте нужен только Docker —
устанавливать Terraform, Node.js, Java или задавать облачные креды **не требуется**.

## Требования

- Docker (Docker Desktop на Windows/macOS или Docker Engine на Linux) с плагином
  `docker compose` (v2). Проверка: `docker info` и `docker compose version`.
- Оболочка `bash`. На Windows — **Git Bash** или **WSL** (скрипт сам отключает
  преобразование путей MSYS и вычисляет Windows-совместимый путь монтирования).
- Доступ в интернет при первом запуске: Docker тянет образы и провайдеры Terraform.

Используемые образы (переопределяются через переменные окружения `IMG_TF`,
`IMG_MMD`, `IMG_PUML`):

| Назначение | Образ |
| --- | --- |
| Terraform | `hashicorp/terraform:1.10` |
| Mermaid   | `minlag/mermaid-cli:latest` |
| PlantUML  | `plantuml/plantuml:latest` |
| S3-хранилище | `minio/minio:latest` + `minio/mc:latest` |

## Быстрый старт

```bash
# из корня репозитория
chmod +x run.sh stop.sh  # один раз (в Git Bash можно: bash run.sh ...)

./run.sh check           # terraform validate + проверка всех диаграмм
./run.sh demo            # рабочее демо удалённого state на локальном Minio
./stop.sh                # остановить Minio и удалить контейнеры/том/сеть
./stop.sh --clean        # то же + удалить локальные артефакты (.verify, .terraform)
```

Остановить среду можно как `./stop.sh`, так и `./run.sh down` (второе просто
вызывает `stop.sh`). Оба варианта идемпотентны.

## Команды `run.sh`

| Команда | Что делает |
| --- | --- |
| `check` (по умолчанию) | `terraform fmt-check` + `validate` для Task1/Task2 и демо-кода; проверка **всех** Mermaid-диаграмм движком mermaid-cli (как рендерит GitHub) и баланс/`-checkonly` PlantUML |
| `terraform` (`tf`) | только Terraform: `fmt-check` + `validate` |
| `diagrams` (`diag`) | только диаграммы: Mermaid + PlantUML |
| `fmt` | авто-форматирование: `terraform fmt -recursive` |
| `up` | поднять локальный Minio и создать bucket `future20-tfstate` под state |
| `demo` | поднять Minio → `terraform init/apply` демо-кода с backend’ом **s3 → Minio** → показать `output` и объект state в Minio |
| `down` | `docker compose down -v` (остановить Minio, удалить том) |
| `all` | `check` + `demo` |
| `help` | справка |

Код возврата `check`/`all` — ненулевой, если есть проваленные проверки
(`terraform validate` или Mermaid). PlantUML-рендер и `fmt` — «мягкие»
(предупреждение, не провал): PlantUML `.puml` через `!include` тянет
C4-PlantUML-библиотеку из интернета, поэтому его полный рендер зависит от сети и
профиля безопасности; гарантированно проверяется баланс `@startuml/@enduml`.

## Что именно проверяется

**Terraform (Task1, Task2).** Для каждой директории (`Task1/modules/vm`,
`Task1/envs/{dev,stage,prod}`, `Task2/terraform`, `Task2/terraform/bootstrap`,
демо) выполняется `terraform init -backend=false` + `terraform validate` в
контейнере. Провайдеры кешируются в `.verify/tfcache`. Креды не нужны — `validate`
не обращается к облаку. Для окружений Task1 подставляется временный публичный
SSH-ключ `.verify/dummy_id.pub` (только чтобы вычислить `file(...)`).

**Диаграммы (Task3, Task4, Task5, Task2).** Каждый `.md` с блоком ` ```mermaid `
прогоняется через `mermaid-cli` (та же библиотека Mermaid, что и на GitHub) —
невалидный синтаксис даёт ошибку. Для `.puml` проверяется баланс и, best-effort,
`plantuml -checkonly`.

## Демо удалённого state (Task2) без облака

`./run.sh demo` показывает механику из Task2 **локально**:

1. Поднимается Minio (S3-совместимое хранилище) и создаётся versioned-bucket
   `future20-tfstate` — полный аналог Yandex Object Storage.
2. `scripts/local-backend-demo/` — самодостаточный Terraform с **пустым**
   `backend "s3" {}` и провайдером `random` (не ходит в облако). Параметры
   backend приходят из [`backend.minio.hcl`](scripts/local-backend-demo/backend.minio.hcl)
   — та же конфигурация, что в [`Task2/terraform/backend.tf`](Task2Advanced/terraform/backend.tf),
   но `endpoint` указывает на Minio.
3. `terraform apply` реально выполняется, а `terraform.tfstate` пишется **в Minio**,
   не на диск. Скрипт это подтверждает: показывает объект state в bucket и
   проверяет отсутствие локального `terraform.tfstate`.

Креды S3 (`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`) передаются через переменные
окружения контейнера — как и в CI/CD с маскированными secrets; в коде их нет.

Консоль Minio во время демо: <http://localhost:9001> (`minioadmin`/`minioadmin`).

## Реестр провайдеров заблокирован из РФ/РБ

HashiCorp блокирует `registry.terraform.io` из России и Беларуси, из-за чего
`terraform init` падает с `Invalid provider registry host ... does not offer a
Terraform provider registry`. Поэтому `run.sh` подкладывает Terraform CLI-конфиг
(`.verify/terraformrc`) с **сетевым зеркалом провайдеров Yandex Cloud**
`https://terraform-mirror.yandexcloud.net/` — оттуда тянется провайдер `yandex`.
Зеркало переопределяется переменной окружения `TF_MIRROR_URL`. Демо
(`scripts/local-backend-demo/`) использует встроенный `terraform_data` и вообще
не требует реестра. Если вы вне РФ/РБ — зеркало тоже работает, менять ничего не нужно.

## Заметки

- **Apple Silicon (Mac M1/M2/M3) и Mermaid.** `mermaid-cli` использует headless
  Chromium, который не запускается под эмуляцией amd64/Rosetta (ошибка
  `rosetta error ... ld-linux-x86-64.so.2` / `Failed to launch the browser`).
  `run.sh` распознаёт это и помечает Mermaid как **предупреждение**, а не провал
  (диаграммы уже валидны и рендерятся на GitHub). Пропустить проверку целиком:
  `MERMAID_SKIP=1 ./run.sh check`. Полноценно Mermaid проверяется на amd64-хосте
  или в CI, либо онлайн на <https://mermaid.live>.
- **Права на bind-mount (Linux).** Если `mermaid-cli` не может писать в
  `.verify/out`, добавьте `--user "$(id -u):$(id -g)"` (на Docker Desktop
  Windows/macOS не требуется).
- Настоящий деплой Task1/Task2 в Yandex Cloud требует кредов (`TF_VAR_yc_token`
  или ключ сервисного аккаунта) — см. `Task1/SOLUTION.md` и `Task2/SOLUTION.md`.
  Локальный харнесс намеренно ограничивается `validate` + демо на Minio.
- Временные артефакты складываются в `.verify/` (в `.gitignore`).
