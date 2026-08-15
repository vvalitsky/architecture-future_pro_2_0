# Требования к версии Terraform и провайдерам для окружения DEV.
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.100.0"
    }
  }

  # Пример удалённого состояния в Yandex Object Storage (S3-совместимое).
  # Раскомментируйте и заполните значения при использовании remote backend.
  # backend "s3" {
  #   endpoint                    = "storage.yandexcloud.net"
  #   bucket                      = "tfstate-future20"
  #   region                      = "ru-central1"
  #   key                         = "dev/terraform.tfstate"
  #   skip_region_validation      = true
  #   skip_credentials_validation = true
  # }
}
