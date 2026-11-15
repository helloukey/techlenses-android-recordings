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
fin(){ adb shell pkill -l SIGINT screenrecord; sleep 9; adb pull /sdcard/$1.mp4 out/$1.mp4 || true; }
st(){ adb shell am force-stop com.android.settings; adb shell input keyevent KEYCODE_HOME; sleep 2; adb shell am start -n com.android.settings/.Settings; sleep 4; }
# notification history with test notification
adb shell am force-stop com.android.settings; adb shell input keyevent KEYCODE_HOME; sleep 2
rec nh2; shot z0
adb shell am start -n com.android.settings/.Settings; sleep 4
tap_text "Notifications" z1; sleep 3
tap_text "Notification history" z2; sleep 3; shot z2
tap_text "Use notification history" z2b; sleep 3; shot z2b
adb shell input keyevent KEYCODE_HOME; sleep 2
adb shell "cmd notification post -t 'Tech Lenses' tltest 'Test notification'"; sleep 2
adb shell cmd statusbar expand-notifications; sleep 3; shot z3
tap_text "Clear all" z4; sleep 2; shot z4
adb shell cmd statusbar collapse; sleep 1
adb shell am start -n com.android.settings/.Settings; sleep 4
tap_text "Notifications" z5; sleep 3
tap_text "Notification history" z6; sleep 3; shot z6; dump z6
adb shell input swipe 360 1400 360 600 300; sleep 2; shot z7
sleep 3; fin nh2
ls -l out
