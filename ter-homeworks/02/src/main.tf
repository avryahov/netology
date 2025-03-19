resource "yandex_vpc_network" "develop" {
  name = var.vpc_name
}
resource "yandex_vpc_subnet" "develop-subnet-1" {
  name           = var.vpc_subnet_name
  zone           = var.default_zone
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = var.default_cidr
}

resource "yandex_iam_service_account" "sa" {
  name        = var.service_account_name
  description = "Service account for Terraform operations"
  folder_id   = var.folder_id
}

resource "yandex_iam_service_account_key" "sa_key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "Key for my-service-account"
  key_algorithm      = "RSA_2048"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_vpc_admin" {
  folder_id = var.folder_id
  role      = "vpc.admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_os_login" {
  folder_id = var.folder_id
  role      = "compute.osAdminLogin"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "local_file" "authorized_key" {
  content = jsonencode({
    id                 = yandex_iam_service_account_key.sa_key.id
    service_account_id = yandex_iam_service_account_key.sa_key.service_account_id
    created_at         = yandex_iam_service_account_key.sa_key.created_at
    key_algorithm      = yandex_iam_service_account_key.sa_key.key_algorithm
    public_key         = yandex_iam_service_account_key.sa_key.public_key
    private_key        = yandex_iam_service_account_key.sa_key.private_key
  })
  filename = ".authorized_key.json"
}

data "yandex_compute_image" "ubuntu" {
  family = var.vm_web_family
}

resource "yandex_compute_instance" "platform" {
  name        = var.vm_web_name
  platform_id = var.vm_web_platform_id
  resources {
    cores         = var.vm_web_resources_cores
    memory        = var.vm_web_resources_memory
    core_fraction = var.vm_web_resources_core_fraction
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
    }
  }
  scheduling_policy {
    preemptible = var.vm_web_scheduling_policy_preemptible
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.develop-subnet-1.id
    nat       = var.vm_web_network_interface_nat
  }

  metadata = {
    serial-port-enable = var.vm_web_metadata_serial_port_enable
    ssh-keys           = "ubuntu:${var.vms_ssh_root_key}"
    enable-oslogin     = var.vm_web_metadata_enable_oslogin
  }
}
