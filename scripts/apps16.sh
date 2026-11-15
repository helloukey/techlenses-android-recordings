#!/usr/bin/env bash
set -x
mkdir -p out apk
R=https://f-droid.org/repo
for f in com.termux_1002.apk org.fossify.filemanager_16.apk; do curl -sL -o apk/$f $R/$f; ls -l apk/$f; done
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

# helper: tap the clickable node nearest the bottom-right (onboarding next arrow)
tap_next(){ dump nx
 python3 - out/ui-nx.xml > /tmp/xy <<'P'
import sys,re
x=open(sys.argv[1]).read()
best=None
for m in re.finditer(r'<node [^>]*?clickable="true"[^>]*?bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',x):
    a=[int(v) for v in m.groups()]
    cx,cy=(a[0]+a[2])//2,(a[1]+a[3])//2
    if best is None or cy*10+cx>best[1]*10+best[0]: best=(cx,cy)
if best: print(*best)
P
 if [ -s /tmp/xy ]; then cat /tmp/xy; adb shell input tap $(cat /tmp/xy); else echo no-clickable; fi; }
typ(){ adb shell input text "$(echo "$1" | sed 's/ /%s/g')"; sleep 1; adb shell input keyevent 66; }
focus(){ adb shell dumpsys window | grep -m1 mCurrentFocus; }
tt(){ if focus | grep -q com.termux; then typ "$1"; else echo "NOT-IN-TERMUX skipped: $1"; fi; }
adb shell input keyevent KEYCODE_HOME; sleep 2
adb shell "nohup screenrecord --time-limit 180 --size 720x1600 --bit-rate 6000000 /sdcard/t3.mp4 >/dev/null 2>&1 &"
sleep 2
adb install -r apk/com.termux_1002.apk 2>&1 | tee out/termux-install.txt
adb shell pm grant com.termux android.permission.POST_NOTIFICATIONS
adb shell monkey -p com.termux -c android.intent.category.LAUNCHER 1; sleep 20; shot t0
for i in 1 2 3 4 5 6; do tap_text "TRY AGAIN" ta$i; sleep 12; shot t1-$i; done
focus | tee out/focus1.txt
tt "uname -m"; sleep 2; shot t3
tt "pkg install -y python"; for i in 1 2 3 4 5 6 7 8; do sleep 9; shot t4-pkg-$i; done
tt "curl -sLO https://raw.githubusercontent.com/helloukey/techlenses-android-recordings/main/scripts/stars.py"; sleep 5; shot t5-curl
tt "python stars.py"; sleep 8; shot t6-stars-1; sleep 6; shot t7-stars-2
sleep 5
adb pull /sdcard/t3.mp4 out/termux3.mp4 || true
adb shell am force-stop com.termux
adb shell input keyevent KEYCODE_HOME; sleep 2
adb install -r apk/org.fossify.filemanager_16.apk | tee out/files-install.txt
adb shell appops set org.fossify.filemanager MANAGE_EXTERNAL_STORAGE allow
adb shell pm grant org.fossify.filemanager android.permission.POST_NOTIFICATIONS
adb shell "nohup screenrecord --time-limit 90 --size 720x1600 --bit-rate 6000000 /sdcard/f3.mp4 >/dev/null 2>&1 &"
sleep 2
adb shell monkey -p org.fossify.filemanager -c android.intent.category.LAUNCHER 1; sleep 6; shot fm0
tap_text "OK" fok; sleep 2; shot fm1
tap_text "Download" fd; sleep 3; shot fm2
adb shell input keyevent KEYCODE_BACK; sleep 1; tap_text "Recents" fr; sleep 3; shot fm3
tap_text "Storage" fs; sleep 3; shot fm4
sleep 12
adb pull /sdcard/f3.mp4 out/files3.mp4 || true
rm -rf apk
ls -l out
