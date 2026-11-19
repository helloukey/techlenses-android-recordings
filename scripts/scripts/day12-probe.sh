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
sleep 7;snap p0-security
scrolltap 'Privacy' || true
snap p1-privacy
scrolltap 'Camera access' || true
snap p2-camera-off
taptext 'Camera access' || true
snap p3-camera-restored
taptext 'Microphone access' || true
snap p4-mic-off
taptext 'Microphone access' || true
snap p5-mic-restored
adb shell input keyevent KEYCODE_HOME
adb shell am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d package:com.google.android.youtube >> "$L" 2>&1
sleep 5;snap a0-youtube
adb shell input swipe 540 1800 540 700 350
sleep 2;snap a1-scrolled
taptext 'Open by default' || true
snap a2-default
taptext 'Open supported links' || true
snap a3-off
taptext 'Open supported links' || true
snap a4-restored
taptext '4 verified links' || true
snap a5-links
adb shell input keyevent KEYCODE_HOME
adb shell cmd statusbar expand-settings
sleep 3;snap q0-panel
taptext 'Edit order of settings.' || true
snap q1-edit
adb shell input swipe 540 1800 540 700 400
sleep 2;snap q2-edit
adb shell input swipe 540 1800 540 700 400
sleep 2;snap q3-edit
