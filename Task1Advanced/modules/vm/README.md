# Модуль `vm` — виртуальная машина Yandex Cloud

Универсальный переиспользуемый модуль Terraform для создания виртуальной
машины в Yandex Cloud с опциональным подключаемым диском данных. Один и тот
же модуль используется во всех окружениях (`dev` / `stage` / `prod`) —
различаются только значения входных переменных. Внутри модуля **нет ни одного
захардкоженного значения окружения**.

Компания «Будущее 2.0» переезжает в Yandex Cloud, поэтому в качестве провайдера
используется `yandex-cloud/yandex`.

## Что делает модуль

- Создаёт `yandex_compute_instance` (ядра, RAM, `core_fraction`, зона,
  прерываемость — всё параметризовано).
- Создаёт загрузочный диск из образа (`image_id`, размер).
- Опционально создаёт `yandex_compute_disk` (диск данных) и подключает его к ВМ
  как `secondary_disk` — только если `extra_disk_size_gb > 0`.
- Привязывает сетевой интерфейс к подсети (`subnet_id`), опционально выдаёт
  публичный IP (NAT).
- Прокидывает SSH-ключ через `metadata.ssh-keys`.

## Входные переменные

| Имя                  | Тип           | Описание                                                        | Дефолт            | Обязательна |
| -------------------- | ------------- | -------------------------------------------------------------- | ----------------- | ----------- |
| `name`               | `string`      | Имя ВМ и связанных ресурсов (префикс окружения)                | —                 | да          |
| `folder_id`          | `string`      | ID каталога (folder) Yandex Cloud                              | —                 | да          |
| `zone`               | `string`      | Зона доступности (`ru-central1-a/-b/-d`)                       | `ru-central1-a`   | нет         |
| `cores`              | `number`      | Количество vCPU ядер (валидация 2..32)                         | `2`               | нет         |
| `memory_gb`          | `number`      | Объём RAM в ГБ (валидация 1..256)                              | `2`               | нет         |
| `core_fraction`      | `number`      | Гарантированная доля vCPU: 5/20/50/100                         | `100`             | нет         |
| `preemptible`        | `bool`        | Прерываемая ВМ                                                  | `false`           | нет         |
| `image_id`           | `string`      | ID образа для загрузочного диска                               | —                 | да          |
| `boot_disk_size_gb`  | `number`      | Размер загрузочного диска, ГБ (валидация >= 5)                 | `10`              | нет         |
| `extra_disk_size_gb` | `number`      | Размер доп. диска, ГБ; `0` — не создавать                      | `0`               | нет         |
| `disk_type`          | `string`      | Тип дисков (`network-ssd` / `network-hdd` / ...)              | `network-ssd`     | нет         |
| `subnet_id`          | `string`      | ID подсети сетевого интерфейса                                 | —                 | да          |
| `nat`                | `bool`        | Выдавать публичный IP (NAT)                                     | `true`            | нет         |
| `ssh_user`           | `string`      | Имя пользователя ОС для SSH-ключа                              | `ubuntu`          | нет         |
| `ssh_public_key`     | `string`      | Содержимое публичного SSH-ключа                                | —                 | да          |
| `labels`             | `map(string)` | Метки для ресурсов окружения                                    | `{}`              | нет         |

## Выходы (outputs)

| Имя                 | Описание                                                |
| ------------------- | ------------------------------------------------------- |
| `instance_id`       | ID созданной виртуальной машины                         |
| `instance_name`     | Имя виртуальной машины                                  |
| `internal_ip`       | Внутренний IP-адрес ВМ в подсети                        |
| `external_ip`       | Внешний (публичный) IP; `null`, если NAT отключён       |
| `boot_disk_id`      | ID загрузочного диска                                   |
| `secondary_disk_id` | ID дополнительного диска; `null`, если он не создавался  |
| `fqdn`              | FQDN виртуальной машины                                 |

## Пример использования

```hcl
module "vm" {
  source = "../../modules/vm"

  name      = "future20-dev-vm"
  folder_id = var.folder_id
  zone      = "ru-central1-a"

  cores         = 2
  memory_gb     = 2
  core_fraction = 20
  preemptible   = true

  image_id           = var.image_id
  boot_disk_size_gb  = 10
  extra_disk_size_gb = 0

  subnet_id      = var.subnet_id
  ssh_public_key = file("~/.ssh/id_rsa.pub")

  labels = {
    environment = "dev"
    project     = "future20"
  }
}
```

## Как запускать для каждого окружения

Модуль не запускается напрямую — он вызывается из каталогов окружений
`envs/dev`, `envs/stage`, `envs/prod`. Из каталога нужного окружения:

```shell
# токен передаётся через переменную окружения, не в .tfvars
export TF_VAR_yc_token="$(yc iam create-token)"     # Linux/macOS
# $env:TF_VAR_yc_token = (yc iam create-token)       # PowerShell

cd envs/dev
terraform init
terraform apply -var-file=dev.tfvars

# аналогично:
#   cd envs/stage && terraform apply -var-file=stage.tfvars
#   cd envs/prod  && terraform apply -var-file=prod.tfvars
```

## Требования

- Terraform >= 1.3.0
- Провайдер `yandex-cloud/yandex` >= 0.100.0
