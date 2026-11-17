#!/usr/bin/env bash
# Android 14 Settings probe: which stock Settings areas exist and what they contain.
mkdir -p out; L=out/log.txt
adb shell settings put global hide_error_dialogs 1
adb shell settings put global development_settings_enabled 1
sleep 60
adb shell getprop ro.build.version.release >> $L
echo "## packages" >> $L
adb shell pm list packages | grep -iE "wellbeing|vending|files|documentsui|storagemanager|android.settings|chrome|quickshare|nearby" >> $L
snap(){ adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1; adb pull /sdcard/u.xml /tmp/u.xml >/dev/null 2>&1
 echo "## $1" >> $L; python3 - >> $L <<'P'
import xml.etree.ElementTree as ET
r=ET.parse('/tmp/u.xml').getroot();o=[]
for n in r.iter('node'):
 for k in ('text','content-desc'):
  v=n.get(k)
  if v: o.append(v)
print(' | '.join(o[:90]))
P
 adb exec-out screencap -p > out/$1.png; }
go(){ adb shell input keyevent KEYCODE_HOME; sleep 2; adb shell am start -a "$2" >> $L 2>&1; sleep 5; snap $1; }
go storage android.settings.INTERNAL_STORAGE_SETTINGS
go apps android.settings.APPLICATION_SETTINGS
go battery android.intent.action.POWER_USAGE_SUMMARY
go batsaver android.settings.BATTERY_SAVER_SETTINGS
go datausage android.settings.DATA_USAGE_SETTINGS
go devopts android.settings.APPLICATION_DEVELOPMENT_SETTINGS
go notif android.settings.NOTIFICATION_SETTINGS
go display android.settings.DISPLAY_SETTINGS
go a11y android.settings.ACCESSIBILITY_SETTINGS
go privacy android.settings.PRIVACY_SETTINGS
go security android.settings.SECURITY_SETTINGS
go wellbeing com.google.android.apps.wellbeing.action.DASHBOARD
adb shell input keyevent KEYCODE_HOME; adb shell am start -a android.settings.INTERNAL_STORAGE_SETTINGS >/dev/null; sleep 4
adb shell input swipe 540 1800 540 700 300; sleep 2; snap storage-scrolled
