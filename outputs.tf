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