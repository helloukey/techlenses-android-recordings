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
python3 - <<'P'
from PIL import Image,ImageDraw
for i,(a,b) in enumerate([((255,120,60),(40,20,90)),((40,200,160),(10,40,80)),((250,210,60),(150,40,60))]):
    im=Image.new('RGB',(1200,900));d=ImageDraw.Draw(im)
    for y in range(900):
        t=y/900;d.line([(0,y),(1200,y)],fill=tuple(int(a[k]*(1-t)+b[k]*t) for k in range(3)))
    d.ellipse((450,250,750,550),fill=(255,255,255))
    im.save(f'/tmp/sample{i+1}.png')
P
adb shell mkdir -p /sdcard/Pictures /sdcard/DCIM/Camera
for i in 1 2 3; do adb push /tmp/sample$i.png /sdcard/Pictures/sample$i.png; adb push /tmp/sample$i.png /sdcard/DCIM/Camera/photo$i.png; done
adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/sample1.png >/dev/null
adb shell input keyevent KEYCODE_HOME; sleep 2
adb shell "nohup screenrecord --time-limit 170 --size 720x1600 --bit-rate 6000000 /sdcard/a6.mp4 >/dev/null 2>&1 &"
sleep 2
for f in apk/*.apk; do adb install -r $f 2>&1 | tee -a out/install.txt; done
# PocketPal APK from GitHub releases (install/launch check only)
curl -s https://api.github.com/repos/a-ghorbani/pocketpal-ai/releases/latest > out/pocketpal-release.json
python3 - <<'P' > /tmp/ppurl
import json
d=json.load(open('out/pocketpal-release.json'))
print(d.get('tag_name'),file=__import__('sys').stderr)
for a in d.get('assets',[]):
    print(a['name'],a['browser_download_url'],a['size'])
P
cat /tmp/ppurl | tee out/pocketpal-assets.txt
PPU=$(grep -E '\.apk' /tmp/ppurl | head -1 | awk '{print $2}')
if [ -n "$PPU" ]; then curl -sL -o apk/pocketpal.apk "$PPU"; ls -l apk/pocketpal.apk; adb install -r apk/pocketpal.apk 2>&1 | tee out/pocketpal-install.txt; fi
adb shell cmd package set-home-activity com.supernova.launcher/.LauncherActivity
adb shell input keyevent KEYCODE_HOME; sleep 5; shot z0
tap_text "Get started" a; sleep 3
for i in 1 2 3 4 5 6 7 8 9 10; do tap_next; sleep 2; shot z1-$i; done
dump zend
adb shell input keyevent KEYCODE_HOME; sleep 3; shot z2-home
adb shell input swipe 360 800 360 800 1200; sleep 3
tap_text "Settings" s1; sleep 3
tap_text "Icons & labels" ic; sleep 3
tap_text "Icon shape" sh; sleep 3
tap_text "Hexagon" hx; sleep 2; shot z3-shape-hex
adb shell input keyevent KEYCODE_BACK; sleep 1; adb shell input keyevent KEYCODE_BACK; sleep 1
tap_text "Home screen" hs; sleep 3; shot z4-homescreen-settings
adb shell input keyevent KEYCODE_HOME; sleep 3; shot z5-home-after
adb shell input swipe 360 1300 360 400 400; sleep 3; shot z6-drawer-after
adb shell input keyevent KEYCODE_HOME; sleep 2
# Fossify Gallery
adb shell appops set org.fossify.gallery MANAGE_MEDIA allow
adb shell appops set org.fossify.gallery MANAGE_EXTERNAL_STORAGE allow
for perm in READ_MEDIA_IMAGES READ_MEDIA_VIDEO POST_NOTIFICATIONS; do adb shell pm grant org.fossify.gallery android.permission.$perm; done
adb shell monkey -p org.fossify.gallery -c android.intent.category.LAUNCHER 1; sleep 8; shot g1
tap_text "Media only" mo; sleep 4; shot g2
tap_text "Camera" cam; sleep 3; shot g3
tap_text "Pictures" pic; sleep 3; shot g4
# PocketPal launch
adb shell pm list packages | grep -i pocketpal | tee out/pp-pkg.txt
PP=$(sed 's/package://' out/pp-pkg.txt | head -1)
if [ -n "$PP" ]; then adb shell monkey -p $PP -c android.intent.category.LAUNCHER 1; sleep 10; shot p1-pocketpal; fi
sleep 15
adb pull /sdcard/a6.mp4 out/a6.mp4 || true
rm -rf apk
ls -l out
