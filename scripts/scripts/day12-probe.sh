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
dragtext(){
 A=$(xy "$1");B=$(xy "$2"); if [ -z "$A" ] || [ -z "$B" ];then return 1;fi
 read -r X Y <<< "$A"; read -r U V <<< "$B"
 echo "DRAG $1 $A TO $2 $B" >> out/taps.txt
 adb shell input touchscreen motionevent DOWN "$X" "$Y";sleep 1
 python3 - "$X" "$Y" "$U" "$V" > /tmp/moves.txt <<'PY'
import sys
x,y,u,v=map(int,sys.argv[1:])
for i in range(1,13):print(round(x+(u-x)*i/12),round(y+(v-y)*i/12))
PY
 while read -r XX YY;do adb shell input touchscreen motionevent MOVE "$XX" "$YY";sleep .08;done < /tmp/moves.txt
 adb shell input touchscreen motionevent UP "$U" "$V";sleep 4
}
adb shell cmd statusbar expand-settings
sleep 4;snap q0-panel
if taptext 'Edit order of settings.';then
 snap q1-before
 dragtext 'Bluetooth' 'Internet' || true
 snap q2-reordered
 adb shell input keyevent KEYCODE_BACK
 adb shell cmd statusbar collapse
 adb shell cmd statusbar expand-settings
 sleep 3
 adb shell input swipe 150 900 950 900 450
 adb shell input swipe 150 900 950 900 450
 sleep 2;snap q3-panel-reordered
 if taptext 'Edit order of settings.';then
  dragtext 'Internet' 'Bluetooth' || true
  snap q4-restored
  adb shell input keyevent KEYCODE_BACK
  snap q5-exit
 fi
fi
adb shell input keyevent KEYCODE_HOME
adb shell cmd notification post -t 'Tech Lenses demo' tl-demo 'Harmless demo reminder' >> "$L" 2>&1
adb shell cmd statusbar expand-notifications
sleep 3;snap n0-notification
XY=$(xy 'Tech Lenses demo')
if [ -n "$XY" ];then adb shell input swipe $XY $XY 1200;sleep 3;snap n1-longpress;fi
adb shell input keyevent KEYCODE_HOME
adb shell am start -a android.settings.SOUND_SETTINGS >> "$L" 2>&1
sleep 5;snap v0-sound
adb shell input keyevent KEYCODE_HOME
adb shell input keyevent KEYCODE_VOLUME_UP
sleep 1;snap v1-volume
