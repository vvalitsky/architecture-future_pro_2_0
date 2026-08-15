# main.tf — демонстрационный, но валидный и связный набор ресурсов.
#
# Здесь создаётся базовый сетевой контур платформы «Будущее 2.0»
# (VPC-сеть + подсеть) в Yandex Cloud. Состояние этих ресурсов
# сохраняется УДАЛЁННО в Object Storage (см. backend.tf).
#
# Переиспользование модуля vm из Task1 (единый техстек «Будущее 2.0»):
#   Модуль можно подключить, передав subnet_id из созданной ниже подсети.
#   Блок закомментирован, чтобы код Task2 оставался самодостаточным и валидным
#   и не требовал image_id/ssh-ключа при демонстрационном plan. Интерфейс
#   соответствует Task1/modules/vm/variables.tf:
#
#   module "vm" {
#     source            = "../../Task1/modules/vm"
#     name              = "${var.env}-app"
#     folder_id         = var.yc_folder_id
#     zone              = var.yc_zone
#     cores             = 2
#     memory_gb         = 4
#     image_id          = "fd8..."                 # ID образа из Marketplace
#     boot_disk_size_gb = 20
#     subnet_id         = yandex_vpc_subnet.this.id
#     ssh_public_key    = file("~/.ssh/id_rsa.pub")
#     labels            = local.common_labels
#   }

locals {
  common_labels = merge(
    {
      project = "future-2-0"
      env     = var.env
      managed = "terraform"
    },
    var.labels,
  )
}

resource "yandex_vpc_network" "this" {
  name        = "${var.env}-future20-network"
  description = "Сетевой контур платформы «Будущее 2.0» (окружение ${var.env})"
  labels      = local.common_labels
}

resource "yandex_vpc_subnet" "this" {
  name           = "${var.env}-future20-subnet"
  description    = "Подсеть окружения ${var.env}"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = var.subnet_v4_cidr_blocks
  labels         = local.common_labels
}
