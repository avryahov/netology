variable "vm_web_family" {
  description = "The family of yandex compute images"
  type        = string
  default     = "ubuntu-2004-lts"
}

variable "vm_web_platform_id" {
  description = "The platform identifier of the yandex compute instance"
  type        = string
  default     = "standard-v1"
}

variable "vm_web_count" {
  description = "Количество web ВМ"
  type        = number
  default     = 2
}

variable "vm_web_name_prefix" {
  description = "Префикс имени web ВМ"
  type        = string
  default     = "web"
}

variable "vm_web_scheduling_policy_preemptible" {
  description = "The preemptible flag of the yandex compute instance scheduling policy"
  type        = bool
  default     = true
}

variable "vm_web_resources" {
  description = "Ресурсы web ВМ"
  type = object({
    cores         = number
    memory        = number
    core_fraction = number
  })
  default = {
    cores         = 2
    memory        = 2
    core_fraction = 10
  }
}

variable "vm_web_disk_size" {
  description = "Размер диска для web ВМ"
  type        = number
  default     = 10
}

variable "vm_storage_disk_type" {
  description = "Тип диска для web ВМ"
  type        = string
  default     = "network-hdd"
}

variable "vm_web_zone" {
  description = "The zone of the yandex compute instance"
  type        = string
  default     = "ru-central1-a"
}

variable "vm_web_network_interface_nat" {
  description = "The nat flag of the yandex compute instance network interface"
  type        = bool
  default     = true
}

variable "vms_metadata_serial_port_enable" {
  description = "Конфигурация метаданных для каждой ВМ"
  type        = number
  default     = 1
}

variable "each_vm" {
  type = list(object({
    vm_name       = string
    cpu           = number
    ram           = number
    disk_volume   = number
    core_fraction = number
  }))
}

variable "vms_ssh_root_key" {
  type        = string
  description = "ssh-keygen -t ed25519"
  sensitive   = true
}