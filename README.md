# GSX Pràctica 2 - Infraestructura IT Organitzacional

Implementació d'una infraestructura moderna containeritzada per GreenDevCorp.

**Assignatura:** Gestió de Sistemes i Xarxes (URV)  
**Equip:** Josep Lluís Marín & Gemma Goitia  
**Deadline:** 15 Maig 2026

---

## Descripció

Aquesta pràctica implementa una infraestructura cloud-native utilitzant:
- **Docker** per containerització
- **Docker Compose** per orquestració multi-contenidor
- **Kubernetes** per desplegament en producció
- **Terraform** per Infrastructure as Code
- **GitHub Actions** per CI/CD
- **NetworkPolicies** per seguretat de xarxa

---

## Arquitectura

```
                    ┌─────────────────────────────────────────────────┐
                    │              Kubernetes Cluster                 │
                    │                 (Minikube)                      │
                    │                                                 │
  Internet ────────▶│   ┌─────────┐   ┌─────────┐   ┌──────────┐      │
       :30080       │   │  Nginx  │──▶│   App   │──▶│ Postgres │      │
                    │   │  :80    │   │  :8080  │   │  :5432   │      │
                    │   └─────────┘   └─────────┘   └────┬─────┘      │
                    │                                     │           │
                    │                              ┌──────▼──────┐    │
                    │                              │ PVC (1Gi)   │    │
                    │                              └─────────────┘    │
                    └─────────────────────────────────────────────────┘
```

---

## Estructura del projecte

    gsx-practica2/
    ├── .github/workflows/ci.yml      # CI/CD Pipeline
    ├── docker/
    │   ├── nginx/                    # Dockerfile + config Nginx
    │   └── app/                      # Dockerfile + app Python
    ├── docker-compose/
    │   └── docker-compose.yml        # Orquestració local
    ├── kubernetes/
    │   ├── *.yml                     # Manifests K8s
    │   └── network-policies/         # NetworkPolicies
    ├── terraform/
    │   ├── *.tf                      # IaC
    │   └── *.tfvars                  # Environments
    ├── scripts/
    │   ├── build-push.sh             # Build Docker images
    │   └── deploy.sh                 # CD local
    └── docs/
        ├── week8/                    # Docker
        ├── week9/                    # Docker Compose
        ├── week10/                   # Kubernetes
        ├── week11/                   # IaC + CI/CD
        └── week12/                   # Network + Identity

---

## Inici ràpid

### Requisits
- Docker + Docker Compose
- Minikube + kubectl
- Terraform >= 1.5

### Opció 1: Docker Compose (desenvolupament)

    cd docker-compose
    cp .env.example .env
    docker compose up --build

Accés: http://localhost:8080

### Opció 2: Kubernetes amb Terraform (producció)

    minikube start
    ./scripts/deploy.sh -e dev

Accés: http://localhost:8080

---

## Environments

| Environment | App Replicas | Debug | Imatge |
|-------------|--------------|-------|--------|
| dev | 1 | true | :latest |
| staging | 2 | false | :stable |
| prod | 3 | false | :v2 |

Comandes:

    ./scripts/deploy.sh -e dev       # Development
    ./scripts/deploy.sh -e staging   # Staging
    ./scripts/deploy.sh -e prod      # Production
    ./scripts/deploy.sh -r           # Rollback
    ./scripts/deploy.sh -s           # Status

---

## CI/CD Pipeline

    Push to main
         │
         ├──► Terraform Validate (fmt, init, validate)
         │
         └──► Docker Build & Security Scan
                  ├── Build amb cache
                  ├── Trivy scan (CRITICAL/HIGH)
                  ├── SBOM generation
                  └── Push to Docker Hub

Tags generats: sha-xxxxxx, latest, stable (en releases)

---

## NetworkPolicies (Seguretat)

Principi: **Default Deny** - Tot bloquejat per defecte.

| Policy | Permet |
|--------|--------|
| deny-all | Bloqueja tot |
| allow-ingress-to-nginx | Internet → Nginx:80 |
| allow-nginx-to-app | Nginx → App:8080 |
| allow-app-to-postgres | App → Postgres:5432 |

Comandes:

    kubectl apply -f kubernetes/network-policies/
    kubectl get networkpolicies

---

## Imatges Docker

| Imatge | Docker Hub |
|--------|------------|
| nginx-gsx | josepllmt20/nginx-gsx |
| app-gsx | josepllmt20/app-gsx |

---

## Setmanes

| Setmana | Tema | Estat |
|---------|------|-------|
| 8 | Containerització (Docker) | ✅ Completada |
| 9 | Multi-container (Docker Compose) | ✅ Completada |
| 10 | Orquestració (Kubernetes) | ✅ Completada |
| 11 | IaC + CI/CD | ✅ Completada |
| 12 | Xarxa i Identitat | ✅ Completada |
| 13 | Integració i Observabilitat | ⬜ Pendent |

---

## Documentació

- [Setmana 8: Docker](docs/week8/week8.md)
- [Setmana 9: Docker Compose](docs/week9/week9.md)
- [Setmana 10: Kubernetes](docs/week10/week10.md)
- [Setmana 11: IaC + CI/CD](docs/week11/week11.md)
- [Setmana 12: Network + Identity](docs/week12/week12.md)

---

## Comandes útils

    # Estat del cluster
    kubectl get pods,svc,deployments

    # Logs
    kubectl logs -f deployment/app

    # Escalar
    kubectl scale deployment/app --replicas=5

    # Rollback
    kubectl rollout undo deployment/app

    # Port-forward
    kubectl port-forward service/nginx 8080:80 --address 0.0.0.0

---

## Autors

- Josep Lluís Marín ([@josepLlMt20](https://github.com/josepLlMt20))
- Gemma Goitia ([@gemmagoitia](https://github.com/gemmagoitia))

---

## Llicència

Projecte acadèmic - URV 2026
