#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Build Docker image and convert all .sbf files in ./data_sbf.
# ============================================================

IMAGE_NAME="rtklib-sbf-converter"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR_HOST="$PROJECT_DIR/data_sbf"

mkdir -p "$DATA_DIR_HOST"

docker build -t "$IMAGE_NAME" "$PROJECT_DIR"

docker run --rm \
    -v "$PROJECT_DIR:/work" \
    -e DATA_DIR="/work/data_sbf" \
    "$IMAGE_NAME"
