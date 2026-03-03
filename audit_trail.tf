resource "yandex_audit_trails_trail" "trail" {
  name        = "cloud-trail"
  description = "Audit trail for monitoring all events in cloud wmx, folder infra"

  # Настройки источника аудита
  source {
    cloud_id = var.cloud_id
    folder_ids = [var.folder_id]
    
    # Включаем все типы событий
    event_types = [
      "yandex.cloud.audit.v1.CreateEvent",
      "yandex.cloud.audit.v1.UpdateEvent",
      "yandex.cloud.audit.v1.DeleteEvent",
      "yandex.cloud.audit.v1.ReadEvent",
      "yandex.cloud.audit.v1.OtherEvent"
    ]
  }

  # Настройки приемника данных аудита
  sink {
    # Используем Cloud Logs для хранения данных аудита
    log_group_id = yandex_logging_group.audit_logs.id
  }

  # Включаем трассировку для получения информации о времени и продолжительности событий
  advanced_config {
    include_metadata = true
    include_request_body = true
    include_response_body = true
  }

  labels = {
    environment = "production"
    project     = "wmx-infra"
  }
}

# Создаем группу логов для хранения данных аудита
resource "yandex_logging_group" "audit_logs" {
  name        = "audit-trail-logs"
  folder_id   = var.folder_id
  retention_period = "720h" # Хранение логов 30 дней
  
  lifecycle {
    prevent_destroy = false
  }
}