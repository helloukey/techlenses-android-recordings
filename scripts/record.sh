#!/usr/bin/env bash
# Records a real Android Settings walkthrough on the emulator. Public test, no accounts.
set -x
mkdir -p out
adb shell getprop ro.build.version.release | tee out/android-version.txt
adb shell getprop ro.build.version.sdk | tee out/sdk.txt
adb shell wm size | tee out/screen.txt
adb shell input keyevent KEYCODE_HOME
sleep 3
adb shell "nohup screenrecord --time-limit 40 --size 720x1600 --bit-rate 6000000 /sdcard/settings.mp4 >/dev/null 2>&1 &"
sleep 2
adb shell am start -a android.settings.SETTINGS
sleep 4
adb exec-out screencap -p > out/step1-settings.png
adb shell input swipe 540 1800 540 700 500
sleep 2
adb shell am start -a android.settings.DISPLAY_SETTINGS
sleep 4
adb exec-out screencap -p > out/step2-display.png
adb shell am start -a android.settings.SOUND_SETTINGS
sleep 4
adb exec-out screencap -p > out/step3-sound.png
adb shell am start -a android.settings.LOCATION_SOURCE_SETTINGS
sleep 4
adb exec-out screencap -p > out/step4-location.png
adb shell input keyevent KEYCODE_HOME
sleep 28
adb pull /sdcard/settings.mp4 out/settings.mp4
ls -l out
