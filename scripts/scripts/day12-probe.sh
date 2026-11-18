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
# Correctly scroll to exact labels before tapping.
scrolltap(){ for i in 1 2 3 4; do taptext "$1" && return 0; adb shell input swipe 540 1800 540 700 350; sleep 2; done; return 1; }
go security android.settings.SECURITY_SETTINGS
scrolltap 'More security & privacy' || true
snap p1-more-security
scrolltap 'App pinning' || scrolltap 'Screen pinning' || true
snap p2-pinning-off
taptext 'Use app pinning' || taptext 'Use screen pinning' || true
snap p3-pinning-on
taptext 'OK' || true
snap p3b-enabled
adb shell input keyevent KEYCODE_HOME
adb shell am start -n com.google.android.deskclock/com.android.deskclock.DeskClock >> "$L" 2>&1
sleep 4; snap p4-clock
adb shell input keyevent KEYCODE_APP_SWITCH; sleep 3; snap p5-recents
# Recent-app icon coordinate comes from the prior successful split-screen layout.
adb shell input tap 540 270; sleep 3; snap p6-app-menu
taptext 'Pin' || taptext 'Pin app' || true
snap p7-pin-confirm
taptext 'Got it' || taptext 'OK' || adb shell input tap 860 2305
sleep 4
snap p8-pinned
adb shell input keyevent KEYCODE_HOME; sleep 3; snap p9-home-while-pinned
adb shell dumpsys activity activities | grep -i -A6 locktask >> out/pin-state.txt
# Correct gesture-navigation unpin interaction.
adb shell input swipe 540 2350 540 1000 2200; sleep 4; snap p10-unpin
adb shell input swipe 540 2370 540 600 1800
sleep 3
# Privacy dashboard path through the security hub.
go privacy android.settings.SECURITY_SETTINGS
scrolltap 'Privacy' || true
snap v1-privacy
scrolltap 'Privacy dashboard' || true
snap v2-dashboard
# Capture magnification setup plus actual visible magnification.
go accessibility android.settings.ACCESSIBILITY_SETTINGS
scrolltap 'Magnification' || true
snap m1-settings
taptext 'Magnification shortcut' || true
snap m2-shortcut
taptext 'Tap accessibility button' || true
taptext 'Save' || true
snap m2b-saved
taptext 'Got it' || taptext 'Allow' || taptext 'OK' || true
snap m3-shortcut-on
adb shell input keyevent KEYCODE_HOME; sleep 3; snap m4-home
# accessibility floating shortcut normally appears at the right screen edge.
adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1; adb pull /sdcard/u.xml /tmp/u.xml >/dev/null 2>&1
for label in 'Magnification' 'Accessibility' 'Accessibility button'; do taptext "$label" && break; done
snap m5-activated
adb shell input tap 400 1000; sleep 3; snap m6-zoomed
adb shell input keyevent KEYCODE_HOME
