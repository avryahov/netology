data "yandex_compute_image" "ubuntu" {
  family = var.vm_node_family
}

resource "yandex_compute_instance" "node" {
  count = var.vm_node_count

  name        = "${var.vm_node_name_prefix}-${count.index + 1}"
  platform_id = var.vm_node_platform_id
  zone        = var.vm_node_zone

  resources {
    cores         = var.vm_node_resources.cores
    memory        = var.vm_node_resources.memory
    core_fraction = var.vm_node_resources.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.vm_node_disk_size
    }
  }

  scheduling_policy {
    preemptible = var.vm_node_scheduling_policy_preemptible
  }

  network_interface {
    subnet_id = var.vm_image_id
    nat       = var.vm_node_network_interface_nat
  }

  metadata = local.combined_metadata
}
