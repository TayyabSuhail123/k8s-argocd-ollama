#!/bin/bash

# Script to generate OpenWebUI sealed secret
# This script creates a sealed secret with a random WEBUI_SECRET_KEY

set -e

kubectl create secret generic openwebui-secret \
  --from-literal=WEBUI_SECRET_KEY=$(openssl rand -base64 32) \
  --dry-run=client -o yaml -n ai-platform | \
  kubeseal --controller-namespace=kube-system \
           --controller-name=sealed-secrets-controller \
           --format=yaml \
  > charts/openwebui/templates/sealedsecret.yaml

echo "✓ Sealed secret created: charts/openwebui/templates/sealedsecret.yaml"
