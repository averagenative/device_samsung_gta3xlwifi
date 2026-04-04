# Custom releasetools for Samsung SM-T510 (gta3xlwifi)
#
# Samsung bootloader loads ramdisk from recovery partition,
# so we must flash boot.img to both boot AND recovery.
#
# Also flash our stock DTBO (Samsung T510XXU5CWA1 firmware).
# Custom-compiled DTBOs crash during UFDT overlay in the bootloader.

import common
import os

def FullOTA_InstallEnd(info):
    # Flash boot.img to recovery partition (Samsung loads ramdisk from here)
    info.script.AppendExtra(
        'package_extract_file("boot.img", '
        '"/dev/block/platform/13500000.dwmmc0/by-name/recovery");')

    # Include and flash stock DTBO
    dtbo_path = os.path.join(info.input_tmp, "IMAGES", "dtbo.img")
    if not os.path.exists(dtbo_path):
        dtbo_path = os.path.join(info.input_tmp, "PREBUILT_IMAGES", "dtbo.img")
    if os.path.exists(dtbo_path):
        common.ZipWrite(info.output_zip, dtbo_path, "dtbo.img")
        info.script.AppendExtra(
            'package_extract_file("dtbo.img", '
            '"/dev/block/platform/13500000.dwmmc0/by-name/dtbo");')
