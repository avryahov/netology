# 15.2 «Вычислительные мощности» — бакет с картинкой.
#
# На этом шаге бакет создаётся БЕЗ шифрования — блок server_side_encryption_configuration
# добавляется в 15.3 «Безопасность» вместе с ключом KMS (terraform/kms.tf), отдельным
# terraform apply. Так весь код по-прежнему растёт последовательно, лекция за лекцией.

resource "yandex_iam_service_account" "storage_sa" {
  name        = "clopro-storage-sa"
  description = "Сервисный аккаунт для управления Object Storage из Terraform"
}

resource "yandex_resourcemanager_folder_iam_member" "storage_sa_editor" {
  folder_id = var.yc_folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.storage_sa.id}"
}

resource "yandex_iam_service_account_static_access_key" "storage_sa_key" {
  service_account_id = yandex_iam_service_account.storage_sa.id
  description        = "Статический ключ для бакета clopro"
}

resource "yandex_storage_bucket" "pictures" {
  bucket     = var.student_bucket_name
  access_key = yandex_iam_service_account_static_access_key.storage_sa_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.storage_sa_key.secret_key

  anonymous_access_flags {
    read = true
    list = false
  }

  # 15.3: сюда добавляется server_side_encryption_configuration — см. 15.3/readme.md.
}

resource "yandex_storage_object" "picture" {
  bucket = yandex_storage_bucket.pictures.bucket
  key    = "netology-cloud.png"
  source = "${path.module}/assets/netology-cloud.png"

  access_key = yandex_iam_service_account_static_access_key.storage_sa_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.storage_sa_key.secret_key
}
