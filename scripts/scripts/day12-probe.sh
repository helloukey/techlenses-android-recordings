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
go security android.settings.SECURITY_SETTINGS
adb shell input swipe 540 1800 540 700 350; sleep 2; snap security-scroll
taptext 'More security & privacy' || taptext 'More security settings' || true
snap more-security
adb shell input swipe 540 1800 540 700 350; sleep 2; snap more-security-scroll
taptext 'App pinning' || taptext 'Screen pinning' || true
snap pinning-settings
# Only toggle if a pinning screen was actually reached.
if grep -qiE 'App pinning|Screen pinning' /tmp/u.xml; then
 taptext 'Use app pinning' || taptext 'Use screen pinning' || true
 snap pinning-on
fi
go gestures android.settings.GESTURE_SETTINGS
snap gestures
# A second direct route is only a Settings deep link, not a feature mutation.
adb shell am start -n com.android.settings/.Settings\$OneHandedSettingsActivity >> "$L" 2>&1; sleep 4; snap one-handed
# Accessibility index and specific features.
go accessibility android.settings.ACCESSIBILITY_SETTINGS
adb shell input swipe 540 1800 540 700 350; sleep 2; snap accessibility-scroll
taptext 'Magnification' || true
snap magnification
adb shell am start -a android.settings.ACCESSIBILITY_SETTINGS >> "$L" 2>&1; sleep 4
taptext 'Extra dim' || true
snap extra-dim
go privacy android.settings.PRIVACY_SETTINGS
taptext 'Privacy dashboard' || true
snap privacy-dashboard
adb shell input keyevent KEYCODE_HOME
