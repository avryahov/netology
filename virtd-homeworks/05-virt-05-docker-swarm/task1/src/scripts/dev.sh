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

# Этап 3: Обработка подсети
echo "$(colorize "STEP" "[STEP 3] Обработка подсети...")"
EXISTING_SUBNETS=$(yc vpc subnet list --format=json | jq -r '.[] | "\(.name) \(.v4_cidr_blocks[0])"')

if [[ "$MODE" == "prod" ]]; then
    # В prod-режиме используем существующую подсеть, если она есть
    if echo "$EXISTING_SUBNETS" | grep -q "^$SUBNET_NAME "; then
        NEW_SUBNET_NAME="$SUBNET_NAME"
        NEW_SUBNET_IP_RANGE=$(echo "$EXISTING_SUBNETS" | grep "^$SUBNET_NAME " | awk '{print $2}')
        NEW_SUBNET_ID=$(yc vpc subnet get "$NEW_SUBNET_NAME" --format=json | jq -r '.id')
        echo "$(colorize "INFO" "[INFO] Подсеть '${NEW_SUBNET_NAME}' уже существует. Будет использована существующая подсеть.")"
    else
        NEW_SUBNET_NAME="$SUBNET_NAME"
        NEW_SUBNET_IP_RANGE=$(generate_unique_ip_range "$EXISTING_SUBNETS")
        echo "$(colorize "INFO" "[INFO] Подсеть '${NEW_SUBNET_NAME}' не найдена. Создаем новую подсеть с IP-диапазоном '${NEW_SUBNET_IP_RANGE}'.")"
        NEW_SUBNET_ID=$(yc vpc subnet create \
            --name "$NEW_SUBNET_NAME" \
            --network-id "$NETWORK_ID" \
            --zone "$DEFAULT_ZONE" \
            --range "$NEW_SUBNET_IP_RANGE" \
            --format=json | jq -r '.id')
        echo "$(colorize "SUCCESS" "[SUCCESS] Подсеть '${NEW_SUBNET_NAME}' успешно создана.")"
    fi
else
    # В pre-prod режиме всегда создаем новую подсеть
    SUBNET_COUNT=$(count_subnets_with_prefix "$SUBNET_NAME" "$EXISTING_SUBNETS")
    NEW_SUBNET_NAME="${SUBNET_NAME}_$((SUBNET_COUNT + 1))"
    NEW_SUBNET_IP_RANGE=$(generate_unique_ip_range "$EXISTING_SUBNETS")
    echo "$(colorize "INFO" "[INFO] Генерируем новое имя подсети: '${NEW_SUBNET_NAME}' с IP-диапазоном '${NEW_SUBNET_IP_RANGE}'.")"
    NEW_SUBNET_ID=$(yc vpc subnet create \
        --name "$NEW_SUBNET_NAME" \
        --network-id "$NETWORK_ID" \
        --zone "$DEFAULT_ZONE" \
        --range "$NEW_SUBNET_IP_RANGE" \
        --format=json | jq -r '.id')
    echo "$(colorize "SUCCESS" "[SUCCESS] Подсеть '${NEW_SUBNET_NAME}' успешно создана.")"
fi

# Этап 4: Обработка образа
IMAGE_NAME="ubuntu-2004-lts-docker"
EXISTING_IMAGES=$(yc compute image list --format=json | jq -r '.[].name')

if [[ "$MODE" == "prod" ]]; then
    # В prod-режиме используем существующий образ, если он есть
    if echo "$EXISTING_IMAGES" | grep -q "^$IMAGE_NAME\$"; then
        NEW_IMAGE_NAME="$IMAGE_NAME"
        IMAGE_ID=$(yc compute image list --format=json | jq -r --arg name "$NEW_IMAGE_NAME" '.[] | select(.name == $name) | .id')
        echo "$(colorize "INFO" "[INFO] Образ '${NEW_IMAGE_NAME}' уже существует. Будет использован существующий образ.")"
    else
        NEW_IMAGE_NAME="$IMAGE_NAME"
        echo "$(colorize "INFO" "[INFO] Образ '${NEW_IMAGE_NAME}' не найден. Будет создан новый образ.")"
        IMAGE_ID=""
    fi
