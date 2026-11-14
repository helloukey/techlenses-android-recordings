#!/usr/bin/env bash
# Android 14 (API 34) Pixel 6 emulator: Do Not Disturb walkthrough. No accounts.
mkdir -p out
tap_text(){ adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1; adb pull /sdcard/u.xml out/ui-$2.xml >/dev/null 2>&1
 python3 - "$1" out/ui-$2.xml > /tmp/xy <<'P'
import sys,re
t=sys.argv[1];x=open(sys.argv[2]).read()
for m in re.finditer(r'text="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',x):
    if m.group(1)==t: print((int(m.group(2))+int(m.group(4)))//2,(int(m.group(3))+int(m.group(5)))//2);break
P
 read X Y < /tmp/xy; echo "tap '$1' at $X $Y"; [ -n "$X" ] && adb shell input tap $X $Y; }
adb shell getprop ro.build.version.release > out/android-version.txt
adb shell input keyevent KEYCODE_HOME; sleep 3
adb shell "nohup screenrecord --time-limit 60 --size 720x1600 --bit-rate 6000000 /sdcard/dnd.mp4 >/dev/null 2>&1 &"
sleep 3
adb shell am start -a android.settings.SETTINGS; sleep 4; adb exec-out screencap -p > out/s1-settings.png
tap_text "Sound & vibration" a; sleep 3; adb exec-out screencap -p > out/s2-sound.png
adb shell input swipe 540 1800 540 900 400; sleep 2
tap_text "Do Not Disturb" b; sleep 3; adb exec-out screencap -p > out/s3-dnd.png
tap_text "Turn on now" c; sleep 3; adb exec-out screencap -p > out/s4-on.png
adb shell input swipe 540 5 540 1200 300; sleep 2; adb exec-out screencap -p > out/s5-shade.png
adb shell input keyevent KEYCODE_HOME; sleep 4
adb pull /sdcard/dnd.mp4 out/dnd.mp4; ls -l out
