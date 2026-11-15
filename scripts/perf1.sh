#!/usr/bin/env bash
set -x
mkdir -p out
log(){ echo "$(date +%T) $*" | tee -a out/steps.log; }
dump(){ adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1; adb pull /sdcard/u.xml out/ui-$1.xml >/dev/null 2>&1; }
tap_text(){ dump $2
 python3 - "$1" out/ui-$2.xml > /tmp/xy <<'P'
import sys,re,html
t=sys.argv[1].lower();x=open(sys.argv[2]).read()
for m in re.finditer(r'(?:text|content-desc)="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',x):
    if t in html.unescape(m.group(1)).lower():
        a=[int(v) for v in m.groups()[1:]];print((a[0]+a[2])//2,(a[1]+a[3])//2);break
P
 if [ -s /tmp/xy ]; then adb shell input tap $(cat /tmp/xy); log tapped "$1"; else log NOTFOUND "$1"; fi; }
expect(){ dump chk; if grep -qi "$1" out/ui-chk.xml; then log OK-state "$1"; else log FAIL-state "$1"; fi; }
QP=$(pgrep -f qemu-system | head -1); log qemu-pid $QP nproc $(nproc)
tr '\0' ' ' < /proc/$QP/cmdline | head -c 600 > out/qemu-cmdline.txt
( while true; do echo "$(date +%s) $(head -1 /proc/stat) | $(awk '{print $14,$15}' /proc/$QP/stat) | $(free -m | awk '/Mem/{print $3,$7}') | $(cat /proc/pressure/cpu 2>/dev/null | head -1)"; sleep 2; done > out/host.log ) &
SAMP=$!
adb shell input keyevent KEYCODE_HOME; sleep 2
adb shell am force-stop com.android.settings
adb shell am start -n com.android.settings/.Settings; sleep 4
scroll(){ for i in $(seq 1 $1); do adb shell input swipe 360 1300 360 500 350; adb shell input swipe 360 500 360 1300 350; done; }
# phase A: control, no recording
adb shell dumpsys gfxinfo com.android.settings reset >/dev/null
log phaseA-start; scroll 10; log phaseA-end
adb shell dumpsys gfxinfo com.android.settings > out/gfx-A-norec.txt
adb shell top -b -n1 -m 8 > out/guest-top-A.txt
# phase B: recording mode 1, self-terminating mp4
adb shell "nohup screenrecord --time-limit 45 --size 720x1600 --bit-rate 6000000 /sdcard/rb.mp4 >/dev/null 2>&1 &"; sleep 2
adb shell dumpsys gfxinfo com.android.settings reset >/dev/null
log phaseB-start; scroll 10
adb shell top -b -n1 -m 8 > out/guest-top-B.txt
tap_text "Display" d1; sleep 3; expect "Dark theme"
tap_text "Dark theme" d2; sleep 3; expect "Use Dark theme"
scroll 3
log phaseB-end
adb shell dumpsys gfxinfo com.android.settings > out/gfx-B-rec.txt
for i in $(seq 1 30); do adb shell pgrep screenrecord >/dev/null || break; sleep 2; done
log screenrecord-exited-after-$i
adb shell ls -l /sdcard/rb.mp4 | tee -a out/steps.log
adb pull /sdcard/rb.mp4 out/rb.mp4 || log PULL-FAILED
# phase C: raw h264 stream
adb shell input keyevent KEYCODE_HOME; sleep 2
adb shell am start -n com.android.settings/.Settings; sleep 3
adb exec-out screenrecord --time-limit 25 --output-format=h264 --size 720x1600 --bit-rate 6000000 - > out/rc.h264 &
RP=$!; sleep 2
scroll 5
wait $RP; ls -l out/rc.h264 | tee -a out/steps.log
adb shell settings put secure ui_night_mode 0
kill $SAMP
ls -l out | tee -a out/steps.log
