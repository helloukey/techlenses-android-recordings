#!/usr/bin/env bash
# Makeover: walk Supernova onboarding/settings; Fossify with permissions granted.
set -x
mkdir -p out apk
R=https://f-droid.org/repo
for f in com.supernova.launcher_6.apk; do
  curl -sL -o apk/$f $R/$f; ls -l apk/$f
done
shot(){ adb exec-out screencap -p > out/$1.png; }
dump(){ adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1; adb pull /sdcard/u.xml out/ui-$1.xml >/dev/null 2>&1; }
tap_text(){ dump $2
 python3 - "$1" out/ui-$2.xml > /tmp/xy <<'P'
import sys,re,html
t=sys.argv[1].lower();x=open(sys.argv[2]).read()
for m in re.finditer(r'(?:text|content-desc)="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',x):
    if t in html.unescape(m.group(1)).lower():
        a=[int(v) for v in m.groups()[1:]];print((a[0]+a[2])//2,(a[1]+a[3])//2);break
P
 if [ -s /tmp/xy ]; then adb shell input tap $(cat /tmp/xy); echo tapped "$1"; else echo notfound "$1"; fi; }

# helper: tap the clickable node nearest the bottom-right (onboarding next arrow)
tap_next(){ dump nx
 python3 - out/ui-nx.xml > /tmp/xy <<'P'
import sys,re
x=open(sys.argv[1]).read()
best=None
for m in re.finditer(r'<node [^>]*?clickable="true"[^>]*?bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',x):
    a=[int(v) for v in m.groups()]
    cx,cy=(a[0]+a[2])//2,(a[1]+a[3])//2
    if best is None or cy*10+cx>best[1]*10+best[0]: best=(cx,cy)
if best: print(*best)
P
 if [ -s /tmp/xy ]; then cat /tmp/xy; adb shell input tap $(cat /tmp/xy); else echo no-clickable; fi; }
adb shell input keyevent KEYCODE_HOME; sleep 2
for f in apk/*.apk; do adb install -r $f 2>&1 | tee -a out/install.txt; done
# PocketPal APK from GitHub releases (install/launch check only)

lp_text(){ dump lp
 python3 - "$1" out/ui-lp.xml > /tmp/xy <<'P'
import sys,re,html
t=sys.argv[1].lower();x=open(sys.argv[2]).read()
for m in re.finditer(r'(?:text|content-desc)="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',x):
    if html.unescape(m.group(1)).lower()==t:
        a=[int(v) for v in m.groups()[1:]];print((a[0]+a[2])//2,(a[1]+a[3])//2);break
P
 if [ -s /tmp/xy ]; then read X Y < /tmp/xy; adb shell input swipe $X $Y $X $Y 900; echo longpress "$1" $X $Y; else echo notfound "$1"; fi; }
adb shell cmd package set-home-activity com.supernova.launcher/.LauncherActivity
adb shell input keyevent KEYCODE_HOME; sleep 5; shot m0
tap_text "Get started" a; sleep 3
for i in 1 2 3 4 5 6 7 8; do
  dump ob
  if grep -q "Icon style" out/ui-ob.xml; then
    adb shell input tap 517 448; sleep 1
    tap_text "Flower" fl; sleep 1; shot m-flower
  fi
  tap_next; sleep 2; shot m1-$i
done
adb shell input keyevent KEYCODE_HOME; sleep 3; shot m2-home
shot n0-home-flower
adb shell input swipe 360 1300 360 400 400; sleep 2; shot n0-drawer-flower
adb shell input keyevent KEYCODE_HOME; sleep 2
shot p0-home
tap_text "Supernova S" ss; sleep 3; shot p1-settings-main
tap_text "Icons & labels" il; sleep 3; shot n1-icons
tap_text "Themed icons" th; sleep 2; shot n2-themed-on
adb shell input keyevent KEYCODE_HOME; sleep 2; shot n2-home-themed
shot q0-home
tap_text "Supernova S" ss3; sleep 3; shot q1-settings-main
tap_text "Home screen" hs; sleep 3; shot n4-homesettings
tap_text "Desktop grid" dg; sleep 3; shot n4-grid-dialog
dump n4
adb shell input tap 681 1562; sleep 2; shot n4-grid-rows
tap_text "OK" gok; sleep 3; shot n4-grid-after
adb shell input keyevent KEYCODE_BACK; sleep 1
adb shell input keyevent KEYCODE_BACK; sleep 1
adb shell input keyevent KEYCODE_HOME; sleep 2; shot n4-home-grid
adb shell input keyevent KEYCODE_HOME; sleep 2
tap_text "Supernova S" ss4; sleep 3
tap_text "Icons & labels" il4; sleep 3; shot s0-icons
tap_text "Icon shape" ish; sleep 3; shot s1-shape-dialog
dump s1
tap_text "Squircle" sq; sleep 2; shot s2-shape-after
adb shell input keyevent KEYCODE_BACK; sleep 1
adb shell input keyevent KEYCODE_HOME; sleep 2; shot s3-home-shape
rm -rf apk
ls -l out
