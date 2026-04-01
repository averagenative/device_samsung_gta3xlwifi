/*
 * Sensor HAL wrapper for Samsung sensors.exynos7904.so
 *
 * The stock Samsung sensor HAL reports API version 1.4 but doesn't
 * implement set_operation_mode(), which Android 13 requires.
 * This wrapper loads the stock HAL and adds the missing function.
 */

#define LOG_TAG "SensorsWrapper"

#include <dlfcn.h>
#include <errno.h>
#include <string.h>
#include <cutils/log.h>
#include <hardware/sensors.h>

static struct sensors_module_t *gVendorModule = NULL;

static int load_vendor_module(void)
{
    void *handle;
    struct sensors_module_t *module;

    if (gVendorModule)
        return 0;

    /* Load the stock Samsung sensor HAL directly by path */
    handle = dlopen("/vendor/lib/hw/sensors.vendor.exynos7904.so",
                    RTLD_NOW | RTLD_LOCAL);
    if (!handle) {
        handle = dlopen("/vendor/lib64/hw/sensors.vendor.exynos7904.so",
                        RTLD_NOW | RTLD_LOCAL);
    }
    if (!handle) {
        ALOGE("Failed to load vendor sensor HAL: %s", dlerror());
        return -EINVAL;
    }

    module = (struct sensors_module_t *)dlsym(handle, HAL_MODULE_INFO_SYM_AS_STR);
    if (!module) {
        ALOGE("Failed to find HAL_MODULE_INFO_SYM: %s", dlerror());
        dlclose(handle);
        return -EINVAL;
    }

    gVendorModule = module;
    ALOGI("Loaded vendor sensor HAL: %s", module->common.name);
    return 0;
}

static int wrapper_get_sensors_list(struct sensors_module_t *module __unused,
                                     struct sensor_t const **list)
{
    if (load_vendor_module())
        return 0;
    return gVendorModule->get_sensors_list(gVendorModule, list);
}

static int wrapper_set_operation_mode(unsigned int mode)
{
    /* Stock Samsung HAL doesn't implement this.
     * Return 0 for normal mode, -EINVAL for unsupported modes. */
    if (mode == 0)
        return 0;
    return -EINVAL;
}

static int wrapper_open(const struct hw_module_t *module __unused,
                        const char *id,
                        struct hw_device_t **device)
{
    if (load_vendor_module())
        return -EINVAL;
    return gVendorModule->common.methods->open(
        (const struct hw_module_t *)gVendorModule, id, device);
}

static struct hw_module_methods_t wrapper_module_methods = {
    .open = wrapper_open,
};

struct sensors_module_t HAL_MODULE_INFO_SYM = {
    .common = {
        .tag = HARDWARE_MODULE_TAG,
        .module_api_version = SENSORS_MODULE_API_VERSION_0_1,
        .hal_api_version = HARDWARE_HAL_API_VERSION,
        .id = SENSORS_HARDWARE_MODULE_ID,
        .name = "Samsung Sensor HAL Wrapper",
        .author = "gta3xlwifi",
        .methods = &wrapper_module_methods,
    },
    .get_sensors_list = wrapper_get_sensors_list,
    .set_operation_mode = wrapper_set_operation_mode,
};
