output "nginx_node_port" {
  description = "NodePort for Nginx service"
  value       = kubernetes_service.nginx.spec[0].port[0].node_port
}

output "app_replicas" {
  description = "Number of app replicas"
  value       = kubernetes_deployment.app.spec[0].replicas
}

output "services" {
  description = "List of services"
  value = [
    kubernetes_service.nginx.metadata[0].name,
    kubernetes_service.app.metadata[0].name,
    kubernetes_service.postgres.metadata[0].name
  ]
}
