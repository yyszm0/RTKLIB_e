#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Convert all Septentrio SBF files under data_sbf/ to RINEX.
#
# Input directory inside mounted project:
#   /work/data_sbf
#
# Output:
#   /work/data_sbf/MAIN/*.obs, *.nav
#   /work/data_sbf/AUX1/*.obs
#
# Classification rule:
#   filename containing "aux1" or "AUX1" -> AUX1
#   all others                         -> MAIN
# ============================================================

DATA_DIR="${DATA_DIR:-/work/data_sbf}"
MAIN_DIR="${MAIN_DIR:-${DATA_DIR}/MAIN}"
AUX1_DIR="${AUX1_DIR:-${DATA_DIR}/AUX1}"

# Optional time filter. Example:
#   START_TIME="2026/06/11 07:44:40"
#   END_TIME="2026/06/11 08:00:00"
START_TIME="${START_TIME:-}"
END_TIME="${END_TIME:-}"

# Optional RINEX version. 3.04 is a safe default for multi-GNSS.
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

mapfile -d '' SBF_FILES < <(find "$DATA_DIR" -type f \( -iname '*.sbf' -o -iname '*.SBF' \) \
    ! -path "$MAIN_DIR/*" \
    ! -path "$AUX1_DIR/*" \
    -print0 | sort -z)

if [ "${#SBF_FILES[@]}" -eq 0 ]; then
    echo "No .sbf files found under: $DATA_DIR"
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

    lower="$(printf '%s' "$base" | tr '[:upper:]' '[:lower:]')"

    if [[ "$lower" == *aux1* ]]; then
        out_obs="$AUX1_DIR/${stem}.obs"
        echo "[AUX1] $sbf"
        echo "       -> $out_obs"

        mapfile -d '' TIME_ARGS < <(build_time_args)
        convbin \
            -r sbf \
            -v "$RINEX_VERSION" \
            "${TIME_ARGS[@]}" \
            -o "$out_obs" \
            "$sbf"

        # AUX1 only needs .obs. Remove nav-like files if convbin created them.
        rm -f "$AUX1_DIR/${stem}.nav" \
              "$AUX1_DIR/${stem}.gnav" \
              "$AUX1_DIR/${stem}.hnav" \
              "$AUX1_DIR/${stem}.qnav" \
              "$AUX1_DIR/${stem}.lnav" \
              "$AUX1_DIR/${stem}.sbs"
    else
        out_obs="$MAIN_DIR/${stem}.obs"
        out_nav="$MAIN_DIR/${stem}.nav"
        echo "[MAIN] $sbf"
        echo "       -> $out_obs"
        echo "       -> $out_nav"

        mapfile -d '' TIME_ARGS < <(build_time_args)
        convbin \
            -r sbf \
            -v "$RINEX_VERSION" \
            "${TIME_ARGS[@]}" \
            -o "$out_obs" \
            -n "$out_nav" \
            "$sbf"
    fi
    echo
done

echo "Done."
