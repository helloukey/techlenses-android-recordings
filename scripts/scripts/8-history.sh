#!/usr/bin/env bash
# Android 14 Data Saver chain capture. Settings only; no traffic benchmark.
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
adb shell am start -a android.settings.SETTINGS; sleep 5; snap n1-settings
tapt "Notifications" exact; snap n2-notifications
tapt "Notification history" exact; snap n3-history-off
tapt "Use notification history" exact; snap n4-history-on
adb shell settings get secure notification_history_enabled >> $L
adb shell cmd notification post -t 'Tech Lenses demo' tl_demo 'Sample reminder - this is a demo notification' >> $L 2>&1
sleep 3
adb shell cmd statusbar expand-notifications; sleep 3; snap n5-demo-shade
adb shell input swipe 200 490 1000 490 400; sleep 3; snap n6-dismissed
adb shell input keyevent KEYCODE_BACK; sleep 3
adb shell am start -a android.settings.NOTIFICATION_HISTORY; sleep 4; snap n7-history-after
adb shell dumpsys notification --noredact > out/notifications-state.txt