else
    # В pre-prod режиме всегда создаем новый образ
    IMAGE_COUNT=$(count_images_with_prefix "$IMAGE_NAME" "$EXISTING_IMAGES")
    NEW_IMAGE_NAME="${IMAGE_NAME}_$((IMAGE_COUNT + 1))"
    echo "$(colorize "INFO" "[INFO] Генерируем новое имя образа: '${NEW_IMAGE_NAME}'.")"
    IMAGE_ID=""
fi

# Этап 5: Запись переменных в файл
cat > "$VARIABLES_FILE" <<EOF
{
  "TOKEN": "$TOKEN",
  "FOLDER_ID": "$FOLDER_ID",
  "DEFAULT_ZONE": "$DEFAULT_ZONE",
  "SUBNET_ID": "$NEW_SUBNET_ID",
  "DISK_TYPE": "$DISK_TYPE",
  "IMAGE_NAME": "$NEW_IMAGE_NAME"
}
EOF

echo "$(colorize "SUCCESS" "[SUCCESS] Переменные для Packer записаны в $VARIABLES_FILE")"

# Этап 6: Валидация конфигурации Packer
echo "$(colorize "STEP" "[STEP 6] Проверяем конфигурацию Packer...")"
if packer validate -var-file="$VARIABLES_FILE" "$CONFIG_FILE"; then
    echo "$(colorize "SUCCESS" "[SUCCESS] Конфигурация Packer валидна.")"
else
    echo "$(colorize "ERROR" "[ERROR] Ошибка валидации конфигурации Packer.")"
    exit 1
fi

# Этап 7: Сборка образа
if [[ -z "$IMAGE_ID" ]]; then
    echo "$(colorize "INFO" "[INFO] Начинаем сборку образа...")"

    packer build -var-file="$VARIABLES_FILE" -machine-readable "$CONFIG_FILE" > packer.log 2>&1 &
    BUILD_PID=$!

    # Отладочный вывод
    echo "$(colorize "DEBUG" "[DEBUG] Запущен процесс packer build с PID: $BUILD_PID")"

    spinner_with_timer $BUILD_PID
    wait $BUILD_PID

    if [[ $? -ne 0 ]]; then
        echo "$(colorize "ERROR" "[ERROR] Процесс packer build завершился с ошибкой. Проверьте логи (packer.log).")"
        exit 1
    fi

    IMAGE_ID=$(yc compute image list --format=json | jq -r --arg name "$NEW_IMAGE_NAME" '.[] | select(.name == $name) | .id')

    if [[ -z "$IMAGE_ID" ]]; then
        echo "$(colorize "ERROR" "[ERROR] Не удалось собрать образ. Проверьте логи (packer.log).")"
        exit 1
    fi

    echo "$(colorize "SUCCESS" "[SUCCESS] Образ собран: ${IMAGE_ID}")"
else
    echo "$(colorize "INFO" "[INFO] Используется существующий образ: ${IMAGE_ID}")"
fi

# Удаление ресурсов только в pre-prod
if [[ "$MODE" == "pre-prod" ]]; then
    # Этап 8: Удаление нового образа
    EXISTING_IMAGE=$(yc compute image list --format=json | jq -r --arg id "$IMAGE_ID" '.[] | select(.id == $id) | .name')
    if [[ -z "$EXISTING_IMAGE" ]]; then
        echo "$(colorize "WARN" "[WARN] Образ с ID '$IMAGE_ID' не найден. Пропускаем удаление.")"
    else
        yc compute image delete --id "$IMAGE_ID"
        echo "$(colorize "SUCCESS" "[SUCCESS] Новый образ удален.")"
    fi

    # Этап 9: Удаление новой подсети
    EXISTING_SUBNET=$(yc vpc subnet get "$NEW_SUBNET_ID" --format=json 2>/dev/null)
    if [[ -z "$EXISTING_SUBNET" ]]; then
        echo "$(colorize "WARN" "[WARN] Подсеть с ID '$NEW_SUBNET_ID' не найдена. Пропускаем удаление.")"
    else
        yc vpc subnet delete --id "$NEW_SUBNET_ID"
        echo "$(colorize "SUCCESS" "[SUCCESS] Новая подсеть удалена.")"
    fi
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
    exit 1
fi