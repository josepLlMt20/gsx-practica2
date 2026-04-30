resource "kubernetes_secret" "db_secret" {
  metadata {
    name = "db-secret"
  }

  data = {
    DB_USER           = var.db_user
    DB_PASSWORD       = var.db_password
    POSTGRES_USER     = var.db_user
    POSTGRES_PASSWORD = var.db_password
  }
}
