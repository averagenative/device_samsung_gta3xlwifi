# Camera ISP Firmware & HAL Bringup — SM-T510 (Exynos 7904)

## Summary

Getting the camera working on the SM-T510 (gta3xlwifi) LineageOS 20 port required solving multiple layered problems spanning kernel drivers, vendor HAL blobs, Android framework enforcement, and DTBO configuration. This document captures the full implementation flow.

## Hardware

| Component | Detail |
|-----------|--------|
| SoC | Samsung Exynos 7904 (universal7904) |
| Rear Camera | Samsung S5K4HA (8MP, sensor_id=39) |
| Front Camera | Samsung S5K5E9 (5MP, sensor_id=41) |
| ISP | Samsung FIMC-IS (Flexible Image Capture) |
| ISP Firmware | `fimc_is_lib.bin` (DDK+VRA) + `fimc_is_rta.bin` (RTA) |
| Kernel | 4.4.302 (Samsung downstream BSP) |

## Implementation Flow (in order of discovery)

### 1. DDK Firmware CDH_SIZE Skip

**Problem:** ISP DDK firmware crashed with NULL pointer at DDK_LIB_ADDR+0x640 during startup.

**Root cause:** The kernel has two ISP driver trees — `fimc-legacy` (binary loading) and `fimc-is2` (memory allocation). fimc-is2 skips a 128K CDH (Camera Debug Helper) header when loading the DDK binary, but fimc-legacy didn't.

**Fix:** Added CDH_SIZE (SZ_128K) skip to fimc-legacy's `fimc_is_load_ddk_bin()` memcpy, and aligned all memory layout defines (VRA_LIB_SIZE, DDK_LIB_SIZE, etc.) between the two drivers.

**Files changed:**
- `drivers/media/platform/exynos/fimc-legacy/include/fimc-is-binary.h`
- `drivers/media/platform/exynos/fimc-legacy/interface/fimc-is-interface-library.h`
- `drivers/media/platform/exynos/fimc-legacy/interface/fimc-is-interface-library.c`

### 2. Custom DTBOs (CCIC S2MM005 Removal)

**Problem:** Compiled DTBOs crashed the device on boot. Had been using stock DTBOs which lacked camera DT fragments.

**Root cause:** DTBO variants `_03` and `_04` included `ccic-s2mm005_gta3xllte_00.dtsi` — a USB-C Power Delivery chip overlay for the S2MM005. The SM-T510 has micro-USB, not USB-C. The chip doesn't exist, and probing it crashed the device.

**Fix:** Removed `#include "ccic-s2mm005_gta3xllte_00.dtsi"` from both DTS files. Compiled DTBOs now include camera sensor DT fragments (S5K4HA rear, S5K5E9 front) without crashing.

**Files changed:**
- `arch/arm64/boot/dts/exynos/dtbo/exynos7904-gta3xlwifi_eur_open_03.dts`
- `arch/arm64/boot/dts/exynos/dtbo/exynos7904-gta3xlwifi_eur_open_04.dts`

### 3. Camera Vendor HAL Blobs

**Problem:** Camera HAL reported 0 cameras — `camera.exynos7904.so` (CameraWrapper) called `hw_get_module_by_class("camera", "vendor")` but the underlying Samsung ExynosCamera HAL wasn't installed.

**Root cause:** Missing vendor blobs. The SamarV-121 device tree had `camera.vendor.so` in the tree but it wasn't installed, and `libexynoscamera3.so` (1.5MB, the actual Samsung camera HAL implementation) plus 8 dependencies were completely absent.

