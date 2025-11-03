#!/bin/bash

set -e

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Check if certs exist; if not, generate them
if [[ ! -f "$SCRIPT_DIR/certs/opencnc.crt" || ! -f "$SCRIPT_DIR/certs/opencnc.key" ]]; then
  echo "📄 TLS certs not found. Generating..."
  "$SCRIPT_DIR/generate-certs.sh"
else
  echo "📄 TLS certs found. Skipping generation."
fi

# Create Kubernetes cluster
echo "🚀 Creating kind cluster..."
kind create cluster

# Create namespace
echo "📁 Creating namespace 'opencnc'..."
kubectl create namespace opencnc

# Create TLS secret using files from certs/
echo "🔐 Creating TLS secret..."
kubectl create secret tls opencnc-shared-cert \
  --cert="$SCRIPT_DIR/certs/opencnc.crt" --key="$SCRIPT_DIR/certs/opencnc.key" \
  -n opencnc

# Load Docker images into kind
echo "📦 Loading Docker images..."
kind load docker-image main-service:latest
kind load docker-image tsn-service:latest
kind load docker-image config-service:latest

# Install Helm charts
echo "📥 Installing Helm charts..."
#helm repo add bitnami https://charts.bitnami.com/bitnami
#helm install etcd bitnami/etcd --namespace opencnc
helm install main-service ./main-service/ --namespace opencnc
helm install tsn-service ./tsn-service/ --namespace opencnc
helm install config-service ./config-service/ --namespace opencnc

# Wait for main-service pod to be ready
echo "⏳ Waiting for main-service pod to be running and ready..."

timeout=120  # seconds
interval=5   # seconds
elapsed=0

while true; do
  phase=$(kubectl get pods -n opencnc -l app=main-service -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "")
  ready=$(kubectl get pods -n opencnc -l app=main-service -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null || echo "false")

  if [[ "$phase" == "Running" && "$ready" == "true" ]]; then
    echo "✅ main-service pod is running and ready."
    break
  fi

  if (( elapsed >= timeout )); then
    echo "❌ Timeout waiting for main-service pod to be ready."
    exit 1
  fi

  echo "Waiting... ($elapsed/$timeout seconds)"
  sleep $interval
  ((elapsed+=interval))
done

# Get main-service pod name
MAIN_POD=$(kubectl get pods -n opencnc -l app=main-service -o jsonpath="{.items[0].metadata.name}")
echo "✅ Found main-service pod: $MAIN_POD"

# Get tsn-service pod name
TSN_POD=$(kubectl get pods -n opencnc -l app=tsn-service -o jsonpath="{.items[0].metadata.name}")
echo "✅ Found main-service pod: $TSN_POD"

# Get config-service pod name
CONFIG_POD=$(kubectl get pods -n opencnc -l app=config-service -o jsonpath="{.items[0].metadata.name}")
echo "✅ Found main-service pod: $CONFIG_POD"

# Run etcd client pod
echo "🔧 Running etcd client pod..."
kubectl run etcd-client --restart='Never' \
  --image docker.io/bitnami/etcd:3.6.2-debian-12-r0 \
  --env ROOT_PASSWORD=$(kubectl get secret --namespace opencnc etcd -o jsonpath="{.data.etcd-root-password}" | base64 -d) \
  --env ETCDCTL_ENDPOINTS="etcd.opencnc.svc.cluster.local:2379" \
  --namespace opencnc \
  --command -- sleep infinity

# Install curl inside main-service pod
echo "📡 Sending config request inside pod..."
kubectl exec -n opencnc "$MAIN_POD" -- sh -c "
  apk add --no-cache curl && \

"

echo "✅ Done."

