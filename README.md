# Env Repo: Helm-чарт для django-app (GitOps)

Цей репозиторій використовується як **env-repo** в GitOps-ланцюжку:

**App repo (Django)** → **Jenkins (CI, build/push в ECR)** →\
**env-repo (цей репозиторій)** → **Argo CD + Helm (CD в EKS)**

Argo CD стежить за цим репозиторієм і застосовує зміни Helm-чарту до
EKS-кластеру.

------------------------------------------------------------------------

## 1. Структура репозиторію

``` text
env-repo
└── charts
    └── django-app
        ├── Chart.yaml
        ├── values.yaml
        └── templates
            ├── deployment.yaml
            ├── hpa.yaml
            └── service.yaml
```

### `Chart.yaml`

Мета-інформація про чарт:

-   назва (`name: django-app`)
-   версія чарта (`version`)
-   версія застосунку (`appVersion`)

### `values.yaml`

Основний файл конфігурації для деплою django-app:

``` yaml
image:
  repository: "<aws_account_id>.dkr.ecr.eu-central-1.amazonaws.com/django-app"
  tag: "latest"
  pullPolicy: IfNotPresent

replicaCount: 2

service:
  type: ClusterIP
  port: 8000

env:
  DJANGO_SETTINGS_MODULE: "config.settings"
  DEBUG: "false"

resources: {}

hpa:
  enabled: true
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 70
```

------------------------------------------------------------------------

## 2. Роль цього репозиторію в GitOps-ланцюжку

1.  **Jenkins** збирає Docker-образ із app-репозиторію (Django).

2.  Jenkins пушить образ в **AWS ECR**:\
    `...dkr.ecr.eu-central-1.amazonaws.com/django-app:<GIT_COMMIT>`

3.  Jenkins оновлює тут файл:

    ``` text
    charts/django-app/values.yaml
    ```

    змінюючи поле:

    ``` yaml
    image:
      tag: "<новий тег образу>"
    ```

4.  Зміни комітяться й пушаться в цей **env-repo**.

5.  **Argo CD** стежить за цим репозиторієм, бачить новий коміт і:

    -   помічає Application як `OutOfSync`
    -   виконує sync (авто або вручну) і оновлює деплой у EKS.

------------------------------------------------------------------------

## 3. Локальне розгортання чарта (для тесту)

``` bash
helm upgrade --install django-app ./charts/django-app   --namespace django   --create-namespace
```

------------------------------------------------------------------------

## 4. Як Jenkins оновлює `values.yaml`

Jenkins:

``` bash
sed -i "s/^\s*tag:\s*.*/  tag: ${GIT_COMMIT}/" charts/django-app/values.yaml
```

------------------------------------------------------------------------

## 5. Типові проблеми та перевірки

-   перевір `aws ecr list-images`
-   перевір sync в Argo CD
-   перевір `values.yaml` після оновлення
