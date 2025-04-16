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

echo "${GREEN}Учетные данные Yandex Cloud успешно получены.${NC}"

# --- Генерация файлов переменных ---
PERSONAL_VARS_FILE="personal.auto.tfvars"
VARS_FILE="terraform.tfvars"

echo "${BLUE}Создаем файл персональных переменных Terraform: $PERSONAL_VARS_FILE${NC}"

cat > "$PERSONAL_VARS_FILE" <<EOF
token           = "$TOKEN"
cloud_id        = "$CLOUD_ID"
folder_id       = "$FOLDER_ID"
EOF

# --- Защита файла переменных ---
chmod 600 "$PERSONAL_VARS_FILE"

echo "${GREEN}Файл '$PERSONAL_VARS_FILE' успешно создан и защищен.${NC}"

echo "${BLUE}Создаем файл переменных Terraform: $VARS_FILE${NC}"

cat > "$VARS_FILE" <<EOF
vm_web_count       = 2
vm_web_name_prefix = "web"
vm_web_disk_size   = 10

vm_web_resources = {
  cores         = 2
  memory        = 1
  core_fraction = 5
}

each_vm = [
  {
    vm_name     = "main"
    cpu         = 2
    ram         = 2
    core_fraction = 10
    disk_volume = 20
  },
  {
    vm_name     = "replica"
    cpu         = 2
    ram         = 1
    core_fraction = 5
    disk_volume = 10
  }
]
EOF

echo "${GREEN}Файл '$VARS_FILE' успешно создан.${NC}"



