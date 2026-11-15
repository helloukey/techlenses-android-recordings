#!/usr/bin/env bash
set -x
mkdir -p out apk

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
rec(){ adb shell "nohup screenrecord --time-limit 70 --size 720x1600 --bit-rate 6000000 /sdcard/$1.mp4 >/dev/null 2>&1 &"; sleep 2; }
fin(){ adb shell pkill -l SIGINT screenrecord; sleep 4; adb pull /sdcard/$1.mp4 out/$1.mp4 || true; }
st(){ adb shell am force-stop com.android.settings; adb shell input keyevent KEYCODE_HOME; sleep 2; adb shell am start -n com.android.settings/.Settings; sleep 4; }
# A: notification history
st; rec nh; shot a0
tap_text "Notifications" a1; sleep 3; shot a1
adb shell input swipe 360 1400 360 600 300; sleep 2; shot a2; dump a2
tap_text "Notification history" a3; sleep 3; shot a3; dump a3
tap_text "Use notification history" a4; sleep 3; shot a4; dump a4
sleep 3; fin nh
# B: dark theme
st; rec dk; shot b0
tap_text "Display" b1; sleep 3; shot b1; dump b1
tap_text "Dark theme" b2; sleep 3; shot b2; dump b2
sleep 3; tap_text "Dark theme" b3; sleep 3; shot b3
sleep 3; fin dk
# C: font size and display size
st; rec fs; shot c0
tap_text "Display" c1; sleep 3
tap_text "Display size and text" c2; sleep 3; shot c2; dump c2
tap_text "Font size" c3; sleep 3; shot c3; dump c3
adb shell input tap 620 1200; sleep 2; shot c4
adb shell input tap 900 1200; sleep 2; shot c5
sleep 3; fin fs
ls -l out
