#!/bin/bash
set -euo pipefail

FUNCTIONS_FILE="functions.sh"
if [[ ! -f "$FUNCTIONS_FILE" ]]; then
    echo "[ERROR] Файл '$FUNCTIONS_FILE' не найден."
    exit 1
fi
source "$FUNCTIONS_FILE"

VARIABLES_JSON="../packer/variables.json"
TERRAFORM_DIR="../terraform"
PERSONAL_VARS_FILE="${TERRAFORM_DIR}/personal.auto.tfvars"
VARS_FILE="${TERRAFORM_DIR}/terraform.tfvars"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519.pub"

# Проверка ключа
if [[ ! -f "$SSH_KEY_PATH" ]]; then
  echo "$(colorize "ERROR" "[ERROR] SSH ключ не найден: $SSH_KEY_PATH")"
  exit 1
fi

SSH_KEY=$(<"$SSH_KEY_PATH")

# Берем значения из variables.json
TOKEN=$(jq -r '.TOKEN' "$VARIABLES_JSON")
FOLDER_ID=$(jq -r '.FOLDER_ID' "$VARIABLES_JSON")
CLOUD_ID=$(yc config get cloud-id)  # Опционально
SUBNET_ID=$(jq -r '.SUBNET_ID' "$VARIABLES_JSON")
IMAGE_ID=$(jq -r '.IMAGE_ID' "$VARIABLES_JSON")
DEFAULT_ZONE=$(jq -r '.DEFAULT_ZONE' "$VARIABLES_JSON")
DOCKER_SUBNET=$(jq -r '.DOCKER_SUBNET' "$VARIABLES_JSON")

# Генерация файлов переменных
cat > "$PERSONAL_VARS_FILE" <<EOF
token             = "$TOKEN"
cloud_id          = "$CLOUD_ID"
folder_id         = "$FOLDER_ID"
subnet_id         = "$SUBNET_ID"
vms_ssh_root_key  = "$SSH_KEY"
vm_image_id       = "$IMAGE_ID"
EOF

cat > "$VARS_FILE" <<EOF
default_zone          = "$DEFAULT_ZONE"
docker_subnet         = "$DOCKER_SUBNET"

vm_node_count         = 3
vm_node_name_prefix   = "node"
vm_node_disk_size     = 10

vm_node_resources = {
  cores         = 2
  memory        = 1
  core_fraction = 5
}

ansible_inventory_file    = "../ansible/hosts.ini"
ansible_playbook_file     = "../ansible/prod.yml"

EOF

chmod 600 "$PERSONAL_VARS_FILE"

echo "$(colorize "SUCCESS" "[INFO] Terraform переменные успешно сгенерированы.")"