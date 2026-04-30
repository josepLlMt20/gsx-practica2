resource "kubernetes_deployment" "app" {
  metadata {
    name = "app"
  }

  spec {
    replicas = var.app_replicas

    selector {
      match_labels = {
        app = "backend"
      }
    }

    template {
      metadata {
        labels = {
          app = "backend"
        }
      }

      spec {
        container {
          name  = "app"
          image = var.app_image

          port {
            container_port = 8080
          }

          env_from {
            config_map_ref {
              name = "app-config"
            }
          }

          env_from {
            secret_ref {
              name = "db-secret"
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 30
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name = "app"
  }

  spec {
    selector = {
      app = "backend"
    port {
      port        = 8080
      target_port = 8080
    }
  }
}
