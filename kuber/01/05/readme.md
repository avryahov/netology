# Домашнее задание к занятию «Хранение в K8s»

### Цель задания

Научиться работать с хранилищами в тестовой среде Kubernetes:
- обеспечить обмен файлами между контейнерами пода;
- создавать **PersistentVolume** (PV) и использовать его в подах через **PersistentVolumeClaim** (PVC);
- объявлять свой **StorageClass** (SC) и монтировать его в под через **PVC**.

------

## **Подготовка**

Окружение, в котором выполнялось задание:
- macOS (Apple Silicon, M4);
- Docker Desktop в роли драйвера;
- Minikube (`minikube start --driver=docker`);
- локальный `kubectl`.

```bash
minikube start
kubectl get nodes
```

------

## Задание 1. Volume: обмен данными между контейнерами в поде

### Задача

Создать Deployment приложения из двух контейнеров (`busybox` и `multitool`), обменивающихся данными через общий `emptyDir`.

Манифест: [`src/task1/containers-data-exchange.yaml`](src/task1/containers-data-exchange.yaml)

Логика:
- контейнер `busybox` каждые 5 секунд дописывает дату в файл `/shared/date.log`;
- контейнер `multitool` непрерывно читает тот же файл (`tail -f /shared/date.log`);
- оба контейнера монтируют общий эфемерный том `emptyDir`, поэтому видят один и тот же файл.

### Ответ

**Шаг 1. Создал Deployment, под поднялся со статусом `2/2 Running`.**

```bash
kubectl apply -f containers-data-exchange.yaml
kubectl get pods -l app=data-exchange
```

![task1-01-2026-06-08.png](screens/task1-01-2026-06-08.png)

**Шаг 2. Описание пода с двумя контейнерами.**

```bash
kubectl describe pods data-exchange
```

Видно оба контейнера (`busybox`, `multitool`), смонтированный том `shared-data` в `/shared` у каждого из них.

![task1-02-2026-06-08.png](screens/task1-02-2026-06-08.png)

**Шаг 3. Контейнер `multitool` читает файл, который пишет `busybox`.**

```bash
kubectl logs <pod> -c multitool --tail=6   # вывод tail -f /shared/date.log
```

Записи появляются с интервалом 5 секунд — обмен данными между контейнерами через общий том работает.

![task1-03-2026-06-08.png](screens/task1-03-2026-06-08.png)

------

## Задание 2. PV, PVC

### Задача

Создать Deployment приложения, использующего локальный PV, созданный вручную.

Манифест: [`src/task2/pv-pvc.yaml`](src/task2/pv-pvc.yaml)

Состав манифеста:
- **PersistentVolume** `local-pv` — `hostPath: /mnt/data` на ноде, `1Gi`, `persistentVolumeReclaimPolicy: Retain`, `storageClassName: manual`;
- **PersistentVolumeClaim** `local-pvc` — привязка к конкретному PV через `volumeName: local-pv`;
- **Deployment** `data-exchange-pvc` — те же `busybox` (писатель) и `multitool` (читатель), но том берётся из PVC.

> `storageClassName: manual` указан и в PV, и в PVC намеренно: в Minikube включён аддон `default-storageclass`, и без явного класса PVC «уехал» бы на динамический провижининг вместо привязки к нашему ручному PV.

### Ответ

**Шаг 2. Создал PV и PVC, развернул Deployment. PVC привязался к PV (`STATUS: Bound`), под `2/2 Running`.**

```bash
kubectl apply -f pv-pvc.yaml
kubectl get pv
kubectl get pvc
kubectl get pods -l app=data-exchange-pvc
```

![task2-01-2026-06-08.png](screens/task2-01-2026-06-08.png)

**Шаг 3. `multitool` читает данные из смонтированной директории; тот же файл лежит на диске ноды в `/mnt/data`.**

```bash
kubectl exec <pod> -c multitool -- tail -5 /shared/date.log
minikube ssh -- sudo tail -3 /mnt/data/date.log
```

![task2-02-2026-06-08.png](screens/task2-02-2026-06-08.png)

**Шаг 4. Удалил Deployment и PVC. PV перешёл в статус `Released`.**

