#!/bin/bash

set -euo pipefail

echo "Start building image..."

# --- Обновление пакетов ---
echo "Updating package lists..."
sudo apt-get update -y || { echo "Ошибка: Не удалось обновить пакеты."; exit 1; }

# --- Установка базовых пакетов ---
echo "Installing base packages..."
sudo apt-get -y install bridge-utils dnsutils iptables curl net-tools tcpdump rsync telnet openssh-server || {
  echo "Ошибка: Не удалось установить базовые пакеты."
  exit 1
}

# --- Установка зависимостей Docker ---
echo "Installing Docker dependencies..."
sudo apt-get install -y ca-certificates curl || {
  echo "Ошибка: Не удалось установить зависимости Docker."
  exit 1
}

# --- Настройка репозитория Docker ---
echo "Setting up Docker repository..."
sudo install -m 0755 -d /etc/apt/keyrings || {
  echo "Ошибка: Не удалось создать директорию /etc/apt/keyrings."
  exit 1
}
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc || {
  echo "Ошибка: Не удалось скачать ключ Docker."
  exit 1
}
sudo chmod a+r /etc/apt/keyrings/docker.asc || {
  echo "Ошибка: Не удалось изменить права доступа к ключу Docker."
  exit 1
}
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || {
    echo "Ошибка: Не удалось добавить репозиторий Docker."
    exit 1
}

# --- Обновление пакетов после добавления репозитория Docker ---
echo "Updating package lists after adding Docker repository..."
sudo apt-get update -y || { echo "Ошибка: Не удалось обновить пакеты после добавления репозитория Docker."; exit 1; }

# --- Установка Docker ---
echo "Installing Docker..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
  echo "Ошибка: Не удалось установить Docker."
  exit 1
}

# --- Добавление пользователя в группу Docker ---
echo "Adding user to Docker group..."
sudo usermod -aG docker ubuntu || {
  echo "Ошибка: Не удалось добавить пользователя в группу Docker."
  exit 1
}

# --- Проверка установки Docker ---
echo "Verifying Docker installation..."
docker --version || {
  echo "Ошибка: Docker не установлен или не работает."
  exit 1
}

# --- Очистка кэша APT ---
echo "Cleaning up APT cache..."
sudo apt-get clean || { echo "Ошибка: Не удалось очистить кэш APT."; exit 1; }
sudo rm -rf /var/lib/apt/lists/* || { echo "Ошибка: Не удалось удалить списки пакетов."; exit 1; }

echo "Image build completed successfully!"