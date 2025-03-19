### vm web vars
variable "vm_web_family" {
  description = "The family of yandex compute images"
  type        = string
  default     = "ubuntu-2004-lts"
}

variable "vm_web_name" {
  description = "The name of the yandex compute instance"
  type        = string
  default     = "netology-develop-platform-web"
}

variable "vm_web_platform_id" {
  description = "The platform identifier of the yandex compute instance"
  type        = string
  default     = "standard-v1"
}

variable "vm_web_resources_cores" {
  description = "The cores value of the yandex compute instance resources"
  type        = number
  default     = 2
}

variable "vm_web_resources_memory" {
  description = "The memory value of the yandex compute instance resources"
  type        = number
  default     = 1
}

variable "vm_web_resources_core_fraction" {
  description = "The core fraction value of the yandex compute instance resources"
  type        = number
  default     = 5
}

variable "vm_web_scheduling_policy_preemptible" {
  description = "The preemptible flag of the yandex compute instance scheduling policy"
  type        = bool
  default     = true
}

variable "vm_web_network_interface_nat" {
  description = "The nat flag of the yandex compute instance network interface"
  type        = bool
  default     = true
}

variable "vm_web_metadata_serial_port_enable" {
  description = "The serial port enable value of the instance metadata"
  type        = number
  default     = 1
}

variable "vm_web_metadata_enable_oslogin" {
  description = "The enable os login flag of the instance metadata"
  type        = string
  default     = "true"
}

### ssh vars

variable "vms_ssh_root_key" {
  type        = string
  description = "ssh-keygen -t ed25519"
  sensitive   = true
}