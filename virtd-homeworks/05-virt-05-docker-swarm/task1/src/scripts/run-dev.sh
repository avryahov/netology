#!/bin/bash
set -euo pipefail

# Цветовые коды ANSI
RED='\033[0;31m'    # Красный
GREEN='\033[0;32m'  # Зелёный
YELLOW='\033[0;33m' # Жёлтый
BLUE='\033[0;34m'   # Синий
NC='\033[0m'        # Сброс цвета

# Пути и константы
PACKER_DIR="../packer"
VARIABLES_FILE="${PACKER_DIR}/variables.json"
CONFIG_FILE="${PACKER_DIR}/my-ubuntu-docker.json"  # Добавлено определение CONFIG_FILE
DEFAULT_ZONE="ru-central1-a"
SUBNET_NAME="develop"
DISK_TYPE="network-hdd"

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

# Функция для крутящегося индикатора
spinner() {
  local delay=0.1
  local spinstr='/-\|'
  local msg="${1:-}"  # Если параметр не передан, используем пустое сообщение
  while :; do
    local temp=${spinstr#?}
    printf "\r%s [%s]" "$msg" "${spinstr:0:1}"
    spinstr=$temp${spinstr%"$temp"}
    sleep $delay
  done
}

# Функция для прогресс-бара
progress_bar() {
  local duration=$1
  local interval=$((duration / 100))
  for ((i = 0; i <= 100; i++)); do
    printf "\r[%-100s] %d%%" "$(printf "%.s" $(seq 1 $i))" "$i"
    sleep $interval
  done
  printf "\n"
}

# Функция для безопасного завершения spinner
terminate_spinner() {
  if [ -n "$SPINNER_PID" ] && kill -0 "$SPINNER_PID" &>/dev/null; then
    kill "$SPINNER_PID" &>/dev/null
    wait "$SPINNER_PID" &>/dev/null
    SPINNER_PID=""
  fi
}

# Функция для проверки команд и наличия файлов
check() {
  local name=$1
  local cmd=$2
  local padded_name
  padded_name=$(add_padding "🔍 Проверка $name")

  printf "%s ... " "$padded_name"

  if [[ $cmd == command* ]]; then
    if ! command -v "${cmd#command }" &>/dev/null; then
      echo "${RED}✗ НЕ НАЙДЕНО${NC}"
      exit 1
    fi
  else
    if ! eval "$cmd"; then
      echo "${RED}✗ НЕ НАЙДЕНО${NC}"
      exit 1
    fi
  fi

  echo "${GREEN}✓ OK${NC}"
}

# Заголовок
echo "${BLUE}🧪 Режим: ПРЕДПРОД (dev)${NC}"

# Этап 1: Предварительная проверка окружения
echo "${YELLOW}⚙️ Выполняем предварительную проверку окружения:${NC}"
check "Yandex CLI" "command yc"
check "jq (JSON parser)" "command jq"
check "packer" "command packer"
check "SSH ключ" "[[ -f $HOME/.ssh/id_ed25519.pub ]]"
echo "${YELLOW}📂 Структура проекта:${NC}"
tree ../ || true

# Этап 2: Получение и запись конфигурации для Yandex Cloud
echo "${BLUE}⚙️ Получение конфигурации Yandex Cloud:${NC}"
TOKEN=$(yc config get token)
FOLDER_ID=$(yc config get folder-id)
CLOUD_ID=$(yc config get cloud-id)

# Выводим маскированные токены и идентификаторы
echo "🔐 TOKEN:                $(log_masked "$TOKEN")"
echo "🆔 FOLDER_ID:            $(log_masked "$FOLDER_ID")"
echo "☁️ CLOUD_ID:             $(log_masked "$CLOUD_ID")"

# Получение ID сети
NETWORK_ID=$(yc vpc network get default --format=json | jq -r '.id')

# Проверка существования подсети
SUBNET_ID=$(yc vpc subnet get "$SUBNET_NAME" --format=json 2>/dev/null | jq -r '.id' || true)

if [[ -z "$SUBNET_ID" ]]; then
  echo "${YELLOW}🛠 Создание подсети '$SUBNET_NAME'...${NC}"
  SUBNET_ID=$(yc vpc subnet create \
    --name "$SUBNET_NAME" \
    --network-id "$NETWORK_ID" \
    --zone "$DEFAULT_ZONE" \
    --range 192.168.0.0/24 \
    --format=json | jq -r '.id')
  echo "${GREEN}✓ Подсеть '$SUBNET_NAME' успешно создана.${NC}"
else
  echo "${GREEN}✓ Подсеть '$SUBNET_NAME' уже существует.${NC}"
fi

# Запись переменных в файл
cat > "$VARIABLES_FILE" <<EOF
{
  "TOKEN": "$TOKEN",
  "FOLDER_ID": "$FOLDER_ID",
  "DEFAULT_ZONE": "$DEFAULT_ZONE",
  "SUBNET_ID": "$SUBNET_ID",
  "DISK_TYPE": "$DISK_TYPE"
}
EOF

echo "${GREEN}✅ Переменные для Packer записаны в $VARIABLES_FILE${NC}"

# Этап 3: Валидация конфигурации Packer
echo "${BLUE}🔧 Валидируем конфигурацию Packer...${NC}"
if packer validate -var-file="$VARIABLES_FILE" "$CONFIG_FILE"; then
  echo "${GREEN}✓ Конфигурация Packer валидна.${NC}"
else
  echo "${RED}✗ Ошибка валидации конфигурации Packer.${NC}"
  exit 1
fi

# Этап 4: Сборка образа
echo "${YELLOW}🚀 Начинаем сборку образа...${NC}"
spinner "Сборка образа..." &
SPINNER_PID=$!

IMAGE_NAME=$(packer build -var-file="$VARIABLES_FILE" -machine-readable "$CONFIG_FILE" |
  tee packer.log |
  awk -F, '$3 == "artifact" && $5 == "id" { print $6 }')

terminate_spinner

if [[ -z "$IMAGE_NAME" ]]; then
  echo "${RED}✗ Не удалось собрать образ. Проверьте логи (packer.log).${NC}"
  exit 1
fi

echo "${GREEN}✅ Образ собран: ${IMAGE_NAME}${NC}"

# Завершение
echo "${BLUE}⏳ Завершение процесса...${NC}"
progress_bar 5
echo "${GREEN}✅ Все этапы успешно завершены.${NC}"