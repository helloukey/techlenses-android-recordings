#!/usr/bin/env bash
# Probe: which hidden-feature settings screens exist on Android 14 Pixel 6 image. No accounts.
mkdir -p out; L=out/log.txt
adb shell settings put global hide_error_dialogs 1
sleep 60
adb shell input keyevent KEYCODE_HOME; sleep 4
dump(){ adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1; adb pull /sdcard/u.xml out/u.xml >/dev/null 2>&1
 echo "## $1" >> $L; python3 - >> $L <<'P'
import re,html
x=open('out/u.xml').read()
t=[html.unescape(m) for m in re.findall(r'text="([^"]+)"',x)]
print(' | '.join(t[:60]))
P
 adb exec-out screencap -p > out/$1.png; }
tapt(){ for i in 1 2 3 4 5; do adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1; adb pull /sdcard/u.xml out/u.xml >/dev/null 2>&1
 python3 - "$1" > /tmp/xy <<'P'
import sys,re,html
t=sys.argv[1].lower();x=open('out/u.xml').read()
for m in re.finditer(r'text="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',x):
    if t in html.unescape(m.group(1)).lower(): print((int(m.group(2))+int(m.group(4)))//2,(int(m.group(3))+int(m.group(5)))//2);break
P
 read X Y < /tmp/xy; if [ -n "$X" ]; then adb shell input tap $X $Y; echo "tapped $1" >> $L; sleep 3; return 0; fi
 adb shell input swipe 540 1800 540 800 300; sleep 2; done; echo "NOT FOUND: $1" >> $L; return 1; }
{ echo "## android"; adb shell getprop ro.build.version.release; adb shell getprop ro.product.model; echo "## packages"; adb shell pm list packages | grep -i -E 'chrome|youtube|gboard|latin|vending|instagram|facebook' ; } >> $L
home(){ adb shell input keyevent KEYCODE_HOME; sleep 2; }
# notification history
adb shell am start -a android.settings.NOTIFICATION_HISTORY; sleep 4; dump n1-history
# notifications settings (snooze toggle)
home; adb shell am start -a android.settings.NOTIFICATION_SETTINGS; sleep 4; dump n2-notif; adb shell input swipe 540 1800 540 800 300; sleep 2; dump n3-notif-scrolled
# app pinning
home; adb shell am start -a android.settings.SECURITY_SETTINGS; sleep 4; dump p1-security
tapt "More security" && dump p2-more; tapt "App pinning" && dump p3-pin
# one-handed
home; adb shell am start -a android.settings.SETTINGS; sleep 4; tapt "System" && dump o1-system; tapt "Gestures" && dump o2-gestures; tapt "One-handed" && dump o3-one
# animations
home; adb shell am start -a android.settings.ACCESSIBILITY_SETTINGS; sleep 4; dump a1-access; tapt "Color and motion" && dump a2-color; tapt "Remove animations" && dump a3-anim
# quick settings edit + snooze post
home; adb shell cmd notification post -S bigtext -t "Demo" t1 "Test message for snooze" >> $L 2>&1; sleep 2
adb shell input swipe 540 5 540 1200 300; sleep 2; adb shell input swipe 540 5 540 1500 300; sleep 3; dump q1-shade
adb shell cmd statusbar collapse; 
# wifi qr
home; adb shell am start -a android.settings.WIFI_SETTINGS; sleep 4; dump w1-wifi
ls -l out >> $L; cat $L
