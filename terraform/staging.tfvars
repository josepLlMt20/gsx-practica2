# Staging Environment
app_env     = "staging"
app_debug   = "false"
app_replicas   = 2
nginx_replicas = 1

# Database
db_name = "greendevcorp_staging"

# Images (staging uses stable tags)
app_image   = "josepllmt20/app-gsx:stable"
nginx_image = "josepllmt20/nginx-gsx:stable"
