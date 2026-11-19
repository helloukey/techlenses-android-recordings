#!/usr/bin/env bash
# Public Android 14 qualification using generic demo text only.
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
  a,b,c,d=map(int,re.findall(r'\d+',n.get('bounds','')))
  print((a+c)//2,(b+d)//2);break
PY
snap(){
 adb shell uiautomator dump /sdcard/u.xml > /tmp/dump-result.txt 2>&1
 adb pull /sdcard/u.xml /tmp/u.xml > /tmp/pull-result.txt 2>&1
 cp /tmp/u.xml "out/$1.xml"
 echo "## $1" >> "$L"
 python3 - >> "$L" <<'PY'
import xml.etree.ElementTree as ET
print(' | '.join(v for n in ET.parse('/tmp/u.xml').getroot().iter('node') for k in ('text','content-desc') if (v:=n.get(k,''))))
PY
 adb exec-out screencap -p > "out/$1.png"
}
taptext(){
 adb shell uiautomator dump /sdcard/u.xml > /tmp/dump-result.txt 2>&1
 adb pull /sdcard/u.xml /tmp/u.xml > /tmp/pull-result.txt 2>&1
 XY=$(python3 /tmp/find.py "$1")
 if [ -n "$XY" ]; then echo "TAP $1 $XY" >> out/taps.txt; adb shell input tap $XY; sleep 3; else echo "NOT FOUND $1" >> "$L"; return 1; fi
}
# Open the observed toolbar menu at 5.5% width, 65.5% height.
adb shell am start -a android.settings.SETTINGS >> "$L" 2>&1
sleep 5
taptext 'Wait' || true
sleep 8
taptext 'Search settings' || taptext 'Search' || true
adb shell input text 'Tech%sLenses%sdemo'
snap c0-text
SIZE=$(adb shell wm size | grep -o '[0-9]*x[0-9]*' | head -1)
W=${SIZE%x*}; H=${SIZE#*x}
adb shell input tap $((W*55/1000)) $((H*655/1000))
sleep 3;snap c1-toolbar
# Clipboard icon visibly centered at x50%, y65.5% in run41.
adb shell input tap $((W*50/100)) $((H*655/1000))
sleep 3;snap c2-clipboard
# Observed Turn on Clipboard button at75%,81.3%.
adb shell input tap $((W*75/100)) $((H*813/1000))
sleep 3;snap c3-enabled
# Select only harmless sample text. No submit or send.
adb shell input swipe $((W*35/100)) $((H*87/1000)) $((W*35/100)) $((H*87/1000)) 1000
sleep 3;snap c4-selection
taptext 'Select all' || true
snap c5-selectall
taptext 'Copy' || true
snap c6-copied
# Return to the visible clipboard panel through same observed toolbar coordinates.
adb shell input tap $((W*55/1000)) $((H*655/1000))
sleep 2
adb shell input tap $((W*50/100)) $((H*655/1000))
sleep 3;snap c7-clip
# Long press the first clip, capture available actions, act only on actual Pin label.
adb shell input swipe $((W*25/100)) $((H*77/100)) $((W*25/100)) $((H*77/100)) 1000
sleep 3;snap c8-clipactions
taptext 'Pin' || true
snap c9-pinned
adb shell input keyevent KEYCODE_BACK
adb shell input keyevent KEYCODE_BACK
adb shell am start -a android.settings.ACCESSIBILITY_SETTINGS >> "$L" 2>&1
sleep 3;taptext 'Magnification' || true
snap m1-settings
# Shortcut switch observed at x89%, y70% of the display.
adb shell input tap $((W*89/100)) $((H*70/100))
sleep 3;snap m2-shortcut
# Follow only an actual approval label if present, capture remaining instructions.
taptext 'Got it' || true
snap m3-shortcut
# Floating shortcut visible at94%,74%; activate then select display center.
adb shell input tap $((W*94/100)) $((H*74/100))
sleep 2;snap m4-activated
adb shell input tap $((W*50/100)) $((H*32/100))
sleep 3;snap m5-zoomed
adb shell input tap $((W*94/100)) $((H*74/100))
sleep 3;snap m6-exit
