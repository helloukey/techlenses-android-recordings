#!/usr/bin/env bash
# Android 14 generic demonstration captures. No private accounts or messages.
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
xy(){
 adb shell uiautomator dump /sdcard/u.xml > /tmp/dump-result.txt 2>&1
 adb pull /sdcard/u.xml /tmp/u.xml > /tmp/pull-result.txt 2>&1
 python3 /tmp/find.py "$1"
}
taptext(){ XY=$(xy "$1"); if [ -n "$XY" ]; then echo "TAP $1 $XY" >> out/taps.txt; adb shell input tap $XY; sleep 3; else echo "NOT FOUND $1" >> "$L"; return 1; fi; }
# Bounded correction: no Quick Settings drag.
adb shell input keyevent KEYCODE_HOME
adb shell am start -a android.settings.SOUND_SETTINGS >> "$L" 2>&1
sleep 4;snap v0-before
adb shell settings get system volume_music >> out/volume-state.txt
# Touch observed Media volume track only; ring/notification/alarm remain separate.
adb shell input tap 950 774
sleep 2;snap v1-media-high
adb shell settings get system volume_music >> out/volume-state.txt
adb shell input tap 462 774
sleep 2;snap v2-media-restored
adb shell settings get system volume_music >> out/volume-state.txt
adb shell input keyevent KEYCODE_HOME
adb shell cmd notification post -t Tech tl-demo demo >> "$L" 2>&1
adb shell cmd statusbar expand-notifications
sleep 3;snap n0-demo
XY=$(xy Tech)
if [ -n "$XY" ];then
 adb shell input swipe $XY $XY 1400;sleep 3;snap n1-options
 if taptext Silent;then snap n2-silent-choice;taptext Done || true;sleep 3;snap n3-after;fi
fi
adb shell cmd statusbar collapse
adb shell input keyevent KEYCODE_HOME
adb shell am start -a android.settings.FONT_SIZE_SETTINGS >> "$L" 2>&1
sleep 4;snap f0-size
