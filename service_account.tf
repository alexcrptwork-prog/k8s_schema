# Create a service account for audit trails and logging
resource "yandex_iam_service_account" "audit_sa" {
  name        = var.service_account_name
  description = "Service account for audit trails and logging"

  folder_id = var.folder_id
}

# Create a static key for the service account
resource "yandex_iam_service_account_static_access_key" "audit_sa_static_key" {
  service_account_id = yandex_iam_service_account.audit_sa.id

  description = "Static access key for audit trails and logging"
}