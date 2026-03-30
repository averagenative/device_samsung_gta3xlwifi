# Custom releasetools for Samsung SM-T510 (gta3xlwifi)
#
# Samsung bootloader loads ramdisk from recovery partition,
# so we must flash boot.img to both boot AND recovery.
#
# Also flash our DTBO to match the kernel version (stock DTBO
# from 4.4.177 has incompatible battery aging data that causes
# a kernel BUG in s2mu005_fuelgauge).

import common

def FullOTA_InstallEnd(info):
    # Flash boot.img to recovery partition (Samsung loads ramdisk from here)
    info.script.AppendExtra(
        'package_extract_file("boot.img", '
        '"/dev/block/platform/13500000.dwmmc0/by-name/recovery");')

    # Flash DTBO to match our kernel
    info.script.AppendExtra(
        'package_extract_file("dtbo_prebuilt.img", '
        '"/dev/block/platform/13500000.dwmmc0/by-name/dtbo");')
