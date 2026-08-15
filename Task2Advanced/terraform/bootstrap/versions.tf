# versions.tf (bootstrap) — версии для первичного создания bucket под state.
# У bootstrap НЕТ backend "s3": он и создаёт этот bucket (проблема курицы и яйца).

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.120.0"
    }
  }
}
