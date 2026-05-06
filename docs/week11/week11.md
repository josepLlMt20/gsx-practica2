# Setmana 11: Infrastructure as Code (IaC) i CI/CD

**Autors:** Josep Lluís Marín & Gemma Goitia  
**Data:** Maig 2026  
**Assignatura:** Gestió de Sistemes i Xarxes (URV)

---

## Objectius

- Implementar Infrastructure as Code amb Terraform
- Configurar un pipeline CI/CD amb GitHub Actions
- Gestionar múltiples environments (dev, staging, prod)
- Automatitzar security scanning i generació de SBOM
- Crear scripts de desplegament local

---

## 1. Infrastructure as Code amb Terraform

### 1.1 Per què Terraform?

Hem escollit **Terraform** en lloc d'Ansible per diverses raons:

| Aspecte | Terraform | Ansible |
|---------|-----------|---------|
| Paradigma | Declaratiu | Imperatiu/Procedural |
| State | Manté estat | Sense estat |
| Idempotència | Nativa | Requereix cura |
| Kubernetes | Provider natiu | Via kubectl |
| Drift detection | Automàtic | Manual |

**Decisió:** Terraform s'integra millor amb Kubernetes gràcies al provider `hashicorp/kubernetes`, permet detectar drift automàticament, i el seu model declaratiu és més adequat per infraestructura immutable.

### 1.2 Estructura de fitxers

```
terraform/
├── main.tf          # Provider configuration
├── variables.tf     # Variable definitions
├── outputs.tf       # Output values
├── configmap.tf     # Kubernetes ConfigMap
├── secret.tf        # Kubernetes Secret
├── postgres.tf      # PostgreSQL deployment + service + storage
├── app.tf           # Backend deployment + service
├── nginx.tf         # Nginx deployment + service
├── dev.tfvars       # Development environment
├── staging.tfvars   # Staging environment
└── prod.tfvars      # Production environment
```

### 1.3 Fitxers principals

#### main.tf - Provider configuration
```hcl
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}
```

#### variables.tf - Definició de variables
```hcl
variable "app_env" {
  description = "Application environment"
  type        = string
  default     = "production"
}

variable "app_replicas" {
  description = "Number of app replicas"
  type        = number
  default     = 2
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true  # No es mostra als logs
}
```

### 1.4 Multiple Environments

Cada environment té el seu fitxer `.tfvars`:

**dev.tfvars:**
```hcl
app_env        = "development"
app_debug      = "true"
app_replicas   = 1
nginx_replicas = 1
app_image      = "josepllmt20/app-gsx:latest"
```

**staging.tfvars:**
```hcl
app_env        = "staging"
app_debug      = "false"
app_replicas   = 2
nginx_replicas = 1
app_image      = "josepllmt20/app-gsx:stable"
```

**prod.tfvars:**
```hcl
app_env        = "production"
app_debug      = "false"
app_replicas   = 3
nginx_replicas = 2
app_image      = "josepllmt20/app-gsx:v2"
```

### 1.5 Gestió de Secrets

Els secrets **no** es guarden als `.tfvars`. S'utilitzen variables d'entorn:

```bash
# Passar password via variable d'entorn
export TF_VAR_db_password="contrasenya_segura"
terraform apply -var-file="prod.tfvars"
```

**Important:** El fitxer `variables.tf` marca `db_password` com a `sensitive = true` per evitar que aparegui als logs.

---

## 2. CI/CD amb GitHub Actions

### 2.1 Arquitectura del Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                        CI Pipeline                               │
├─────────────────────────────────────────────────────────────────┤
│  Trigger: push to main, tags v*, pull requests                   │
│                                                                   │
│  ┌──────────────────────┐    ┌────────────────────────────────┐ │
│  │  terraform-validate   │    │     docker-build               │ │
│  │  ────────────────────│    │  ──────────────────────────────│ │
│  │  1. fmt -check        │    │  1. Setup Buildx               │ │
│  │  2. init -backend=false│   │  2. Login Docker Hub           │ │
│  │  3. validate          │    │  3. Build images (with cache)  │ │
│  └──────────────────────┘    │  4. Trivy security scan        │ │
│                               │  5. Generate SBOM              │ │
│         (parallel)            │  6. Push (main/tags only)      │ │
│                               └────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Workflow complet (.github/workflows/ci.yml)

El workflow té dos jobs paral·lels:

#### Job 1: Validate Terraform
```yaml
terraform-validate:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: hashicorp/setup-terraform@v3
    - run: terraform fmt -check -recursive
    - run: terraform init -backend=false
    - run: terraform validate
```

