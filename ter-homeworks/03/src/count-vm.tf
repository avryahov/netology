data "yandex_compute_image" "ubuntu" {
  family = var.vm_web_family
}

resource "yandex_compute_instance" "web" {
  count = var.vm_web_count

  name        = "${var.vm_web_name_prefix}-${count.index + 1}"
  platform_id = var.vm_web_platform_id
  zone        = var.vm_web_zone

  resources {
    cores         = var.vm_web_resources.cores
    memory        = var.vm_web_resources.memory
    core_fraction = var.vm_web_resources.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.vm_web_disk_size
    }
  }

  scheduling_policy {
    preemptible = var.vm_web_scheduling_policy_preemptible
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.develop.id
    nat       = var.vm_web_network_interface_nat
    security_group_ids = [yandex_vpc_security_group.example.id]
  }

  metadata = local.combined_metadata
}
