/*
 * Bluetooth Audio AIDL HAL service for SM-T510.
 * Loads android.hardware.bluetooth.audio-impl and registers
 * IBluetoothAudioProviderFactory/default.
 */

#define LOG_TAG "BtAudioAIDLHAL"

#include <android/binder_manager.h>
#include <android/binder_process.h>
#include <utils/Log.h>

#include "BluetoothAudioProviderFactory.h"

using ::aidl::android::hardware::bluetooth::audio::
    BluetoothAudioProviderFactory;

int main() {
    ABinderProcess_setThreadPoolMaxThreadCount(0);

    auto factory = ::ndk::SharedRefBase::make<BluetoothAudioProviderFactory>();
    const std::string instance_name =
        std::string() + BluetoothAudioProviderFactory::descriptor + "/default";

    binder_status_t aidl_status = AServiceManager_addService(
        factory->asBinder().get(), instance_name.c_str());
    if (aidl_status != STATUS_OK) {
        ALOGE("Could not register %s, status=%d", instance_name.c_str(),
              aidl_status);
        return 1;
    }

    ALOGI("Bluetooth Audio AIDL HAL registered: %s", instance_name.c_str());
    ABinderProcess_joinThreadPool();
    return 0;
}
