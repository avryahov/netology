#!/bin/bash
set -euo pipefail

# Цветовые коды ANSI
GREEN='\033[0;32m'    # Зелёный
YELLOW='\033[0;33m'   # Жёлтый
RED='\033[0;31m'      # Красный
STEP_COLOR='\033[0;36m'  # Голубой для этапов
NC='\033[0m'          # Сброс цвета

# Пути и константы
PACKER_DIR="../packer"
VARIABLES_FILE="${PACKER_DIR}/variables.json"
CONFIG_FILE="${PACKER_DIR}/my-ubuntu-docker.json"  # Добавлено определение CONFIG_FILE
DEFAULT_ZONE="ru-central1-a"
SUBNET_NAME="develop"
DISK_TYPE="network-hdd"

# Простой спиннер с отсчетом времени
spinner_with_timer() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'
  local start_time=$(date +%s)
  local elapsed=0

  while ps -p $pid > /dev/null; do
    local current_char=${spinstr:0:1}
    printf "%c %ds \r" "$current_char" "$elapsed"
    spinstr=${spinstr:1}${spinstr:0:1}
    sleep $delay
    elapsed=$(( $(date +%s) - start_time ))
  done

  # После завершения работы ждем короткую задержку (например, 0.2 секунды)
  sleep 0.2

  # После завершения работы очищаем последнюю строку спиннера
  printf "\r\x1b[K"

  # Выводим финальное сообщение
  printf "done (%ds)\n" "$elapsed"
}

# Функция для маскирования значений (выводим только последние 4 символа)
log_masked() {
  local val=$1
  echo "********${val: -4}"
}

