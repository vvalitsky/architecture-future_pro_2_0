# local-backend-demo — самодостаточная демонстрация УДАЛЁННОГО state Terraform
# на S3-совместимом хранилище (локальный Minio из docker-compose.yml).
#
# Зачем: доказать, что механика remote-state из Task2 работает локально в Docker,
# БЕЗ облачных кредов и БЕЗ доступа к registry.terraform.io.
#
# Используется встроенный ресурс terraform_data (провайдер terraform.io/builtin,
# входит в CLI) — поэтому `terraform init/apply` не качает НИ ОДНОГО внешнего
# провайдера и работает даже там, где реестр HashiCorp заблокирован. Состояние
# при этом реально пишется в Minio (не на диск).
#
# Backend s3 сознательно ПУСТОЙ: параметры подключения к Minio передаются через
# `-backend-config=backend.minio.hcl` при `terraform init` (см. run.sh demo).

terraform {
  required_version = ">= 1.10"

  backend "s3" {}
}

# «Состояние», которое ляжет в state-файл в Minio (без внешних провайдеров).
resource "terraform_data" "demo" {
  input = "future20 remote-state demo :: apply OK"
}

resource "terraform_data" "env_marker" {
  input = {
    project = "future-2-0"
    purpose = "проверка удалённого state на локальном Minio"
  }
}

output "stored_value" {
  description = "Значение, прочитанное из state, хранящегося удалённо в Minio"
  value       = terraform_data.demo.output
}

output "marker" {
  description = "Составное значение из удалённого state"
  value       = terraform_data.env_marker.output
}
