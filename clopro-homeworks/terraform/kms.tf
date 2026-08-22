# 15.3 «Безопасность в облачных провайдерах» — ключ KMS для шифрования бакета
# (terraform/storage.tf) и, повторно, для шифрования кластера Kubernetes из 15.4
# (terraform/kubernetes.tf) — условие ДЗ 15.4 прямо требует переиспользовать этот ключ.

resource "yandex_kms_symmetric_key" "clopro_key" {
  name              = "clopro-key"
  description       = "Ключ для шифрования бакета pictures и кластера Kubernetes"
  default_algorithm = "AES_256"
  rotation_period   = "8760h" # 1 год
}

resource "yandex_kms_symmetric_key_iam_binding" "clopro_key_storage_access" {
  symmetric_key_id = yandex_kms_symmetric_key.clopro_key.id
  role             = "kms.keys.encrypterDecrypter"

  members = [
    "serviceAccount:${yandex_iam_service_account.storage_sa.id}",
  ]
}
