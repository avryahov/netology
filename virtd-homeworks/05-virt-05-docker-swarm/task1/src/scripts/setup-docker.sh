#!/bin/bash

set -euo pipefail

# Цветной вывод
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "${BLUE}Start building image...${NC}"

# --- Обновление пакетов ---
echo "${BLUE}Updating package lists...${NC}"
sudo apt-get update -y || { echo "${RED}Ошибка: Не удалось обновить пакеты.${NC}"; exit 1; }

# --- Установка базовых пакетов ---
echo "${BLUE}Installing base packages...${NC}"
sudo apt-get -y install bridge-utils bind-utils iptables curl net-tools tcpdump rsync telnet openssh-server || {
  echo "${RED}Ошибка: Не удалось установить базовые пакеты.${NC}"
  exit 1
}

# --- Установка зависимостей Docker ---
echo "${BLUE}Installing Docker dependencies...${NC}"
sudo apt-get install -y ca-certificates curl || {
  echo "${RED}Ошибка: Не удалось установить зависимости Docker.${NC}"
  exit 1
}

# --- Настройка репозитория Docker ---
echo "${BLUE}Setting up Docker repository...${NC}"
sudo install -m 0755 -d /etc/apt/keyrings || {
  echo "${RED}Ошибка: Не удалось создать директорию /etc/apt/keyrings.${NC}"
  exit 1
}
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc || {
  echo "${RED}Ошибка: Не удалось скачать ключ Docker.${NC}"
  exit 1
}
sudo chmod a+r /etc/apt/keyrings/docker.asc || {
  echo "${RED}Ошибка: Не удалось изменить права доступа к ключу Docker.${NC}"
  exit 1
}
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || {
  echo "${RED}Ошибка: Не удалось добавить репозиторий Docker.${NC}"
  exit 1
}

# --- Обновление пакетов после добавления репозитория Docker ---
echo "${BLUE}Updating package lists after adding Docker repository...${NC}"
sudo apt-get update -y || { echo "${RED}Ошибка: Не удалось обновить пакеты после добавления репозитория Docker.${NC}"; exit 1; }

# --- Установка Docker ---
echo "${BLUE}Installing Docker...${NC}"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
  echo "${RED}Ошибка: Не удалось установить Docker.${NC}"
  exit 1
}

# --- Добавление пользователя в группу Docker ---
echo "${BLUE}Adding user to Docker group...${NC}"
sudo usermod -aG docker ubuntu || {
  echo "${RED}Ошибка: Не удалось добавить пользователя в группу Docker.${NC}"
  exit 1
}

# --- Проверка установки Docker ---
echo "${BLUE}Verifying Docker installation...${NC}"
docker --version || {
  echo "${RED}Ошибка: Docker не установлен или не работает.${NC}"
  exit 1
}

# --- Очистка кэша APT ---
echo "${BLUE}Cleaning up APT cache...${NC}"
sudo apt-get clean || { echo "${RED}Ошибка: Не удалось очистить кэш APT.${NC}"; exit 1; }
sudo rm -rf /var/lib/apt/lists/* || { echo "${RED}Ошибка: Не удалось удалить списки пакетов.${NC}"; exit 1; }

echo "${GREEN}Image build completed successfully!${NC}"