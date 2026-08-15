# main.tf (bootstrap) — первичное создание bucket в Object Storage под Terraform state.
#
# ПРОБЛЕМА КУРИЦЫ И ЯЙЦА:
#   Чтобы хранить state удалённо в S3-backend, нужен bucket. Но чтобы создать
#   bucket через Terraform, ему тоже нужен state. Bootstrap разрывает цикл:
#   он запускается ОДИН раз с ЛОКАЛЬНЫМ state и создаёт bucket + сервисный
#   аккаунт + статический ключ доступа. После этого основной код (../) уже
#   использует этот bucket как удалённый backend.
#
# Что делать с state самого bootstrap:
#   * вариант A: держать bootstrap.tfstate локально/в приватном хранилище
#     (ресурсов мало, они меняются редко);
#   * вариант B: после создания bucket мигрировать и bootstrap в этот же
#     bucket с отдельным key (например, future-2-0/bootstrap/terraform.tfstate).

provider "yandex" {
  cloud_id                 = var.yc_cloud_id
  folder_id                = var.yc_folder_id
  zone                     = var.yc_zone
  service_account_key_file = var.yc_service_account_key_file
}

# Сервисный аккаунт, от имени которого Terraform обращается к Object Storage.
resource "yandex_iam_service_account" "tf_state" {
  name        = "tf-state-sa"
  description = "SA для доступа Terraform к bucket с удалённым состоянием"
}

# Права на управление объектами в Object Storage.
resource "yandex_resourcemanager_folder_iam_member" "tf_state_storage" {
  folder_id = var.yc_folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.tf_state.id}"
}

# Статический ключ доступа (access_key/secret_key) — это и есть учётные данные
# для S3-backend. В CI/CD они кладутся в маскированные secrets
# AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY.
resource "yandex_iam_service_account_static_access_key" "tf_state" {
  service_account_id = yandex_iam_service_account.tf_state.id
  description        = "Статический ключ для S3-backend Terraform"
}

# Собственно bucket для state.
resource "yandex_storage_bucket" "tf_state" {
  access_key = yandex_iam_service_account_static_access_key.tf_state.access_key
  secret_key = yandex_iam_service_account_static_access_key.tf_state.secret_key
  bucket     = var.state_bucket_name

  # Версионирование — чтобы можно было откатиться к прошлой версии state
  # при повреждении.
  versioning {
    enabled = true
  }

  # Запрет анонимного доступа — state содержит чувствительные данные.
  anonymous_access_flags {
    read        = false
    list        = false
    config_read = false
  }

  # Защита от случайного удаления bucket вместе с историей state.
  lifecycle {
    prevent_destroy = true
  }

  depends_on = [yandex_resourcemanager_folder_iam_member.tf_state_storage]
}
