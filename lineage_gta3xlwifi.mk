$(call inherit-product, device/samsung/gta3xlwifi/full_gta3xlwifi.mk)

# Inherit some common Lineage stuff
$(call inherit-product, vendor/lineage/config/common_full_tablet_wifionly.mk)

PRODUCT_NAME := lineage_gta3xlwifi

# Build fingerprint
BUILD_FINGERPRINT := "samsung/gta3xlwifixx/gta3xlwifi:11/RP1A.200720.012/T510XXU5CWA1:user/release-keys"
