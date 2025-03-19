###cloud vars

variable "token" {
  type        = string
  sensitive   = true
}

variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
  sensitive   = true
}

variable "organization_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/organization/get-id"
  sensitive   = true
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
  sensitive   = true
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}
variable "default_cidr" {
  type = list(string)
  default = ["10.0.1.0/24"]
  description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
}

variable "vpc_name" {
  type        = string
  default     = "develop"
  description = "VPC network & subnet name"
}

variable "vpc_subnet_name" {
  type        = string
  default     = "develop-subnet-1"
  description = "VPC network & subnet name"
}

variable "service_account_name" {
  description = "The name of the service account"
  type        = string
  default     = "avryahov-sa"
}

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

###ssh vars

variable "vms_ssh_root_key" {
  type        = string
  description = "ssh-keygen -t ed25519"
  sensitive   = true
}