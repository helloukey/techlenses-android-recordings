#!/usr/bin/env bash
set -x
mkdir -p out
log(){ echo "$(date +%T) $*" | tee -a out/steps.log; }
QP=$(pgrep -f qemu-system | head -1)
( while true; do echo "$(date +%s) $(head -1 /proc/stat) | $(awk '{print $14,$15}' /proc/$QP/stat) | $(free -m | awk '/Mem/{print $3,$7}')"; sleep 2; done > out/host.log ) &
SAMP=$!
adb shell wm size | tee -a out/steps.log; adb shell wm density | tee -a out/steps.log
adb shell getprop ro.product.model | tee -a out/steps.log
home(){ adb shell input keyevent KEYCODE_HOME; sleep 1; adb shell am force-stop com.android.settings; adb shell am start -n com.android.settings/.Settings --activity-clear-task; sleep 4; for i in 1 2 3 4; do adb shell input keyevent KEYCODE_BACK; done; adb shell am start -n com.android.settings/.Settings; sleep 3; }
scroll(){ for i in $(seq 1 $1); do adb shell input swipe $2 $3 $2 $4 350; adb shell input swipe $2 $4 $2 $3 350; done; }
phase(){ N=$1; W=$2; H=$3; D=$4
 if [ "$W" = "default" ]; then adb shell wm size reset; adb shell wm density reset; else adb shell wm size ${W}x${H}; adb shell wm density $D; fi
 sleep 5; adb shell wm size | tee -a out/steps.log
 home; SW=$(adb shell wm size | tail -1 | sed 's/.*: //' | cut -dx -f1); SH=$(adb shell wm size | tail -1 | sed 's/.*: //' | cut -dx -f2)
 X=$((SW/2)); Y1=$((SH*65/100)); Y2=$((SH*25/100))
 adb exec-out screencap -p > out/$N-start.png
 adb shell "nohup screenrecord --time-limit 30 --size 720x1600 --bit-rate 6000000 /sdcard/$N.mp4 >/dev/null 2>&1 &"; sleep 2
 adb shell dumpsys gfxinfo com.android.settings reset >/dev/null
 log $N-start; scroll 10 $X $Y1 $Y2; log $N-end
 adb shell dumpsys gfxinfo com.android.settings > out/gfx-$N.txt
 adb exec-out screencap -p > out/$N-end.png
 for i in $(seq 1 20); do adb shell pgrep screenrecord >/dev/null || break; sleep 2; done
 adb pull /sdcard/$N.mp4 out/$N.mp4 || log PULL-FAILED-$N
}
log renderer-info
for p in ro.hardware.egl ro.hardware.vulkan ro.kernel.qemu.gles ro.boot.qemu.gles ro.opengles.version; do echo "$p=$(adb shell getprop $p)" | tee -a out/steps.log; done
adb shell dumpsys SurfaceFlinger | grep -iE 'GLES|renderer|vendor|version' | head -8 | tee out/sf-gles.txt
adb logcat -d 2>/dev/null | grep -iE 'swiftshader|angle|gfxstream|EGL_emulation|renderer' | head -15 > out/logcat-gl.txt
tr '\0' ' ' < /proc/$QP/cmdline | head -c 700 > out/qemu-cmdline.txt
sleep 20; home; scroll 4 360 1000 400
phase R1 default
phase R2 default
phase R3 default
kill $SAMP
ls -l out | tee -a out/steps.log
