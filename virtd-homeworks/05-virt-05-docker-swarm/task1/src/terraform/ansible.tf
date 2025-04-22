resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tftpl", {
    nodes = [
      for vm in yandex_compute_instance.node :
      {
        name              = vm.name
        fqdn              = vm.fqdn
        network_interface = vm.network_interface
      }
    ]
  })

  filename = var.ansible_inventory_file
}

resource "null_resource" "ansible_provision" {
  depends_on = [
    yandex_compute_instance.node,
    local_file.ansible_inventory
  ]

  provisioner "local-exec" {
    command = <<EOT
    # Создаем временный файл с ключом
    echo "${var.vms_ssh_root_key}" > /tmp/ssh_key.pub

    # Добавляем ключ в ssh-agent
    eval $(ssh-agent) && cat /tmp/ssh_key.pub | ssh-add -

    # Удаляем временный файл
    rm -f /tmp/ssh_key.pub
  EOT

    on_failure = continue
  }

  # optional sleep delay, uncomment if needed
  provisioner "local-exec" {
    command = "sleep 60"
  }

  provisioner "local-exec" {
    command    = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${var.ansible_inventory_file} -e docker_subnet=${var.docker_subnet}  ${var.ansible_playbook_file}"
    on_failure = continue
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }

  triggers = {
    always_run      = "${timestamp()}"
    always_run_uuid = "${uuid()}"
  }
}