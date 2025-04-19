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

# Проверка допустимости режима
if [[ "$MODE" != "prod" && "$MODE" != "pre-prod" ]]; then
  echo "$(colorize "[ERROR] Неверный режим: $MODE. Используйте 'prod' или 'pre-prod'.")"
  exit 1
fi

# Запуск dev.sh
bash ./dev.sh "$MODE"

# Генерация tf vars только для режима prod
if [[ "$MODE" != "pre-prod" ]]; then
  echo "$(colorize "INFO" "[INFO] Запускаем генерацию tf vars...")"
  bash ./generate-tf-vars.sh "$MODE"

  # Переход в директорию terraform
  TERRAFORM_DIR="../terraform"
  if [[ ! -d "$TERRAFORM_DIR" ]]; then
      echo "$(colorize "[ERROR] Директория '$TERRAFORM_DIR' не найдена. Убедитесь, что структура проекта корректна.")"
      exit 1
  fi

  cd "$TERRAFORM_DIR"

  # Выполнение Terraform init
  echo "$(colorize "INFO" "[INFO] Выполняем terraform init...")"
  terraform init | tee -a terraform.log

  # Выполнение Terraform plan
  echo "$(colorize "INFO" "[INFO] Выполняем terraform plan...")"
  terraform plan -var-file="personal.auto.tfvars" | tee -a terraform.log

  # Выполнение Terraform apply
  echo "$(colorize "INFO" "[INFO] Выполняем terraform apply...")"
  terraform apply -auto-approve -var-file="personal.auto.tfvars" | tee -a terraform.log

  # Вывод успешного завершения
  echo "$(colorize "SUCCESS" "[FINISH] Скрипт выполнен успешно в режиме ${MODE^^}. ВМ настроены с помощью Terraform и Ansible.")"
else
  echo "$(colorize "SUCCESS" "[FINISH] Скрипт выполнен успешно в режиме ${MODE^^}. Terraform и Ansible пропущены.")"
fi