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
# Notification snooze qualification with an explicitly labelled harmless test notice.
adb shell am start -a android.settings.NOTIFICATION_SETTINGS >> "$L" 2>&1
sleep 5;snap n0-settings
taptext 'Wait' || true
sleep 8;snap n1-settings
scrolltap 'Allow notification snoozing' || true
snap n2-enabled
adb shell cmd notification post -t 'Tech Lenses demo' techlenses-demo 'Harmless sample notification. Nothing to reply to.' >> "$L" 2>&1
sleep 3
adb shell cmd statusbar expand-notifications
sleep 3;snap n3-notification
taptext 'Expand' || true
snap n4-expanded
taptext 'Snooze' || taptext 'Snooze notification' || true
snap n5-snoozed
taptext '1 hour' || true
snap n6-duration
taptext '15 minutes' || true
snap n7-selected
taptext 'Undo' || true
snap n8-undo
