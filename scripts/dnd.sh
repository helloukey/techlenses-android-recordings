#!/usr/bin/env bash
# E2E probe: notification history + snooze, app pinning, Chrome and YouTube first screens. No accounts.
mkdir -p out; L=out/log.txt
adb shell settings put global hide_error_dialogs 1
sleep 60
adb shell input keyevent KEYCODE_HOME; sleep 4
cat > /tmp/find.py <<'P'
import sys,re,html,xml.etree.ElementTree as ET
t=sys.argv[1].lower(); mode=sys.argv[2] if len(sys.argv)>2 else 'any'
r=ET.parse('/tmp/u.xml').getroot()
for n in r.iter('node'):
    s=(n.get('text','')+'|'+n.get('content-desc','')).lower()
    if t in s:
        b=re.findall(r'\d+',n.get('bounds'));x1,y1,x2,y2=map(int,b)
        print((x1+x2)//2,(y1+y2)//2,n.get('clickable'),n.get('class'));break
P
snap(){ adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1; adb pull /sdcard/u.xml /tmp/u.xml >/dev/null 2>&1; cp /tmp/u.xml out/$1.xml
 echo "## $1" >> $L; python3 - >> $L <<'P'
import xml.etree.ElementTree as ET
r=ET.parse('/tmp/u.xml').getroot();o=[]
for n in r.iter('node'):
    for k in ('text','content-desc'):
        v=n.get(k)
        if v: o.append(v)
print(' | '.join(o[:70]))
P
 adb exec-out screencap -p > out/$1.png; }
tapt(){ for i in 1 2 3 4; do adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1; adb pull /sdcard/u.xml /tmp/u.xml >/dev/null 2>&1
 python3 /tmp/find.py "$1" > /tmp/xy; read X Y C K < /tmp/xy
 if [ -n "$X" ]; then adb shell input tap $X $Y; echo "tapped $1 at $X $Y" >> $L; sleep 3; return 0; fi
 adb shell input swipe 540 1800 540 800 300; sleep 2; done; echo "NOT FOUND: $1" >> $L; return 1; }
home(){ adb shell input keyevent KEYCODE_HOME; sleep 2; }
# A clear all then history
adb shell am start -a android.settings.NOTIFICATION_HISTORY; sleep 4
tapt "Use notification history"; sleep 2
home
adb shell cmd notification post -S bigtext -t "Priya" t1 "Flat number is B-204, gate code 4471" >> $L 2>&1
adb shell cmd notification post -S bigtext -t "Cab" t2 "Your driver arrives in 5 min" >> $L 2>&1; sleep 2
adb shell cmd statusbar expand-notifications; sleep 3; snap n0-shade
tapt "Clear all"; sleep 2; snap n1-cleared
adb shell cmd statusbar expand-notifications; sleep 2; snap n2-shade-after
adb shell cmd statusbar collapse; home
adb shell am start -a android.settings.NOTIFICATION_HISTORY; sleep 4; tapt "Shell"; sleep 2; snap n3-history
# B app pinning
home; adb shell am start -a android.settings.SECURITY_SETTINGS; sleep 4; tapt "More security"; tapt "App pinning"; tapt "Use app pinning"; sleep 2; tapt "OK"; sleep 2; snap p1-on
home; adb shell am start -n com.android.chrome/com.google.android.apps.chrome.Main; sleep 5
adb shell input keyevent KEYCODE_APP_SWITCH; sleep 3
adb shell input tap 540 265; sleep 2; snap p3-menu
tapt "Pin"; sleep 3; snap p4-pinned
adb shell input keyevent KEYCODE_HOME; sleep 2; snap p5-home-try
adb shell input swipe 540 2399 540 1500 3000; sleep 3; snap p6-unpin-try
adb shell input keyevent KEYCODE_BACK; sleep 2; snap p7-back-try
ls -l out >> $L; cat $L
