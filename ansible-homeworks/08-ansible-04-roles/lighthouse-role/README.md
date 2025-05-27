Lighthouse Role
===============

Ansible роль для установки и настройки [Lighthouse](https://github.com/VKCOM/lighthouse) — веб-интерфейса для ClickHouse.

Requirements
------------

- Ansible >= 2.9
- Целевая ОС: Debian/Ubuntu (роль ориентирована на apt-based системы)
- Предварительно установленный ClickHouse-сервер

Role Variables
--------------

| Переменная              | Значение по умолчанию     | Описание                                                                 |
|-------------------------|---------------------------|--------------------------------------------------------------------------|
| `lighthouse_dest`       | `/var/www/lighthouse`     | Путь для установки Lighthouse                                            |
| `lighthouse_version`    | `master`                  | Ветка или тег репозитория GitHub (например, `v1.0.0`, `master`)         |

Дополнительно:

- Роль использует `hostvars['clickhouse-01']['ansible_host']` для построения ссылки на ClickHouse в интерфейсе.
  Убедитесь, что в `inventory` или `group_vars` указано имя хоста `clickhouse-01`.

Dependencies
------------

Нет. Роль не зависит от других ролей.

> ⚠️ Возможна интеграция с ролью ClickHouse, если потребуется динамически конфигурировать доступ через Lighthouse.

Example Playbook
----------------

```yaml
- name: Установка интерфейса LightHouse
  hosts: lighthouse
  become: true

  roles:
    - role: lighthouse-role
      vars:
        lighthouse_version: "master"
        lighthouse_dest: "/opt/lighthouse"