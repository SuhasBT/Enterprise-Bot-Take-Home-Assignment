#!/bin/bash
set -euo pipefail

CLUSTER_NAME="demo"
NAMESPACE="demo"
RELEASE_NAME="demo"
IMAGE_NAME="enterprise-service:1.0"

# Create or reuse kind cluster
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  kind create cluster --name "${CLUSTER_NAME}"
else
  echo "Kind cluster '${CLUSTER_NAME}' already exists, reusing..."
fi

# Install ingress-nginx (idempotent)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

# Build Docker image
docker build -t "${IMAGE_NAME}" ./service

# Load image into kind cluster
kind load docker-image "${IMAGE_NAME}" --name "${CLUSTER_NAME}"

# Create namespace if not exists
kubectl get ns "${NAMESPACE}" >/dev/null 2>&1 || kubectl create ns "${NAMESPACE}"

# Install or upgrade Helm release
helm upgrade --install "${RELEASE_NAME}" ./chart/enterprise-service -n "${NAMESPACE}"

echo "Setup complete!"
