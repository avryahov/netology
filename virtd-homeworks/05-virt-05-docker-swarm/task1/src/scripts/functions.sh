#!/bin/bash

# Цветовые коды ANSI
declare -A COLORS=(
    ["INFO"]=""
    ["STEP"]="\033[0;36m"  # Голубой
    ["SUCCESS"]="\033[0;32m"  # Зелёный
    ["WARN"]="\033[0;33m"  # Жёлтый
    ["ERROR"]="\033[0;31m"  # Красный
    ["NC"]="\033[0m"        # Сброс цвета
)

# Универсальная функция для покраски текста
colorize() {
    local tag=$1
    local message=$2
    local color=${COLORS[$tag]:-""}  # Если тег не найден, цвет не применяется
    echo -e "${color}${message}${COLORS["NC"]}"
}

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
            echo "$(colorize "ERROR" "FAILED")"
            exit 1
        fi
    else
        if ! eval "$cmd"; then
            echo "$(colorize "ERROR" "FAILED")"
            exit 1
        fi
    fi

    echo "$(colorize "SUCCESS" "OK")"
}

# Функция для подсчета количества подсетей с заданным префиксом
count_subnets_with_prefix() {
  local prefix=$1
  local existing_subnets=$2
  echo "$existing_subnets" | grep -E "^${prefix}(_[0-9]+)? " | wc -l
}

# Функция для генерации уникального IP-диапазона
generate_unique_ip_range() {
    local base="192.168"
    local index=1
    local existing_subnets=$1

    # Проверяем все существующие диапазоны
    while true; do
        local range="${base}.${index}.0/24"
        if ! echo "$existing_subnets" | grep -q "$range"; then
            echo "$range"
            return
        fi
        index=$((index + 1))
    done
}

# Функция для подсчета количества образов с заданным префиксом
count_images_with_prefix() {
    local prefix=$1
    local existing_images=$2
    echo "$existing_images" | grep -E "^${prefix}(_[0-9]+)?$" | wc -l
}