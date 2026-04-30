variable "app_env" {
  description = "Application environment"
  type        = string
  default     = "production"
}

variable "app_debug" {
  description = "Enable debug mode"
  type        = string
  default     = "false"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "greendevcorp"
}

variable "db_user" {
  description = "Database user"
  type        = string
  default     = "gsx"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "gsx123"
}

variable "app_replicas" {
  description = "Number of app replicas"
  type        = number
  default     = 2
}

variable "app_image" {
  description = "Docker image for app"
  type        = string
  default     = "josepllmt20/app-gsx:v2"
}

variable "nginx_image" {
  description = "Docker image for nginx"
  type        = string
  default     = "josepllmt20/nginx-gsx:v2"
}

variable "nginx_replicas" {
  description = "Number of nginx replicas"
  type        = number
  default     = 1
}
