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
# Inspect screen-timeout durations through visible controls only.
adb shell am force-stop com.android.settings
adb shell input keyevent KEYCODE_HOME
adb shell am start -a android.settings.DISPLAY_SETTINGS >> "$L" 2>&1
sleep 4
adb shell screenrecord --bit-rate 5000000 --time-limit 150 /sdcard/timeout-demo.mp4 &
REC=$!
snap t0-display
if taptext 'Screen timeout';then
 snap t1-choices
 if taptext '30 seconds';then
  snap t2-thirty-seconds
  if taptext '2 minutes';then snap t3-two-minutes;fi
 fi
fi
adb shell pkill -2 screenrecord || true
wait "$REC" || true
adb pull /sdcard/timeout-demo.mp4 out/timeout-demo.mp4 >> "$L" 2>&1
