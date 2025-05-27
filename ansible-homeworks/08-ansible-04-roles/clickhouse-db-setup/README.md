ClickHouse DB Setup Role
=========================

Ansible-роль для инициализации базы данных ClickHouse: создание БД, пользователей, задание прав и др.

Предполагается, что сам ClickHouse уже установлен (например, с помощью отдельной роли).

Requirements
------------

- Ansible >= 2.9
- Предварительно установленный ClickHouse (роль не занимается его установкой)
- Python-библиотека `lxml` на управляющей машине (если используется `xml`-модуль)

Role Variables
--------------

| Переменная                   | Значение по умолчанию | Описание                                                        |
|------------------------------|------------------------|-----------------------------------------------------------------|
| `clickhouse_db_name`         | `logs`                | Имя создаваемой базы данных                                     |
| `clickhouse_db_user`         | `vector`              | Имя создаваемого пользователя                                   |
| `clickhouse_db_user_password`| `vector`              | Пароль пользователя                                             |
| `clickhouse_db_host`         | `localhost`           | Хост ClickHouse для подключения (обычно localhost)              |
| `clickhouse_http_port`       | `8123`                | HTTP-порт ClickHouse                                            |

Дополнительные переменные можно задать в `defaults/main.yml` или через `group_vars`.

Dependencies
------------

- `clickhouse`: роль установки ClickHouse (например, [AlexeySetevoi/ansible-clickhouse](https://github.com/AlexeySetevoi/ansible-clickhouse))

Example Playbook
----------------

```yaml
- name: Настройка БД и пользователей ClickHouse
  hosts: clickhouse
  become: true
  roles:
    - role: clickhouse-db-setup
      vars:
        clickhouse_db_name: logs
        clickhouse_db_user: vector
        clickhouse_db_user_password: vector