locals {
  root    = "netology"
  env     = "develop"
  project = "platform"

  vm_web_name = "${local.root}-${local.env}-${local.project}-web"
  vm_db_name  = "${local.root}-${local.env}-${local.project}-db"
}

locals {
  combined_metadata = {
    serial-port-enable = var.vms_metadata.serial-port-enable
    ssh-keys           = "ubuntu:${var.vms_ssh_root_key}"
    enable-oslogin     = var.vms_metadata.enable-oslogin
  }
}

