variable "yc_token" {
  description = "IAM/OAuth-токен Yandex Cloud. Передаётся только через переменную окружения TF_VAR_yc_token, в файле не хранится."
  type        = string
  sensitive   = true
}

variable "yc_cloud_id" {
  description = "Идентификатор облака."
  type        = string
}

variable "yc_folder_id" {
  description = "Идентификатор каталога (folder), в котором создаются все ресурсы."
  type        = string
}

variable "yc_zone_a" {
  description = "Зона доступности A."
  type        = string
  default     = "ru-central1-a"
}

variable "yc_zone_b" {
  description = "Зона доступности B."
  type        = string
  default     = "ru-central1-b"
}

variable "yc_zone_d" {
  description = "Зона доступности D."
  type        = string
  default     = "ru-central1-d"
}

variable "ssh_public_key_path" {
  description = "Путь к локальному публичному SSH-ключу, который прокидывается в metadata ВМ."
  type        = string
}

variable "student_bucket_name" {
  description = "Имя бакета Object Storage. Должно быть глобально уникальным, например avrjakhov-20260819."
  type        = string
}

variable "mysql_user_password" {
  description = "Пароль пользователя MySQL netology_user. Учебный стенд — задан дефолт, при желании переопределяется через TF_VAR_mysql_user_password."
  type        = string
  sensitive   = true
  default     = "Clopro15Netology!"
}
