# =====================================================================
# Входные переменные модуля vm.
# Модуль полностью параметризован: значения окружений НЕ захардкожены,
# все конфигурации приходят снаружи (через env/*.tfvars).
# =====================================================================

# --- Идентификация и размещение ---

variable "name" {
  description = "Имя ВМ и связанных ресурсов (уникальный префикс в пределах окружения)"
  type        = string
}

variable "folder_id" {
  description = "ID каталога (folder) Yandex Cloud, в котором создаются ресурсы"
  type        = string
}

variable "zone" {
  description = "Зона доступности Yandex Cloud (ru-central1-a / -b / -d)"
  type        = string
  default     = "ru-central1-a"
}

# --- Вычислительные ресурсы ---

variable "cores" {
  description = "Количество vCPU ядер ВМ"
  type        = number
  default     = 2

  validation {
    condition     = var.cores >= 2 && var.cores <= 32
    error_message = "Количество ядер (cores) должно быть в диапазоне от 2 до 32."
  }
}

variable "memory_gb" {
  description = "Объём оперативной памяти в ГБ"
  type        = number
  default     = 2

  validation {
    condition     = var.memory_gb >= 1 && var.memory_gb <= 256
    error_message = "Объём памяти (memory_gb) должен быть в диапазоне от 1 до 256 ГБ."
  }
}

variable "core_fraction" {
  description = "Гарантированная доля vCPU в процентах (5, 20, 50, 100)"
  type        = number
  default     = 100

  validation {
    condition     = contains([5, 20, 50, 100], var.core_fraction)
    error_message = "core_fraction должен быть одним из значений: 5, 20, 50, 100."
  }
}

variable "preemptible" {
  description = "Прерываемая (preemptible) ВМ — дешевле, но может быть остановлена облаком"
  type        = bool
  default     = false
}

# --- Диски ---

variable "image_id" {
  description = "ID образа для загрузочного диска (например, актуальный Ubuntu из Yandex Cloud Marketplace)"
  type        = string
}

variable "boot_disk_size_gb" {
  description = "Размер загрузочного диска в ГБ"
  type        = number
  default     = 10

  validation {
    condition     = var.boot_disk_size_gb >= 5
    error_message = "Размер загрузочного диска (boot_disk_size_gb) должен быть не менее 5 ГБ."
  }
}

variable "extra_disk_size_gb" {
  description = "Размер подключаемого дополнительного диска в ГБ; 0 — диск не создаётся"
  type        = number
  default     = 0

  validation {
    condition     = var.extra_disk_size_gb >= 0
    error_message = "Размер дополнительного диска (extra_disk_size_gb) не может быть отрицательным."
  }
}

variable "disk_type" {
  description = "Тип дисков (network-ssd, network-hdd, network-ssd-nonreplicated)"
  type        = string
  default     = "network-ssd"
}

# --- Сеть и доступ ---

variable "subnet_id" {
  description = "ID подсети, к которой подключается сетевой интерфейс ВМ"
  type        = string
}

variable "nat" {
  description = "Выдавать ли ВМ публичный IP (NAT)"
  type        = bool
  default     = true
}

variable "ssh_user" {
  description = "Имя пользователя ОС, для которого прокидывается SSH-ключ"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "Содержимое публичного SSH-ключа для доступа к ВМ"
  type        = string
}

# --- Метаданные ---

variable "labels" {
  description = "Метки (labels) для всех ресурсов окружения"
  type        = map(string)
  default     = {}
}
