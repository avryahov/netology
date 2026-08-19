# 15.4 «Кластеры. Ресурсы под управлением облачного провайдера» — отказоустойчивый
# кластер Managed MySQL в private-подсетях зон A и B.
#
# resource_preset_id подобран под требование задания «платформа Intel Broadwell,
# производительность 50% CPU» — перед apply проверьте актуальное имя пресета командой
# `yc mdb mysql resource-preset list` (см. Шаг в 15.4/readme.md) и поправьте здесь при
# расхождении.

resource "yandex_mdb_mysql_cluster" "clopro_mysql" {
  name        = "clopro-mysql"
  environment = "PRESTABLE"
  network_id  = yandex_vpc_network.clopro.id
  version     = "8.0"

  security_group_ids  = [yandex_vpc_security_group.mysql.id, yandex_vpc_network.clopro.default_security_group_id]
  deletion_protection = true

  resources {
    resource_preset_id = "b2.medium"
    disk_type_id       = "network-ssd"
    disk_size          = 20
  }

  host {
    zone      = var.yc_zone_a
    subnet_id = yandex_vpc_subnet.private_a.id
  }

  host {
    zone      = var.yc_zone_b
    subnet_id = yandex_vpc_subnet.private_b.id
  }

  backup_window_start {
    hours   = 23
    minutes = 59
  }

  maintenance_window {
    type = "WEEKLY"
    day  = "SUN"
    hour = 4
  }
}

resource "yandex_mdb_mysql_database" "netology_db" {
  cluster_id = yandex_mdb_mysql_cluster.clopro_mysql.id
  name       = "netology_db"
}

resource "yandex_mdb_mysql_user" "netology_user" {
  cluster_id = yandex_mdb_mysql_cluster.clopro_mysql.id
  name       = "netology_user"
  password   = var.mysql_user_password

  permission {
    database_name = yandex_mdb_mysql_database.netology_db.name
    roles         = ["ALL"]
  }
}
