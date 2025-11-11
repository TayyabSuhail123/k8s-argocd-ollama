#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script for AI Platform GitOps case study
# Creates a hardened kind cluster with node isolation and installs ArgoCD
# Follows production-grade practices: RBAC, NetworkPolicies, GitOps-only workflow

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_NAME="ai-platform-kind"
ARGOCD_VERSION="stable"

echo ""
echo "=================================="
echo "AI Platform Bootstrap - Step 1/7"
echo "Creating kind cluster: ${CLUSTER_NAME}"
echo "=================================="

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo "⚠️  Cluster '${CLUSTER_NAME}' already exists. Delete it first with: kind delete cluster --name ${CLUSTER_NAME}"
  exit 1
fi

kind create cluster --name "${CLUSTER_NAME}" --config "${SCRIPT_DIR}/kind-cluster.yaml"

# Connect local registry to kind network (if registry exists)
if docker ps --format '{{.Names}}' | grep -q "^kind-registry$"; then
  echo ""
  echo "Connecting local registry to kind network..."
  # Only connect if not already connected
  if ! docker network inspect kind | grep -q "kind-registry"; then
    docker network connect kind kind-registry 2>/dev/null || true
  fi
  echo "✓ Local registry connected - images will pull from localhost:5001"
fi

echo ""
echo "=================================="
echo "Step 2/7: Verifying node labels and taints"
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
echo "Step 3/7: Creating namespaces"
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
echo "Step 4/7: Installing Prometheus CRDs"
echo "=================================="

# Install Prometheus CRDs required for ServiceMonitors
if [ -f "${SCRIPT_DIR}/install-prometheus-crds.sh" ]; then
  echo "Installing Prometheus CRDs (required for metrics collection)..."
  "${SCRIPT_DIR}/install-prometheus-crds.sh"
  echo "✓ Prometheus CRDs installed"
else
  echo "⚠️  install-prometheus-crds.sh not found, skipping..."
fi

echo ""
echo "=================================="
echo "Step 5/7: Pre-loading images (SKIPPED - using local registry)"
echo "=================================="

# Images are pulled from local registry (localhost:5001) instead of remote
# This provides instant image pulls without needing to pre-load into nodes
if docker ps --format '{{.Names}}' | grep -q "^kind-registry$"; then
  echo "✓ Local registry detected - images will pull from localhost:5001"
  echo "  Pods will start in seconds instead of minutes!"
else
  echo "⚠️  No local registry found. Run ./setup-registry.sh and ./push-images.sh first"
  echo "  Without registry, pods will pull from remote registries (slow)"
fi

echo ""
echo "=================================="
echo "Step 6/7: Installing ArgoCD"
echo "=================================="

# Install official ArgoCD manifest
ARGOCD_MANIFEST_URL="https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"
echo "Fetching official ArgoCD manifest..."
echo "URL: ${ARGOCD_MANIFEST_URL}"

if ! kubectl apply -n argocd -f "${ARGOCD_MANIFEST_URL}"; then
  echo "⚠️  Failed to download ArgoCD manifest. Check internet connection or use air-gapped install."
  exit 1
fi

echo "Waiting for ArgoCD pods to be ready (this may take 3-5 minutes on first run)..."
echo "Tip: ArgoCD images are pulled from internet once. Subsequent cluster recreations will be faster."
echo ""

# Wait with longer timeout and show progress
if ! kubectl wait --for=condition=Ready pods --all -n argocd --timeout=600s; then
  echo ""
  echo "⚠️  ArgoCD pods did not become ready within 10 minutes."
  echo "This usually means slow image pulls. Check pod status:"
  echo "  kubectl get pods -n argocd"
  echo "  kubectl describe pod -n argocd <pod-name>"
  exit 1
fi

echo "✓ ArgoCD core components installed"

echo ""
echo "=================================="
echo "Step 7/7: Bootstrap Complete!"
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
echo "5. Bootstrap GitOps (deploys all applications with sync waves):"
echo "   kubectl apply -f argocd/root-app.yaml"
echo "   This connects ArgoCD to your Git repository and deploys:"
echo "   - Wave 0: sealed-secrets, metrics-server (infrastructure)"
echo "   - Wave 1: prometheus (monitoring)"
echo "   - Wave 2: ollama (AI backend)"
echo "   - Wave 3: openwebui (AI frontend)"
echo ""
echo "6. Monitor application deployment:"
echo "   kubectl get applications -n argocd"
echo "   kubectl get pods -n ai-platform -w"
echo ""
echo "=================================="
