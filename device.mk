DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay

# Allow missing dependencies for initial build — some HAL modules
# from the common tree aren't built yet (need vendor sources)
ALLOW_MISSING_DEPENDENCIES := true

# Inherit common device configuration
$(call inherit-product, device/samsung/universal7904-common/universal7904-common.mk)

# Remove common tree packages that don't work on SM-T510
# Samsung sensors impl doesn't work with our stub — use AOSP impl
# Hardware gatekeeper needs TEE — use software gatekeeper
# Fingerprint HAL — tablet has no fingerprint sensor
PRODUCT_PACKAGES_REMOVE += \
    android.hardware.sensors@1.0-impl.samsung \
    android.hardware.gatekeeper@1.0-impl \
    android.hardware.gatekeeper@1.0-service \
    android.hardware.biometrics.fingerprint@2.3-service.samsung \
    vendor.lineage.touch@1.0-service.samsung

# Inherit vendor blobs
$(call inherit-product, vendor/samsung/gta3xlwifi/gta3xlwifi-vendor.mk)

# Bluetooth
# NOTE: Do NOT include android.hardware.bluetooth.audio-impl — it installs an
# AIDL VINTF manifest that causes the BT stack to use the AIDL path, but Android 13
# has no mechanism to run the AIDL provider in the audio HAL process (they need to
# share a session singleton). Without AIDL, the BT stack falls back to HIDL 2.0
# passthrough which is already loaded in-process by android.hardware.audio.service.
PRODUCT_PACKAGES += \
    android.hardware.bluetooth@1.1-service \
    android.hardware.bluetooth.audio@2.1-impl \
    audio.bluetooth.default \
    libbt-vendor

PRODUCT_COPY_FILES += \
    hardware/samsung_slsi/libbt/conf/bt_did.conf:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth/bt_did.conf \
    hardware/samsung_slsi/libbt/conf/bt_vendor.conf:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth/bt_vendor.conf

# BT address generation + device init
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/init.gta3xlwifi.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.gta3xlwifi.rc \
    $(LOCAL_PATH)/rootdir/etc/bt_addr_gen.sh:$(TARGET_COPY_OUT_VENDOR)/bin/bt_addr_gen.sh

# Fstab
PRODUCT_PACKAGES += \
    fstab.exynos7904 \
    fstab.ramdisk

# Sensors — use AOSP default impl (not Samsung) + stub HAL module
PRODUCT_PACKAGES += \
    android.hardware.sensors@1.0-impl \
    android.hardware.sensors@1.0-service \
    sensors.exynos7904

# Keymaster/Gatekeeper — software implementations (TEE not available with TWRP kernel)
PRODUCT_PACKAGES += \
    android.hardware.gatekeeper@1.0-service.software \
    android.hardware.keymaster@4.1-service

# Device characteristics
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := hdpi
PRODUCT_CHARACTERISTICS := tablet

# VNDK — vendor blobs from Android 12 (LOS 19.1) need VNDK v32
PRODUCT_EXTRA_VNDK_VERSIONS += 32

# Vendor blobs link against libutils-v32.so — installed via cc_prebuilt_library_shared in Android.bp
PRODUCT_PACKAGES += \
    libutils-v32

# Empty sensors multihal config (no sub-HALs, our stub provides zero sensors)
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/sensors/hals.conf:$(TARGET_COPY_OUT_VENDOR)/etc/sensors/hals.conf

# USB / ADB — legacy USB gadget has no mtp handler, use adb only
# WITH_ADB_INSECURE disables ADB authentication (needed for headless debugging)
WITH_ADB_INSECURE := true
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    persist.sys.usb.config=adb \
    service.adb.root=1

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += $(LOCAL_PATH)

# Wifi
PRODUCT_PACKAGES += \
    android.hardware.wifi@1.0-service \
    wpa_supplicant \
    hostapd \
    WifiOverlay \
    wlbtd

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/wifi/p2p_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/p2p_supplicant_overlay.conf \
    $(LOCAL_PATH)/configs/wifi/wpa_supplicant.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant.conf \
    $(LOCAL_PATH)/configs/wifi/wpa_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant_overlay.conf
