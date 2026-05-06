# Production Environment
app_env     = "production"
app_debug   = "false"
app_replicas   = 3
nginx_replicas = 2

# Database
db_name = "greendevcorp"

# Images (prod uses specific version tags)
app_image   = "josepllmt20/app-gsx:v2"
nginx_image = "josepllmt20/nginx-gsx:v2"
