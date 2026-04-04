#!/bin/bash
# Build DTBO image for Samsung SM-T510 (gta3xlwifi)
#
# Samsung's bootloader matches DTBO entries by hw_rev using custom[0]/custom[1]
# fields in the dt_table_entry header. Without these, the bootloader can't find
# a matching overlay and boot fails.
#
# Stock SM-T510 hw_rev mapping (from GPIO straps):
#   Entry 0: hw_rev 3-3   (gta3xlwifi_eur_open_03)
#   Entry 1: hw_rev 4-255 (gta3xlwifi_eur_open_04)
#
# All production SM-T510 units have hw_rev >= 3.

set -e

KERNEL_OUT="${1:?Usage: build_dtbo.sh <kernel_out_dir> <output_dtbo.img>}"
OUTPUT="${2:?Usage: build_dtbo.sh <kernel_out_dir> <output_dtbo.img>}"
MKDTBOIMG="${ANDROID_BUILD_TOP}/system/libufdt/utils/src/mkdtboimg.py"
DTBO_DIR="${KERNEL_OUT}/arch/arm64/boot/dts/exynos/dtbo"

python3 "${MKDTBOIMG}" create "${OUTPUT}" \
  --page_size=2048 --version=0 \
  "${DTBO_DIR}/exynos7904-gta3xlwifi_eur_open_03.dtbo" --custom0=3 --custom1=3 \
  "${DTBO_DIR}/exynos7904-gta3xlwifi_eur_open_04.dtbo" --custom0=4 --custom1=255

echo "Built DTBO: $(ls -la "${OUTPUT}")"
