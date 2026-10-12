#
# Copyright (C) 2021-2022 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# ART / Dexpreopt
PRODUCT_USES_DEFAULT_ART_CONFIG := true

# Enable dexpreopt
WITH_DEXPREOPT := true
WITH_DEXPREOPT_DEBUG_INFO := false
DEX_PREOPT_DEFAULT := speed-profile
PRODUCT_SYSTEM_SERVER_COMPILER_FILTER := speed-profile

TARGET_HAS_UDFPS := true
TARGET_IS_LEGACY := true
TARGET_HAS_FM := true

# Inherit from sm8150-common
$(call inherit-product, device/xiaomi/sm8150-common/msmnile.mk)

# AAPT
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := xxhdpi

# Audio configs
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(LOCAL_PATH)/audio/,$(TARGET_COPY_OUT_VENDOR)/etc)

# Boot animation
TARGET_SCREEN_HEIGHT := 2340
TARGET_SCREEN_WIDTH := 1080

# Camera
$(call inherit-product-if-exists, device/xiaomi/miuicamera/device.mk)

PRODUCT_PACKAGES += \
    libMegviiFacepp-0.5.2 \
    libmegface \
    libmpbase_shim \
    libpiex_shim

# Camera motor
PRODUCT_PACKAGES += \
    vendor.xiaomi.hardware.motor@1.0-service.xml

PRODUCT_PACKAGES += \
    vendor.xiaomi.hardware.motor@1.0.vendor

# Dolby
$(call inherit-product, hardware/dolby/dolby.mk)

# Init
$(call soong_config_set,xiaomi_msmnile,variant_lib,//$(LOCAL_PATH):libvariant_xiaomi_raphael)

# Maintainer Flag
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.lunaris.maintainer=Chethan

# MiuiCamera
$(call inherit-product-if-exists, device/xiaomi/miuicamera/device.mk)

# Overlays
PRODUCT_PACKAGES += \
    ApertureOverlayDevice \
    FrameworkResOverlayDevice \
    LineageSDKOverlayDevice \
    LineageSystemUIOverlayDevice \
    SettingsOverlayDevice \
    SystemUIOverlayDevice

# Power
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/etc/powerhint.json:$(TARGET_COPY_OUT_VENDOR)/etc/powerhint.json

# Signing
PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/lunaris-priv/keys/releasekey

# Sensors
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/sensors/hals.conf:$(TARGET_COPY_OUT_VENDOR)/etc/sensors/hals.conf

# Shipping API level
PRODUCT_SHIPPING_API_LEVEL := 28

# RemovePackages
 PRODUCT_PACKAGES += \
     RemovePackagesRaphael

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# Inherit from vendor blobs
$(call inherit-product, vendor/xiaomi/raphael/raphael-vendor.mk)

# Boot debugging: adb comes up without the authorization prompt (the screen
# never gets past the logo), the kernel log goes into logcat and logs are
# streamed to /metadata/raphael-debug. Always on for userdebug/eng, where adbd
# also starts as root; force it on a user build with RAPHAEL_BOOT_DEBUG=true.
ifneq ($(RAPHAEL_BOOT_DEBUG)$(filter userdebug eng,$(TARGET_BUILD_VARIANT)),)
PRODUCT_PACKAGES += \
    init.raphael.debug.rc \
    raphael-debuglog.sh

PRODUCT_PRODUCT_PROPERTIES += \
    ro.adb.secure=0 \
    persist.sys.usb.config=mtp,adb \
    ro.logd.kernel=true \
    persist.logd.size=16M \
    persist.logd.logpersistd=logcatd \
    persist.logd.logpersistd.buffer=all \
    persist.logd.logpersistd.size=30

ifneq ($(filter userdebug eng,$(TARGET_BUILD_VARIANT)),)
PRODUCT_PRODUCT_PROPERTIES += \
    service.adb.root=1
endif
endif
