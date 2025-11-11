#!/bin/bash

# Setup local Docker registry for kind cluster
# This registry persists across cluster deletions and provides fast image pulls

set -e

REGISTRY_NAME="kind-registry"
REGISTRY_PORT="5001"

echo "=================================================="
echo "Setting Up Local Docker Registry"
echo "=================================================="
echo ""

# Check if registry already exists
if docker ps -a --format '{{.Names}}' | grep -q "^${REGISTRY_NAME}$"; then
  echo "ℹ️  Registry '${REGISTRY_NAME}' already exists"
  
  # Check if it's running
  if docker ps --format '{{.Names}}' | grep -q "^${REGISTRY_NAME}$"; then
    echo "✓ Registry is already running on localhost:${REGISTRY_PORT}"
  else
    echo "⚠️  Registry exists but is stopped. Starting..."
    docker start "${REGISTRY_NAME}"
    echo "✓ Registry started on localhost:${REGISTRY_PORT}"
  fi
else
  echo "Creating new Docker registry container..."
  docker run -d \
    --restart=always \
    --name "${REGISTRY_NAME}" \
    -p "${REGISTRY_PORT}:5000" \
    registry:2
  
  echo "✓ Registry created and running on localhost:${REGISTRY_PORT}"
fi

echo ""
echo "=================================================="
echo "✓ Local Registry Ready!"
echo "=================================================="
echo ""
echo "Registry URL: localhost:${REGISTRY_PORT}"
echo "Container: ${REGISTRY_NAME}"
echo ""
echo "📋 Next Steps:"
echo "1. Run: ./push-images.sh (push images to local registry)"
echo "2. Run: ./bootstrap.sh (create cluster with registry support)"
echo "3. Images will pull in seconds instead of minutes!"
echo ""
