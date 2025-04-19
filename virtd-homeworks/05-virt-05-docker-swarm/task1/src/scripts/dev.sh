#!/bin/bash
set -euo pipefail

MODE="${1:-pre-prod}"

# Проверка наличия файла functions.sh
FUNCTIONS_FILE="functions.sh"
if [[ ! -f "$FUNCTIONS_FILE" ]]; then
    echo "[ERROR] Файл '$FUNCTIONS_FILE' не найден. Убедитесь, что он находится в той же директории, что и скрипт."
    exit 1
fi

# Импортируем функции
source "$FUNCTIONS_FILE"

# Пути и константы
PACKER_DIR="../packer"
VARIABLES_FILE="${PACKER_DIR}/variables.json"
CONFIG_FILE="${PACKER_DIR}/my-ubuntu-docker.json"
DEFAULT_ZONE="ru-central1-a"
SUBNET_NAME="develop"
DISK_TYPE="network-hdd"

# Заголовок
echo "$(colorize "STEP" "[START] Режим: ${MODE^^}")"

# Этап 1: Предварительная проверка окружения
echo "$(colorize "STEP" "[STEP 1] Выполняем предварительную проверку окружения:")"
check "Yandex CLI" "command yc"
check "jq (JSON parser)" "command jq"
check "packer" "command packer"
check "SSH ключ" "[[ -f $HOME/.ssh/id_ed25519.pub ]]"

echo "$(colorize "INFO" "[INFO] Структура проекта:")"
tree ../ || true

# Этап 2: Получение и запись конфигурации для Yandex Cloud
echo "$(colorize "STEP" "[STEP 2] Получение конфигурации Yandex Cloud:")"
TOKEN=$(yc config get token)
FOLDER_ID=$(yc config get folder-id)
CLOUD_ID=$(yc config get cloud-id)
NETWORK_ID=$(yc vpc network get default --format=json | jq -r '.id')

# Выводим маскированные токены и идентификаторы
echo "$(colorize "INFO" "TOKEN:                $(log_masked "$TOKEN")")"
echo "$(colorize "INFO" "FOLDER_ID:            $(log_masked "$FOLDER_ID")")"
echo "$(colorize "INFO" "CLOUD_ID:             $(log_masked "$CLOUD_ID")")"
echo "$(colorize "INFO" "NETWORK_ID:           $(log_masked "$NETWORK_ID")")"

# Этап 3: Проверка наличия подсети и генерация нового имени
echo "$(colorize "STEP" "[STEP 3] Обработка подсети...")"
EXISTING_SUBNETS=$(yc vpc subnet list --format=json | jq -r '.[] | "\(.name) \(.v4_cidr_blocks[0])"')

if echo "$EXISTING_SUBNETS" | grep -q "^$SUBNET_NAME "; then
    echo "$(colorize "WARN" "[WARN] Подсеть с именем '${SUBNET_NAME}' уже существует.")"
    SUBNET_COUNT=$(count_subnets_with_prefix "$SUBNET_NAME" "$EXISTING_SUBNETS")
    NEW_SUBNET_NAME="${SUBNET_NAME}_$((SUBNET_COUNT + 1))"
    echo "$(colorize "INFO" "[INFO] Генерируем новое имя подсети: '${NEW_SUBNET_NAME}'.")"
else
    NEW_SUBNET_NAME="$SUBNET_NAME"
    echo "$(colorize "INFO" "[INFO] Подсеть с именем '${SUBNET_NAME}' не найдена. Будет использовано имя '${NEW_SUBNET_NAME}'.")"
fi

NEW_SUBNET_IP_RANGE=$(generate_unique_ip_range "$EXISTING_SUBNETS")
echo "$(colorize "INFO" "[INFO] Генерируем уникальный IP-диапазон: '${NEW_SUBNET_IP_RANGE}'.")"

if echo "$EXISTING_SUBNETS" | grep -q "^$NEW_SUBNET_NAME "; then
    echo "$(colorize "ERROR" "[ERROR] Имя '${NEW_SUBNET_NAME}' уже занято. Возможна коллизия.")"
    exit 1
else
    echo "$(colorize "INFO" "[INFO] Имя '${NEW_SUBNET_NAME}' свободно для использования.")"
fi

echo "$(colorize "INFO" "[INFO] Создание подсети '${NEW_SUBNET_NAME}' с IP-диапазоном '${NEW_SUBNET_IP_RANGE}'...")"
NEW_SUBNET_ID=$(yc vpc subnet create \
    --name "$NEW_SUBNET_NAME" \
    --network-id "$NETWORK_ID" \
    --zone "$DEFAULT_ZONE" \
    --range "$NEW_SUBNET_IP_RANGE" \
    --format=json | jq -r '.id')
echo "$(colorize "SUCCESS" "[INFO] Подсеть '${NEW_SUBNET_NAME}' успешно создана.")"

