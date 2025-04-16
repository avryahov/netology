vm_web_count       = 2
vm_web_name_prefix = "web"
vm_web_disk_size   = 10

vm_web_resources = {
  cores         = 2
  memory        = 1
  core_fraction = 5
}

each_vm = [
  {
    vm_name     = "main"
    cpu         = 2
    ram         = 2
    core_fraction = 20
    disk_volume = 20
  },
  {
    vm_name     = "replica"
    cpu         = 2
    ram         = 1
    core_fraction = 5
    disk_volume = 10
  }
]
