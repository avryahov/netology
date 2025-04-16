#!/bin/bash

# Получение token
TOKEN=$(yc config get token)

# Получение organization_id
ORGANIZATION_ID=$(yc organization-manager organization list --format json | jq -r '.[].id')

# Получение cloud_id
CLOUD_ID=$(yc config get cloud-id)

# Получение folder_id
FOLDER_ID=$(yc config get folder-id)

# Получение ssh-key
SSH_KEY=$(cat "$HOME"/.ssh/id_ed25519.pub)

# Запись значений в файл terraform.tfvars
cat <<EOF > personal.auto.tfvars
token = "$TOKEN"
organization_id = "$ORGANIZATION_ID"
cloud_id  = "$CLOUD_ID"
folder_id = "$FOLDER_ID"
vms_ssh_root_key = "$SSH_KEY"
EOF

echo "Файл terraform.tfvars успешно создан."