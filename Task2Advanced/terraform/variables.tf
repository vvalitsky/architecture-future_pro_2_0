# variables.tf — входные переменные корневого модуля.
# Ни одного захардкоженного значения окружения — всё через переменные/tfvars.

# --- Аутентификация и адресация в Yandex Cloud ---

variable "yc_cloud_id" {
  description = "ID облака Yandex Cloud"
  type        = string
}

variable "yc_folder_id" {
  description = "ID каталога (folder) Yandex Cloud"
  type        = string
}

variable "yc_zone" {
  description = "Зона доступности по умолчанию (например, ru-central1-a)"
  type        = string
  default     = "ru-central1-a"
}

variable "yc_service_account_key_file" {
  description = <<-EOT
    Путь к JSON-ключу сервисного аккаунта.
    В CI/CD секрет YC_SA_JSON записывается во временный файл и путь передаётся сюда.
    Если null — провайдер использует env YC_SERVICE_ACCOUNT_KEY_FILE / YC_TOKEN.
  EOT
  type        = string
  default     = null
}

# --- Параметры демонстрационных ресурсов ---

variable "env" {
  description = "Имя окружения (dev/stage/prod). Используется в именах и метках ресурсов."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.env)
    error_message = "env должен быть одним из: dev, stage, prod."
  }
}

variable "subnet_v4_cidr_blocks" {
  description = "Список CIDR-блоков IPv4 для подсети"
  type        = list(string)
  default     = ["10.10.0.0/24"]
}

variable "labels" {
  description = "Дополнительные метки, добавляемые ко всем ресурсам"
  type        = map(string)
  default     = {}
}
