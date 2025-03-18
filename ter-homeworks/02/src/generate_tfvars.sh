#!/bin/bash

# Получение cloud_id
TOKEN=$(yc config get token)

# Получение cloud_id
ORGANIZATION_ID=$(yc organization-manager organization list --format json | jq -r '.[].id')

# Получение cloud_id
CLOUD_ID=$(yc config get cloud-id)

# Получение folder_id
FOLDER_ID=$(yc config get folder-id)

# Запись значений в файл terraform.tfvars
cat <<EOF > terraform.tfvars
token = "$TOKEN"
organization_id = "$ORGANIZATION_ID"
cloud_id  = "$CLOUD_ID"
folder_id = "$FOLDER_ID"
EOF

echo "Файл terraform.tfvars успешно создан."