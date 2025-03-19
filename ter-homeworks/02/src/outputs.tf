output "service_account_name" {
  value = yandex_iam_service_account.sa.name
}

output "vm_public_ip" {
  value = yandex_compute_instance.platform.network_interface.0.nat_ip_address
}