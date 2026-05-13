#!/bin/bash

# Путь к docker-compose.yml
COMPOSE_FILE="/home/ubuntu/teamcity/docker-compose.yml"

# Проверяем, существует ли файл
if [ ! -f "$COMPOSE_FILE" ]; then
  echo "Ошибка: Файл $COMPOSE_FILE не найден."
  exit 1
fi

# Переходим в директорию
cd "$(dirname "$COMPOSE_FILE")"

# Запускаем docker compose
sudo docker compose up -d

echo "TeamCity Server и Agent запущены."