locals {
  combined_metadata = {
    serial-port-enable = var.vms_metadata_serial_port_enable
    ssh-keys           = file("~/.ssh/id_ed25519.pub")
  }
}