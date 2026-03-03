# Audit Trail для Yandex Cloud

Данный Terraform конфигурация создает Audit Trail в Yandex Cloud для отслеживания всех событий в указанном облаке и папке.

## Описание

Ресурсы, создаваемые данной конфигурацией:

- `yandex_audit_trails_trail` - основной ресурс аудита, который отслеживает все события в облаке и папке
- `yandex_logging_group` - группа логов для хранения данных аудита

Audit Trail будет отслеживать:
- Все события над объектами в облаке wmx
- Все события в папке infra
- Время возникновения событий
- Продолжительность событий
- Информацию о том, кто инициировал событие

## Переменные

- `cloud_id` - ID облака Yandex Cloud
- `folder_id` - ID папки Yandex Cloud
- `yc_token` - OAuth токен для аутентификации в Yandex Cloud

## Использование

1. Установите переменные в файле `terraform.tfvars` или передайте их как переменные окружения
2. Выполните `terraform init`
3. Выполните `terraform plan`
4. Выполните `terraform apply`

## Выводимые значения

- `audit_trail_id` - ID созданного audit trail
- `audit_trail_name` - Имя созданного audit trail
- `log_group_id` - ID группы логов для аудита
- `log_group_name` - Имя группы логов для аудита