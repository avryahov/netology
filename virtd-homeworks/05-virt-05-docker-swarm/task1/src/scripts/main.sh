#!/bin/bash
set -euo pipefail

# Проверка наличия файла functions.sh
FUNCTIONS_FILE="functions.sh"
if [[ ! -f "$FUNCTIONS_FILE" ]]; then
    echo "[ERROR] Файл '$FUNCTIONS_FILE' не найден. Убедитесь, что он находится в той же директории, что и скрипт."
    exit 1
fi

# Импортируем функции
source "$FUNCTIONS_FILE"

MODE="${1:-prod}"

if [[ "$MODE" != "prod" && "$MODE" != "pre-prod" ]]; then
  echo "$(colorize "[ERROR] Неверный режим: $MODE. Используйте 'prod' или 'pre-prod'.")"
  exit 1
fi
bash ./dev.sh "$MODE"

if [[ "$MODE" != "pre-prod" ]]; then
  echo "$(colorize "INFO" "[INFO] Запускаем генерацию tf vars...")"
  bash ./generate-tf-vars.sh "$MODE"

  echo "$(colorize "SUCCESS" "[FINISH] Скрипт выполнен успешно в режиме ${MODE^^}")"
fi