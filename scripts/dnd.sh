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
# pinning complete
adb shell am start -a android.settings.SECURITY_SETTINGS; sleep 4; tapt "More security"; tapt "App pinning"; tapt "Use app pinning"; sleep 2; tapt "OK"; sleep 2
home; adb shell am start -n com.android.chrome/com.google.android.apps.chrome.Main; sleep 5
adb shell input keyevent KEYCODE_APP_SWITCH; sleep 3
adb shell input tap 540 265; sleep 2; tapt "Pin"; sleep 3; snap q1-pin-dialog
tapt "Got it"; sleep 2; snap q2-pinned
adb shell input keyevent KEYCODE_HOME; sleep 2; snap q3-home-while-pinned
adb shell input swipe 540 2399 540 1400 400; sleep 3; snap q4-swipe-up
adb shell input swipe 540 2399 540 1500 2500; sleep 3; snap q5-swipe-hold
adb shell cmd overlay enable com.android.internal.systemui.navbar.threebutton; sleep 5; snap q6-3button
adb shell input swipe 200 2330 200 2330 3000; sleep 3; snap q7-longpress-back
adb shell input swipe 540 2330 540 2330 3000; sleep 3; snap q8-longpress-home
adb shell dumpsys activity activities | grep -iE 'lockTaskMode|mLockTaskModeState' | head -3 >> $L
# gboard clipboard setting
home; adb shell am start -a android.settings.INPUT_METHOD_SETTINGS; sleep 4; snap g1-input
tapt "On-screen keyboard"; sleep 2; snap g2-onscreen
tapt "Gboard"; sleep 3; snap g3-gboard
tapt "Clipboard"; sleep 2; snap g4-clipboard
# chrome typed url
home; adb shell am start -n com.android.chrome/com.google.android.apps.chrome.Main; sleep 5
tapt "Search or type web address"; sleep 2; adb shell input text "chrome://flags"; adb shell input keyevent KEYCODE_ENTER; sleep 6; snap h1-flags
# play store
home; adb shell monkey -p com.android.vending -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 8; snap v1-playstore
ls -l out >> $L; cat $L
