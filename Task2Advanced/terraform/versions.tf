# versions.tf — версии Terraform и провайдеров.
# Единый техстек «Будущее 2.0»: облако Yandex Cloud, IaC — Terraform.

terraform {
  # use_lockfile в S3-backend поддерживается начиная с Terraform 1.10.
  required_version = ">= 1.10.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.120.0"
    }
  }
}
