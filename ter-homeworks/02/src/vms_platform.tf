### vm web vars
variable "vm_web_family" {
  description = "The family of yandex compute images"
  type = string
  default = "ubuntu-2004-lts"
}

variable "vm_web_name" {
  description = "The name of the yandex compute instance"
  type = string
  default = "netology-develop-platform-web"
}

variable "vm_web_platform_id" {
  description = "The platform identifier of the yandex compute instance"
  type = string
  default = "standard-v1"
}

### ssh vars

variable "vms_ssh_root_key" {
  type        = string
  description = "ssh-keygen -t ed25519"
  sensitive   = true
}