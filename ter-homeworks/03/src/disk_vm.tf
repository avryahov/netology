data "yandex_compute_image" "ubuntu_storage" {
  family = var.vm_web_family
}

resource "yandex_compute_disk" "storage_disks" {
  count = 3

  name = "storage-disk-${count.index + 1}"
  size = 1
  type = var.vm_storage_disk_type
  zone = var.vm_web_zone
}

resource "yandex_compute_instance" "storage" {
  name        = "storage"
  platform_id = var.vm_web_platform_id
  zone        = var.vm_web_zone

  resources {
    cores         = var.vm_web_resources.cores
    memory        = var.vm_web_resources.memory
    core_fraction = var.vm_web_resources.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_storage.id
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

  dynamic "secondary_disk" {
    for_each = {for disk in yandex_compute_disk.storage_disks : disk.name => disk}

    content {
      disk_id = secondary_disk.value.id
    }
  }

  metadata = local.combined_metadata
}