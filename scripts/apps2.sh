#!/usr/bin/env bash
# Probe 2: Supernova as home, Fossify apps, no accounts.
set -x
mkdir -p out apk
R=https://f-droid.org/repo
for f in com.supernova.launcher_6.apk org.fossify.gallery_40.apk org.fossify.notes_13.apk org.fossify.filemanager_16.apk; do
  curl -sL -o apk/$f $R/$f; ls -l apk/$f
done
sha256sum apk/*.apk | tee out/apk-sha256.txt
shot(){ adb exec-out screencap -p > out/$1.png; }
adb shell input keyevent KEYCODE_HOME; sleep 3
adb shell "nohup screenrecord --time-limit 170 --size 720x1600 --bit-rate 6000000 /sdcard/a2.mp4 >/dev/null 2>&1 &"
sleep 2
for f in apk/*.apk; do adb install -r $f 2>&1 | tee -a out/install.txt; done
adb shell cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME | tee out/home-activities.txt
H=$(grep -o 'com.supernova.launcher/[^ ]*' out/home-activities.txt | head -1)
echo "HOME=$H"
adb shell cmd package set-home-activity "$H" | tee out/set-home.txt
sleep 2; adb shell input keyevent KEYCODE_HOME; sleep 5; shot t1-home
adb shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME | tee out/resolved-home.txt
adb shell input swipe 360 1300 360 400 400; sleep 3; shot t2-drawer
adb shell input keyevent KEYCODE_HOME; sleep 2
adb shell input swipe 360 800 360 800 1200; sleep 3; shot t3-longpress
adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1; adb pull /sdcard/u.xml out/ui-t3.xml
adb shell input keyevent KEYCODE_BACK; sleep 1
for p in org.fossify.gallery org.fossify.notes org.fossify.filemanager; do
  adb shell monkey -p $p -c android.intent.category.LAUNCHER 1; sleep 7; shot t-$p
done
adb shell input keyevent KEYCODE_HOME; sleep 3; shot t9-home
for p in org.fossify.gallery org.fossify.notes org.fossify.filemanager com.supernova.launcher; do adb shell dumpsys package $p | grep -E "versionName|android.permission\.[A-Z_]+" | sort -u > out/perm-$p.txt; done
sleep 40
adb pull /sdcard/a2.mp4 out/a2.mp4 || true
ls -l out
