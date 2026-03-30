#!/bin/bash
#
# Apply framework/system patches required for SM-T510 (gta3xlwifi)
# Run from the root of the LineageOS source tree.
#
# Usage: device/samsung/gta3xlwifi/patches/apply-patches.sh
#

set -e

PATCH_DIR="$(cd "$(dirname "$0")" && pwd)"
TOP="${PATCH_DIR}/../../../.."

echo "Applying gta3xlwifi patches from: ${PATCH_DIR}"

apply_patch() {
    local repo="$1"
    local patch="$2"
    local desc="$3"

    echo -n "  ${desc}... "
    if cd "${TOP}/${repo}" && git apply --check "${patch}" 2>/dev/null; then
        git apply "${patch}"
        echo "OK"
    elif cd "${TOP}/${repo}" && git apply --reverse --check "${patch}" 2>/dev/null; then
        echo "already applied"
    else
        echo "FAILED (may need manual merge)"
        return 1
    fi
}

apply_patch "frameworks/base" \
    "${PATCH_DIR}/0001-Parcel-java-relax-enforceNoDataAvail-for-Samsung-HAL.patch" \
    "Parcel.java: relax enforceNoDataAvail for Samsung vendor HAL"

apply_patch "frameworks/native" \
    "${PATCH_DIR}/0002-Parcel-cpp-relax-enforceNoDataAvail-for-Samsung-HAL.patch" \
    "Parcel.cpp: relax enforceNoDataAvail for Samsung vendor HAL"

apply_patch "packages/modules/Bluetooth" \
    "${PATCH_DIR}/0003-btif_hh-join-old-polling-thread-on-HID-reconnect.patch" \
    "btif_hh: join old polling thread on HID reconnect"

echo "Done. All patches applied."
