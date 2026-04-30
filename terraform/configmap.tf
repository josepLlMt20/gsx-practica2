resource "kubernetes_config_map" "app_config" {
  metadata {
    name = "app-config"
  }

  data = {
    APP_ENV   = var.app_env
    APP_DEBUG = var.app_debug
    DB_HOST   = "postgres"
    DB_PORT   = "5432"
    DB_NAME   = var.db_name
  }
}
