#!/bin/bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuració
DOCKER_USER="josepllmt20"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_DIR="$REPO_DIR/terraform"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     🚀 GreenDevCorp CD Pipeline 🚀     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Funció per mostrar ús
usage() {
    echo -e "${YELLOW}Ús:${NC} $0 [opcions]"
    echo ""
    echo "Opcions:"
    echo "  -t, --tag TAG      Tag de la imatge (default: latest)"
    echo "  -p, --plan         Només mostra el pla, no aplica"
    echo "  -d, --destroy      Destrueix la infraestructura"
    echo "  -s, --status       Mostra l'estat actual"
    echo "  -h, --help         Mostra aquest missatge"
    echo ""
    echo "Exemples:"
    echo "  $0                 # Desplegament amb :latest"
    echo "  $0 -t v3           # Desplegament amb :v3"
    echo "  $0 -t abc123f      # Desplegament amb commit SHA"
    echo "  $0 -s              # Veure estat dels pods"
    exit 1
}

# Parsejar arguments
TAG="latest"
PLAN_ONLY=false
DESTROY=false
STATUS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tag) TAG="$2"; shift 2 ;;
        -p|--plan) PLAN_ONLY=true; shift ;;
        -d|--destroy) DESTROY=true; shift ;;
        -s|--status) STATUS=true; shift ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Opció desconeguda: $1${NC}"; usage ;;
    esac
done

# Verificar Minikube
echo -e "${YELLOW}[1/5]${NC} Verificant Minikube..."
if ! minikube status &>/dev/null; then
    echo -e "${YELLOW}      Minikube no està actiu. Iniciant...${NC}"
    minikube start
fi
echo -e "${GREEN}      ✓ Minikube actiu${NC}"

# Si només volem estat
if [ "$STATUS" = true ]; then
    echo ""
    echo -e "${BLUE}═══ ESTAT ACTUAL ═══${NC}"
    echo ""
    echo -e "${YELLOW}Pods:${NC}"
    kubectl get pods -o wide
    echo ""
    echo -e "${YELLOW}Services:${NC}"
    kubectl get services
    echo ""
    echo -e "${YELLOW}PV/PVC:${NC}"
    kubectl get pv,pvc
    echo ""
    echo -e "${YELLOW}Terraform State:${NC}"
    cd "$TERRAFORM_DIR"
    terraform show -no-color | head -20
    exit 0
fi

# Si volem destruir
if [ "$DESTROY" = true ]; then
    echo ""
    echo -e "${RED}⚠️  ATENCIÓ: Això destruirà tota la infraestructura!${NC}"
    read -p "Estàs segur? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        cd "$TERRAFORM_DIR"
        terraform destroy -auto-approve
        echo -e "${GREEN}✓ Infraestructura destruïda${NC}"
    else
        echo -e "${YELLOW}Cancel·lat${NC}"
    fi
    exit 0
fi

# Verificar imatges
echo -e "${YELLOW}[2/5]${NC} Verificant imatges Docker..."
APP_IMAGE="$DOCKER_USER/app-gsx:$TAG"
NGINX_IMAGE="$DOCKER_USER/nginx-gsx:$TAG"
echo -e "      App:   ${BLUE}$APP_IMAGE${NC}"
echo -e "      Nginx: ${BLUE}$NGINX_IMAGE${NC}"

# Terraform init
echo -e "${YELLOW}[3/5]${NC} Inicialitzant Terraform..."
cd "$TERRAFORM_DIR"
terraform init -input=false > /dev/null
echo -e "${GREEN}      ✓ Terraform inicialitzat${NC}"
# Terraform plan
echo -e "${YELLOW}[4/5]${NC} Generant pla..."
terraform plan \
    -var="app_image=$APP_IMAGE" \
    -var="nginx_image=$NGINX_IMAGE" \
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
echo -e "${YELLOW}[5/5]${NC} Aplicant canvis..."
read -p "Vols continuar? (y/n): " confirm
if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    terraform apply tfplan
    rm -f tfplan
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     ✅ Desplegament completat! ✅      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Pods:${NC}"
    kubectl get pods
    echo ""
    echo -e "${YELLOW}Per accedir:${NC}"
    echo "  kubectl port-forward service/nginx 8888:80 --address 0.0.0.0"
    echo "  Després: http://localhost:8888"
else
    rm -f tfplan
    echo -e "${YELLOW}Cancel·lat${NC}"
fi
