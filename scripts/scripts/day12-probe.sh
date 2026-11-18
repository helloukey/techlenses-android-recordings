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
# Readability probe: all changes through Android Settings UI.
go a0-accessibility android.settings.ACCESSIBILITY_SETTINGS
scrolltap 'Display size and text' || true
snap r1-default
# Font-size increase is the first Make larger node; display is the second.
tapnth(){
 adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1
 adb pull /sdcard/u.xml /tmp/u.xml >/dev/null 2>&1
 XY=$(python3 - "$1" "$2" <<'CODE'
import sys,re,xml.etree.ElementTree as ET
nodes=[n for n in ET.parse('/tmp/u.xml').getroot().iter('node') if any(sys.argv[1]==n.get(k,'') for k in ('text','content-desc'))]
if len(nodes)>int(sys.argv[2]):
 n=nodes[int(sys.argv[2])];x,y,xx,yy=map(int,re.findall(r'\d+',n.get('bounds','')));print((x+xx)//2,(y+yy)//2)
CODE
)
 if [ -n "$XY" ]; then echo "TAPN $1 $2 $XY" >> out/taps.txt;adb shell input tap $XY;sleep 3; else echo "NOT FOUND $1 $2" >> "$L";fi
}
tapnth 'Make larger' 0
tapnth 'Make larger' 0
snap r2-font
adb shell input keyevent KEYCODE_BACK;sleep 3;snap r2b-font-applied
scrolltap 'Display size and text' || true
tapnth 'Make larger' 1
snap r2c-display
taptext 'Bold text' || true
snap r3-bold
adb shell input keyevent KEYCODE_BACK; sleep 3
snap r4-accessibility-after
scrolltap 'Display size and text' || true
snap r5-return
# Restore using the visible Reset settings flow, not a hidden system write.
scrolltap 'Reset settings' || true
snap r6-reset-prompt
taptext 'Reset' || taptext 'Reset settings' || true
snap r7-reset
adb shell input keyevent KEYCODE_BACK; sleep 3
snap r8-accessibility-restored
adb shell pm list packages > out/packages.txt
