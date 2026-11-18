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
# Chrome public-document PDF qualification. No account or permission grants.
adb shell am start -a android.intent.action.VIEW -d 'https://example.com' com.android.chrome >> "$L" 2>&1
sleep 8;snap c1-first
# Only skip sign-in/onboarding choices; no accepting app permissions.
taptext 'Use without an account' || taptext 'No thanks' || true
sleep 4;snap c2-after-choice
taptext 'No thanks' || true
sleep 3;snap c3-page
taptext 'More options' || true
snap c4-menu
scrolltap 'Share...' || taptext 'Share' || true
snap c5-share
scrolltap 'Print' || true
snap c6-print
taptext 'Save as PDF' || true
snap c7-destination
taptext 'Save to PDF' || taptext 'Save as PDF' || true
snap c8-save
# Stop unless the actual print/save UI is present. No external sending.
adb shell find /sdcard/Download -maxdepth 1 -type f > out/downloads.txt
