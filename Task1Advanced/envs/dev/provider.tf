# Провайдер Yandex Cloud для окружения DEV.
# Все значения передаются через переменные, без хардкода.
provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}
