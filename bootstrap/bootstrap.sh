#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script for AI Platform GitOps case study
# Creates a hardened kind cluster with node isolation and installs ArgoCD
# Follows production-grade practices: RBAC, NetworkPolicies, GitOps-only workflow

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_NAME="ai-platform-kind"
ARGOCD_VERSION="stable"

echo "=================================="
echo "AI Platform Bootstrap - Step 1/5"
echo "Creating kind cluster: ${CLUSTER_NAME}"
echo "=================================="

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo "⚠️  Cluster '${CLUSTER_NAME}' already exists. Delete it first with: kind delete cluster --name ${CLUSTER_NAME}"
  exit 1
fi

kind create cluster --name "${CLUSTER_NAME}" --config "${SCRIPT_DIR}/kind-cluster.yaml"

echo ""
echo "=================================="
echo "Step 2/5: Verifying node labels and taints"
echo "=================================="

# Wait for nodes to be ready
echo "Waiting for nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=120s

echo ""
echo "Node configuration:"
kubectl get nodes --show-labels
echo ""
echo "Node taints:"
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints

echo ""
echo "=================================="
echo "Step 3/5: Creating namespaces"
echo "=================================="

# Create namespaces with labels for network policy selection
kubectl create namespace argocd || true
kubectl label namespace argocd name=argocd --overwrite

kubectl create namespace ai-platform || true
kubectl label namespace ai-platform name=ai-platform --overwrite

kubectl create namespace monitoring || true
kubectl label namespace monitoring name=monitoring --overwrite

echo "✓ Namespaces created: argocd, ai-platform, monitoring"

echo ""
echo "=================================="
echo "Step 4/5: Installing ArgoCD"
echo "=================================="

# Install official ArgoCD manifest
ARGOCD_MANIFEST_URL="https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"
echo "Fetching official ArgoCD manifest..."
echo "URL: ${ARGOCD_MANIFEST_URL}"

if ! kubectl apply -n argocd -f "${ARGOCD_MANIFEST_URL}"; then
  echo "⚠️  Failed to download ArgoCD manifest. Check internet connection or use air-gapped install."
  exit 1
fi

echo "Waiting for ArgoCD pods to be ready (this may take 1-2 minutes)..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

echo "✓ ArgoCD core components installed"

echo ""
echo "=================================="
echo "Step 5/5: Bootstrap Complete!"
echo "=================================="

echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Access ArgoCD UI (port-forward):"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "   Then open: https://localhost:8080"
echo ""
echo "2. Get ArgoCD admin password:"
echo "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo"
echo "   Username: admin"
echo ""
echo "3. (Optional) Install ArgoCD CLI for terminal access:"
echo "   brew install argocd"
echo "   argocd login localhost:8080"
echo ""
echo "4. Verify cluster state:"
echo "   kubectl get nodes -o wide"
echo "   kubectl get pods -n argocd"
echo ""
echo "=================================="