#### Job 2: Build & Security Scan
```yaml
docker-build:
  runs-on: ubuntu-latest
  steps:
    # Build amb cache de GitHub Actions
    - uses: docker/build-push-action@v5
      with:
        cache-from: type=gha
        cache-to: type=gha,mode=max
    
    # Security scanning amb Trivy
    - uses: aquasecurity/trivy-action@master
      with:
        severity: 'CRITICAL,HIGH'
        exit-code: '1'  # Falla si troba vulnerabilitats
    
    # Generar SBOM (Software Bill of Materials)
    - uses: aquasecurity/trivy-action@master
      with:
        format: 'cyclonedx'
        output: 'sbom.json'
```

### 2.3 Estratègia de Tags

| Condició | Tags generats |
|----------|---------------|
| Push a main | `sha-abc1234`, `latest` |
| Tag v* (release) | `sha-abc1234`, `latest`, `v1.0.0`, `stable` |
| Pull request | Només build local (no push) |

### 2.4 Security Scanning

**Trivy** escaneja les imatges per:
- Vulnerabilitats del sistema operatiu (Alpine packages)
- Vulnerabilitats de dependències (Python packages)
- Misconfiguracions

El pipeline **falla** si es troben vulnerabilitats CRITICAL o HIGH no resoltes.

### 2.5 SBOM Generation

Generem un **Software Bill of Materials** en format CycloneDX per a cada imatge:
- Documenta totes les dependències
- Requerit per compliance (NIST, CISA)
- S'emmagatzema com artifact del workflow

---

## 3. Script de Desplegament Local (deploy.sh)

### 3.1 Funcionalitats

```bash
./scripts/deploy.sh [opcions]

Opcions:
  -e, --env ENV      Environment: dev, staging, prod
  -t, --tag TAG      Tag de la imatge
  -p, --plan         Només mostra el pla
  -d, --destroy      Destrueix la infraestructura
  -s, --status       Mostra l'estat actual
  -r, --rollback     Rollback a la versió anterior
```

### 3.2 Exemples d'ús

```bash
# Desplegar a development
./scripts/deploy.sh -e dev

# Veure pla sense aplicar
./scripts/deploy.sh -e staging -p

# Desplegar a producció amb tag específic
./scripts/deploy.sh -e prod -t v3

# Rollback immediat
./scripts/deploy.sh -r

# Veure estat actual
./scripts/deploy.sh -s
```

### 3.3 Flux del script

1. Verifica que Minikube estigui actiu
2. Inicialitza Terraform
3. Genera el pla amb l'environment seleccionat
4. Demana confirmació (excepte amb `-p`)
5. Aplica els canvis
6. Espera que els pods estiguin ready
7. Mostra l'estat final

---

## 4. Comandes principals

### Terraform

```bash
cd terraform

# Inicialitzar
terraform init

# Validar format
terraform fmt -recursive
terraform validate

# Pla per environment
terraform plan -var-file="dev.tfvars"
terraform plan -var-file="staging.tfvars"
terraform plan -var-file="prod.tfvars"

# Aplicar
terraform apply -var-file="dev.tfvars"

# Destruir
terraform destroy -var-file="dev.tfvars"

# Veure outputs
terraform output
```

### Kubernetes (verificació)

```bash
# Estat dels pods
kubectl get pods -o wide

# Logs d'un pod
kubectl logs -f deployment/app

# Rollback manual
kubectl rollout undo deployment/app
kubectl rollout history deployment/app

# Port-forward per accedir
kubectl port-forward service/nginx 8888:80
```

### GitHub Actions (local testing)

```bash
# Simular workflow localment amb act
act push -j terraform-validate
act push -j docker-build
```

---

## 5. Flux CI/CD complet

```
┌────────────┐     ┌─────────────┐     ┌──────────────┐
│   Commit   │────▶│   GitHub    │────▶│   Actions    │
│   & Push   │     │   (main)    │     │   Trigger    │
└────────────┘     └─────────────┘     └──────┬───────┘
                                              │
                   ┌──────────────────────────┴───────────────────┐
                   │                                               │
         ┌─────────▼─────────┐                    ┌────────────────▼─────────────┐
         │ Terraform Validate│                    │       Docker Build           │
         │  - fmt check      │                    │  1. Build amb cache GHA      │
         │  - init           │                    │  2. Trivy security scan      │
         │  - validate       │                    │  3. Generar SBOM             │
         └─────────┬─────────┘                    │  4. Push a Docker Hub        │
                   │                              └────────────────┬─────────────┘
                   │                                               │
                   └──────────────────────┬───────────────────────┘
                                          │
                                ┌─────────▼─────────┐
                                │   PR Status       │
                                │   ✅ All passed   │
                                └─────────┬─────────┘
                                          │
                        ┌─────────────────▼─────────────────┐
                        │         CD (Local)                 │
                        │  ./scripts/deploy.sh -e prod       │
                        │  1. Terraform plan                 │
                        │  2. Confirmació manual             │
                        │  3. Terraform apply                │
                        │  4. kubectl rollout status         │
                        └────────────────────────────────────┘
```

