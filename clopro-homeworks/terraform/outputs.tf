output "nat_instance_internal_ip" {
  value = yandex_compute_instance.nat_instance.network_interface[0].ip_address
}

output "public_vm_external_ip" {
  value = yandex_compute_instance.public_vm.network_interface[0].nat_ip_address
}

output "private_vm_internal_ip" {
  value = yandex_compute_instance.private_vm.network_interface[0].ip_address
}

output "lamp_nlb_external_ip" {
  value = [for l in yandex_lb_network_load_balancer.lamp_nlb.listener : l.external_address_spec[0].address][0]
}

output "bucket_picture_url" {
  value = "https://${var.student_bucket_name}.storage.yandexcloud.net/netology-cloud.png"
}

output "mysql_cluster_id" {
  value = yandex_mdb_mysql_cluster.clopro_mysql.id
}

output "kubernetes_cluster_id" {
  value = yandex_kubernetes_cluster.clopro_k8s.id
}

output "kubernetes_external_v4_endpoint" {
  value = yandex_kubernetes_cluster.clopro_k8s.master[0].external_v4_endpoint
}
