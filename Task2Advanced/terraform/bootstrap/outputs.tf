# outputs.tf (bootstrap)

output "state_bucket_name" {
  description = "Имя созданного bucket под Terraform state"
  value       = yandex_storage_bucket.tf_state.bucket
}

output "state_sa_id" {
  description = "ID сервисного аккаунта для доступа к state"
  value       = yandex_iam_service_account.tf_state.id
}

# Учётные данные для S3-backend. ЧУВСТВИТЕЛЬНЫЕ — не печатать в логах CI/CD.
# Получить локально: terraform output -raw state_access_key
output "state_access_key" {
  description = "AWS_ACCESS_KEY_ID для S3-backend"
  value       = yandex_iam_service_account_static_access_key.tf_state.access_key
  sensitive   = true
}

output "state_secret_key" {
  description = "AWS_SECRET_ACCESS_KEY для S3-backend"
  value       = yandex_iam_service_account_static_access_key.tf_state.secret_key
  sensitive   = true
}
