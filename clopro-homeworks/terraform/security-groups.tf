resource "yandex_vpc_security_group" "common" {
  name        = "clopro-common-sg"
  description = "Общая security group: SSH, ICMP, весь трафик внутри группы, весь исходящий трафик"
  network_id  = yandex_vpc_network.clopro.id

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "ICMP"
    description    = "ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol          = "ANY"
    description       = "весь трафик внутри группы (public <-> private, jump-хосты)"
    predefined_target = "self_security_group"
  }

  egress {
    protocol       = "ANY"
    description    = "весь исходящий трафик"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "lamp_web" {
  name        = "clopro-lamp-web-sg"
  description = "HTTP/HTTPS для группы ВМ LAMP за балансировщиком, здоровье-чеки NLB"
  network_id  = yandex_vpc_network.clopro.id

  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol          = "TCP"
    description       = "health checks сетевого балансировщика"
    port              = 80
    predefined_target = "loadbalancer_healthchecks"
  }

  egress {
    protocol       = "ANY"
    description    = "весь исходящий трафик"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "k8s_main" {
  name        = "clopro-k8s-main-sg"
  description = "Обязательные правила для регионального мастера и узлов Managed Kubernetes"
  network_id  = yandex_vpc_network.clopro.id

  ingress {
    protocol       = "TCP"
    description    = "доступ к API Kubernetes-мастера снаружи"
    port           = 6443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTPS для kubectl / веб-интерфейсов через LB"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol          = "ANY"
    description       = "трафик между мастером и узлами внутри группы"
    predefined_target = "self_security_group"
  }

  ingress {
    protocol       = "TCP"
    description    = "диапазон NodePort-сервисов"
    from_port      = 30000
    to_port        = 32767
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "весь исходящий трафик"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "mysql" {
  name        = "clopro-mysql-sg"
  description = "Доступ к кластеру MySQL из сети проекта"
  network_id  = yandex_vpc_network.clopro.id

  ingress {
    protocol       = "TCP"
    description    = "MySQL из внутренней сети проекта"
    port           = 3306
    v4_cidr_blocks = ["192.168.0.0/16"]
  }

  egress {
    protocol       = "ANY"
    description    = "весь исходящий трафик"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
