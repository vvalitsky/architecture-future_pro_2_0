# =====================================================================
# Модуль vm — универсальная виртуальная машина Yandex Cloud.
# Ресурсы: yandex_compute_instance + опциональный подключаемый диск.
# Ни одного захардкоженного значения окружения — всё через var.*.
# =====================================================================

locals {
  # Дополнительный диск создаётся только если задан положительный размер.
  create_extra_disk = var.extra_disk_size_gb > 0
}

# Дополнительный (подключаемый) диск данных.
# Управляется отдельно от ВМ; count реализует опциональность.
resource "yandex_compute_disk" "secondary" {
  count = local.create_extra_disk ? 1 : 0

  name      = "${var.name}-data"
  folder_id = var.folder_id
  zone      = var.zone
  size      = var.extra_disk_size_gb
  type      = var.disk_type
  labels    = var.labels
}

# Виртуальная машина
resource "yandex_compute_instance" "this" {
  name        = var.name
  folder_id   = var.folder_id
  zone        = var.zone
  platform_id = "standard-v3"
  labels      = var.labels

  # Прерываемость задаётся переменной окружения (dev — true, prod — false).
  scheduling_policy {
    preemptible = var.preemptible
  }

  # Ядра, RAM и гарантированная доля vCPU — из переменных.
  resources {
    cores         = var.cores
    memory        = var.memory_gb
    core_fraction = var.core_fraction
  }

  # Загрузочный диск из образа.
  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = var.boot_disk_size_gb
      type     = var.disk_type
    }
  }

  # Подключение дополнительного диска (если он создан).
  dynamic "secondary_disk" {
    for_each = local.create_extra_disk ? [1] : []
    content {
      disk_id     = yandex_compute_disk.secondary[0].id
      auto_delete = false
    }
  }

  # Привязка к подсети окружения.
  network_interface {
    subnet_id = var.subnet_id
    nat       = var.nat
  }

  # SSH-ключ передаётся через метаданные инстанса.
  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key}"
  }
}
