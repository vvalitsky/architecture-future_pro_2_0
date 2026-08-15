# Выходы окружения PROD (проксируют выходы модуля vm).

output "instance_id" {
  description = "ID ВМ окружения prod"
  value       = module.vm.instance_id
}

output "instance_name" {
  description = "Имя ВМ"
  value       = module.vm.instance_name
}

output "internal_ip" {
  description = "Внутренний IP-адрес ВМ"
  value       = module.vm.internal_ip
}

output "external_ip" {
  description = "Внешний IP-адрес ВМ"
  value       = module.vm.external_ip
}

output "secondary_disk_id" {
  description = "ID дополнительного диска данных"
  value       = module.vm.secondary_disk_id
}

output "fqdn" {
  description = "FQDN ВМ"
  value       = module.vm.fqdn
}
