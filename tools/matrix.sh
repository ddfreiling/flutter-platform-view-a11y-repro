#!/bin/zsh
# Runs every variant x mode on a connected device with TalkBack on and writes, per combination:
#   <out>/<v>-<m>-full.xml   uiautomator dump (includes views that are not important)
#   <out>/<v>-<m>-comp.xml   uiautomator dump --compressed (important views only)
#   <out>/<v>-<m>-views.txt  native view classes from dumpsys (confirms the composition mode)
#   <out>/<v>-<m>-tb.txt     TalkBack focus rectangle per swipe (8 x next, then 8 x previous)
# Then prints a summary via summarize.py.
#
# usage: TB_SERIAL=<serial> tools/matrix.sh <out dir> [variant/mode ...]
S=${TB_SERIAL:?set TB_SERIAL to the adb device serial}
OUT=${1:?output dir}; shift; mkdir -p $OUT
HERE=${0:a:h}
PKG=com.example.platform_view_a11y_repro
COMBOS=(${@:-container/hc container/tlhc textview/hc textview/tlhc webview/hc webview/tlhc \
  container_webview/hc container_webview/tlhc workaround/hc workaround/tlhc})

dump() { adb -s $S shell uiautomator dump $2 /sdcard/repro.xml >/dev/null; adb -s $S exec-out cat /sdcard/repro.xml > $1; }

for c in $COMBOS; do
  n=${c/\//-}
  echo "== $c"
  adb -s $S shell am start -S -n $PKG/.MainActivity --es route /$c >/dev/null
  sleep 5
  dump $OUT/$n-full.xml
  dump $OUT/$n-comp.xml --compressed
  adb -s $S shell dumpsys activity top | grep -E "PlatformViewWrapper|FlutterMutatorView|VirtualDisplay|WebView|TextView|LinearLayout|WorkaroundRoot|FlutterView" \
    | grep -v "^ *Local\|mAdded" | sed 's/{[^}]*}//' > $OUT/$n-views.txt
  TB_SHOTS=$OUT $HERE/tb.sh $n- rrrrrrrrllllllll > $OUT/$n-tb.txt
done
python3 -I $HERE/summarize.py $OUT $COMBOS
