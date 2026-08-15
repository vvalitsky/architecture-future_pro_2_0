# Задание 1 — Модульная инфраструктура для нескольких сред (dev / stage / prod)

Решение для компании **«Будущее 2.0»**. Универсальный переиспользуемый модуль
Terraform `vm` и три окружения (`dev`, `stage`, `prod`), каждое со своей
конфигурацией, передаваемой через `-var-file=*.tfvars`. Провайдер —
**Yandex Cloud** (`yandex-cloud/yandex`), так как компания переезжает в
Yandex Cloud (в Задании 2 используется Yandex Object Storage).

## Структура каталогов

```text
Task1/
├── SOLUTION.md                 # этот файл — описание всего решения
├── .gitignore                  # игнор state/секретов, пример .tfvars оставлен
├── modules/
│   └── vm/                     # переиспользуемый модуль виртуальной машины
│       ├── main.tf             # yandex_compute_instance + доп. диск + сеть
│       ├── variables.tf        # входные переменные с описаниями и валидацией
│       ├── outputs.tf          # выходы (id, ip, диски, fqdn)
│       ├── versions.tf         # required_providers (yandex) + required_version
│       └── README.md           # пользовательская документация модуля
└── envs/
    ├── dev/                    # маленькая прерываемая ВМ
    │   ├── backend.tf          # версии Terraform/провайдера (+ пример S3 backend)
    │   ├── provider.tf         # provider "yandex" через переменные
    │   ├── main.tf             # module "vm" { source = "../../modules/vm" ... }
    │   ├── variables.tf        # переменные окружения
    │   ├── outputs.tf          # выходы окружения
    │   ├── dev.tfvars          # конфигурация dev (плейсхолдеры)
    │   └── terraform.tfvars.example
    ├── stage/                  # средняя ВМ (аналогичный набор файлов + stage.tfvars)
    └── prod/                   # крупная ВМ + диск данных (+ prod.tfvars)
```

## Что делает модуль `vm`

- `yandex_compute_instance` — ВМ с параметрами: `cores`, `memory_gb`,
  `core_fraction`, `zone`, `preemptible`, `platform_id = standard-v3`.
- Загрузочный диск из образа `image_id` заданного размера `boot_disk_size_gb`.
- Опциональный `yandex_compute_disk` (диск данных) — создаётся и подключается
  как `secondary_disk` только при `extra_disk_size_gb > 0` (через `count` и
  `dynamic`-блок).
- Сетевой интерфейс привязан к `subnet_id`, публичный IP через `nat`.
- SSH-ключ прокинут в `metadata.ssh-keys`.
- Метки `labels` применяются ко всем ресурсам.

Внутри модуля **нет захардкоженных значений окружений** — всё поступает через
`var.*`. См. подробную документацию: [`modules/vm/README.md`](modules/vm/README.md).

## Входы и выходы модуля (кратко)

Полные таблицы — в [`modules/vm/README.md`](modules/vm/README.md).

- Обязательные входы: `name`, `folder_id`, `image_id`, `subnet_id`,
  `ssh_public_key`.
- Необязательные (с дефолтами): `zone`, `cores`, `memory_gb`, `core_fraction`,
  `preemptible`, `boot_disk_size_gb`, `extra_disk_size_gb`, `disk_type`, `nat`,
  `ssh_user`, `labels`.
- Выходы: `instance_id`, `instance_name`, `internal_ip`, `external_ip`,
  `boot_disk_id`, `secondary_disk_id`, `fqdn`.

## Различия конфигураций окружений

| Параметр             | dev              | stage             | prod              |
| -------------------- | ---------------- | ----------------- | ----------------- |
| `name`               | `future20-dev-vm`| `future20-stage-vm`| `future20-prod-vm`|
| `cores`              | 2                | 4                 | 8                 |
| `memory_gb`          | 2                | 8                 | 16                |
| `core_fraction`      | 20               | 100               | 100               |
| `preemptible`        | `true`           | `false`           | `false`           |
| `boot_disk_size_gb`  | 10               | 50                | 100               |
| `extra_disk_size_gb` | 0                | 0                 | 200               |
| `zone`               | `ru-central1-a`  | `ru-central1-b`   | `ru-central1-d`   |
| `subnet_id`          | свой (dev)       | свой (stage)      | свой (prod)       |
| `labels.environment` | `dev`            | `stage`           | `prod`            |

## Как применять окружение

Аутентификация: токен передаётся через переменную окружения (не в `.tfvars`).

```shell
export TF_VAR_yc_token="$(yc iam create-token)"     # Linux/macOS
# $env:TF_VAR_yc_token = (yc iam create-token)       # PowerShell
```

DEV:

```shell
cd envs/dev
terraform init
terraform apply -var-file=dev.tfvars
```

STAGE:

```shell
cd envs/stage
terraform init
terraform apply -var-file=stage.tfvars
```

PROD:

```shell
cd envs/prod
terraform init
terraform apply -var-file=prod.tfvars
```

Перед `apply` полезно выполнить `terraform fmt -check`, `terraform validate` и
`terraform plan -var-file=<env>.tfvars`.

## Переиспользуемость

- Единственный источник логики ВМ — `modules/vm`. Окружения не дублируют код
  ресурсов, а лишь **вызывают модуль** с разными значениями переменных.
- Добавление нового окружения = новый каталог в `envs/` с собственным
  `*.tfvars`; правки модуля не требуются.
- Изменение поведения ВМ (например, новый параметр) делается в одном месте — в
  модуле — и автоматически доступно всем окружениям.
- Секреты (`yc_token`) и параметры (`folder_id`, `subnet_id`, путь к SSH-ключу)
  вынесены в переменные; в репозитории лежат только плейсхолдеры и
  `terraform.tfvars.example`.

## Замечания по безопасности

- `yc_token` помечен `sensitive` и не хранится в `.tfvars` — только через
  `TF_VAR_yc_token`.
- `.gitignore` исключает `*.tfstate*`, каталог `.terraform/` и реальные
  `*.tfvars` (кроме `*.tfvars.example`).
- Для командной работы рекомендуется удалённый state в Yandex Object Storage
  (S3-совместимый backend) — заготовка приведена в `envs/*/backend.tf`.
