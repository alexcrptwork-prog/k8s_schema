variable "cloud_id" {
  description = "ID облака Yandex Cloud"
  type        = string
  default     = "b1g5de8vn0u3pnn4555l"
}

variable "folder_id" {
  description = "ID папки Yandex Cloud"
  type        = string
  default     = "b1gsfjphh1bev42ggmnc"
}

variable "yc_token" {
  description = "OAuth токен для аутентификации в Yandex Cloud"
  type        = string
  sensitive   = true
}