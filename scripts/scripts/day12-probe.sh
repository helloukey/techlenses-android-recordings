#!/usr/bin/env bash
# Android 14 public demonstration probe. No accounts, credentials or private data.
set -u
mkdir -p out
L=out/log.txt
sleep 45
adb shell getprop ro.build.version.release > "$L"
adb shell settings put global hide_error_dialogs 1
cat > /tmp/find.py <<'PY'
import sys,re,xml.etree.ElementTree as ET
term=sys.argv[1].lower()
for n in ET.parse('/tmp/u.xml').getroot().iter('node'):
 if any(term==n.get(k,'').lower() for k in ('text','content-desc')):
  x1,y1,x2,y2=map(int,re.findall(r'\d+',n.get('bounds','')))
  print((x1+x2)//2,(y1+y2)//2);break
PY
snap(){
 adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1
 adb pull /sdcard/u.xml /tmp/u.xml >/dev/null 2>&1
 cp /tmp/u.xml "out/$1.xml"
 echo "## $1" >> "$L"
 python3 - >> "$L" <<'PY'
import xml.etree.ElementTree as ET
print(' | '.join(v for n in ET.parse('/tmp/u.xml').getroot().iter('node') for k in ('text','content-desc') if (v:=n.get(k,''))))
PY
 adb exec-out screencap -p > "out/$1.png"
}
taptext(){
 adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1
 adb pull /sdcard/u.xml /tmp/u.xml >/dev/null 2>&1
 XY=$(python3 /tmp/find.py "$1")
 if [ -n "$XY" ]; then echo "TAP $1 $XY" >> out/taps.txt; adb shell input tap $XY; sleep 3; else echo "NOT FOUND $1" >> "$L"; return 1; fi
}
go(){ adb shell input keyevent KEYCODE_HOME; adb shell am force-stop com.android.settings; adb shell am start -a "$2" >> "$L" 2>&1; sleep 4; snap "$1"; }
scrolltap(){ for i in 1 2 3 4; do taptext "$1" && return 0; adb shell input swipe 540 1800 540 700 350; sleep 2; done; return 1; }
# Personal dictionary qualification, generic demo text only.
adb shell ime list -s >> "$L"
adb shell am start -a android.settings.USER_DICTIONARY_SETTINGS >> "$L" 2>&1
sleep 5;snap g0-dictionary
taptext 'Wait' || true
sleep 8;snap g1-dictionary
taptext 'For all languages' || taptext 'All languages' || taptext 'English (United States)' || true
snap g2-language
taptext 'Add' || taptext 'Add word' || true
snap g3-add
# Fill visible standard dictionary fields using UI labels only.
taptext 'Type a word' || true
adb shell input text 'Thanks%sfor%syour%stime'
snap g4-word
taptext 'Optional shortcut' || true
adb shell input text 'tltx'
snap g5-shortcut
adb shell input keyevent KEYCODE_BACK
adb shell input keyevent KEYCODE_BACK
snap g6-list
adb shell am start -a android.settings.SETTINGS >> "$L" 2>&1
sleep 3;snap g7-settings
taptext 'Search settings' || taptext 'Search' || true
adb shell input text 'tltx'
snap g8-suggestion
taptext 'Thanks for your time' || true
snap g9-result
adb shell input keyevent KEYCODE_BACK
adb shell input keyevent KEYCODE_BACK
adb shell am start -a android.settings.USER_DICTIONARY_SETTINGS >> "$L" 2>&1
sleep 3;taptext 'English (United States)' || true
snap g10-saved-list
taptext 'Thanks for your time' || true
snap g11-edit
taptext 'Delete' || true
snap g12-deleted
