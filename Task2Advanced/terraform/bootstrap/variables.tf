# variables.tf (bootstrap)

variable "yc_cloud_id" {
  description = "ID облака Yandex Cloud"
  type        = string
}

variable "yc_folder_id" {
  description = "ID каталога (folder) Yandex Cloud"
  type        = string
}

variable "yc_zone" {
  description = "Зона доступности по умолчанию"
  type        = string
  default     = "ru-central1-a"
}

variable "yc_service_account_key_file" {
  description = "Путь к JSON-ключу сервисного аккаунта (или null для env-аутентификации)"
  type        = string
  default     = null
}

variable "state_bucket_name" {
  # Глобально уникальное имя bucket в Object Storage под Terraform state
  # (напр. future20-tf-state). Единый bucket на все окружения, разделение —
  # через разные key (см. backend.hcl.example основного модуля).
  description = "Глобально уникальное имя bucket в Object Storage под Terraform state (напр. future20-tf-state)"
  type        = string
}
