#!/bin/bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuració
DOCKER_USER="josepllmt20"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_DIR="$REPO_DIR/terraform"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     🚀 GreenDevCorp CD Pipeline 🚀     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

usage() {
    echo -e "${YELLOW}Ús:${NC} $0 [opcions]"
    echo ""
    echo "Opcions:"
    echo "  -e, --env ENV      Environment: dev, staging, prod (default: dev)"
    echo "  -t, --tag TAG      Tag de la imatge (sobreescriu el tfvars)"
    echo "  -p, --plan         Només mostra el pla"
    echo "  -d, --destroy      Destrueix la infraestructura"
    echo "  -s, --status       Mostra l'estat actual"
    echo "  -r, --rollback     Rollback a la versió anterior"
    echo "  -h, --help         Mostra aquest missatge"
    echo ""
    echo "Exemples:"
    echo "  $0 -e dev          # Desplegament a dev"
    echo "  $0 -e staging      # Desplegament a staging"
    echo "  $0 -e prod -t v3   # Desplegament a prod amb tag v3"
    echo "  $0 -r              # Rollback"
    exit 1
}

# Parsejar arguments
ENV="dev"
TAG=""
PLAN_ONLY=false
DESTROY=false
STATUS=false
ROLLBACK=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env) ENV="$2"; shift 2 ;;
        -t|--tag) TAG="$2"; shift 2 ;;
        -p|--plan) PLAN_ONLY=true; shift ;;
        -d|--destroy) DESTROY=true; shift ;;
        -s|--status) STATUS=true; shift ;;
        -r|--rollback) ROLLBACK=true; shift ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Opció desconeguda: $1${NC}"; usage ;;
    esac
done

# Validar environment
if [[ ! "$ENV" =~ ^(dev|staging|prod)$ ]]; then
    echo -e "${RED}Environment invàlid: $ENV${NC}"
    echo "Usa: dev, staging, prod"
    exit 1
fi

TFVARS_FILE="$TERRAFORM_DIR/$ENV.tfvars"
if [ ! -f "$TFVARS_FILE" ]; then
    echo -e "${RED}Fitxer $TFVARS_FILE no existeix${NC}"
    exit 1
fi

echo -e "${BLUE}Environment: ${YELLOW}$ENV${NC}"
echo ""

# Verificar Minikube
echo -e "${YELLOW}[1/5]${NC} Verificant Minikube..."
if ! minikube status &>/dev/null; then
    echo -e "${YELLOW}      Minikube no està actiu. Iniciant...${NC}"
    minikube start
fi
echo -e "${GREEN}      ✓ Minikube actiu${NC}"

# Status
if [ "$STATUS" = true ]; then
    echo ""
    echo -e "${BLUE}═══ ESTAT ACTUAL ($ENV) ═══${NC}"
    echo ""
    echo -e "${YELLOW}Pods:${NC}"
    kubectl get pods -o wide
    echo ""
    echo -e "${YELLOW}Services:${NC}"
    kubectl get services
    echo ""
    echo -e "${YELLOW}Deployments:${NC}"
    kubectl get deployments -o wide
    echo ""
    echo -e "${YELLOW}Rollout History (app):${NC}"
    kubectl rollout history deployment/app 2>/dev/null || echo "No history"
    exit 0
fi

# Rollback
if [ "$ROLLBACK" = true ]; then
    echo ""
    echo -e "${YELLOW}Executant rollback...${NC}"
    kubectl rollout undo deployment/app
    kubectl rollout undo deployment/nginx
    echo -e "${GREEN}✓ Rollback completat${NC}"
    echo ""
    kubectl get pods
    exit 0
fi

# Destroy
if [ "$DESTROY" = true ]; then
    echo ""
    echo -e "${RED}⚠️  ATENCIÓ: Destruir infraestructura ($ENV)${NC}"
    read -p "Estàs segur? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        cd "$TERRAFORM_DIR"
        terraform destroy -var-file="$ENV.tfvars" -auto-approve
        echo -e "${GREEN}✓ Infraestructura destruïda${NC}"
    else
        echo -e "${YELLOW}Cancel·lat${NC}"
    fi
    exit 0
fi

# Terraform init
echo -e "${YELLOW}[2/5]${NC} Inicialitzant Terraform..."
cd "$TERRAFORM_DIR"
terraform init -input=false > /dev/null
echo -e "${GREEN}      ✓ Terraform inicialitzat${NC}"

# Preparar variables
EXTRA_VARS=""
if [ -n "$TAG" ]; then
    EXTRA_VARS="-var=app_image=$DOCKER_USER/app-gsx:$TAG -var=nginx_image=$DOCKER_USER/nginx-gsx:$TAG"
fi

# Terraform plan
echo -e "${YELLOW}[3/5]${NC} Generant pla ($ENV)..."
terraform plan \
    -var-file="$ENV.tfvars" \
    $EXTRA_VARS \
    -out=tfplan \
    -input=false

if [ "$PLAN_ONLY" = true ]; then
    echo ""
    echo -e "${YELLOW}Mode plan-only. No s'aplica res.${NC}"
    rm -f tfplan
    exit 0
fi

# Terraform apply
echo ""
echo -e "${YELLOW}[4/5]${NC} Aplicant canvis..."
read -p "Vols continuar amb $ENV? (y/n): " confirm
if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    terraform apply tfplan
    rm -f tfplan
    
    # Esperar que els pods estiguin llestos
    echo ""
    echo -e "${YELLOW}[5/5]${NC} Esperant pods..."
    kubectl rollout status deployment/app --timeout=120s
    kubectl rollout status deployment/nginx --timeout=60s
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ Desplegament $ENV completat! ✅   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    kubectl get pods
    echo ""
    echo -e "${YELLOW}Accés:${NC}"
    echo "  kubectl port-forward service/nginx 8888:80 --address 0.0.0.0"
else
    rm -f tfplan
    echo -e "${YELLOW}Cancel·lat${NC}"
fi
