#!/bin/bash
set -e

CLUSTER_NAME="kind"
NAMESPACE="opencnc"

echo "?? Starting OpenCNC uninstall / cleanup..."

# --------------------------------------------------------
# 1. Delete the kind cluster (fixes: node(s) already exist)
# --------------------------------------------------------
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo "??? Deleting kind cluster '${CLUSTER_NAME}'..."
  kind delete cluster --name "${CLUSTER_NAME}"
else
  echo "?? No kind cluster named '${CLUSTER_NAME}' found. Skipping."
fi

# --------------------------------------------------------
# 2. If a cluster still exists (rare), clean namespace + releases
# --------------------------------------------------------
# Check if kubectl works (cluster exists)
if kubectl get ns >/dev/null 2>&1; then
  # Delete Helm releases
  echo "??? Deleting Helm releases (if they exist)..."
  helm uninstall main-service -n "${NAMESPACE}" 2>/dev/null || true
  helm uninstall tsn-service -n "${NAMESPACE}" 2>/dev/null || true
  helm uninstall config-service -n "${NAMESPACE}" 2>/dev/null || true
  helm uninstall etcd -n "${NAMESPACE}" 2>/dev/null || true

  # Delete etcd-client pod
  echo "??? Deleting etcd-client pod..."
  kubectl delete pod etcd-client -n "${NAMESPACE}" 2>/dev/null || true

  # Delete namespace
  echo "??? Deleting namespace '${NAMESPACE}'..."
  kubectl delete namespace "${NAMESPACE}" 2>/dev/null || true
else
  echo "?? No Kubernetes cluster running. Skipping namespace cleanup."
fi

# --------------------------------------------------------
# 3. OPTIONAL: Remove generated TLS certs
# --------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
CERT_DIR="${SCRIPT_DIR}/certs"

if [ -d "$CERT_DIR" ]; then
  echo "? Do you want to delete generated TLS certificates in $CERT_DIR ? (y/N)"
  read -r resp
  if [[ "$resp" == "y" || "$resp" == "Y" ]]; then
    echo "??? Deleting TLS certificates..."
    rm -rf "$CERT_DIR"
  else
    echo "? Keeping certificates."
  fi
fi

echo "? Uninstall complete. System restored."
