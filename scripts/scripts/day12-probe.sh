#!/usr/bin/env bash
# Android 14 public demonstration probe. No accounts, credentials or private data.
set -u
mkdir -p out
L=out/log.txt
sleep 45
adb shell getprop ro.build.version.release > "$L"
adb shell settings put global hide_error_dialogs 1
cat > /tmp/find.py <<'PY'
import sys,re,xml.etree.ElementTree as ET
term=sys.argv[1].lower()
for n in ET.parse('/tmp/u.xml').getroot().iter('node'):
 if any(term==n.get(k,'').lower() for k in ('text','content-desc')):
  x1,y1,x2,y2=map(int,re.findall(r'\d+',n.get('bounds','')))
  print((x1+x2)//2,(y1+y2)//2);break
PY
snap(){
 adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1
 adb pull /sdcard/u.xml /tmp/u.xml >/dev/null 2>&1
 cp /tmp/u.xml "out/$1.xml"
 echo "## $1" >> "$L"
 python3 - >> "$L" <<'PY'
import xml.etree.ElementTree as ET
print(' | '.join(v for n in ET.parse('/tmp/u.xml').getroot().iter('node') for k in ('text','content-desc') if (v:=n.get(k,''))))
PY
 adb exec-out screencap -p > "out/$1.png"
}
taptext(){
 adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1
 adb pull /sdcard/u.xml /tmp/u.xml >/dev/null 2>&1
 XY=$(python3 /tmp/find.py "$1")
 if [ -n "$XY" ]; then echo "TAP $1 $XY" >> out/taps.txt; adb shell input tap $XY; sleep 3; else echo "NOT FOUND $1" >> "$L"; return 1; fi
}
go(){ adb shell input keyevent KEYCODE_HOME; adb shell am force-stop com.android.settings; adb shell am start -a "$2" >> "$L" 2>&1; sleep 4; snap "$1"; }
scrolltap(){ for i in 1 2 3 4; do taptext "$1" && return 0; adb shell input swipe 540 1800 540 700 350; sleep 2; done; return 1; }
# Chrome Find in page qualification. Public Chromium documentation only.
adb shell am start -a android.intent.action.VIEW -d 'https://www.chromium.org/user-experience/find-in-page/' com.android.chrome >> "$L" 2>&1
sleep 8;snap f0-start
taptext 'Wait' || true
sleep 12;snap f1-first
taptext 'Use without an account' || taptext 'No thanks' || true
sleep 4;snap f2-choice
taptext 'No thanks' || true
sleep 8;snap f3-page
taptext 'More options' || true
snap f4-menu
taptext 'Find in page' || true
snap f5-find
adb shell input text 'find'
sleep 3;snap f6-match
taptext 'Next result' || taptext 'Next' || true
snap f7-next
# Replace the four-character demonstration query without changing the page.
taptext 'Find in page' || true
adb shell input keyevent KEYCODE_MOVE_END
for i in 1 2 3 4; do adb shell input keyevent KEYCODE_DEL; done
adb shell input text 'zzztlmissing'
sleep 3;snap f8-absent
taptext 'Close find in page' || taptext 'Close' || true
snap f9-exit
