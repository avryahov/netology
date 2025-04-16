locals {
  combined_metadata = {
    serial-port-enable = var.vms_metadata_serial_port_enable
    ssh-keys           = "ubuntu:${var.vms_ssh_root_key}"
  }
}

