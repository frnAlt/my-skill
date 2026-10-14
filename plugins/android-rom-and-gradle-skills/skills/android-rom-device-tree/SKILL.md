---
name: android-rom-device-tree
description: Guide for AOSP, LineageOS, and custom ROM device tree development, vendor blob extraction, kernel defconfig, and SELinux policy tuning. Use when editing BoardConfig.mk, device.mk, AndroidProducts.mk, extracting vendor blobs, compiling custom ROMs, or fixing avc denied SELinux errors.
---

# Android Custom ROM & Device Tree Specialist

This skill provides step-by-step guidance for building and maintaining custom Android ROM device trees (e.g., LineageOS, PixelOS, AOSP) for target OEM hardware.

## 1. Device Tree Architecture

A standard device tree resides under `device/<oem>/<codename>/`:

```text
device/<oem>/<codename>/
├── Android.mk / Android.bp
├── AndroidProducts.mk       # Defines lunch targets
├── BoardConfig.mk           # Hardware flags, partitions, kernel headers
├── device.mk                # Product packages, overlays, system properties
├── extract-files.sh         # Script to extract blobs from device or dump
├── proprietary-files.txt    # List of vendor binaries/libraries needed
├── overlay/                 # Resource overlays (config.xml, framework overrides)
├── rootdir/                 # Init scripts (init.target.rc, fstab)
└── sepolicy/                # SELinux vendor rules & contexts
```

## 2. Core Makefile Configurations

### `AndroidProducts.mk`
```makefile
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/lineage_<codename>.mk

COMMON_LUNCH_CHOICES := \
    lineage_<codename>-user \
    lineage_<codename>-userdebug \
    lineage_<codename>-eng
```

### `BoardConfig.mk`
```makefile
DEVICE_PATH := device/<oem>/<codename>

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic

# Kernel
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
BOARD_KERNEL_PAGESIZE := 4096
BOARD_BOOT_HEADER_VERSION := 2
BOARD_KERNEL_BASE := 0x40078000
BOARD_KERNEL_CMDLINE := console=ttyMSM0,115200n8 earlycon=msm_geni_serial,0x4a90000 androidboot.hardware=qcom
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb

# Partitions & Dynamic Partitions
BOARD_SUPER_PARTITION_SIZE := 9126805504
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_ext product vendor odm

# SELinux
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor
```

### `device.mk`
```makefile
# Inherit proprietary vendor files
$(call inherit-product, vendor/<oem>/<codename>/<codename>-vendor.mk)

# Runtime Resource Overlays (RRO)
DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay

# Init scripts & fstab mount points
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/fstab.qcom:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.qcom \
    $(LOCAL_PATH)/rootdir/etc/init.<codename>.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.<codename>.rc

# Essential HAL packages
PRODUCT_PACKAGES += \
    android.hardware.audio.service \
    android.hardware.camera.provider@2.4-service \
    android.hardware.graphics.composer@2.1-service \
    android.hardware.wifi@1.0-service
```

## 3. Vendor Blob Extraction

1. Connect target device with USB debugging enabled, or mount an unpacked stock fastboot ROM/dump to a directory:
   ```bash
   # From connected device
   ./extract-files.sh

   # From mounted system/vendor image directory
   ./extract-files.sh /path/to/extracted/dump
   ```
2. Verify that pinned blobs in `proprietary-files.txt` match the target Android release (check 32-bit vs 64-bit library paths).

## 4. SELinux Policy Debugging

When hardware fails to initialize or crashes occur, check for `avc: denied` logs:

```bash
# Capture SELinux denials
adb logcat -d | grep "avc: denied"

# Or from dmesg
adb shell dmesg | grep "avc: denied"
```

Resolve denials by adding required rules to `sepolicy/vendor/<domain>.te`:

```text
# Example: Allow vendor_hal_camera to read sysfs_battery
allow vendor_hal_camera sysfs_battery:file r_file_perms;
```

Always use macro helpers (`r_file_perms`, `rw_file_perms`, `binder_call`) rather than raw permissions, and never violate global `neverallow` rules.

## 5. Compiling the ROM

```bash
# Initialize build environment
source build/envsetup.sh

# Select lunch target
lunch lineage_<codename>-userdebug

# Build target image with parallel threads
mka bacon -j$(nproc)
```
