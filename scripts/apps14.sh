#!/usr/bin/env bash
set -x
mkdir -p out apk
R=https://f-droid.org/repo
for f in org.fossify.notes_13.apk org.fossify.filemanager_16.apk; do curl -sL -o apk/$f $R/$f; ls -l apk/$f; done
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
adb shell "nohup screenrecord --time-limit 100 --size 720x1600 --bit-rate 6000000 /sdcard/p2.mp4 >/dev/null 2>&1 &"
sleep 2
adb shell am start -a android.intent.action.VIEW -d https://www.perplexity.ai -n com.android.chrome/com.google.android.apps.chrome.Main; sleep 8; shot c0
tap_text "Use without an account" ua; sleep 6; shot c1
sleep 10; shot c2
adb shell input tap 360 1487; sleep 4; shot c3-gotit
dump c3
sleep 4; shot c4
tap_text "Ask anything" aa; sleep 2; shot c5-focus
adb shell input text "What%sis%sCSS%scorner-shape"; sleep 1; shot c6-typed
adb shell input keyevent 66; sleep 20; shot c7-answer-1; sleep 15; shot c8-answer-2
dump c8
sleep 10
adb pull /sdcard/p2.mp4 out/perplexity2.mp4 || true
adb install -r apk/org.fossify.notes_13.apk | tee out/notes-install.txt
adb install -r apk/org.fossify.filemanager_16.apk | tee out/files-install.txt
for p in org.fossify.notes org.fossify.filemanager; do adb shell pm grant $p android.permission.POST_NOTIFICATIONS; done
adb shell input keyevent KEYCODE_HOME; sleep 2
adb shell "nohup screenrecord --time-limit 100 --size 720x1600 --bit-rate 6000000 /sdcard/n1.mp4 >/dev/null 2>&1 &"
sleep 2
adb shell monkey -p org.fossify.notes -c android.intent.category.LAUNCHER 1; sleep 6; shot n0
dump n0
tap_next; sleep 3; shot n1
adb shell input text "Shopping%slist"; sleep 2; shot n2
dump n2
adb shell input keyevent KEYCODE_BACK; sleep 2; shot n3
adb shell am force-stop org.fossify.notes
adb shell monkey -p org.fossify.filemanager -c android.intent.category.LAUNCHER 1; sleep 6; shot fm0
dump fm0
tap_text "Download" fd; sleep 3; shot fm1
sleep 15
adb pull /sdcard/n1.mp4 out/fossify.mp4 || true
rm -rf apk
ls -l out