```bash
kubectl delete deployment data-exchange-pvc
kubectl delete pvc local-pvc
kubectl get pv local-pv
kubectl describe pv local-pv
```

![task2-03-2026-06-08.png](screens/task2-03-2026-06-08.png)

**Пояснение (шаг 4).**
PV не удалился вместе с PVC и не вернулся в статус `Available`, а перешёл в `Released`. Причина — политика `persistentVolumeReclaimPolicy: Retain`. При `Retain` Kubernetes намеренно **не освобождает** том автоматически: данные считаются ценными, и кластер оставляет администратору решение, что с ними делать. В поле `Claim` у PV по-прежнему указан удалённый `default/local-pvc` — именно эта ссылка не даёт тому повторно связаться с новым PVC. Чтобы переиспользовать PV, его пришлось бы вручную «почистить» (убрать `claimRef`) или пересоздать.

**Шаг 5. Файл сохранился на локальном диске ноды. Удалил PV — файл остался на месте.**

```bash
minikube ssh -- sudo ls -la /mnt/data        # файл на месте до удаления PV
kubectl delete pv local-pv
kubectl get pv local-pv                       # NotFound — объект PV удалён
minikube ssh -- sudo ls -la /mnt/data         # файл СОХРАНИЛСЯ после удаления PV
```

![task2-04-2026-06-08.png](screens/task2-04-2026-06-08.png)

**Пояснение (шаг 5).**
После удаления объекта PV файл `date.log` остался лежать в `/mnt/data` на ноде. Причина та же — политика `Retain` плюс природа `hostPath`. PersistentVolume — это лишь **объект Kubernetes API**, описывающий, *где* лежат данные; он не владеет самими данными. Для `hostPath` физические данные — это обычная директория на диске ноды. Удаление PV убирает только запись в API-сервере, но не трогает каталог на хосте. Поэтому файл переживает удаление PVC и самого PV, и его пришлось бы удалять вручную с ноды.

------

## Задание 3. StorageClass

### Задача

Создать Deployment приложения, использующего PVC, созданный на основе StorageClass.

Манифест: [`src/task3/sc.yaml`](src/task3/sc.yaml)

Состав манифеста:
- **StorageClass** `local-sc` — `provisioner: kubernetes.io/no-provisioner`, `volumeBindingMode: WaitForFirstConsumer`;
- **PersistentVolume** `local-sc-pv` — статический PV под этот SC (`hostPath: /mnt/sc-data`, `storageClassName: local-sc`);
- **PersistentVolumeClaim** `local-sc-pvc` — запрашивает том у класса `local-sc`;
- **Deployment** `data-exchange-sc` — `busybox` + `multitool` поверх PVC.

> С `no-provisioner` тома автоматически не создаются, поэтому к SC добавлен статический PV — иначе PVC навсегда остался бы в `Pending`. Режим `WaitForFirstConsumer` откладывает привязку PVC к PV до момента, когда появится потребляющий том под.

### Ответ

**Шаг 2. Создал SC, PV под него и PVC, развернул Deployment. PVC привязался (`Bound`), под `2/2 Running`.**

```bash
kubectl apply -f sc.yaml
kubectl get sc local-sc
kubectl get pv local-sc-pv
kubectl get pvc local-sc-pvc
kubectl get pods -l app=data-exchange-sc
```

![task3-01-2026-06-08.png](screens/task3-01-2026-06-08.png)

**Шаг 3. `multitool` читает файл, который `busybox` пишет каждые 5 секунд; тот же файл на диске ноды в `/mnt/sc-data`.**

```bash
kubectl exec <pod> -c multitool -- tail -5 /shared/date.log
minikube ssh -- sudo tail -3 /mnt/sc-data/date.log
```

![task3-02-2026-06-08.png](screens/task3-02-2026-06-08.png)

------

## Итоги

| Задание | Механизм | Что показано |
|---|---|---|
| 1 | `emptyDir` | Обмен данными между контейнерами внутри пода; том живёт в пределах пода |
| 2 | PV + PVC (`hostPath`, `Retain`) | Ручное создание тома, привязка через `volumeName`, поведение `Retain` при удалении PVC/PV, сохранность данных на диске ноды |
| 3 | StorageClass (`no-provisioner`, `WaitForFirstConsumer`) | Статическое подключение локального тома через свой SC |
