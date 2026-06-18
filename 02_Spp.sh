#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Run single-point positioning for every matching .obs/.nav
# pair in data/GNSS/MAIN.
#
# Input:
#   data/GNSS/MAIN/*.obs
#   data/GNSS/MAIN/*.nav
#
# Example:
#   uav__415_0616_1.obs
#   uav__415_0616_1.nav
#
# Output:
#   data/GNSS/MAIN/SPP/uav__415_0616_1.pos
#   data/GNSS/MAIN/SPP/uav__415_0616_1.pos.stat
# ============================================================

IMAGE_NAME="rtklib-sbf-converter"

# このスクリプトが存在するディレクトリ
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

# src/RTKLIB_eから2階層上
ROOT_DIR="$(cd "$PROJECT_DIR/../.." && pwd)"

DATA_DIR_HOST="$ROOT_DIR/data/GNSS"
MAIN_DIR_HOST="$DATA_DIR_HOST/MAIN"
OUTPUT_DIR_HOST="$MAIN_DIR_HOST/SPP"

if [[ ! -d "$MAIN_DIR_HOST" ]]; then
    echo "Error: MAIN directory does not exist:"
    echo "  $MAIN_DIR_HOST"
    exit 1
fi

if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "Error: Docker image does not exist:"
    echo "  $IMAGE_NAME"
    echo
    echo "Build it first:"
    echo "  ./00_DockerBuild.sh"
    exit 1
fi

mkdir -p "$OUTPUT_DIR_HOST"

echo "Docker image:"
echo "  $IMAGE_NAME"

echo "Input directory:"
echo "  $MAIN_DIR_HOST"

echo "Output directory:"
echo "  $OUTPUT_DIR_HOST"

echo

docker run --rm \
    --entrypoint /bin/bash \
    -v "$DATA_DIR_HOST:/data/GNSS" \
    "$IMAGE_NAME" \
    -c '
set -euo pipefail

INPUT_DIR="/data/GNSS/MAIN"
OUTPUT_DIR="/data/GNSS/MAIN/SPP"

mkdir -p "$OUTPUT_DIR"

if ! command -v rnx2rtkp >/dev/null 2>&1; then
    echo "Error: rnx2rtkp was not found in the Docker image."
    exit 1
fi

shopt -s nullglob

obs_files=("$INPUT_DIR"/*.obs)

if (( ${#obs_files[@]} == 0 )); then
    echo "Error: no .obs files were found:"
    echo "  $INPUT_DIR"
    exit 1
fi

processed=0
missing_nav=0
failed=0

for obs_file in "${obs_files[@]}"; do
    filename="$(basename "$obs_file")"
    base_name="${filename%.obs}"

    nav_file="$INPUT_DIR/${base_name}.nav"
    pos_file="$OUTPUT_DIR/${base_name}.pos"

    echo "------------------------------------------------------------"
    echo "Dataset:"
    echo "  $base_name"

    if [[ ! -f "$nav_file" ]]; then
        echo "Warning: matching .nav file was not found:"
        echo "  OBS: $obs_file"
        echo "  NAV: $nav_file"

        missing_nav=$((missing_nav + 1))
        continue
    fi

    echo "OBS:"
    echo "  $obs_file"

    echo "NAV:"
    echo "  $nav_file"

    echo "Output:"
    echo "  $pos_file"

    if rnx2rtkp \
        -p 0 \
        -sys GRE \
        -y 2 \
        -o "$pos_file" \
        "$obs_file" \
        "$nav_file"
    then
        echo "Completed:"
        echo "  $pos_file"

        processed=$((processed + 1))
    else
        echo "Error: positioning failed:"
        echo "  $base_name"

        failed=$((failed + 1))
    fi
done

echo
echo "============================================================"
echo "Single-point positioning completed"
echo "============================================================"
echo "Processed   : $processed"
echo "Missing NAV : $missing_nav"
echo "Failed      : $failed"
echo "Output      : $OUTPUT_DIR"

if (( failed > 0 )); then
    exit 1
fi
'
