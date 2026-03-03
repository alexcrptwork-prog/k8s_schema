terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.98"
    }
  }
}

provider "yandex" {
  # Параметры аутентификации должны быть заданы через переменные окружения
  # YC_FOLDER_ID или в провайдере напрямую
  # token     = var.yc_token
  # folder_id = var.folder_id
  # cloud_id  = var.cloud_id
}