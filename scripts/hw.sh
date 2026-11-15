#!/usr/bin/env bash
mkdir -p out
{
echo "== host"; date -u; uname -a; nproc; lscpu | head -20; free -m; df -h / | tail -2
echo "== kvm"; ls -l /dev/kvm; grep -c -E 'vmx|svm' /proc/cpuinfo
echo "== emulator procs"; ps aux | grep -E 'qemu|emulator' | grep -v grep | cut -c1-600
echo "== emulator version"; $ANDROID_HOME/emulator/emulator -version 2>&1 | head -4
echo "== avd config"; cat ~/.android/avd/*.avd/config.ini 2>/dev/null | grep -E 'hw.ramSize|hw.cpu.ncore|hw.gpu|image.sysdir|disk.dataPartition|hw.lcd|abi.type|vm.heapSize'
echo "== guest"; adb shell getprop ro.build.version.release; adb shell getprop ro.build.version.sdk; adb shell getprop ro.product.cpu.abi; adb shell getprop ro.hardware.gralloc; adb shell getprop ro.kernel.qemu.gles; adb shell getprop ro.boot.qemu.gltransport; adb shell getprop ro.product.model
adb shell wm size; adb shell wm density
adb shell "grep -m1 'model name' /proc/cpuinfo; grep -c processor /proc/cpuinfo; head -2 /proc/meminfo"
echo "== screencap timing x10"
s=$(date +%s.%N); for i in 1 2 3 4 5 6 7 8 9 10; do adb exec-out screencap -p > /dev/null; done; e=$(date +%s.%N); echo "10 screencaps seconds: $(echo "$e - $s" | bc)"
echo "== uiautomator dump timing x5"
s=$(date +%s.%N); for i in 1 2 3 4 5; do adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1; done; e=$(date +%s.%N); echo "5 dumps seconds: $(echo "$e - $s" | bc)"
} > out/hw.txt 2>&1
cat out/hw.txt
