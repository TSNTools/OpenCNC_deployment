#!/usr/bin/env bash
set -e

# -----------------------------------------
# CONFIG
# -----------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
CLUSTER_NAME="kind"
NAMESPACE="opencnc"
CERT_DIR="$SCRIPT_DIR/certs"
CERT_CRT="$CERT_DIR/tls.crt"
CERT_KEY="$CERT_DIR/tls.key"

# -----------------------------------------
# 1. Ensure TLS certificates exist
# -----------------------------------------
mkdir -p "$CERT_DIR"

if [[ ! -f "$CERT_CRT" || ! -f "$CERT_KEY" ]]; then
  echo "🔐 TLS certs missing, generating..."
  "$SCRIPT_DIR/generate-certs.sh"
else
  echo "🔐 TLS certs found."
fi

# -----------------------------------------
# 2. Create kind cluster if missing
# -----------------------------------------
if ! kind get clusters | grep -q "^$CLUSTER_NAME$"; then
  echo "🚀 Creating kind cluster..."
  kind create cluster --name "$CLUSTER_NAME"
else
  echo "🚀 Kind cluster already exists."
fi


# -----------------------------------------
# 3. Load all local docker image tar files
# -----------------------------------------
echo "🐳 Loading local Docker images..."
find "$SCRIPT_DIR" -maxdepth 1 -name "*.tar" | while read -r tarfile; do
  echo "  → Loading $tarfile into Docker..."
  docker load -i "$tarfile"

  IMAGE_NAME=$(docker load -i "$tarfile" | awk '{print $3}')
  echo "  → Loading $IMAGE_NAME into kind..."
  kind load docker-image "$IMAGE_NAME" --name "$CLUSTER_NAME"
done

# -----------------------------------------
# 4. Create namespace (if not exists)
# -----------------------------------------
kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

# -----------------------------------------
# 5. Create TLS secret
# -----------------------------------------
if kubectl get secret opencnc-shared-cert &> /dev/null; then
    echo "🔒 Secret 'opencnc-shared-cert' already exists. Skipping creation."
else
kubectl create secret generic opencnc-shared-cert \
  --from-file=ca.crt="$CERT_DIR/ca.crt" \
  --from-file=tls.crt="$CERT_DIR/tls.crt" \
  --from-file=tls.key="$CERT_DIR/tls.key"

    echo "✅ Secret 'opencnc-shared-cert' created."
fi


# Loop over all tar files in the same directory
for image in "$SCRIPT_DIR"/*.tar; do
    echo "🔄 Loading Docker image: $image"
    docker load -i "$image"
done

# -----------------------------------------
# 6. Install only the etcd helm chart (into opencnc)
# -----------------------------------------
echo "📥 Installing etcd chart..."
helm upgrade --install etcd "$SCRIPT_DIR/etcd-1" -n "$NAMESPACE"

# -----------------------------------------
# 7. Wait until etcd pods are ready
# -----------------------------------------
echo "⏳ Waiting for etcd pods to be Ready..."
kubectl wait --for=condition=Ready pod -l app=etcd -n "$NAMESPACE" --timeout=180s

echo "🎉 Deployment complete: etcd is ready!"

ETCD_SECRET_NAME="etcd"
ETCD_PASSWORD="myStrongPassword"   # Replace with your desired password

if kubectl get secret "$ETCD_SECRET_NAME" &> /dev/null; then
    echo "🔒 Secret '$ETCD_SECRET_NAME' already exists. Skipping creation."
else
    kubectl create secret generic "$ETCD_SECRET_NAME" \
      --from-literal=username=root \
      --from-literal=password="$ETCD_PASSWORD"
    echo "✅ Secret '$ETCD_SECRET_NAME' created."
fi


# Install application charts
for chart in main-service tsn-service config-service; do
  echo "📥 Installing $chart chart..."
  helm upgrade --install "$chart" "$SCRIPT_DIR/$chart"
done

echo "🎉 All services are ready."

