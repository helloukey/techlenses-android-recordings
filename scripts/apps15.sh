#!/usr/bin/env bash
set -x
mkdir -p out apk
R=https://f-droid.org/repo
for f in com.termux_1002.apk; do curl -sL -o apk/$f $R/$f; ls -l apk/$f; done
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
adb shell "nohup screenrecord --time-limit 180 --size 720x1600 --bit-rate 6000000 /sdcard/t2.mp4 >/dev/null 2>&1 &"
sleep 2
adb install -r apk/com.termux_1002.apk 2>&1 | tee out/termux-install.txt
adb shell pm grant com.termux android.permission.POST_NOTIFICATIONS
adb shell monkey -p com.termux -c android.intent.category.LAUNCHER 1; sleep 5; shot t0
for i in 1 2 3 4 5 6; do sleep 10; shot t1-$i; done
typ "uname -m"; sleep 2
typ "pkg install -y python"; for i in 1 2 3 4 5 6 7 8; do sleep 9; shot t4-pkg-$i; done
typ "curl -sLO https://raw.githubusercontent.com/helloukey/techlenses-android-recordings/main/scripts/stars.py"; sleep 5; shot t5-curl
typ "python stars.py"; sleep 8; shot t6-stars-1; sleep 6; shot t7-stars-2
sleep 12
adb pull /sdcard/t2.mp4 out/termux2.mp4 || true
adb shell am force-stop com.termux
adb shell input keyevent KEYCODE_BACK; adb shell input keyevent KEYCODE_HOME; sleep 2
dump pre; grep -o 'text="[^"]*isn.t responding"' out/ui-pre.xml && tap_text "Wait" anr
adb shell "nohup screenrecord --time-limit 100 --size 720x1600 --bit-rate 6000000 /sdcard/p3.mp4 >/dev/null 2>&1 &"
sleep 2
adb shell am start -a android.intent.action.VIEW -d https://www.perplexity.ai -n com.android.chrome/com.google.android.apps.chrome.Main; sleep 8; shot c0
for i in 1 2 3; do tap_text "Wait" w$i; tap_text "Use without an account" ua$i; sleep 5; shot c1-$i; done
tap_text "No thanks" nt; sleep 3
tap_text "Got it" gi; sleep 3; shot c4
tap_text "Ask anything" aa; sleep 2; shot c5-focus
adb shell input text "What%sis%sCSS%scorner-shape"; sleep 1; shot c6-typed
adb shell input keyevent 66; sleep 20; shot c7-answer-1; sleep 15; shot c8-answer-2
dump c8
sleep 8
adb pull /sdcard/p3.mp4 out/perplexity3.mp4 || true
rm -rf apk
ls -l out
