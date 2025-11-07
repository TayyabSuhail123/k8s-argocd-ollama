#!/bin/bash

# Install Prometheus Operator CRDs manually
# These CRDs are too large for ArgoCD to manage due to Kubernetes annotation size limits
# We use kubectl replace to avoid the 262KB annotation limit

set -e

echo "📦 Installing Prometheus Operator CRDs..."

PROMETHEUS_OPERATOR_VERSION="v0.77.1"
CRD_BASE_URL="https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${PROMETHEUS_OPERATOR_VERSION}/example/prometheus-operator-crd"

CRDS=(
  "monitoring.coreos.com_alertmanagerconfigs.yaml"
  "monitoring.coreos.com_alertmanagers.yaml"
  "monitoring.coreos.com_podmonitors.yaml"
  "monitoring.coreos.com_probes.yaml"
  "monitoring.coreos.com_prometheusagents.yaml"
  "monitoring.coreos.com_prometheuses.yaml"
  "monitoring.coreos.com_prometheusrules.yaml"
  "monitoring.coreos.com_scrapeconfigs.yaml"
  "monitoring.coreos.com_servicemonitors.yaml"
  "monitoring.coreos.com_thanosrulers.yaml"
)

for crd in "${CRDS[@]}"; do
  echo "  → Installing ${crd}..."
  # Try replace first (for updates), fallback to create
  kubectl replace -f "${CRD_BASE_URL}/${crd}" --force 2>/dev/null || \
    kubectl create -f "${CRD_BASE_URL}/${crd}"
done

echo "✅ Successfully installed all Prometheus Operator CRDs"
echo ""
echo "Installed CRDs:"
kubectl get crd | grep monitoring.coreos.com
