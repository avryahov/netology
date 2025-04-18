#!/bin/bash

set -euo pipefail

# Цветной вывод
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "${BLUE}Начинаем процесс генерации переменных для Terraform...${NC}"

# --- Проверка наличия Yandex CLI ---
echo "${BLUE}Проверяем наличие Yandex CLI...${NC}"
if ! command -v yc &> /dev/null; then
  echo "${RED}Ошибка: Yandex CLI не установлен или не доступен в PATH.${NC}"
  exit 1
fi

echo "${GREEN}Yandex CLI найден.${NC}"

# --- Получение YC credentials ---
echo "${BLUE}Получаем учетные данные Yandex Cloud...${NC}"

if ! TOKEN=$(yc config get token 2>/dev/null); then
  echo "${RED}Ошибка: Не удалось получить OAuth-токен. Убедитесь, что Yandex CLI настроен.${NC}"
  exit 1
fi

if ! CLOUD_ID=$(yc config get cloud-id 2>/dev/null); then
  echo "${RED}Ошибка: Не удалось получить Cloud ID. Убедитесь, что Yandex CLI настроен.${NC}"
  exit 1
fi

if ! FOLDER_ID=$(yc config get folder-id 2>/dev/null); then
  echo "${RED}Ошибка: Не удалось получить Folder ID. Убедитесь, что Yandex CLI настроен.${NC}"
  exit 1
fi

# --- Проверка наличия jq ---
echo "${BLUE}Проверяем наличие jq...${NC}"
if ! command -v jq &> /dev/null; then
  echo "${RED}Ошибка: jq не установлен или не доступен в PATH.${NC}"
  exit 1
fi

if ! NETWORK_ID=$(yc vpc network get default --format=json | jq -r '.id' 2>/dev/null); then
  echo "${RED}Ошибка: Не удалось получить Network ID. Убедитесь, что Yandex CLI настроен.${NC}"
  exit 1
fi

SUBNET_NAME="develop"
DEFAULT_ZONE="ru-central1-a"

if ! SUBNET_ID=$(yc vpc subnet get $SUBNET_NAME 2>/dev/null); then
  if ! SUBNET_ID=$(yc vpc subnet create --name $SUBNET_NAME --network-id $NETWORK_ID --zone $DEFAULT_ZONE --range 192.168.0.0/24); then
    echo "${RED}Ошибка: Не удалось создать подсеть.${NC}"
    exit 1
  fi
fi

echo "${GREEN}Учетные данные Yandex Cloud успешно получены.${NC}"

# --- Загрузка SSH ключа ---
SSH_KEY_PATH="$HOME/.ssh/id_ed25519.pub"
echo "${BLUE}Проверяем наличие SSH ключа по пути: $SSH_KEY_PATH${NC}"
if [[ ! -f "$SSH_KEY_PATH" ]]; then
  echo "${RED}Ошибка: SSH ключ не найден по пути: $SSH_KEY_PATH${NC}"
  exit 1
fi

SSH_KEY=$(cat "$SSH_KEY_PATH")
echo "${GREEN}SSH ключ успешно загружен.${NC}"

# --- Проверка наличия Packer ---
echo "${BLUE}Проверяем наличие Packer...${NC}"
if ! command -v packer &> /dev/null; then
  echo "${RED}Ошибка: Packer не установлен или не доступен в PATH.${NC}"
  exit 1
fi

echo "${GREEN}Packer найден.${NC}"

# --- Проверка директории Packer ---
PACKER_DIR="../packer"
PACKER_CONFIG_FILE="${PACKER_DIR}/my-ubuntu-docker.json"

echo "${BLUE}Проверяем существование директории Packer: $PACKER_DIR...${NC}"
if [[ ! -d "$PACKER_DIR" ]]; then
  echo "${RED}Ошибка: Директория Packer '$PACKER_DIR' не существует.${NC}"
  exit 1
fi

# Переходим в директорию Packer
cd "$PACKER_DIR" || { echo "${RED}Ошибка: Не удалось перейти в директорию '$PACKER_DIR'.${NC}"; exit 1; }

