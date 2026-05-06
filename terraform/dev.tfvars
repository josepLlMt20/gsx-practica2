# Development Environment
app_env     = "development"
app_debug   = "true"
app_replicas   = 1
nginx_replicas = 1

# Database
db_name = "greendevcorp_dev"

# Images (dev uses latest)
app_image   = "josepllmt20/app-gsx:latest"
nginx_image = "josepllmt20/nginx-gsx:latest"
