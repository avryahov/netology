# Базовый образ Ubuntu
FROM ubuntu:22.04

# Определение переменных
ARG ROOT_PASSWORD
ARG VECTOR_VERSION

# Обновление пакетов и установка необходимых зависимостей
RUN apt-get update && \
    apt-get install -y openssh-server python3 sudo curl wget tar && \
    apt-get clean

# Настройка SSH
RUN mkdir /var/run/sshd && \
    echo "root:${ROOT_PASSWORD}" | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Отключение DNS-проверки для ускорения подключения
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

# Установка Vector
RUN curl -L https://packages.timber.io/vector/${VECTOR_VERSION}/vector-${VECTOR_VERSION}-arm64-unknown-linux-musl.tar.gz -o /tmp/vector.tar.gz && \
    mkdir -p /opt/vector && \
    tar -xzf /tmp/vector.tar.gz -C /opt/vector --strip-components=1 && \
    ln -s /opt/vector/bin/vector /usr/local/bin/vector && \
    rm -f /tmp/vector.tar.gz

# Копирование конфигурации Vector
COPY files/vector_config.toml /etc/vector/vector.toml

# Создание директории для данных Vector
RUN mkdir -p /var/lib/vector && \
    chmod -R 755 /var/lib/vector

# Порт SSH
EXPOSE 2223

# Запуск SSH-сервера
CMD ["/usr/sbin/sshd", "-D"]