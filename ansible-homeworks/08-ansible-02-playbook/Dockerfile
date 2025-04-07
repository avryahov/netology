# Базовый образ Ubuntu
FROM ubuntu:22.04

# Определение переменных
ARG ROOT_PASSWORD

# Обновление пакетов и установка необходимых зависимостей
RUN apt-get update && \
    apt-get install -y openssh-server python3 sudo && \
    apt-get clean

# Настройка SSH
RUN mkdir /var/run/sshd && \
    echo "root:${ROOT_PASSWORD}" | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Отключение DNS-проверки для ускорения подключения
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

# Порт SSH
EXPOSE 2222

# Запуск SSH-сервера
CMD ["/usr/sbin/sshd", "-D"]