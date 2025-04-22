#!/bin/bash

set -euo pipefail

# --- Начало сборки образа ---
echo "Начинаем сборку образа..."

# --- Обновление списка пакетов ---
echo "Обновляем список пакетов..."
sudo apt-get update -y || { echo "Ошибка: Не удалось обновить список пакетов."; exit 1; }

# --- Установка базовых пакетов ---
echo "Устанавливаем базовые пакеты..."
sudo apt-get -y install bridge-utils dnsutils iptables curl net-tools tcpdump rsync telnet openssh-server || {
  echo "Ошибка: Не удалось установить базовые пакеты."
  exit 1
}

# --- Установка Python ---
echo "Устанавливаем Python..."
sudo apt-get install -y python3 python3-pip python3-venv || {
  echo "Ошибка: Не удалось установить Python."
  exit 1
}

# --- Установка библиотеки Docker для Python ---
echo "Устанавливаем библиотеку Docker для Python..."
python3.8 -m pip install docker || {
  echo "Ошибка: Не удалось установить библиотеку Docker для Python."
  exit 1
}

# --- Установка зависимостей Docker ---
echo "Устанавливаем зависимости Docker..."
sudo apt-get install -y ca-certificates curl || {
  echo "Ошибка: Не удалось установить зависимости Docker."
  exit 1
}

# --- Настройка репозитория Docker ---
echo "Настройка репозитория Docker..."
sudo install -m 0755 -d /etc/apt/keyrings || {
  echo "Ошибка: Не удалось создать директорию /etc/apt/keyrings."
  exit 1
}
sudo curl --retry 5 --retry-delay 5 -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc || {
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

# --- Обновление списка пакетов после добавления репозитория Docker ---
echo "Обновляем список пакетов после добавления репозитория Docker..."
sudo apt-get update -y || { echo "Ошибка: Не удалось обновить список пакетов после добавления репозитория Docker."; exit 1; }

# --- Установка Docker ---
echo "Устанавливаем Docker..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
  echo "Ошибка: Не удалось установить Docker."
  exit 1
}

# --- Добавление пользователя в группу Docker ---
echo "Добавляем пользователя в группу Docker..."
sudo usermod -aG docker ubuntu || {
  echo "Ошибка: Не удалось добавить пользователя в группу Docker."
  exit 1
}

# --- Применение изменений группы Docker без перезагрузки ---
echo "Применяем изменения группы Docker..."
newgrp docker || {
  echo "Ошибка: Не удалось применить изменения группы Docker."
  exit 1
}

# --- Проверка состояния службы Docker ---
echo "Проверяем состояние службы Docker..."
sudo systemctl is-active --quiet docker || {
  echo "Ошибка: Служба Docker не запущена."
  exit 1
}

# --- Проверка установки Docker ---
echo "Проверяем установку Docker..."
docker --version || {
  echo "Ошибка: Docker не установлен или не работает."
  exit 1
}

# --- Проверка установки библиотеки Docker для Python ---
echo "Проверяем установку библиотеки Docker для Python..."
python3 -c "import docker; print('Docker Python library version:', docker.__version__)" || {
  echo "Ошибка: Библиотека Docker для Python не установлена или не работает."
  exit 1
}

# --- Очистка кэша APT ---
echo "Очищаем кэш APT..."
sudo apt-get clean || { echo "Ошибка: Не удалось очистить кэш APT."; exit 1; }

# --- Конец сборки образа ---
echo "Сборка образа завершена успешно!"