# Этап 4: Проверка наличия образа и инкрементация имени
IMAGE_NAME="ubuntu-2004-lts-docker"
EXISTING_IMAGES=$(yc compute image list --format=json | jq -r '.[].name')

if echo "$EXISTING_IMAGES" | grep -q "^$IMAGE_NAME\$"; then
    echo "$(colorize "WARN" "[WARN] Образ с именем '${IMAGE_NAME}' уже существует.")"
    IMAGE_COUNT=$(count_images_with_prefix "$IMAGE_NAME" "$EXISTING_IMAGES")
    NEW_IMAGE_NAME="${IMAGE_NAME}_$((IMAGE_COUNT + 1))"
    echo "$(colorize "INFO" "[INFO] Генерируем новое имя образа: '${NEW_IMAGE_NAME}'.")"
else
    NEW_IMAGE_NAME="$IMAGE_NAME"
    echo "$(colorize "INFO" "[INFO] Образ с именем '${IMAGE_NAME}' не найден. Будет использовано имя '${NEW_IMAGE_NAME}'.")"
fi

if echo "$EXISTING_IMAGES" | grep -q "^$NEW_IMAGE_NAME\$"; then
    echo "$(colorize "ERROR" "[ERROR] Имя '${NEW_IMAGE_NAME}' уже занято. Возможна коллизия.")"
    exit 1
else
    echo "$(colorize "INFO" "[INFO] Имя '${NEW_IMAGE_NAME}' свободно для использования.")"
fi

# Этап 5: Запись переменных в файл
cat > "$VARIABLES_FILE" <<EOF
{
  "TOKEN": "$TOKEN",
  "FOLDER_ID": "$FOLDER_ID",
  "DEFAULT_ZONE": "$DEFAULT_ZONE",
  "SUBNET_ID": "$NEW_SUBNET_ID",
  "DISK_TYPE": "$DISK_TYPE",
  "IMAGE_NAME": "$NEW_IMAGE_NAME",
  "IMAGE_FAMILY": "ubuntu-2004-lts"
}
EOF

echo "$(colorize "SUCCESS" "[INFO] Переменные для Packer записаны в $VARIABLES_FILE")"

# Этап 6: Валидация конфигурации Packer
echo "$(colorize "STEP" "[STEP 6] Проверяем конфигурацию Packer...")"
if packer validate -var-file="$VARIABLES_FILE" "$CONFIG_FILE"; then
    echo "$(colorize "SUCCESS" "[INFO] Конфигурация Packer валидна.")"
else
    echo "$(colorize "ERROR" "[ERROR] Ошибка валидации конфигурации Packer.")"
    exit 1
fi

# Этап 7: Сборка образа
echo "$(colorize "INFO" "[INFO] Начинаем сборку образа...")"

packer build -var-file="$VARIABLES_FILE" -machine-readable "$CONFIG_FILE" > packer.log 2>&1 &
BUILD_PID=$!
spinner_with_timer $BUILD_PID
wait $BUILD_PID

IMAGE_ID=$(yc compute image list --format=json | jq -r --arg name "$NEW_IMAGE_NAME" '.[] | select(.name == $name) | .id')

if [[ -z "$IMAGE_ID" ]]; then
    echo "$(colorize "ERROR" "[ERROR] Не удалось собрать образ. Проверьте логи (packer.log).")"
    exit 1
fi

echo "$(colorize "SUCCESS" "[INFO] Образ собран: ${IMAGE_ID}")"

# Удаление ресурсов только в pre-prod
if [[ "$MODE" == "pre-prod" ]]; then
# Этап 8: Удаление нового образа
    echo "$(colorize "INFO" "[INFO] Удаляем новый образ (${NEW_IMAGE_NAME})...")"
    yc compute image delete --id "$IMAGE_ID"
    echo "$(colorize "SUCCESS" "[INFO] Новый образ удален.")"

    # Этап 9: Удаление новой подсети
    echo "$(colorize "INFO" "[INFO] Удаляем новую подсеть (${NEW_SUBNET_NAME})...")"
    yc vpc subnet delete --id "$NEW_SUBNET_ID"
    echo "$(colorize "SUCCESS" "[INFO] Новая подсеть удалена.")"
else
    # Обновляем variables.json с новым полем IMAGE_ID
    jq --arg id "$IMAGE_ID" '. + {IMAGE_ID: $id}' "$VARIABLES_FILE" > "${VARIABLES_FILE}.tmp" && mv "${VARIABLES_FILE}.tmp" "$VARIABLES_FILE"

    echo "$(colorize "INFO" "[INFO] Прод-режим: Образ и подсеть НЕ удаляются.")"
fi

# Завершение
if [ $? -eq 0 ]; then
    echo "$(colorize "SUCCESS" "[DONE] Подготовка завершена. Mode: $MODE")"
else
    echo "$(colorize "ERROR" "[ERROR] Сборка завершена с ошибкой.")"
fi
