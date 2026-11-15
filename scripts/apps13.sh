#!/usr/bin/env bash
set -x
mkdir -p out apk
R=https://f-droid.org/repo
for f in com.termux_1002.apk org.fdroid.fdroid_2000053.apk; do curl -sL -o apk/$f $R/$f; ls -l apk/$f; done
shot(){ adb exec-out screencap -p > out/$1.png; }
dump(){ adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1; adb pull /sdcard/u.xml out/ui-$1.xml >/dev/null 2>&1; }
tap_text(){ dump $2
 python3 - "$1" out/ui-$2.xml > /tmp/xy <<'P'
import sys,re,html
t=sys.argv[1].lower();x=open(sys.argv[2]).read()
for m in re.finditer(r'(?:text|content-desc)="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',x):
    if t in html.unescape(m.group(1)).lower():
        a=[int(v) for v in m.groups()[1:]];print((a[0]+a[2])//2,(a[1]+a[3])//2);break
P
 if [ -s /tmp/xy ]; then adb shell input tap $(cat /tmp/xy); echo tapped "$1"; else echo notfound "$1"; fi; }

typ(){ adb shell input text "$(echo "$1" | sed 's/ /%s/g')"; sleep 1; adb shell input keyevent 66; }
adb shell input keyevent KEYCODE_HOME; sleep 2
adb shell "nohup screenrecord --time-limit 180 --size 720x1600 --bit-rate 6000000 /sdcard/t1.mp4 >/dev/null 2>&1 &"
sleep 2
adb install -r apk/com.termux_1002.apk 2>&1 | tee out/termux-install.txt
adb shell pm grant com.termux android.permission.POST_NOTIFICATIONS
adb shell monkey -p com.termux -c android.intent.category.LAUNCHER 1; sleep 5; shot t0
for i in 1 2 3 4 5 6; do sleep 10; shot t1-$i; done
dump t1
typ "echo hello from Termux"; sleep 2; shot t2-echo
typ "uname -m"; sleep 2; shot t3-uname
typ "pkg install -y python"; for i in 1 2 3 4 5 6 7 8; do sleep 9; shot t4-pkg-$i; done
typ "python --version"; sleep 3; shot t5-python
typ "python -m this"; sleep 4; shot t6-pyver
sleep 25
adb pull /sdcard/t1.mp4 out/termux.mp4 || true
adb shell am force-stop com.termux
adb shell input keyevent KEYCODE_HOME; sleep 2
adb shell "nohup screenrecord --time-limit 180 --size 720x1600 --bit-rate 6000000 /sdcard/f1.mp4 >/dev/null 2>&1 &"
sleep 2
adb install -r apk/org.fdroid.fdroid_2000053.apk 2>&1 | tee out/fdroid-install.txt
adb shell pm grant org.fdroid.fdroid android.permission.POST_NOTIFICATIONS
adb shell monkey -p org.fdroid.fdroid -c android.intent.category.LAUNCHER 1; sleep 6; shot f0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14; do sleep 10; shot f1-$i; done
dump f1
tap_text "Search" fs; sleep 3; shot f2-search
adb shell input text Fossify; sleep 1; adb shell input keyevent 66; sleep 6; shot f3-results
tap_text "Fossify Notes" fn; sleep 5; shot f4-notes
sleep 8
adb pull /sdcard/f1.mp4 out/fdroid.mp4 || true
rm -rf apk
adb shell input keyevent KEYCODE_HOME; sleep 2
adb shell "nohup screenrecord --time-limit 90 --size 720x1600 --bit-rate 6000000 /sdcard/p1.mp4 >/dev/null 2>&1 &"
sleep 2
adb shell am start -a android.intent.action.VIEW -d https://www.perplexity.ai -n com.android.chrome/com.google.android.apps.chrome.Main; sleep 8; shot c0
tap_text "Use without an account" ua; sleep 3; shot c1
tap_text "No thanks" nt; sleep 3; shot c2
tap_text "Got it" gi; sleep 2
for i in 1 2 3 4 5 6; do sleep 8; shot c3-$i; done
dump c3
sleep 10
adb pull /sdcard/p1.mp4 out/perplexity.mp4 || true
ls -l out
