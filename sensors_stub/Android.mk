LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := sensors.exynos7904
LOCAL_MODULE_RELATIVE_PATH := hw
LOCAL_VENDOR_MODULE := true
LOCAL_SRC_FILES := sensors_wrapper.c
LOCAL_SHARED_LIBRARIES := liblog libcutils libhardware libdl
LOCAL_HEADER_LIBRARIES := libhardware_headers
LOCAL_MODULE_TAGS := optional
LOCAL_MULTILIB := 32
include $(BUILD_SHARED_LIBRARY)
