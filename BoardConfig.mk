DEVICE_PATH := device/samsung/gta3xlwifi

# Inherit common board flags FIRST, then override
include device/samsung/universal7904-common/BoardConfigCommon.mk

# Bluetooth
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := $(DEVICE_PATH)/bluetooth

# Display — override common tree's 420 for 10.1" tablet
TARGET_SCREEN_DENSITY := 240

# Kernel
BOARD_KERNEL_CMDLINE := androidboot.force_normal_boot=1
TARGET_KERNEL_CONFIG := gta3xlwifi_defconfig
# Samsung SM-T510 bootloader requires dt_size=1 in boot.img header.
# dt_size=0 or dt_size=4096 causes bootloader DABT crash.
# Use a 1-byte dummy file as --dt to set dt_size=1.
# The bootloader loads DTB/DTBO from their dedicated partitions instead.
BOARD_CUSTOM_BOOTIMG_MK := hardware/samsung/mkbootimg.mk
BOARD_MKBOOTIMG_ARGS += --dt $(DEVICE_PATH)/dt_dummy.img --board SRPSA25A003RU

# Partitions
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 3196059648
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 39845888
BOARD_VENDORIMAGE_PARTITION_SIZE := 343932928

BOARD_ROOT_EXTRA_SYMLINKS := \
    /mnt/vendor/efs:/efs \
    /mnt/vendor/efs:/factory

# Recovery
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.exynos7904

# Samsung bootloader loads ramdisk from recovery partition.
# Flash boot.img to recovery during OTA install.
TARGET_RELEASETOOLS_EXTENSIONS := $(DEVICE_PATH)

# Fingerprint — SM-T510 has no fingerprint sensor
TARGET_HAS_NO_FINGERPRINT := true

# Sepolicy
BOARD_SEPOLICY_TEE_FLAVOR := mobicore
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor

# SPL
VENDOR_SECURITY_PATCH := 2023-02-01
BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/dtbo_prebuilt.img
