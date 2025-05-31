# Домашнее задание к занятию 7 «Жизненный цикл ПО»

## Подготовка к выполнению

1. Получить бесплатную версию Jira - https://www.atlassian.com/ru/software/jira/work-management/free (скопируйте ссылку в адресную строку). Вы можете воспользоваться любым(в том числе бесплатным vpn сервисом) если сайт у вас недоступен. Кроме того вы можете скачать [docker образ](https://hub.docker.com/r/atlassian/jira-software/#) и запустить на своем хосте self-managed версию jira.
2. Настроить её для своей команды разработки.
3. Создать доски Kanban и Scrum.
4. [Дополнительные инструкции от разработчика Jira](https://support.atlassian.com/jira-cloud-administration/docs/import-and-export-issue-workflows/).

## Основная часть

Необходимо создать собственные workflow для двух типов задач: bug и остальные типы задач. Задачи типа bug должны проходить жизненный цикл:

1. Open -> On reproduce.
2. On reproduce -> Open, Done reproduce.
3. Done reproduce -> On fix.
4. On fix -> On reproduce, Done fix.
5. Done fix -> On test.
6. On test -> On fix, Done.
7. Done -> Closed, Open.

Остальные задачи должны проходить по упрощённому workflow:

1. Open -> On develop.
2. On develop -> Open, Done develop.
3. Done develop -> On test.
4. On test -> On develop, Done.
5. Done -> Closed, Open.

**Что нужно сделать**

1. Создайте задачу с типом bug, попытайтесь провести его по всему workflow до Done.
2. Создайте задачу с типом epic, к ней привяжите несколько задач с типом task, проведите их по всему workflow до Done.
3. При проведении обеих задач по статусам используйте kanban.
4. Верните задачи в статус Open.
5. Перейдите в Scrum, запланируйте новый спринт, состоящий из задач эпика и одного бага, стартуйте спринт, проведите задачи до состояния Closed. Закройте спринт.
6. Если всё отработалось в рамках ожидания — выгрузите схемы workflow для импорта в XML. Файлы с workflow и скриншоты workflow приложите к решению задания.

---

### Ответ

С помощью `docker compose` поднял Jira на macbook-е личном

![screenshot-2025-05-26-18-46-08.png](screens/screenshot-2025-05-26-18-46-08.png)

Использовал `postgres` в качестве базы данных

![screenshot-2025-05-26-18-50-35.png](screens/screenshot-2025-05-26-18-50-35.png)

Создал два проекта отдельно для `Kanban-доски` и отдельно `Scrum` с нарезкой задач на спринты

![screenshot-2025-05-31-15-53-12.png](screens/screenshot-2025-05-31-15-53-12.png)

Создал **рабочий процесс** для работы с багами

![screenshot-2025-05-29-09-07-33.png](screens/screenshot-2025-05-29-09-07-33.png)

Создал **рабочий процесс** для работы с трекингом базовых задач

![screenshot-2025-05-29-09-52-51.png](screens/screenshot-2025-05-29-09-52-51.png)

Привязал **рабочие процессы** к проектам через **схемы**

![screenshot-2025-05-29-09-54-33.png](screens/screenshot-2025-05-29-09-54-33.png)

![screenshot-2025-05-31-15-05-12.png](screens/screenshot-2025-05-31-15-05-12.png)


1. Переделал доску `Kanban`, а именно докинул в текущие колонки статусы из наших **workflow**

![screenshot-2025-05-31-16-09-09.png](screens/screenshot-2025-05-31-16-09-09.png)

Создал задачу с типом **bug** 

![screenshot-2025-05-31-16-14-35.png](screens/screenshot-2025-05-31-16-14-35.png)

По итогу `Kanban-доска` выглядит так

![screenshot-2025-05-31-16-15-56.png](screens/screenshot-2025-05-31-16-15-56.png)

Прогнал задачу по всем статусам до статуса `Done`

![screenshot-2025-05-31-16-17-21.png](screens/screenshot-2025-05-31-16-17-21.png)

![screenshot-2025-05-31-16-17-33.png](screens/screenshot-2025-05-31-16-17-33.png)

![screenshot-2025-05-31-16-17-42.png](screens/screenshot-2025-05-31-16-17-42.png)

![screenshot-2025-05-31-16-17-52.png](screens/screenshot-2025-05-31-16-17-52.png)

![screenshot-2025-05-31-16-17-59.png](screens/screenshot-2025-05-31-16-17-59.png)

![screenshot-2025-05-31-16-18-05.png](screens/screenshot-2025-05-31-16-18-05.png)

![screenshot-2025-05-31-16-18-12.png](screens/screenshot-2025-05-31-16-18-12.png)

По итогу `Kanban-доска` выглядит так

![screenshot-2025-05-31-16-18-20.png](screens/screenshot-2025-05-31-16-18-20.png)

Не стал под каждый статус создавать колонку в доске для отчетности и прозрачности!




2. Создайте задачу с типом epic, к ней привяжите несколько задач с типом task, проведите их по всему workflow до Done.
3. При проведении обеих задач по статусам используйте kanban.
4. Верните задачи в статус Open.
5. Перейдите в Scrum, запланируйте новый спринт, состоящий из задач эпика и одного бага, стартуйте спринт, проведите задачи до состояния Closed. Закройте спринт.
6. Если всё отработалось в рамках ожидания — выгрузите схемы workflow для импорта в XML. Файлы с workflow и скриншоты workflow приложите к решению задания.