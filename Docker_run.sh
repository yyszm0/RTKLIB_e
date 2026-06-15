#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Build Docker image and convert all .sbf files in data/GNSS.
#
# Directory structure:
#
# project_root/
# ├── data/
# │   └── GNSS/
# │       └── *.sbf
# └── src/
#     └── RTKLIB_e/
#         ├── Docker_run.sh
#         └── Dockerfile
# ============================================================

IMAGE_NAME="rtklib-sbf-converter"

# Docker_run.shが存在する src/RTKLIB_e
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

# src/RTKLIB_e から2階層上のプロジェクトルート
ROOT_DIR="$(cd "$PROJECT_DIR/../.." && pwd)"

# ホスト側のSBFデータディレクトリ
DATA_DIR_HOST="$ROOT_DIR/data/GNSS"

if [[ ! -d "$DATA_DIR_HOST" ]]; then
    echo "Error: GNSS data directory does not exist:"
    echo "  $DATA_DIR_HOST"
    exit 1
fi

echo "Docker project directory:"
echo "  $PROJECT_DIR"

echo "SBF data directory:"
echo "  $DATA_DIR_HOST"

docker build \
    -t "$IMAGE_NAME" \
    "$PROJECT_DIR"

docker run --rm \
    -v "$PROJECT_DIR:/work" \
    -v "$DATA_DIR_HOST:/data/GNSS" \
    -e DATA_DIR="/data/GNSS" \
    "$IMAGE_NAME"
    