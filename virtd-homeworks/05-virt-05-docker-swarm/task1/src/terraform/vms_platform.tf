###vm vars
variable "vm_node_family" {
  description = "The family of yandex compute images"
  type        = string
  default     = "ubuntu-22-04-lts"
}

variable "vm_node_platform_id" {
  description = "The platform identifier of the yandex compute instance"
  type        = string
  default     = "standard-v1"
}

variable "vm_node_count" {
  description = "Количество node ВМ"
  type        = number
  default     = 3
}

variable "vm_node_name_prefix" {
  description = "Префикс имени node ВМ"
  type        = string
  default     = "node"
}

variable "vm_node_scheduling_policy_preemptible" {
  description = "The preemptible flag of the yandex compute instance scheduling policy"
  type        = bool
  default     = true
}

variable "vm_node_resources" {
  description = "Ресурсы node ВМ"
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

variable "vm_node_disk_size" {
  description = "Размер диска для node ВМ"
  type        = number
  default     = 10
}

variable "vm_node_zone" {
  description = "The zone of the yandex compute instance"
  type        = string
  default     = "ru-central1-a"
}

variable "vm_node_network_interface_nat" {
  description = "The nat flag of the yandex compute instance network interface"
  type        = bool
  default     = true
}

variable "vms_metadata_serial_port_enable" {
  description = "Конфигурация метаданных для каждой ВМ"
  type        = number
  default     = 1
}

variable "vms_ssh_root_key" {
  type        = string
  description = "ssh-keygen -t ed25519"
  sensitive   = true
}

variable "vm_image_id" {
  description = "My Ubuntu Docker image id"
  type        = string
}