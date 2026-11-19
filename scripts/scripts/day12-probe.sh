#!/usr/bin/env bash
# Public Android 14 qualification using generic demo text only.
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
  a,b,c,d=map(int,re.findall(r'\d+',n.get('bounds','')))
  print((a+c)//2,(b+d)//2);break
PY
snap(){
 adb shell uiautomator dump /sdcard/u.xml > /tmp/dump-result.txt 2>&1
 adb pull /sdcard/u.xml /tmp/u.xml > /tmp/pull-result.txt 2>&1
 cp /tmp/u.xml "out/$1.xml"
 echo "## $1" >> "$L"
 python3 - >> "$L" <<'PY'
import xml.etree.ElementTree as ET
print(' | '.join(v for n in ET.parse('/tmp/u.xml').getroot().iter('node') for k in ('text','content-desc') if (v:=n.get(k,''))))
PY
 adb exec-out screencap -p > "out/$1.png"
}
taptext(){
 adb shell uiautomator dump /sdcard/u.xml > /tmp/dump-result.txt 2>&1
 adb pull /sdcard/u.xml /tmp/u.xml > /tmp/pull-result.txt 2>&1
 XY=$(python3 /tmp/find.py "$1")
 if [ -n "$XY" ]; then echo "TAP $1 $XY" >> out/taps.txt; adb shell input tap $XY; sleep 3; else echo "NOT FOUND $1" >> "$L"; return 1; fi
}
scrolltap(){ for i in 1 2 3 4; do taptext "$1" && return 0; adb shell input swipe 540 1800 540 700 350; sleep 2; done; return 1; }
adb shell am start -a android.settings.PRIVACY_SETTINGS >> "$L" 2>&1
sleep 5;taptext 'Wait' || true
sleep 5;snap p0-privacy
scrolltap 'More privacy settings' || true
snap p1-more
# Capture only labels actually present; no invisible toggle changes.
taptext 'Camera access' || true
snap p2-camera
taptext 'Camera access' || true
snap p3-restored
# App-link settings for the installed public YouTube app.
adb shell input keyevent KEYCODE_HOME
adb shell am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d package:com.google.android.youtube >> "$L" 2>&1
sleep 5;snap a0-youtube
scrolltap 'Open by default' || true
snap a1-default
taptext 'Open supported links' || true
snap a2-off
taptext 'Open supported links' || true
snap a3-restored
# Native quick-settings controls and editor, read only.
adb shell cmd statusbar expand-settings
sleep 4;snap q0-panel
taptext 'Edit' || true
snap q1-edit
adb shell input swipe 540 1800 540 700 400
sleep 3;snap q2-edit
