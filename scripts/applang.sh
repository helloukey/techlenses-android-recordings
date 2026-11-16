#!/usr/bin/env bash
# Per-app language probe (Android 14): Settings > System > Languages > App languages, Chrome.
mkdir -p out; L=out/log.txt
adb shell settings put global hide_error_dialogs 1
sleep 60
adb shell input keyevent KEYCODE_HOME; sleep 4
cat > /tmp/find.py <<'P'
import sys,re,xml.etree.ElementTree as ET
t=sys.argv[1].lower()
r=ET.parse('/tmp/u.xml').getroot()
for n in r.iter('node'):
    s=(n.get('text','')+'|'+n.get('content-desc','')).lower()
    if t in s:
        b=re.findall(r'\d+',n.get('bounds'));x1,y1,x2,y2=map(int,b)
        print((x1+x2)//2,(y1+y2)//2);break
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
 python3 /tmp/find.py "$1" > /tmp/xy; read X Y < /tmp/xy
 if [ -n "$X" ]; then adb shell input tap $X $Y; echo "tapped $1 at $X $Y" >> $L; sleep 3; return 0; fi
 adb shell input swipe 540 1800 540 800 300; sleep 2; done; echo "NOT FOUND: $1" >> $L; return 1; }
home(){ adb shell input keyevent KEYCODE_HOME; sleep 2; }
adb shell getprop ro.build.version.release >> $L
# Chrome first run (before language change)
home; adb shell am start -n com.android.chrome/com.google.android.apps.chrome.Main; sleep 8; snap a0-chrome-before
home
# Settings > System > Languages > App languages
adb shell am start -a android.settings.SETTINGS; sleep 4; snap b0-settings
tapt "System"; snap b1-system
tapt "Languages"; snap b2-languages
tapt "App languages"; snap b3-app-languages
tapt "Chrome"; snap b4-chrome-langs
tapt "Spanish"; snap b5-spanish-list
tapt "Espa"; sleep 2; snap b6-after-pick
# reopen Chrome
home; adb shell am force-stop com.android.chrome; adb shell am start -n com.android.chrome/com.google.android.apps.chrome.Main; sleep 8; snap c0-chrome-after
# revert to system default
home; adb shell am start -a android.settings.SETTINGS; sleep 4
tapt "System"; tapt "Languages"; tapt "App languages"; tapt "Chrome"; snap d0-revert-list
tapt "System default"; sleep 2; snap d1-reverted
ls -l out >> $L; cat $L
