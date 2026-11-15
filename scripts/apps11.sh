#!/usr/bin/env bash
set -x
mkdir -p out apk
R=https://f-droid.org/repo
for f in com.termux_1002.apk org.fdroid.fdroid_2000053.apk; do curl -sL -o apk/$f $R/$f; ls -l apk/$f; done
shot(){ adb exec-out screencap -p > out/$1.png; }
dump(){ adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1; adb pull /sdcard/u.xml out/ui-$1.xml >/dev/null 2>&1; }
typ(){ adb shell input text "$(echo "$1" | sed 's/ /%s/g')"; sleep 1; adb shell input keyevent 66; }
adb shell input keyevent KEYCODE_HOME; sleep 2
adb shell "nohup screenrecord --time-limit 180 --size 720x1600 --bit-rate 6000000 /sdcard/t1.mp4 >/dev/null 2>&1 &"
sleep 2
adb install -r apk/com.termux_1002.apk 2>&1 | tee out/termux-install.txt
adb shell monkey -p com.termux -c android.intent.category.LAUNCHER 1; sleep 5; shot t0
for i in 1 2 3 4 5 6; do sleep 10; shot t1-$i; done
dump t1
typ "echo hello from Termux"; sleep 2; shot t2-echo
typ "uname -m"; sleep 2; shot t3-uname
typ "pkg install -y python"; for i in 1 2 3 4 5 6 7 8; do sleep 9; shot t4-pkg-$i; done
typ "python -c 'print(2**100)'"; sleep 4; shot t5-python
typ "python -c 'import sys;print(sys.version.split()[0])'"; sleep 4; shot t6-pyver
sleep 25
adb pull /sdcard/t1.mp4 out/termux.mp4 || true
adb shell am force-stop com.termux
adb shell input keyevent KEYCODE_HOME; sleep 2
adb shell "nohup screenrecord --time-limit 120 --size 720x1600 --bit-rate 6000000 /sdcard/f1.mp4 >/dev/null 2>&1 &"
sleep 2
adb install -r apk/org.fdroid.fdroid_2000053.apk 2>&1 | tee out/fdroid-install.txt
adb shell monkey -p org.fdroid.fdroid -c android.intent.category.LAUNCHER 1; sleep 6; shot f0
for i in 1 2 3 4 5 6; do sleep 8; shot f1-$i; done
dump f1
sleep 20
adb pull /sdcard/f1.mp4 out/fdroid.mp4 || true
rm -rf apk
ls -l out
