# =====================================================================
# Переменные окружения STAGE.
# Значения задаются в stage.tfvars (несекретные) и через переменные
# окружения / CLI (секреты: yc_token).
# =====================================================================

# --- Аутентификация и размещение в Yandex Cloud ---

variable "yc_token" {
  description = "OAuth/IAM токен Yandex Cloud. Рекомендуется задавать через переменную окружения TF_VAR_yc_token, а не в .tfvars"
  type        = string
  default     = null
  sensitive   = true
}

variable "cloud_id" {
  description = "ID облака Yandex Cloud"
  type        = string
}

variable "folder_id" {
  description = "ID каталога (folder), в котором создаются ресурсы окружения"
  type        = string
}

variable "zone" {
  description = "Зона доступности по умолчанию для окружения"
  type        = string
  default     = "ru-central1-a"
}

# --- Параметры ВМ окружения (передаются в модуль vm) ---

variable "name" {
  description = "Имя/префикс ВМ окружения"
  type        = string
}

variable "cores" {
  description = "Количество vCPU ядер"
  type        = number
}

variable "memory_gb" {
  description = "Объём RAM в ГБ"
  type        = number
}

variable "core_fraction" {
  description = "Гарантированная доля vCPU (5/20/50/100)"
  type        = number
  default     = 100
}

variable "preemptible" {
  description = "Прерываемая ВМ"
  type        = bool
  default     = false
}

variable "image_id" {
  description = "ID образа загрузочного диска"
  type        = string
}

variable "boot_disk_size_gb" {
  description = "Размер загрузочного диска, ГБ"
  type        = number
  default     = 10
}

variable "extra_disk_size_gb" {
  description = "Размер дополнительного диска, ГБ (0 — не создавать)"
  type        = number
  default     = 0
}

variable "subnet_id" {
  description = "ID подсети окружения"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Путь к файлу публичного SSH-ключа"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "labels" {
  description = "Метки ресурсов окружения"
  type        = map(string)
  default     = {}
}
