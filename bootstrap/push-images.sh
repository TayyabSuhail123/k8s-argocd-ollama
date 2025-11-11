#!/bin/bash

# Push images to local Docker registry
# Run this once to populate the registry with required images

set -e

REGISTRY_URL="localhost:5001"

echo "=================================================="
echo "Pushing Images to Local Registry"
echo "=================================================="
echo ""

# Array of images to push: "source|destination"
declare -a IMAGES=(
  "ghcr.io/open-webui/open-webui:0.3.32|${REGISTRY_URL}/open-webui:0.3.32"
  "ollama/ollama:latest|${REGISTRY_URL}/ollama:latest"
  "python:3.11-slim|${REGISTRY_URL}/python:3.11-slim"
)

for IMAGE_PAIR in "${IMAGES[@]}"; do
  IFS='|' read -r SOURCE DEST <<< "$IMAGE_PAIR"
  
  echo "Processing: $SOURCE"
  
  # Check if source image exists locally
  if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${SOURCE}$"; then
    echo "⬇ Pulling from remote: $SOURCE"
    docker pull "$SOURCE"
  else
    echo "✓ Already in Docker cache: $SOURCE"
  fi
  
  # Tag for local registry
  echo "🏷️  Tagging as: $DEST"
  docker tag "$SOURCE" "$DEST"
  
  # Push to local registry
  echo "⬆ Pushing to local registry..."
  docker push "$DEST"
  
  echo "✓ Pushed: $DEST"
  echo ""
done

echo "=================================================="
echo "✓ All Images Pushed to Local Registry!"
echo "=================================================="
echo ""
echo "Verify images in registry:"
echo "  curl http://localhost:5000/v2/_catalog"
echo ""
echo "Ready to create kind cluster with fast image pulls!"
echo ""
