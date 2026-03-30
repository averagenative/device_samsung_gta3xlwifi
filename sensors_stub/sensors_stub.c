#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <hardware/sensors.h>

static int stub_activate(struct sensors_poll_device_t* dev __unused,
                         int handle __unused, int enabled __unused) {
    return 0;
}

static int stub_setDelay(struct sensors_poll_device_t* dev __unused,
                         int handle __unused, int64_t ns __unused) {
    return 0;
}

static int stub_poll(struct sensors_poll_device_t* dev __unused,
                     sensors_event_t* data __unused, int count __unused) {
    // Block forever — no sensors to report
    pause();
    return 0;
}

static int stub_close(struct hw_device_t* dev) {
    free(dev);
    return 0;
}

static int sensors_get_sensors_list(struct sensors_module_t* module __unused,
                                     struct sensor_t const** list) {
    *list = NULL;
    return 0;
}

static int open_sensors(const struct hw_module_t* module,
                        const char* id __unused,
                        struct hw_device_t** device) {
    struct sensors_poll_device_t* dev = calloc(1, sizeof(*dev));
    if (!dev) return -ENOMEM;

    dev->common.tag = HARDWARE_DEVICE_TAG;
    dev->common.version = SENSORS_DEVICE_API_VERSION_0_1;
    dev->common.module = (struct hw_module_t*)module;
    dev->common.close = stub_close;
    dev->activate = stub_activate;
    dev->setDelay = stub_setDelay;
    dev->poll = stub_poll;

    *device = &dev->common;
    return 0;
}

static struct hw_module_methods_t sensors_module_methods = {
    .open = open_sensors,
};

struct sensors_module_t HAL_MODULE_INFO_SYM = {
    .common = {
        .tag = HARDWARE_MODULE_TAG,
        .module_api_version = SENSORS_MODULE_API_VERSION_0_1,
        .hal_api_version = HARDWARE_HAL_API_VERSION,
        .id = SENSORS_HARDWARE_MODULE_ID,
        .name = "Stub Sensors Module",
        .author = "LineageOS gta3xlwifi",
        .methods = &sensors_module_methods,
    },
    .get_sensors_list = sensors_get_sensors_list,
};
