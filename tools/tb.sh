#!/bin/zsh
# Drives TalkBack on a connected Android device through a temporary uinput touchscreen.
# `adb shell input` events bypass TalkBack; a uinput device goes through it like a real finger.
#
# usage: tb.sh <prefix> <gestures>
#   r  swipe right (next item)      l  swipe left (previous item)
#   d  double tap (activate)        t/u/s  touch-explore (hold) at fixed points, edit below
# Takes a screenshot after each gesture into $TB_SHOTS (default $TMPDIR/shots) and prints the
# bounding box of TalkBack's blue focus rectangle per step (None = no rectangle visible).
# Coordinates assume a 1080x2340 screen. Set TB_SERIAL to the adb serial.
S=${TB_SERIAL:?set TB_SERIAL to the adb device serial}
D=${TB_SHOTS:-${TMPDIR:-/tmp}/shots}; mkdir -p $D
P=$1; G=$2
HERE=${0:a:h}
ev(){ echo "{\"id\":2,\"command\":\"inject\",\"events\":[$1]}"; }
swipe(){ ev "3,47,0,3,57,$RANDOM,3,53,$1,3,54,$2,3,58,50,1,330,1,0,0,0"; sleep 0.02
 for k in 1 2 3 4 5 6; do x=$(( $1 + ($3-$1)*k/6 )); ev "3,53,$x,3,54,$2,0,0,0"; sleep 0.02; done
 ev "3,57,-1,1,330,0,0,0,0"; }
hold(){ ev "3,47,0,3,57,$RANDOM,3,53,$1,3,54,$2,3,58,50,1,330,1,0,0,0"; sleep 0.6
 ev "3,53,$(($1+3)),3,54,$2,0,0,0"; sleep 0.4; ev "3,57,-1,1,330,0,0,0,0"; }
tap(){ ev "3,47,0,3,57,$RANDOM,3,53,$1,3,54,$2,3,58,50,1,330,1,0,0,0"; sleep 0.04; ev "3,57,-1,1,330,0,0,0,0"; }
REG='{"id":2,"command":"register","name":"Diag Touch","vid":6353,"pid":11329,"bus":"usb","configuration":[{"type":100,"data":[1,3]},{"type":101,"data":[330]},{"type":103,"data":[47,53,54,57,58]},{"type":110,"data":[1]}],"abs_info":[{"code":47,"info":{"value":0,"minimum":0,"maximum":9,"fuzz":0,"flat":0,"resolution":0}},{"code":53,"info":{"value":0,"minimum":0,"maximum":1079,"fuzz":0,"flat":0,"resolution":0}},{"code":54,"info":{"value":0,"minimum":0,"maximum":2339,"fuzz":0,"flat":0,"resolution":0}},{"code":57,"info":{"value":0,"minimum":0,"maximum":65535,"fuzz":0,"flat":0,"resolution":0}},{"code":58,"info":{"value":0,"minimum":0,"maximum":255,"fuzz":0,"flat":0,"resolution":0}}]}'
( echo "$REG"; sleep 5; i=0
  for g in ${(s::)G}; do i=$((i+1))
    case $g in
      r) swipe 300 1900 850;;
      l) swipe 850 1900 300;;
      d) tap 540 1900; sleep 0.12; tap 540 1900;;
      t) hold 300 620;;
      u) hold 300 1500;;
      s) hold 990 340;;
    esac
    sleep 2.5; adb -s $S exec-out screencap -p > $D/$P$i.png
  done; sleep 1 ) | adb -s $S shell uinput - >/dev/null 2>&1
python3 -I $HERE/focus.py $D $P ${#G}
