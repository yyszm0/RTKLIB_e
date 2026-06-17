#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Convert all .sbf files in data/GNSS using the existing
# RTKLIB SBF converter Docker image.
#
# Directory structure:
#
# project_root/
# ├── data/
# │   └── GNSS/
# │       └── *.sbf
# └── src/
#     └── RTKLIB_e/
#         ├── Docker_build.sh
#         ├── Docker_run.sh
#         └── Dockerfile
# ============================================================

IMAGE_NAME="rtklib-sbf-converter"

# このスクリプトが存在する src/RTKLIB_e
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

# src/RTKLIB_eから2階層上のプロジェクトルート
ROOT_DIR="$(cd "$PROJECT_DIR/../.." && pwd)"

# ホスト側のSBFデータディレクトリ
DATA_DIR_HOST="$ROOT_DIR/data/GNSS"

if [[ ! -d "$DATA_DIR_HOST" ]]; then
    echo "Error: GNSS data directory does not exist:"
    echo "  $DATA_DIR_HOST"
    exit 1
fi

# Dockerイメージが存在するか確認
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "Error: Docker image does not exist:"
    echo "  $IMAGE_NAME"
    echo
    echo "Run the build script first:"
    echo "  ./Docker_build.sh"
    exit 1
fi

echo "Docker project directory:"
echo "  $PROJECT_DIR"

echo "SBF data directory:"
echo "  $DATA_DIR_HOST"

echo "Docker image:"
echo "  $IMAGE_NAME"

docker run --rm \
    -v "$PROJECT_DIR:/work" \
    -v "$DATA_DIR_HOST:/data/GNSS" \
    -e DATA_DIR="/data/GNSS" \
    "$IMAGE_NAME"
