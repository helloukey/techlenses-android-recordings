#!/usr/bin/env bash
# Open-source app probe on a clean emulator: no accounts. Installs F-Droid repo APKs, checks permissions, launches.
set -x
mkdir -p out apk
R=https://f-droid.org/repo
for f in org.fdroid.basic_2000051.apk com.supernova.launcher_6.apk com.eddyizm.degoogled.tempus_50.apk; do
  curl -sL -o apk/$f $R/$f; ls -l apk/$f
done
sha256sum apk/*.apk | tee out/apk-sha256.txt
adb shell getprop ro.build.version.release | tee out/android-version.txt
adb shell wm size | tee out/screen.txt
shot(){ adb exec-out screencap -p > out/$1.png; }
tap_text(){ adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1; adb pull /sdcard/u.xml out/ui-$2.xml >/dev/null 2>&1
 python3 - "$1" out/ui-$2.xml > /tmp/xy <<'P'
import sys,re,html
t=sys.argv[1].lower();x=open(sys.argv[2]).read()
for m in re.finditer(r'(?:text|content-desc)="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',x):
    if t in html.unescape(m.group(1)).lower():
        a=[int(v) for v in m.groups()[1:]];print((a[0]+a[2])//2,(a[1]+a[3])//2);break
P
 if [ -s /tmp/xy ]; then adb shell input tap $(cat /tmp/xy); echo tapped "$1"; else echo notfound "$1"; fi; }
adb shell input keyevent KEYCODE_HOME; sleep 3
adb shell "nohup screenrecord --time-limit 120 --size 720x1600 --bit-rate 6000000 /sdcard/apps.mp4 >/dev/null 2>&1 &"
sleep 2; shot s0-home-before
for f in com.supernova.launcher_6.apk com.eddyizm.degoogled.tempus_50.apk org.fdroid.basic_2000051.apk; do adb install -r apk/$f 2>&1 | tee -a out/install.txt; done
adb shell dumpsys package com.supernova.launcher | grep -iE "permission|versionName|android.permission" | head -60 > out/supernova-permissions.txt
adb shell dumpsys package com.eddyizm.degoogled.tempus | grep -iE "versionName|permission" | head -60 > out/tempus-permissions.txt
cat out/supernova-permissions.txt
adb shell monkey -p org.fdroid.basic -c android.intent.category.LAUNCHER 1; sleep 6; shot s1-fdroid
adb shell input keyevent KEYCODE_HOME; sleep 3; shot s2-home-chooser
tap_text Supernova c1; sleep 2; shot s3-after-pick
tap_text Always c2; sleep 4; shot s4-supernova-home
adb shell input keyevent KEYCODE_HOME; sleep 3; shot s5-home
adb shell input swipe 360 1300 360 400 400; sleep 3; shot s6-drawer
adb shell monkey -p com.eddyizm.degoogled.tempus -c android.intent.category.LAUNCHER 1; sleep 8; shot s7-tempus
sleep 5
adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1; adb pull /sdcard/u.xml out/ui-final.xml
sleep 30
adb pull /sdcard/apps.mp4 out/apps.mp4 || true
ls -l out
