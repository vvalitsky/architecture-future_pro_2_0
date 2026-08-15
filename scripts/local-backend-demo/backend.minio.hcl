# backend.minio.hcl — параметры S3-backend для ЛОКАЛЬНОГО Minio.
# Передаётся так же, как боевой backend.hcl в Task2:
#   terraform init -backend-config=backend.minio.hcl
#
# Отличие от прод-конфигурации (Task2/terraform/backend.tf) — только endpoint
# указывает на Minio, а не на Yandex Object Storage. Логика та же.
#
# Креды (access_key/secret_key) здесь НЕ хранятся — они приходят из переменных
# окружения AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY (см. run.sh demo),
# как и в CI/CD с маскированными secrets.

bucket = "future20-tfstate"
key    = "local-demo/terraform.tfstate"
region = "ru-central1"

# Endpoint локального Minio (имя сервиса в сети docker-compose future20-net).
endpoints = {
  s3 = "http://minio:9000"
}

# Флаги совместимости с не-AWS S3 (Minio / Yandex Object Storage).
use_path_style              = true
skip_credentials_validation = true
skip_region_validation      = true
skip_metadata_api_check     = true
skip_requesting_account_id  = true
skip_s3_checksum            = true
