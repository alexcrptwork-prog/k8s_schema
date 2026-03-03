output "audit_trail_id" {
  description = "ID созданного audit trail"
  value       = yandex_audit_trails_trail.trail.id
}

output "audit_trail_name" {
  description = "Имя созданного audit trail"
  value       = yandex_audit_trails_trail.trail.name
}

output "log_group_id" {
  description = "ID группы логов для аудита"
  value       = yandex_logging_group.audit_logs.id
}

output "log_group_name" {
  description = "Имя группы логов для аудита"
  value       = yandex_logging_group.audit_logs.name
}

output "service_account_id" {
  description = "ID созданного сервисного аккаунта"
  value       = yandex_iam_service_account.audit_sa.id
}

output "service_account_name" {
  description = "Имя созданного сервисного аккаунта"
  value       = yandex_iam_service_account.audit_sa.name
}

output "static_access_key_id" {
  description = "ID статического ключа доступа"
  value       = yandex_iam_service_account_static_access_key.audit_sa_static_key.key_id
  sensitive   = true
}

output "static_access_key_secret" {
  description = "Секрет статического ключа доступа"
  value       = yandex_iam_service_account_static_access_key.audit_sa_static_key.secret
  sensitive   = true
}