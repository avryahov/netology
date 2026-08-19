# 15.2 «Вычислительные мощности. Балансировщики нагрузки» — Instance Group с шаблоном LAMP
# за сетевым балансировщиком нагрузки.

resource "yandex_iam_service_account" "ig_sa" {
  name        = "clopro-ig-sa"
  description = "Сервисный аккаунт для Instance Group"
}

resource "yandex_resourcemanager_folder_iam_member" "ig_sa_editor" {
  folder_id = var.yc_folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.ig_sa.id}"
}

resource "yandex_compute_instance_group" "lamp" {
  name               = "clopro-lamp-ig"
  folder_id          = var.yc_folder_id
  service_account_id = yandex_iam_service_account.ig_sa.id

  instance_template {
    platform_id = "standard-v3"

    resources {
      cores  = 2
      memory = 2
    }

    boot_disk {
      initialize_params {
        image_id = "fd827b91d99psvq5fjit" # LAMP
        size     = 20
      }
    }

    network_interface {
      network_id         = yandex_vpc_network.clopro.id
      subnet_ids         = [yandex_vpc_subnet.public_a.id]
      nat                = true
      security_group_ids = [yandex_vpc_security_group.common.id, yandex_vpc_security_group.lamp_web.id, yandex_vpc_network.clopro.default_security_group_id]
    }

    metadata = {
      ssh-keys  = "ubuntu:${file(var.ssh_public_key_path)}"
      user-data = <<-EOF
        #cloud-config
        runcmd:
          - echo "<html><body><h1>Netology clopro-15</h1><img src='https://${var.student_bucket_name}.storage.yandexcloud.net/netology-cloud.png'></body></html>" > /var/www/html/index.html
      EOF
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = [var.yc_zone_a]
  }

  deploy_policy {
    max_unavailable = 1
    max_creating    = 1
    max_expansion   = 1
    max_deleting    = 1
  }

  health_check {
    interval            = 5
    timeout             = 2
    healthy_threshold   = 2
    unhealthy_threshold = 2

    http_options {
      port = 80
      path = "/"
    }
  }

  load_balancer {
    target_group_name = "clopro-lamp-tg"
  }
}

resource "yandex_lb_network_load_balancer" "lamp_nlb" {
  name = "clopro-lamp-nlb"

  listener {
    name = "http"
    port = 80

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.lamp.load_balancer[0].target_group_id

    healthcheck {
      name = "http"

      http_options {
        port = 80
        path = "/"
      }
    }
  }
}
