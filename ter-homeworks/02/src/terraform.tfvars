vms_resources = {
  web = {
    cores         = 2
    memory        = 1
    core_fraction = 5
  },
  db = {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
}

vms_metadata = {
  serial-port-enable = 1
  enable-oslogin     = "true"
}