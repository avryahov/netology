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