---

## 6. Decisions de disseny

### 6.1 Separació CI vs CD

- **CI (GitHub Actions):** Build, test, scan, push automàtic
- **CD (Script local):** Desplegament manual amb confirmació

**Raó:** Per a un entorn d'aprenentatge és més segur requerir confirmació manual abans de desplegar. En un entorn real, el CD també seria automàtic amb ArgoCD o similar.

### 6.2 Cache de Docker builds

Utilitzem cache de GitHub Actions (`type=gha`) per accelerar builds:
- Primera build: ~2-3 minuts
- Builds següents amb cache: ~30-60 segons

### 6.3 Terraform state local

No utilitzem remote state (S3, GCS) perquè:
- Estem en un entorn local (Minikube)
- Simplifica la configuració per aprendre
- En producció real, seria **obligatori** usar remote state

### 6.4 Rollback strategy

Dues opcions disponibles:
1. **Kubernetes rollback:** `kubectl rollout undo` (immediat)
2. **Terraform rollback:** Canviar tags als tfvars i re-aplicar

---

## 7. Problemes resolts durant la setmana

### 7.1 Trivy scan failures

**Problema:** Les imatges Alpine tenien vulnerabilitats CVE.  
**Solució:** Afegir `apk update && apk upgrade` als Dockerfiles.

### 7.2 Hardcoded credentials a les probes

**Problema:** Les health probes de PostgreSQL tenien usuari/DB hardcoded.  
**Solució:** Usar variables d'entorn del contenidor:
```hcl
command = ["sh", "-c", "pg_isready -U $POSTGRES_USER -d $POSTGRES_DB"]
```

### 7.3 tfvars ignorats per git

**Problema:** El `.gitignore` excloïa `*.tfvars` per seguretat.  
**Solució:** Els nostres tfvars NO contenen secrets (passwords via `TF_VAR_`), així que els hem exclòs de l'exclusió amb `!terraform/*.tfvars`.

---

## 8. Checklist de verificació

- [x] Terraform fmt passa sense errors
- [x] Terraform validate passa
- [x] Trivy no troba vulnerabilitats CRITICAL/HIGH
- [x] SBOM generat per cada imatge
- [x] Imatges pujades a Docker Hub amb tags correctes
- [x] Script deploy.sh funciona per tots els environments
- [x] Rollback funciona correctament

---

## 9. Preguntes d'entrevista preparades

### P: Per què Terraform i no Ansible?

**R:** Terraform és declaratiu i manté estat, mentre que Ansible és procedural. Per Kubernetes, el provider de Terraform permet definir l'estat desitjat i detectar drift automàticament. Ansible seria millor per configuració de servidors tradicionals (instal·lar paquets, editar fitxers).

### P: Com funciona el pipeline CI/CD?

**R:** Cada push a main dispara dos jobs paral·lels:
1. Validació de Terraform (format i sintaxi)
2. Build de Docker amb cache, security scan amb Trivy, generació de SBOM, i push a Docker Hub

El CD és manual via script local que executa Terraform amb confirmació.

### P: Com fas rollback?

**R:** Dues opcions:
1. Ràpid: `kubectl rollout undo deployment/app`
2. Controlat: Canviar el tag de la imatge als tfvars i re-aplicar Terraform

### P: Quina diferència hi ha entre environments?

**R:** 
- **dev:** 1 rèplica, debug=true, imatge :latest
- **staging:** 2 rèpliques, debug=false, imatge :stable  
- **prod:** 3 rèpliques, debug=false, imatge amb versió específica (:v2)

### P: Com gestiones els secrets?

**R:** Els secrets mai es guarden al repositori. Utilitzem:
- Variables d'entorn `TF_VAR_db_password` per Terraform
- Kubernetes Secrets (base64) per runtime
- GitHub Secrets per CI/CD (Docker Hub credentials)

### P: Què és l'SBOM i per què el generem?

**R:** Software Bill of Materials és un inventari de totes les dependències d'una imatge. És requerit per compliance de seguretat i permet auditar vulnerabilitats de supply chain.

---

## 10. Enllaços i recursos

- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [GitHub Actions Docker Build](https://github.com/docker/build-push-action)
- [Trivy Security Scanner](https://trivy.dev/)
- [CycloneDX SBOM](https://cyclonedx.org/)