# --- Проверка существования файла конфигурации Packer ---
echo "${BLUE}Проверяем существование файла конфигурации Packer: $PACKER_CONFIG_FILE...${NC}"
if [[ ! -f "$PACKER_CONFIG_FILE" ]]; then
  echo "${RED}Ошибка: Файл конфигурации Packer '$PACKER_CONFIG_FILE' не найден.${NC}"
  exit 1
fi

# --- Валидация Packer конфигурации ---
echo "${BLUE}Проверяем Packer конфигурацию $PACKER_CONFIG_FILE...${NC}"
if ! packer validate "$PACKER_CONFIG_FILE"; then
  echo "${RED}Ошибка: Конфигурация Packer недействительна. Прерываем процесс.${NC}"
  exit 1
fi

echo "${GREEN}Конфигурация Packer успешно проверена.${NC}"

# --- Сборка образа с помощью Packer ---
echo "${BLUE}Начинаем сборку образа с помощью Packer...${NC}"

# Передаем переменные в Packer
if ! IMAGE_NAME=$(packer build \
  -var "TOKEN=$TOKEN" \
  -var "FOLDER_ID=$FOLDER_ID" \
  -var "DEFAULT_ZONE=$DEFAULT_ZONE" \
  -var "SUBNET_ID=$SUBNET_ID" \
  -var "DISK_TYPE=$DISK_TYPE" \
  -machine-readable "$PACKER_CONFIG_FILE" | awk -F',' '$3 == "artifact" && $5 == "id" {print $6}'); then
  echo "${RED}Ошибка: Не удалось собрать образ с помощью Packer.${NC}"
  exit 1
fi

echo "${GREEN}Образ успешно собран. Имя образа: $IMAGE_NAME.${NC}"

# --- Проверка созданного образа через YC CLI ---
echo "${BLUE}Проверяем созданный образ в списке образов Yandex Cloud...${NC}"
if ! IMAGE_ID=$(yc compute image list --format=json | jq -r --arg name "$IMAGE_NAME" '.[] | select(.name == $name) | .id'); then
  echo "${RED}Ошибка: Не удалось найти созданный образ в списке образов Yandex Cloud.${NC}"
  exit 1
fi

if [[ -z "$IMAGE_ID" ]]; then
  echo "${RED}Ошибка: Созданный образ не найден в списке образов Yandex Cloud.${NC}"
  exit 1
fi

echo "${GREEN}Созданный образ найден. ID образа: $IMAGE_ID.${NC}"

# --- Генерация файлов переменных ---
PERSONAL_VARS_FILE="personal.auto.tfvars"
VARS_FILE="terraform.tfvars"

# --- Проверка существования папки terraform ---
if [[ ! -d "../terraform" ]]; then
  echo "${RED}Ошибка: Папка '../terraform' не существует.${NC}"
  exit 1
fi

echo "${BLUE}Создаем файл персональных переменных Terraform: $PERSONAL_VARS_FILE${NC}"

cat > "../terraform/$PERSONAL_VARS_FILE" <<EOF
token             = "$TOKEN"
cloud_id          = "$CLOUD_ID"
folder_id         = "$FOLDER_ID"
subnet_id         = "$SUBNET_ID"
vms_ssh_root_key  = "$SSH_KEY"
EOF

# --- Защита файла переменных ---
chmod 600 "$PERSONAL_VARS_FILE"

echo "${GREEN}Файл '$PERSONAL_VARS_FILE' успешно создан и защищен.${NC}"

echo "${BLUE}Создаем файл переменных Terraform: $VARS_FILE${NC}"

DISK_TYPE="network-hdd"

cat > "../terraform/$VARS_FILE" <<EOF
vm_node_count         = 3
vm_node_name_prefix   = "node"
vm_node_disk_size     = 10
vm_storage_disk_type  = "$DISK_TYPE"
default_zone          = "$DEFAULT_ZONE"

ansible_inventory_file    = "../ansible/hosts.ini"
ansible_playbook_file     = "../ansible/prod.yml"

vm_image_id               = "$IMAGE_ID"

vm_node_resources = {
  cores         = 2
  memory        = 1
  core_fraction = 5
}
EOF

echo "${GREEN}Файл '$VARS_FILE' успешно создан.${NC}"

echo "${BLUE}Создаем файл переменных Terraform: $VARS_FILE${NC}"