**Fix:** Extracted from stock firmware (T510XXU5CWA1):
- `camera.vendor.universal7904.so` — stock Samsung camera module (renamed for `hw_get_module_by_class` lookup via `ro.product.board`)
- `libexynoscamera3.so` — main ExynosCamera HAL implementation
- `libhwjpeg.so`, `libcsc.so`, `libuniplugin.so`, `libsensorlistener.so`, `libuniapi.so`, `libSEF.quram.so`, `libgiantmscl.so` — dependencies
- `libsensorndkbridge.so` — stock version (has Samsung's `ALooper_forCamera` symbol)
- `android.frameworks.sensorservice@1.0.vendor` — needed by stock libsensorndkbridge

### 4. CameraWrapper Fixes

**Problem:** Multiple crashes in the CameraWrapper (`camera.exynos7904.so`):

a. **`camera_open_legacy` SIGSEGV** — Provider called `openLegacy()` which tried Camera2 API on a Camera3-only vendor HAL. Fixed by returning `-EOPNOTSUPP`.

b. **`camera.vendor.so` naming** — `hw_get_module_by_class("camera", "vendor")` looks for `camera.vendor.<variant>.so`, not `camera.vendor.so`. Renamed to `camera.vendor.universal7904.so` to match `ro.product.board`.

c. **Metadata sanitization** — Samsung vendor tags (tag >= 0x80000000) in camera metadata corrupt Java-side `CameraCharacteristics` parsing. Added `sanitize_camera_metadata()` to strip vendor tags from static characteristics and `construct_default_request_settings`.

d. **Vendor tag ops** — Set `get_vendor_tag_ops = camera_get_vendor_tag_ops` (pass-through) so the framework's vendor tag descriptor is populated.

### 5. Binder Parcel Enforcement Fix

**Problem:** `BadParcelableException: Parcel data not fully consumed, unread size: 4` on `submitRequestList`. ALL camera apps crashed.

**Root cause:** Android 13 added `enforceNoDataAvail()` to both Java `Parcel.java` and C++ `Parcel.cpp`. Samsung's vendor HAL (from Android 11) includes 4 extra bytes in binder responses that the stricter Android 13 checking rejects. Android 11 silently ignored these.

**Fix:** Changed `enforceNoDataAvail()` to log-and-continue instead of throw, in BOTH:
- `frameworks/base/core/java/android/os/Parcel.java` (Java side)
- `frameworks/native/libs/binder/Parcel.cpp` (C++ side — the one the cameraserver actually uses)

**Critical note:** Must wipe dalvik cache after flashing for the Java framework change to take effect.

### 6. ISP Chain Module ID Mapping

**Problem:** `fimc_is_ischain_init_wrap: moduel id(0) is invalid` — HAL passes camera position (0=rear) but fimc-legacy expected sensor_id (39=S5K4HA).

**Root cause:** fimc-is2 maps position → sensor_id via `priv->rear_sensor_id`, but fimc-legacy directly compared `module_id == module->sensor_id`.

**Fix:** Ported fimc-is2's position-to-sensor_id mapping into fimc-legacy's `fimc_is_ischain_init_wrap()`.

### 7. Switch to fimc-is2 (THE KEY FIX)

**Problem:** `WRAP_GetSensorDriver[3456]: invalid moduleID(39)!!!` — DDK firmware binary couldn't find sensor driver for S5K4HA.

**Root cause:** The DDK binary (`fimc_is_lib.bin`) was compiled for fimc-is2's `set_os_system_funcs` function table. fimc-legacy provided a different function table (missing `funcs[49]` fd_data, `funcs[50]` hybrid_fd_data, `funcs[91]` binary_version, and others). The DDK's internal sensor driver table couldn't initialize without these functions.

**Fix:** Switched kernel config from `CONFIG_VIDEO_EXYNOS_FIMC_LEGACY=y` to `CONFIG_VIDEO_EXYNOS_FIMC_IS2=y` (and `CONFIG_VENDER_MCD_V2=y`). This gives the DDK binary the exact initialization sequence and function table it was designed for.

**This was the final camera fix.** The CDH_SIZE alignment work done on fimc-legacy was already present in fimc-is2 (that's where we copied it from). The `reserve-fimc=` memory allocation was already handled by fimc-is2.

## Current Status

- **Rear camera (S5K4HA):** Working — preview, capture, photo saving all functional via Open Camera
- **Front camera (S5K5E9):** Not working — GPIO power-on fails (`exynos_fimc_is_sensor_gpio(1) fail(-19)`)
- **Aperture (CameraX):** Crashes due to `lensFacingInteger: null` from vendor tag metadata. Open Camera (Camera2 API direct) works fine as alternative.
- **Preview FPS:** Low — needs optimization of sensor mode / ISP pipeline configuration

## Lessons Learned

1. **Two ISP drivers coexist** — fimc-legacy and fimc-is2 must be aligned or you must choose one
2. **DDK binary is driver-specific** — compiled for fimc-is2's function table, won't work with fimc-legacy
3. **CCIC overlays crash WiFi-only models** — S2MM005 USB-PD chip doesn't exist on micro-USB devices
4. **Android 13 Parcel strictness** — `enforceNoDataAvail()` breaks Samsung Android 11 vendor HALs
5. **Camera HAL naming matters** — `hw_get_module_by_class` uses property-based variant lookup
6. **Vendor tags corrupt metadata** — must sanitize or properly register Samsung's SecCameraVendorTags
