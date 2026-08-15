# Bootstrap — первичное создание bucket под удалённый Terraform state

Этот код решает **проблему курицы и яйца**: чтобы хранить состояние Terraform
удалённо в S3-совместимом Object Storage, нужен bucket, но чтобы создать bucket
через Terraform — нужно где-то хранить его состояние.

Bootstrap запускается **один раз** с **локальным** state и создаёт:

| Ресурс | Назначение |
| --- | --- |
| `yandex_iam_service_account.tf_state` | сервисный аккаунт для доступа к Object Storage |
| `yandex_resourcemanager_folder_iam_member` | роль `storage.editor` на folder |
| `yandex_iam_service_account_static_access_key` | статический ключ (access/secret) для S3-backend |
| `yandex_storage_bucket.tf_state` | сам bucket под state (версионирование + запрет анонимного доступа) |

## Как запустить

```bash
cd Task2/terraform/bootstrap

cp terraform.tfvars.example terraform.tfvars   # заполнить своими значениями

terraform init            # backend локальный — bucket ещё не существует
terraform plan  -out=tfplan
terraform apply tfplan
```

## Забрать ключи доступа для S3-backend

```bash
terraform output -raw state_access_key   # -> AWS_ACCESS_KEY_ID
terraform output -raw state_secret_key   # -> AWS_SECRET_ACCESS_KEY
```

Полученные значения положите в **маскированные** secrets/переменные CI/CD:

- GitHub Actions → *Settings → Secrets and variables → Actions*:
  `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- GitLab CI → *Settings → CI/CD → Variables* (Masked, Protected):
  `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`

## Что делать со state самого bootstrap

- **Вариант A (просто):** хранить `terraform.tfstate` bootstrap локально/в
  приватном защищённом месте — ресурсов мало, меняются они редко.
- **Вариант B (аккуратно):** после создания bucket добавить bootstrap свой
  `backend "s3"` с отдельным ключом (`future-2-0/bootstrap/terraform.tfstate`)
  и выполнить `terraform init -migrate-state`.

> `prevent_destroy = true` на bucket защищает историю state от случайного
> `terraform destroy`. Чтобы удалить bucket намеренно, сначала снимите этот флаг.
