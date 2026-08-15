# =====================================================================
# Окружение STAGE — вызов переиспользуемого модуля vm со stage-конфигурацией.
# Один и тот же модуль используется во всех окружениях, различаются
# только значения переменных (см. stage.tfvars).
# =====================================================================

module "vm" {
  source = "../../modules/vm"

  # Размещение
  name      = var.name
  folder_id = var.folder_id
  zone      = var.zone

  # Вычислительные ресурсы
  cores         = var.cores
  memory_gb     = var.memory_gb
  core_fraction = var.core_fraction
  preemptible   = var.preemptible

  # Диски
  image_id           = var.image_id
  boot_disk_size_gb  = var.boot_disk_size_gb
  extra_disk_size_gb = var.extra_disk_size_gb

  # Сеть и доступ
  subnet_id      = var.subnet_id
  ssh_public_key = file(pathexpand(var.ssh_public_key_path))

  # Метки
  labels = var.labels
}
