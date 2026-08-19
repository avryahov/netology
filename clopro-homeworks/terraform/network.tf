# 15.1 «Организация сети» — базовая сеть, NAT-инстанс, публичная и приватная подсети.
# 15.4 добавляет ещё по одной public- и private-подсети в зонах B и D для отказоустойчивости
# кластеров Kubernetes и MySQL — см. блоки в конце файла.

resource "yandex_vpc_network" "clopro" {
  name = "clopro-network"
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

# --- Публичная подсеть (зона A) -------------------------------------------

resource "yandex_vpc_subnet" "public_a" {
  name           = "clopro-public-a"
  zone           = var.yc_zone_a
  network_id     = yandex_vpc_network.clopro.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_compute_instance" "nat_instance" {
  name        = "clopro-nat-instance"
  platform_id = "standard-v3"
  zone        = var.yc_zone_a

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd80mrhj8fl2oe87o4e1"
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_a.id
    ip_address         = "192.168.10.254"
    nat                = true
    security_group_ids = [yandex_vpc_security_group.common.id, yandex_vpc_network.clopro.default_security_group_id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}

resource "yandex_compute_instance" "public_vm" {
  name        = "clopro-public-vm"
  platform_id = "standard-v3"
  zone        = var.yc_zone_a

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.common.id, yandex_vpc_network.clopro.default_security_group_id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}

# --- Приватная подсеть (зона A) --------------------------------------------

resource "yandex_vpc_route_table" "private_a" {
  name       = "clopro-private-a-rt"
  network_id = yandex_vpc_network.clopro.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "192.168.10.254"
  }
}

resource "yandex_vpc_subnet" "private_a" {
  name           = "clopro-private-a"
  zone           = var.yc_zone_a
  network_id     = yandex_vpc_network.clopro.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.private_a.id
}

resource "yandex_compute_instance" "private_vm" {
  name        = "clopro-private-vm"
  platform_id = "standard-v3"
  zone        = var.yc_zone_a

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.common.id, yandex_vpc_network.clopro.default_security_group_id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}

# --- Дополнительные зоны для 15.4 (Kubernetes и MySQL) ----------------------

resource "yandex_vpc_subnet" "public_b" {
  name           = "clopro-public-b"
  zone           = var.yc_zone_b
  network_id     = yandex_vpc_network.clopro.id
  v4_cidr_blocks = ["192.168.11.0/24"]
}

resource "yandex_vpc_subnet" "public_d" {
  name           = "clopro-public-d"
  zone           = var.yc_zone_d
  network_id     = yandex_vpc_network.clopro.id
  v4_cidr_blocks = ["192.168.12.0/24"]
}

resource "yandex_vpc_subnet" "private_b" {
  name           = "clopro-private-b"
  zone           = var.yc_zone_b
  network_id     = yandex_vpc_network.clopro.id
  v4_cidr_blocks = ["192.168.21.0/24"]
}

resource "yandex_vpc_subnet" "private_d" {
  name           = "clopro-private-d"
  zone           = var.yc_zone_d
  network_id     = yandex_vpc_network.clopro.id
  v4_cidr_blocks = ["192.168.22.0/24"]
}
