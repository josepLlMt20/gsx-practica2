# GSX Practica 2 - Infraestructura IT Organitzacional

Implementacio d'una infraestructura moderna containeritzada per GreenDevCorp.

**Assignatura:** Gestio de Sistemes i Xarxes (URV)  
**Equip:** Josep Lluis Marin & Gemma Goitia  
**Deadline:** 15 Maig 2026

---

## Descripcio

Aquesta practica implementa una infraestructura cloud-native utilitzant:
- **Docker** per containeritzacio
- **Docker Compose** per orquestracio multi-contenidor
- **Kubernetes** per desplegament en produccio
- **Terraform** per Infrastructure as Code
- **GitHub Actions** per CI/CD

---

## Arquitectura

```
                    ┌─────────────────────────────────────────────────┐
                    │              Kubernetes Cluster                 │
                    │                 (Minikube)                      │
                    │                                                 │
  Internet ────────▶│   ┌─────────┐   ┌─────────┐   ┌──────────┐    │
       :30080       │   │  Nginx  │──▶│   App   │──▶│ Postgres │    │
                    │   │  :80    │   │  :8080  │   │  :5432   │    │
                    │   │ (2 rep) │   │ (3 rep) │   │ (1 rep)  │    │
                    │   └─────────┘   └─────────┘   └────┬─────┘    │
                    │                                     │          │
                    │                              ┌──────▼──────┐   │
                    │                              │ PVC (1Gi)   │   │
                    │                              └─────────────┘   │
                    └─────────────────────────────────────────────────┘
```

---

## Estructura del projecte

```
gsx-practica2/
├── .github/
│   └── workflows/
│       └── ci.yml           # CI/CD Pipeline
├── docker/
│   ├── nginx/
│   │   ├── Dockerfile
│   │   ├── nginx.conf
│   │   └── index.html
│   └── app/
│       ├── Dockerfile
│       └── app.py
├── docker-compose/
│   ├── docker-compose.yml
│   └── .env.example
├── kubernetes/
│   ├── configmap.yml
│   ├── secret.yml
│   ├── postgres-storage.yml
│   ├── postgres.yml
│   ├── app.yml
│   └── nginx.yml
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── configmap.tf
│   ├── secret.tf
│   ├── postgres.tf
│   ├── app.tf
│   ├── nginx.tf
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
├── scripts/
│   ├── build-push.sh
│   └── deploy.sh
└── docs/
    ├── week8/week8.md
    ├── week9/week9.md
    ├── week10/week10.md
    └── week11/week11.md
```

---

## Inici rapid

### Requisits
- Docker
- Docker Compose
- Minikube
- Terraform >= 1.5
- kubectl

### Opcio 1: Docker Compose (desenvolupament local)

```bash
cd docker-compose
cp .env.example .env
docker compose up --build
```

Acces:
- Web: http://localhost:8080
- API: http://localhost:8080/api
- Grafana: http://localhost:3000 (admin/admin)

### Opcio 2: Kubernetes amb Terraform (produccio)

```bash
# Iniciar Minikube
minikube start

# Desplegar amb l'script
./scripts/deploy.sh -e dev      # Development
./scripts/deploy.sh -e staging  # Staging
./scripts/deploy.sh -e prod     # Production

# O manualment amb Terraform
cd terraform
export TF_VAR_db_password="contrasenya_segura"
terraform init
terraform apply -var-file="prod.tfvars"

# Accedir al servei
kubectl port-forward service/nginx 8888:80
```

---

## Imatges Docker

