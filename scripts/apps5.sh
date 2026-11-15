#!/usr/bin/env bash
# Probe 3: walk Supernova onboarding/settings; Fossify with permissions granted.
set -x
mkdir -p out apk
R=https://f-droid.org/repo
for f in com.supernova.launcher_6.apk org.fossify.gallery_40.apk org.fossify.notes_13.apk org.fossify.filemanager_16.apk; do
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
read W H < <(adb shell wm size | grep -oE '[0-9]+x[0-9]+' | tail -1 | tr x ' ')
AX=$((W*81/100)); AY=$((H*92/100)); echo "screen $W x $H arrow $AX $AY"
tapxy(){ adb shell input tap $1 $2; }
python3 - <<'P'
from PIL import Image,ImageDraw
import colorsys
for i,(a,b) in enumerate([((255,120,60),(40,20,90)),((40,200,160),(10,40,80)),((250,210,60),(150,40,60))]):
    im=Image.new('RGB',(1200,900));d=ImageDraw.Draw(im)
    for y in range(900):
        t=y/900;d.line([(0,y),(1200,y)],fill=tuple(int(a[k]*(1-t)+b[k]*t) for k in range(3)))
    d.ellipse((450,250,750,550),fill=(255,255,255))
    im.save(f'/tmp/sample{i+1}.png')
P
adb shell mkdir -p /sdcard/Pictures
for i in 1 2 3; do adb push /tmp/sample$i.png /sdcard/Pictures/sample$i.png; adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/sample$i.png >/dev/null; done
adb shell input keyevent KEYCODE_HOME; sleep 2
adb shell "nohup screenrecord --time-limit 170 --size 720x1600 --bit-rate 6000000 /sdcard/a4.mp4 >/dev/null 2>&1 &"
sleep 2
for f in apk/*.apk; do adb install -r $f 2>&1 | tee -a out/install.txt; done
adb shell cmd package set-home-activity com.supernova.launcher/.LauncherActivity
adb shell input keyevent KEYCODE_HOME; sleep 5; shot w0
tap_text "Get started" a; sleep 3
tap_text "Skip setup" sk; sleep 4; shot y1-after-skip
adb shell input keyevent KEYCODE_HOME; sleep 3; shot y2-home-before
adb shell input swipe 360 800 360 800 1200; sleep 3
tap_text "Settings" s1; sleep 3
tap_text "Icons & labels" ic; sleep 3
tap_text "Icon shape" sh; sleep 3; shot y3-shape-dialog
tap_text "Squircle" q1; tap_text "Circle" q2; sleep 2; shot y4-shape-picked
adb shell input keyevent KEYCODE_BACK; sleep 1
tap_text "Themed icons" th; sleep 2; shot y5-themed
adb shell input keyevent KEYCODE_HOME; sleep 3; shot y6-home-after
adb shell input swipe 360 1300 360 400 400; sleep 3; shot y7-drawer-after
adb shell input keyevent KEYCODE_HOME; sleep 2
for perm in READ_MEDIA_IMAGES READ_MEDIA_VIDEO POST_NOTIFICATIONS; do adb shell pm grant org.fossify.gallery android.permission.$perm; done
adb shell monkey -p org.fossify.gallery -c android.intent.category.LAUNCHER 1; sleep 8; shot x1-gallery
tap_text "Media only" mo; sleep 4; shot x2-gallery-media; tap_text "Pictures" gp; sleep 3; shot x3-gallery-pictures
sleep 20
adb pull /sdcard/a4.mp4 out/a4.mp4 || true
ls -l out
