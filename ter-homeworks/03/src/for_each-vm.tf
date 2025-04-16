data "yandex_compute_image" "ubuntu_db" {
  family = var.vm_web_family
}

resource "yandex_compute_instance" "db" {
  for_each = {for vm in var.each_vm : vm.vm_name => vm}

  name        = each.value.vm_name
  platform_id = var.vm_web_platform_id
  zone        = var.vm_web_zone

  resources {
    cores         = each.value.cpu
    memory        = each.value.ram
    core_fraction = each.value.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_db.id
      size     = each.value.disk_volume
    }
  }

  scheduling_policy {
    preemptible = var.vm_web_scheduling_policy_preemptible
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.develop.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.example.id]
  }

  metadata = local.combined_metadata
}