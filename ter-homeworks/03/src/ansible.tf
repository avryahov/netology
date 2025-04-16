resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tftpl", {
    webservers = [
      for vm in yandex_compute_instance.web :
      {
        name  = vm.name
        fqdn  = vm.fqdn
        network_interface = vm.network_interface
      }
    ]
    databases = [
      for vm in yandex_compute_instance.db :
      {
        name  = vm.name
        fqdn  = vm.fqdn
        network_interface = vm.network_interface
      }
    ]
    storage = [
      {
        name  = yandex_compute_instance.storage.name
        fqdn  = yandex_compute_instance.storage.fqdn
        network_interface = yandex_compute_instance.storage.network_interface
      }
    ]
  })

  filename = "${path.module}/hosts.ini"
}

resource "null_resource" "ansible_provision" {
  depends_on = [
    yandex_compute_instance.web,
    yandex_compute_instance.db,
    yandex_compute_instance.storage,
    local_file.ansible_inventory
  ]

  provisioner "local-exec" {
    command    = "eval $(ssh-agent) && cat ~/.ssh/id_rsa.pub | ssh-add -"
    on_failure = continue
  }

  # optional sleep delay, uncomment if needed
  # provisioner "local-exec" {
  #   command = "sleep 60"
  # }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${var.ansible_inventory_file} ${var.ansible_playbook_file}"
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