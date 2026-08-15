# =====================================================================
# Выходные значения модуля vm.
# =====================================================================

output "instance_id" {
  description = "ID созданной виртуальной машины"
  value       = yandex_compute_instance.this.id
}

output "instance_name" {
  description = "Имя виртуальной машины"
  value       = yandex_compute_instance.this.name
}

output "internal_ip" {
  description = "Внутренний IP-адрес ВМ в подсети"
  value       = yandex_compute_instance.this.network_interface[0].ip_address
}

output "external_ip" {
  description = "Внешний (публичный) IP-адрес ВМ; null, если NAT отключён"
  value       = try(yandex_compute_instance.this.network_interface[0].nat_ip_address, null)
}

output "boot_disk_id" {
  description = "ID загрузочного диска"
  value       = yandex_compute_instance.this.boot_disk[0].disk_id
}

output "secondary_disk_id" {
  description = "ID дополнительного диска; null, если диск не создавался"
  value       = local.create_extra_disk ? yandex_compute_disk.secondary[0].id : null
}

output "fqdn" {
  description = "FQDN виртуальной машины"
  value       = yandex_compute_instance.this.fqdn
}
