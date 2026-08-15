# provider.tf — конфигурация провайдера Yandex Cloud через переменные.
#
# Аутентификация:
#   * service_account_key_file — путь к JSON-ключу сервисного аккаунта.
#     В CI/CD секрет YC_SA_JSON записывается во временный файл, а путь к нему
#     передаётся через переменную var.yc_service_account_key_file
#     (или через env YC_SERVICE_ACCOUNT_KEY_FILE — тогда переменную можно оставить null).
#   * Никаких токенов/ключей в коде — только переменные и secrets.

provider "yandex" {
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone

  # Если null — провайдер прочитает YC_SERVICE_ACCOUNT_KEY_FILE / YC_TOKEN из окружения.
  service_account_key_file = var.yc_service_account_key_file
}
