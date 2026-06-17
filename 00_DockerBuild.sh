#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Build the RTKLIB SBF converter Docker image.
# ============================================================

IMAGE_NAME="rtklib-sbf-converter"

# このスクリプトが存在する src/RTKLIB_e
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Docker project directory:"
echo "  $PROJECT_DIR"

echo "Docker image:"
echo "  $IMAGE_NAME"

docker build \
    -t "$IMAGE_NAME" \
    "$PROJECT_DIR"

echo "Docker image build completed:"
echo "  $IMAGE_NAME"
