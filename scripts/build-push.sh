#!/bin/bash
set -euo pipefail

DOCKER_USER="josepllmt20"
VERSION="${1:-v1}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== BUILD & PUSH DOCKER IMAGES ==="
echo "Versió: $VERSION"
echo ""

# Build Nginx
echo "[1/4] Building nginx-gsx:$VERSION..."
docker build -t nginx-gsx:$VERSION "$REPO_DIR/docker/nginx"
docker tag nginx-gsx:$VERSION $DOCKER_USER/nginx-gsx:$VERSION

# Build App
echo "[2/4] Building app-gsx:$VERSION..."
docker build -t app-gsx:$VERSION "$REPO_DIR/docker/app"
docker tag app-gsx:$VERSION $DOCKER_USER/app-gsx:$VERSION

# Push
echo "[3/4] Pushing nginx-gsx:$VERSION..."
docker push $DOCKER_USER/nginx-gsx:$VERSION

echo "[4/4] Pushing app-gsx:$VERSION..."
docker push $DOCKER_USER/app-gsx:$VERSION

echo ""
echo "=== COMPLETAT ==="
docker images | grep -E "(nginx-gsx|app-gsx)" | head -4
