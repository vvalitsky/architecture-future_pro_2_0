# backend.tf — УДАЛЁННОЕ хранение состояния Terraform.
#
# Состояние (terraform.tfstate) НЕ хранится локально. Оно лежит в
# S3-совместимом объектном хранилище Yandex Object Storage
# (endpoint storage.yandexcloud.net). Альтернатива для локальной/on-prem
# разработки — Minio (см. backend.hcl.example и SOLUTION.md).
#
# ВАЖНО:
#   * bucket и key НЕ хардкодятся здесь — они передаются во время
#     `terraform init -backend-config=...` (см. backend.hcl.example).
#     Это позволяет одному коду обслуживать разные окружения (dev/stage/prod),
#     каждое со своим ключом state.
#   * access_key / secret_key НЕ хранятся в коде. Они читаются из переменных
#     окружения AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY, которые в CI/CD
#     задаются через маскированные secrets/CI-variables.

terraform {
  backend "s3" {
    # Endpoint S3-совместимого хранилища. Для Terraform >= 1.6 используется
    # блок endpoints (раньше был скалярный endpoint = "storage.yandexcloud.net").
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    region = "ru-central1"

    # --- Значения ниже передаются через -backend-config (backend.hcl.example) ---
    # bucket = "future20-tf-state"                       # имя bucket в Object Storage
    # key    = "future-2-0/dev/terraform.tfstate"        # отдельный ключ на каждое окружение
    # -------------------------------------------------------------------------

    # Флаги совместимости с не-AWS S3-хранилищем (Yandex Object Storage / Minio):
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true # необходимо для Terraform >= 1.6.1
    skip_s3_checksum            = true # необходимо для Terraform >= 1.6.3
    skip_metadata_api_check     = true

    # --- Блокировка state (state locking) ---
    # Yandex Object Storage НЕ поддерживает DynamoDB, поэтому для защиты от
    # одновременного apply используется нативная блокировка через lock-файл
    # в самом bucket (поддерживается Terraform >= 1.10).
    use_lockfile = true
    # Для AWS S3 вместо use_lockfile традиционно применяют таблицу DynamoDB:
    #   dynamodb_table = "terraform-locks"
  }
}
