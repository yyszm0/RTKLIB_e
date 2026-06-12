#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Convert all Septentrio SBF files directly under data_sbf/ to RINEX.
#
# Input:
#   /work/data_sbf/*.sbf
#
# Output:
#   /work/data_sbf/MAIN/*.obs, *.nav
#   /work/data_sbf/AUX1/*.obs
#
# Important:
#   One SBF contains both MAIN and AUX1 data.
#   Therefore, each SBF is converted twice:
#     1) default antenna -> MAIN
#     2) -ro "-AUX1"    -> AUX1
# ============================================================

DATA_DIR="${DATA_DIR:-/work/data_sbf}"
MAIN_DIR="${MAIN_DIR:-${DATA_DIR}/MAIN}"
AUX1_DIR="${AUX1_DIR:-${DATA_DIR}/AUX1}"

START_TIME="${START_TIME:-}"
END_TIME="${END_TIME:-}"
RINEX_VERSION="${RINEX_VERSION:-3.04}"

mkdir -p "$MAIN_DIR" "$AUX1_DIR"

if ! command -v convbin >/dev/null 2>&1; then
    echo "ERROR: convbin was not found in PATH" >&2
    exit 1
fi

if [ ! -d "$DATA_DIR" ]; then
    echo "ERROR: DATA_DIR does not exist: $DATA_DIR" >&2
    echo "Create data_sbf/ and put .sbf files there." >&2
    exit 1
fi

# data_sbf直下のSBFだけ対象にする
mapfile -d '' SBF_FILES < <(
    find "$DATA_DIR" -maxdepth 1 -type f \( -iname '*.sbf' -o -iname '*.SBF' \) -print0 | sort -z
)

if [ "${#SBF_FILES[@]}" -eq 0 ]; then
    echo "No .sbf files found directly under: $DATA_DIR"
    exit 0
fi

echo "DATA_DIR : $DATA_DIR"
echo "MAIN_DIR : $MAIN_DIR"
echo "AUX1_DIR : $AUX1_DIR"
echo "RINEX    : $RINEX_VERSION"
if [ -n "$START_TIME" ] || [ -n "$END_TIME" ]; then
    echo "TIME     : ${START_TIME:-beginning} -> ${END_TIME:-end}"
fi
echo

build_time_args() {
    local args=()
    if [ -n "$START_TIME" ]; then
        args+=("-ts" "$START_TIME")
    fi
    if [ -n "$END_TIME" ]; then
        args+=("-te" "$END_TIME")
    fi
    printf '%s\0' "${args[@]}"
}

for sbf in "${SBF_FILES[@]}"; do
    base="$(basename "$sbf")"
    stem="${base%.*}"

    main_obs="$MAIN_DIR/${stem}.obs"
    main_nav="$MAIN_DIR/${stem}.nav"
    aux1_obs="$AUX1_DIR/${stem}.obs"

    mapfile -d '' TIME_ARGS < <(build_time_args)

    echo "[MAIN] $sbf"
    echo "       -> $main_obs"
    echo "       -> $main_nav"

    convbin \
        -r sbf \
        -v "$RINEX_VERSION" \
        "${TIME_ARGS[@]}" \
        -o "$main_obs" \
        -n "$main_nav" \
        "$sbf"

    echo

    echo "[AUX1] $sbf"
    echo "       -> $aux1_obs"

    convbin \
        -r sbf \
        -v "$RINEX_VERSION" \
        -ro "-AUX1" \
        "${TIME_ARGS[@]}" \
        -o "$aux1_obs" \
        "$sbf"

    # AUX1ではobsだけ残す
    rm -f "$AUX1_DIR/${stem}.nav" \
          "$AUX1_DIR/${stem}.gnav" \
          "$AUX1_DIR/${stem}.hnav" \
          "$AUX1_DIR/${stem}.qnav" \
          "$AUX1_DIR/${stem}.lnav" \
          "$AUX1_DIR/${stem}.sbs"

    echo
done

echo "Done."
