# outputs.tf — полезные выходы корневого модуля.

output "network_id" {
  description = "ID созданной VPC-сети"
  value       = yandex_vpc_network.this.id
}

output "network_name" {
  description = "Имя созданной VPC-сети"
  value       = yandex_vpc_network.this.name
}

output "subnet_id" {
  description = "ID созданной подсети (можно передать в модуль ВМ из Task1)"
  value       = yandex_vpc_subnet.this.id
}

output "subnet_cidr" {
  description = "CIDR-блоки подсети"
  value       = yandex_vpc_subnet.this.v4_cidr_blocks
}
