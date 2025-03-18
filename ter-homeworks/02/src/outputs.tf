output "service_account_name" {
  value = yandex_iam_service_account.sa.name
}

output "private_key" {
  value     = yandex_iam_service_account_key.sa_key.private_key
  sensitive = true
}

output "public_key" {
  value = yandex_iam_service_account_key.sa_key.public_key
}

output "vm_public_ip" {
  value = yandex_compute_instance.platform.network_interface.0.nat_ip_address
}