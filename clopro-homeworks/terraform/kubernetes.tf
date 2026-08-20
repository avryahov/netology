# 15.4 «Кластеры. Ресурсы под управлением облачного провайдера» — региональный мастер
# Managed Kubernetes в трёх public-подсетях (зоны A, B, D) и группа узлов с автомасштабированием.

resource "yandex_iam_service_account" "k8s_sa" {
  name        = "clopro-k8s-sa"
  description = "Сервисный аккаунт кластера Kubernetes (мастер и узлы)"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_sa_editor" {
  folder_id = var.yc_folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_sa_images_puller" {
  folder_id = var.yc_folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

resource "yandex_kubernetes_cluster" "clopro_k8s" {
  name        = "clopro-k8s"
  description = "Региональный кластер K8s для домашних заданий блока 15"

  network_id = yandex_vpc_network.clopro.id

  master {
    regional {
      region = "ru-central1"

      location {
        zone      = var.yc_zone_a
        subnet_id = yandex_vpc_subnet.public_a.id
      }

      location {
        zone      = var.yc_zone_b
        subnet_id = yandex_vpc_subnet.public_b.id
      }

      location {
        zone      = var.yc_zone_d
        subnet_id = yandex_vpc_subnet.public_d.id
      }
    }

    public_ip          = true
    security_group_ids = [yandex_vpc_security_group.common.id, yandex_vpc_security_group.k8s_main.id, yandex_vpc_network.clopro.default_security_group_id]
  }

  service_account_id      = yandex_iam_service_account.k8s_sa.id
  node_service_account_id = yandex_iam_service_account.k8s_sa.id

  kms_provider {
    key_id = yandex_kms_symmetric_key.clopro_key.id
  }

  release_channel = "STABLE"
}

resource "yandex_kubernetes_node_group" "clopro_nodes" {
  cluster_id = yandex_kubernetes_cluster.clopro_k8s.id
  name       = "clopro-nodes"
  version    = "1.32"

  instance_template {
    platform_id = "standard-v3"

    network_interface {
      nat                = true
      subnet_ids         = [yandex_vpc_subnet.public_a.id]
      security_group_ids = [yandex_vpc_security_group.common.id, yandex_vpc_security_group.k8s_main.id, yandex_vpc_network.clopro.default_security_group_id]
    }

    resources {
      cores  = 2
      memory = 4
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    container_runtime {
      type = "containerd"
    }
  }

  scale_policy {
    auto_scale {
      initial = 3
      min     = 3
      max     = 6
    }
  }

  allocation_policy {
    location {
      zone = var.yc_zone_a
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true
  }
}
