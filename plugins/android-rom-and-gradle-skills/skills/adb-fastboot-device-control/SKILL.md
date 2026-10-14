---
name: adb-fastboot-device-control
description: Advanced instructions for debugging, flashing, and controlling physical or virtual Android devices via ADB and Fastboot. Use when executing adb shell commands, capturing logcat traces, installing APKs, querying device hardware properties, rebooting to bootloader/recovery/fastbootd, or flashing device partitions.
---

# ADB & Fastboot Device Control Skill

This skill guides you through inspecting, debugging, and flashing Android devices using `adb` and `fastboot`.

## 1. Device Connection & Discovery

```bash
# Verify connected devices
adb devices -l

# Check device authorization or state
adb get-state

# Restart adb server with root access if device supports it
adb root
adb wait-for-device
adb remount
```

## 2. Logcat Debugging & Crash Investigation

Always filter logcat to avoid capturing millions of irrelevant system lines:

```bash
# Filter by application package PID
PID=$(adb shell pidof -s com.example.app)
adb logcat --pid=$PID

# Capture pure crashes and tombstone stacks
adb logcat -b crash -v time -d

# Filter by specific log tags
adb logcat -v time -s "AndroidRuntime:E" "MyAppTag:D" "*:S"

# Clear log buffer before reproducing a bug
adb logcat -c && adb logcat -v threadtime
```

## 3. Package & Activity Manager Commands

```bash
# Query installed package info and APK path
adb shell pm path com.example.app
adb shell pm list packages -f | grep <keyword>

# Force-stop, clear data, and uninstall
adb shell am force-stop com.example.app
adb shell pm clear com.example.app
adb uninstall com.example.app

# Launch explicit activity or broadcast with extras
adb shell am start -n com.example.app/.MainActivity -e "key" "value"
adb shell am broadcast -a com.example.ACTION_UPDATE --es "status" "ready"

# Grant runtime permissions
adb shell pm grant com.example.app android.permission.POST_NOTIFICATIONS
adb shell pm grant com.example.app android.permission.READ_MEDIA_IMAGES
```

## 4. Hardware, System Properties & Performance

```bash
# Read hardware and ROM build properties
adb shell getprop ro.product.model
adb shell getprop ro.build.version.release
adb shell getprop ro.product.cpu.abi
adb shell getprop ro.build.flavor

# Check system resources & memory consumption
adb shell dumpsys meminfo com.example.app
adb shell dumpsys battery
adb shell top -m 10 -s cpu
```

## 5. Fastboot & Bootloader Operations

Use fastboot for partition flashing, custom kernel testing, and recovery manipulation:

```bash
# Verify fastboot device detection
fastboot devices

# Read partition slot and bootloader variables
fastboot getvar current-slot
fastboot getvar all

# Boot into recovery or fastbootd (Dynamic Partitions)
fastboot reboot recovery
fastboot reboot fastboot

# Flash essential partitions
fastboot flash boot boot.img
fastboot flash dtbo dtbo.img
fastboot flash recovery recovery.img
fastboot flash vbmeta --disable-verity --disable-verification vbmeta.img

# Temporary boot test without flashing
fastboot boot test-boot.img

# Reboot back to system
fastboot reboot
```
