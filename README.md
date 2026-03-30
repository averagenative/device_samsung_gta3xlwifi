# LineageOS 20 for Samsung Galaxy Tab A 10.1 (2019) — SM-T510

Native (non-GSI) LineageOS 20 (Android 13) port for the Samsung SM-T510 WiFi-only tablet (codename: **gta3xlwifi**, SoC: Exynos 7904).

## Status

| Feature | Status | Notes |
|---------|--------|-------|
| Boot / Stability | Working | Daily-driver stable |
| Display | Working | 10.1" 1920x1200 TFT LCD |
| Touchscreen | Working | STMicro FTS1BA90A, firmware built into kernel |
| WiFi | Working | Samsung SCSC/WLBT Maxwell MX140 |
| Bluetooth scanning | Working | Discovers, pairs, connects |
| BT A2DP audio | Working | HIDL passthrough HAL |
| Rear camera | Working | S5K4HA 8MP, via Open Camera (Camera2 API) |
| Front camera | Partial | S5K5E9, works briefly then drops (GPIO timing) |
| Web browsing | Working | |
| USB / ADB | Working | |
| Speakers | Untested | Dual TFA9896 + SMA1301 codec initializes |
| Auto-rotate | Not working | Accelerometer driver loads but sensor HAL doesn't read it |
| Touch to wake | Not working | FTS driver enters deep sleep instead of low-power mode |
| BT keyboard/HID | Not working | UHID polling thread race condition (patch included) |
| GApps | Not tested | MindTheGapps arm64 zip fails TWRP arch check |
| Aperture (CameraX) | Crashes | Vendor tag metadata issue; use Open Camera instead |
| SELinux | Permissive | Needs proper allow rules |

## Repositories

| Repository | Branch | Description |
|------------|--------|-------------|
| [device_samsung_gta3xlwifi](https://github.com/averagenative/device_samsung_gta3xlwifi) | `lineage-20` | Device tree (this repo) |
| [android_device_samsung_universal7904-common](https://github.com/averagenative/android_device_samsung_universal7904-common) | `lineage-20` | Common device tree (camera wrapper, HAL configs) |
| [android_kernel_samsung_universal7904](https://github.com/averagenative/android_kernel_samsung_universal7904) | `lineage-20` | Kernel (4.4.302, fimc-is2 ISP, sensor drivers) |
| vendor_samsung_universal7904-common | `lineage-19.1` | Vendor blobs (fork of SamarV-121, camera blobs added) |

## Build Instructions

### Prerequisites

- ~400GB disk, 16GB+ RAM, multi-core CPU
- LineageOS 20 source tree synced
- Physical SM-T510 with unlocked bootloader and TWRP

### 1. Sync device repos

```bash
# In your LineageOS source root
git clone https://github.com/averagenative/device_samsung_gta3xlwifi -b lineage-20 device/samsung/gta3xlwifi
git clone https://github.com/averagenative/android_device_samsung_universal7904-common -b lineage-20 device/samsung/universal7904-common
git clone https://github.com/averagenative/android_kernel_samsung_universal7904 -b lineage-20 kernel/samsung/universal7904
# Vendor blobs (from SamarV-121 + camera additions)
# git clone <your-vendor-fork> -b lineage-19.1 vendor/samsung/universal7904-common
```

### 2. Sync LineageOS-UL framework repos

LineageOS-UL provides framework patches for kernel 4.4 compatibility (eBPF, netd, etc.):

```bash
# Replace upstream AOSP repos with LineageOS-UL lineage-20.0 branches
# See: https://github.com/LineageOS-UL (54 repos)
```

### 3. Apply patches

```bash
device/samsung/gta3xlwifi/patches/apply-patches.sh
```

This applies required patches to:
- `frameworks/base` — Parcel.java: relax `enforceNoDataAvail()` for Samsung vendor HAL
- `frameworks/native` — Parcel.cpp: same fix for native binder (cameraserver)
- `packages/modules/Bluetooth` — Fix BT HID keyboard UHID polling thread race

### 4. Build

```bash
source build/envsetup.sh
lunch lineage_gta3xlwifi-userdebug
mka bacon
```

### 5. Flash

1. Boot into TWRP (Power + Volume Up from powered off state)
2. **Wipe > Format Data** (first time only)
3. Push ROM zip: `adb push out/target/product/gta3xlwifi/lineage-20.0-*.zip /sdcard/`
4. TWRP Install > select zip > swipe to flash
5. Wipe dalvik cache (Wipe > Advanced > Dalvik/ART Cache)
6. Reboot

**Note:** Stock DTBO flash is no longer needed — compiled DTBOs with camera config are included in the ROM.

### 6. Install Open Camera

The default Aperture app (CameraX) crashes due to Samsung vendor tag metadata. Use Open Camera instead:

```bash
adb install opencamera.apk
adb shell pm grant net.sourceforge.opencamera android.permission.CAMERA
```

## Key Technical Decisions

### Camera: fimc-is2 over fimc-legacy

The Exynos 7904 kernel has two ISP driver trees: `fimc-legacy` and `fimc-is2`. The stock DDK firmware binary (`fimc_is_lib.bin`) was compiled for fimc-is2's function table and initialization sequence. Using fimc-legacy caused `WRAP_GetSensorDriver: invalid moduleID` because the DDK couldn't initialize its sensor driver table.

**Solution:** `CONFIG_VIDEO_EXYNOS_FIMC_IS2=y` in the kernel defconfig. See [docs/camera-isp-firmware.md](docs/camera-isp-firmware.md) for the full camera bringup story.

### Binder Parcel enforcement

Android 13 added strict `enforceNoDataAvail()` checks in both Java and C++ Parcel classes. Samsung's vendor camera HAL (from Android 11) includes 4 extra bytes in binder responses that this check rejects. The patches relax this to log-and-continue, matching Android 11/12 behavior.

### DTBO: CCIC S2MM005 removal

The SM-T510 has micro-USB, not USB-C. DTBO variants `_03` and `_04` included an overlay for the S2MM005 USB-C Power Delivery chip which doesn't exist on this device. Probing it crashed the bootloader. Removing the CCIC include enables compiled DTBOs with camera sensor DT fragments.

## Device Specifications

| Property | Value |
|----------|-------|
| Model | SM-T510 (WiFi-only) |
| Codename | gta3xlwifi |
| SoC | Samsung Exynos 7904 (universal7904) |
| Arch | ARM64 |
| Kernel | 4.4.302 |
| Display | 10.1" 1920x1200 TFT LCD (HX8279D) |
| WiFi/BT | Samsung SCSC/WLBT Maxwell MX140 |
| Touch | STMicroelectronics FTS1BA90A |
| Rear Camera | Samsung S5K4HA (8MP) |
| Front Camera | Samsung S5K5E9 (5MP) |
| Speakers | Dual TFA9896 + SMA1301 |
| Storage | 64GB eMMC + microSD |
| Last stock firmware | T510XXU5CWA1 (Android 11) |

## Credits

- **[SamarV-121](https://github.com/SamarV-121)** — Exynos 7904 platform base (kernel, common device tree, vendor blobs)
- **[LineageOS-UL](https://github.com/LineageOS-UL)** — Framework patches for kernel 4.4 compatibility
- **[gta3xlwifi-dev](https://github.com/gta3xlwifi-dev)** — Earlier SM-T510 LineageOS work (19.1 base)
- **LineageOS** — Android 13 framework and build system