| Imatge | Descripcio | Docker Hub |
|--------|------------|------------|
| nginx-gsx | Servidor web + reverse proxy | [josepllmt20/nginx-gsx](https://hub.docker.com/r/josepllmt20/nginx-gsx) |
| app-gsx | Backend Python amb PostgreSQL | [josepllmt20/app-gsx](https://hub.docker.com/r/josepllmt20/app-gsx) |

Tags disponibles: `latest`, `stable`, `v1`, `v2`, `sha-xxxxxxx`

---

## CI/CD Pipeline

El pipeline de GitHub Actions s'executa en cada push a `main`:

```
┌────────────────┐    ┌────────────────┐
│   Terraform    │    │  Docker Build  │
│   Validate     │    │  & Push        │
│  ─────────────│    │ ─────────────  │
│  - fmt check   │    │ - Buildx cache │
│  - validate    │    │ - Trivy scan   │
└───────┬────────┘    │ - SBOM gen     │
        │             │ - Push Hub     │
        │             └───────┬────────┘
        │                     │
        └──────────┬──────────┘
                   ▼
           ┌──────────────┐
           │   Merge OK   │
           └──────────────┘
```

---

## Scripts disponibles

| Script | Descripcio |
|--------|------------|
| `scripts/build-push.sh` | Build i push de Docker images |
| `scripts/deploy.sh` | Desplegament amb Terraform |

### deploy.sh

```bash
./scripts/deploy.sh [opcions]

Opcions:
  -e, --env ENV      Environment: dev, staging, prod
  -t, --tag TAG      Tag de la imatge
  -p, --plan         Nomes mostra el pla
  -d, --destroy      Destrueix la infraestructura
  -s, --status       Mostra l'estat actual
  -r, --rollback     Rollback a la versio anterior

Exemples:
  ./scripts/deploy.sh -e dev          # Desplegar a dev
  ./scripts/deploy.sh -e prod -t v3   # Desplegar v3 a prod
  ./scripts/deploy.sh -r              # Rollback
```

---

## Environments

| Environment | Repliques App | Repliques Nginx | Debug | Imatge |
|-------------|---------------|-----------------|-------|--------|
| dev | 1 | 1 | true | :latest |
| staging | 2 | 1 | false | :stable |
| prod | 3 | 2 | false | :v2 |

---

## Setmanes

| Setmana | Tema | Estat |
|---------|------|-------|
| 8 | Containeritzacio (Docker) | Completada |
| 9 | Multi-container (Docker Compose) | Completada |
| 10 | Orquestracio (Kubernetes) | Completada |
| 11 | IaC + CI/CD (Terraform + GitHub Actions) | Completada |
| 12 | Xarxa i Identitat | Pendent |
| 13 | Integracio i Observabilitat | Pendent |

## Documentacio

- [Setmana 8: Docker](docs/week8/week8.md)
- [Setmana 9: Docker Compose](docs/week9/week9.md)
- [Setmana 10: Kubernetes](docs/week10/week10.md)
- [Setmana 11: IaC + CI/CD](docs/week11/week11.md)

---

## Deploy des de zero (Clean Start)

Si necessites esborrar tot i tornar a desplegar:

### Pas 1: Netejar

```bash
# Esborrar Minikube completament
minikube delete

# (Opcional) Netejar Docker
docker system prune -a --volumes -f
```

### Pas 2: Iniciar Minikube

```bash
minikube start --memory=4096 --cpus=2
```

### Pas 3: Desplegar amb Terraform

```bash
cd terraform

# Netejar estat anterior
rm -rf .terraform terraform.tfstate*

# Inicialitzar i desplegar
terraform init
export TF_VAR_db_password="gsx123"
terraform apply -var-file="dev.tfvars"
```

### Pas 4: Verificar

```bash
# Esperar que tots els pods estiguin Ready
kubectl get pods -w

# Accedir al servei
kubectl port-forward service/nginx 8080:80 --address 0.0.0.0

# Provar (des d'altra terminal)
curl http://localhost:8080
curl http://localhost:8080/api
```

### Opcio rapida amb script

```bash
./scripts/deploy.sh -e dev
```

---

## Comandes de demostracio

```bash
# Estat dels pods
kubectl get pods -o wide

# Logs en temps real
kubectl logs -f deployment/app

# Escalar a 5 repliques
kubectl scale deployment/app --replicas=5
kubectl get pods -w

# Rollback
kubectl rollout undo deployment/app

# Historial de versions
kubectl rollout history deployment/app

# Destruir tot
cd terraform && terraform destroy -var-file="dev.tfvars"
```

---

## Autors

- Josep Lluis Marin ([@josepLlMt20](https://github.com/josepLlMt20))
- Gemma Goitia ([@gemmagoitia](https://github.com/gemmagoitia))

---

## Llicencia

Projecte academic - URV 2026
