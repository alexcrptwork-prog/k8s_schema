# Grant permissions for audit trails
resource "yandex_resourcemanager_folder_iam_binding" "audit_trails_editor" {
  folder_id = var.folder_id
  role      = "audittrails.editor"

  members = [
    "serviceAccount:${yandex_iam_service_account.audit_sa.id}",
  ]
}

# Grant permissions for logging
resource "yandex_resourcemanager_folder_iam_binding" "logging_writer" {
  folder_id = var.folder_id
  role      = "logging.writer"

  members = [
    "serviceAccount:${yandex_iam_service_account.audit_sa.id}",
  ]
}