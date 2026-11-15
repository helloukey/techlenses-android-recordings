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
adb shell input keyevent KEYCODE_HOME; sleep 2
adb shell "nohup screenrecord --time-limit 170 --size 720x1600 --bit-rate 6000000 /sdcard/a3.mp4 >/dev/null 2>&1 &"
sleep 2
for f in apk/*.apk; do adb install -r $f 2>&1 | tee -a out/install.txt; done
adb shell pm list packages | grep -E "supernova|fossify" | tee out/installed.txt
adb shell cmd package set-home-activity com.supernova.launcher/.LauncherActivity
adb shell input keyevent KEYCODE_HOME; sleep 5; shot u0
tap_text "Get started" a; sleep 3; shot u1; dump u1
for i in 2 3 4 5 6; do
  tap_text "Continue" n$i || true; sleep 2
  tap_text "Next" m$i || true; sleep 2
  tap_text "Skip" k$i || true; sleep 2
  shot u$i
done
adb shell input keyevent KEYCODE_HOME; sleep 3; shot u7-home
adb shell input swipe 360 800 360 800 1200; sleep 3; shot u8-menu
tap_text "Settings" s1; sleep 3; shot u9-settings; dump u9
adb shell input swipe 360 1200 360 400 400; sleep 2; shot u10-settings2
adb shell input keyevent KEYCODE_HOME; sleep 2
adb shell input swipe 360 1300 360 400 400; sleep 3; shot u11-drawer
for p in org.fossify.gallery org.fossify.notes org.fossify.filemanager; do
  for perm in READ_MEDIA_IMAGES READ_MEDIA_VIDEO POST_NOTIFICATIONS; do adb shell pm grant $p android.permission.$perm; done
  adb shell appops set $p MANAGE_EXTERNAL_STORAGE allow
done
adb shell am start -a android.intent.action.VIEW -d content://media/external/images/media >/dev/null 2>&1
adb shell monkey -p org.fossify.gallery -c android.intent.category.LAUNCHER 1; sleep 7; shot v1-gallery
adb shell monkey -p org.fossify.filemanager -c android.intent.category.LAUNCHER 1; sleep 7; shot v2-files
adb shell monkey -p org.fossify.notes -c android.intent.category.LAUNCHER 1; sleep 7
adb shell input text "Shopping%slist"; sleep 2; shot v3-notes
sleep 25
adb pull /sdcard/a3.mp4 out/a3.mp4 || true
ls -l out
