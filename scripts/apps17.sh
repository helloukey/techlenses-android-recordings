#!/usr/bin/env bash
set -x
mkdir -p out apk
R=https://f-droid.org/repo

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
adb shell input keyevent KEYCODE_HOME; sleep 2
adb shell "nohup screenrecord --time-limit 150 --size 720x1600 --bit-rate 6000000 /sdcard/i1.mp4 >/dev/null 2>&1 &"
sleep 2
adb shell am start -a android.intent.action.VIEW -d https://www.instagram.com/ -n com.android.chrome/com.google.android.apps.chrome.Main; sleep 8; shot i0
for i in 1 2 3; do tap_text "Wait" w$i; tap_text "Use without an account" ua$i; sleep 4; done; shot i1
tap_text "No thanks" nt; sleep 3; shot i2
sleep 8; shot i3
tap_text "More options" mo; sleep 2; shot i4
dump menu
tap_text "Install app" ia; sleep 2; shot i5
tap_text "Add to Home screen" ah; sleep 2; shot i6
dump dlg
tap_text "Install" ins; sleep 3; shot i7
tap_text "Add" add; sleep 3; shot i8
adb shell input keyevent KEYCODE_HOME; sleep 3; shot i9
dump home
sleep 10
adb pull /sdcard/i1.mp4 out/insta-pwa.mp4 || true
ls -l out
