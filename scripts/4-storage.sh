#!/usr/bin/env bash
# Android 14 storage chain capture. Disposable test content only (a 150 MB demo file made by the script).
mkdir -p out; L=out/log.txt
adb shell settings put global hide_error_dialogs 1
sleep 60
adb shell getprop ro.build.version.release >> $L
cat > /tmp/find.py <<'P'
import sys,re,xml.etree.ElementTree as ET
t=sys.argv[1].lower(); ex=len(sys.argv)>2
r=ET.parse('/tmp/u.xml').getroot()
for n in r.iter('node'):
 for v in (n.get('text',''),n.get('content-desc','')):
  v=v.lower()
  if (v==t) if ex else (t in v and v):
   b=re.findall(r'\d+',n.get('bounds'));x1,y1,x2,y2=map(int,b)
   print((x1+x2)//2,(y1+y2)//2,x1,y1,x2,y2);sys.exit()
P
snap(){ adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1; adb pull /sdcard/u.xml /tmp/u.xml >/dev/null 2>&1; cp /tmp/u.xml out/$1.xml
 echo "## $1" >> $L; python3 - >> $L <<'P'
import xml.etree.ElementTree as ET
r=ET.parse('/tmp/u.xml').getroot();o=[]
for n in r.iter('node'):
 for k in ('text','content-desc'):
  v=n.get(k)
  if v: o.append(v)
print(' | '.join(o[:90]))
P
 adb exec-out screencap -p > out/$1.png; }
# tapt TEXT [exact] [scroll]
tapt(){ for i in 1 2 3 4; do adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1; adb pull /sdcard/u.xml /tmp/u.xml >/dev/null 2>&1
 python3 /tmp/find.py "$1" $2 > /tmp/xy; read X Y R <<< "$(cat /tmp/xy)"
 if [ -n "$X" ]; then echo "TAP $1 $(cat /tmp/xy)" >> out/taps.txt; adb shell input tap $X $Y; sleep 3; return 0; fi
 adb shell input swipe 540 1800 540 800 300; sleep 2; done; echo "NOT FOUND: $1" >> $L; return 1; }
# disposable demo content
adb shell "dd if=/dev/zero of=/sdcard/Download/demo-recording.mp4 bs=1M count=150" >> $L 2>&1
adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Download/demo-recording.mp4 >/dev/null 2>&1
# make some Chrome cache
adb shell am start -n com.android.chrome/com.google.android.apps.chrome.Main >/dev/null 2>&1; sleep 8
adb shell input keyevent KEYCODE_HOME; sleep 2
adb shell am start -a android.settings.INTERNAL_STORAGE_SETTINGS >/dev/null; sleep 5; snap s1-storage
tapt "Apps" exact; snap s2-apps
tapt "Chrome" exact; snap s3-chrome
tapt "Clear cache"; snap s4-clearcache
adb shell input keyevent KEYCODE_BACK; adb shell input keyevent KEYCODE_BACK; sleep 2
adb shell am start -a android.settings.INTERNAL_STORAGE_SETTINGS >/dev/null; sleep 4; snap s5-storage-again
tapt "Free up space"; sleep 3; snap s6-files
snap s7-selected-default
tapt "Free up 1"; sleep 3; snap s8-confirm
adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1; adb pull /sdcard/u.xml /tmp/u.xml >/dev/null 2>&1
python3 - > /tmp/xy <<'P'
import re,xml.etree.ElementTree as ET
r=ET.parse('/tmp/u.xml').getroot();m=None
for n in r.iter('node'):
 if n.get('text','')=='Free up space' and n.get('clickable')=='true':m=n
if m is None:
 for n in r.iter('node'):
  if n.get('text','')=='Free up space':m=n
x1,y1,x2,y2=map(int,re.findall(r'\d+',m.get('bounds')));print((x1+x2)//2,(y1+y2)//2,x1,y1,x2,y2)
P
echo "TAP confirm $(cat /tmp/xy)" >> out/taps.txt; read X Y R <<< "$(cat /tmp/xy)"; adb shell input tap $X $Y; sleep 4; snap s10-after
adb shell input keyevent KEYCODE_BACK; sleep 1
adb shell am start -a android.settings.INTERNAL_STORAGE_SETTINGS >/dev/null; sleep 4; snap s11-storage-final