# Функция для расчета необходимого количества пробелов
add_padding() {
  local text="$1"
  local target_length=40  # Фиксированная ширина столбца
  local padding=""
  local current_length=${#text}

  if (( current_length < target_length )); then
    padding=$(printf "%*s" $((target_length - current_length)) "")
  fi

  echo "$text$padding"
}

# Функция для проверки команд и наличия файлов
check() {
  local name=$1
  local cmd=$2
  local padded_name
  padded_name=$(add_padding "[INFO] Проверка $name")

  printf "%s ... " "$padded_name"

  if [[ $cmd == command* ]]; then
    if ! command -v "${cmd#command }" &>/dev/null; then
      echo "${RED}FAILED${NC}"
      exit 1
    fi
  else
    if ! eval "$cmd"; then
      echo "${RED}FAILED${NC}"
      exit 1
    fi
  fi

  echo "${GREEN}OK${NC}"
}

# Заголовок
echo "${STEP_COLOR}[START] Режим: ПРЕДПРОД (dev)${NC}"

# Этап 1: Предварительная проверка окружения
echo "${STEP_COLOR}[STEP 1] Выполняем предварительную проверку окружения:${NC}"
check "Yandex CLI" "command yc"
check "jq (JSON parser)" "command jq"
check "packer" "command packer"
check "SSH ключ" "[[ -f $HOME/.ssh/id_ed25519.pub ]]"
echo "[INFO] Структура проекта:"
tree ../ || true

# Этап 2: Получение и запись конфигурации для Yandex Cloud
echo "${STEP_COLOR}[STEP 2] Получение конфигурации Yandex Cloud:${NC}"
TOKEN=$(yc config get token)
FOLDER_ID=$(yc config get folder-id)
CLOUD_ID=$(yc config get cloud-id)

# Выводим маскированные токены и идентификаторы
echo "TOKEN:                $(log_masked "$TOKEN")"
echo "FOLDER_ID:            $(log_masked "$FOLDER_ID")"
echo "CLOUD_ID:             $(log_masked "$CLOUD_ID")"

# Получение ID сети
NETWORK_ID=$(yc vpc network get default --format=json | jq -r '.id')

# Этап 3: Проверка наличия подсети и генерация нового имени
EXISTING_SUBNETS=$(yc vpc subnet list --format=json | jq -r '.[] | "\(.name) \(.v4_cidr_blocks[0])"')

echo "[INFO] Проверяем наличие подсети с именем '${SUBNET_NAME}'..."

# Функция для подсчета количества подсетей с заданным префиксом
count_subnets_with_prefix() {
  local prefix=$1
  echo "$EXISTING_SUBNETS" | grep -E "^${prefix}(_[0-9]+)? " | wc -l
}

# Функция для генерации уникального IP-диапазона
generate_unique_ip_range() {
  local base="192.168"
  local index=1

  # Проверяем все существующие диапазоны
  while true; do
    local range="${base}.${index}.0/24"
    if ! echo "$EXISTING_SUBNETS" | grep -q "$range"; then
      echo "$range"
      return
    fi
    index=$((index + 1))
  done
}

# Проверяем, существует ли подсеть с базовым именем SUBNET_NAME
if echo "$EXISTING_SUBNETS" | grep -q "^$SUBNET_NAME "; then
  echo "${YELLOW}[WARN] Подсеть с именем '${SUBNET_NAME}' уже существует.${NC}"

  # Считаем количество подсетей с префиксом SUBNET_NAME
  SUBNET_COUNT=$(count_subnets_with_prefix "$SUBNET_NAME")
  NEW_SUBNET_NAME="${SUBNET_NAME}_$((SUBNET_COUNT + 1))"

  echo "[INFO] Генерируем новое имя подсети: '${NEW_SUBNET_NAME}'."
else
  NEW_SUBNET_NAME="$SUBNET_NAME"
  echo "${GREEN}[INFO] Подсеть с именем '${SUBNET_NAME}' не найдена. Будет использовано имя '${NEW_SUBNET_NAME}'.${NC}"
fi

# Генерируем уникальный IP-диапазон
NEW_SUBNET_IP_RANGE=$(generate_unique_ip_range)
echo "[INFO] Генерируем уникальный IP-диапазон: '${NEW_SUBNET_IP_RANGE}'."

# Проверяем, свободно ли новое имя
echo "[INFO] Проверяем, свободно ли имя '${NEW_SUBNET_NAME}'..."
if echo "$EXISTING_SUBNETS" | grep -q "^$NEW_SUBNET_NAME "; then
  echo "${RED}[ERROR] Имя '${NEW_SUBNET_NAME}' уже занято. Возможна коллизия.${NC}"
  exit 1
else
  echo "${GREEN}[INFO] Имя '${NEW_SUBNET_NAME}' свободно для использования.${NC}"
fi

# Создание новой подсети
echo "[INFO] Создание подсети '${NEW_SUBNET_NAME}' с IP-диапазоном '${NEW_SUBNET_IP_RANGE}'..."
NEW_SUBNET_ID=$(yc vpc subnet create \
  --name "$NEW_SUBNET_NAME" \
  --network-id "$NETWORK_ID" \
  --zone "$DEFAULT_ZONE" \
  --range "$NEW_SUBNET_IP_RANGE" \
  --format=json | jq -r '.id')
echo "${GREEN}[INFO] Подсеть '${NEW_SUBNET_NAME}' успешно создана.${NC}"

# Этап 4: Проверка наличия образа и инкрементация имени
IMAGE_NAME="ubuntu-2004-lts-docker"
EXISTING_IMAGES=$(yc compute image list --format=json | jq -r '.[].name')

echo "[INFO] Проверяем наличие образа с именем '${IMAGE_NAME}'..."

# Функция для подсчета количества образов с заданным префиксом
count_images_with_prefix() {
  local prefix=$1
  echo "$EXISTING_IMAGES" | grep -E "^${prefix}(_[0-9]+)?$" | wc -l
}

# Проверяем, существует ли образ с базовым именем IMAGE_NAME
if echo "$EXISTING_IMAGES" | grep -q "^$IMAGE_NAME\$"; then
  echo "${YELLOW}[WARN] Образ с именем '${IMAGE_NAME}' уже существует.${NC}"

  # Считаем количество образов с префиксом IMAGE_NAME
  IMAGE_COUNT=$(count_images_with_prefix "$IMAGE_NAME")
  NEW_IMAGE_NAME="${IMAGE_NAME}_$((IMAGE_COUNT + 1))"

  echo "[INFO] Генерируем новое имя образа: '${NEW_IMAGE_NAME}'."
else
  NEW_IMAGE_NAME="$IMAGE_NAME"
  echo "${GREEN}[INFO] Образ с именем '${IMAGE_NAME}' не найден. Будет использовано имя '${NEW_IMAGE_NAME}'.${NC}"
fi

# Проверяем, свободно ли новое имя
echo "[INFO] Проверяем, свободно ли имя '${NEW_IMAGE_NAME}'..."
if echo "$EXISTING_IMAGES" | grep -q "^$NEW_IMAGE_NAME\$"; then
  echo "${RED}[ERROR] Имя '${NEW_IMAGE_NAME}' уже занято. Возможна коллизия.${NC}"
  exit 1
else
  echo "${GREEN}[INFO] Имя '${NEW_IMAGE_NAME}' свободно для использования.${NC}"
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

echo "${GREEN}[INFO] Переменные для Packer записаны в $VARIABLES_FILE${NC}"

# Этап 6: Валидация конфигурации Packer
echo "${STEP_COLOR}[STEP 6] Проверяем конфигурацию Packer...${NC}"
if packer validate -var-file="$VARIABLES_FILE" "$CONFIG_FILE"; then
  echo "${GREEN}[INFO] Конфигурация Packer валидна.${NC}"
else
  echo "${RED}[ERROR] Ошибка валидации конфигурации Packer.${NC}"
  exit 1
fi

# Этап 7: Сборка образа
echo "[INFO] Начинаем сборку образа..."  # Перевод строки после сообщения

packer build -var-file="$VARIABLES_FILE" -machine-readable "$CONFIG_FILE" > packer.log 2>&1 &
BUILD_PID=$!
spinner_with_timer $BUILD_PID
wait $BUILD_PID

# Получаем ID нового образа
IMAGE_ID=$(yc compute image list --format=json | jq -r --arg name "$NEW_IMAGE_NAME" '.[] | select(.name == $name) | .id')

if [[ -z "$IMAGE_ID" ]]; then
  echo "${RED}[ERROR] Не удалось собрать образ. Проверьте логи (packer.log).${NC}"
  exit 1
fi

echo "${GREEN}[INFO] Образ собран: ${IMAGE_ID}${NC}"

# Этап 8: Удаление нового образа
echo "[INFO] Удаляем новый образ (${NEW_IMAGE_NAME})..."
yc compute image delete --id "$IMAGE_ID"
echo "${GREEN}[INFO] Новый образ удален.${NC}"

# Этап 9: Удаление новой подсети
echo "[INFO] Удаляем новую подсеть (${NEW_SUBNET_NAME})..."
yc vpc subnet delete --id "$NEW_SUBNET_ID"
echo "${GREEN}[INFO] Новая подсеть удалена.${NC}"

# Завершение
if [ $? -eq 0 ]; then
  echo "${GREEN}[SUCCESS] Все этапы успешно завершены.${NC}"
else
  echo "${RED}[ERROR] Сборка завершена с ошибкой.${NC}"
fi