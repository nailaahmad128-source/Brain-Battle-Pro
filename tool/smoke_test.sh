#!/usr/bin/env bash
# Runs inside an Android emulator (CI). Installs the release APK, launches it like a user
# tapping the icon, drives it with random input, and fails on any crash. Logs are kept in smoke_out/.
PKG=com.midostudio.brainbattlepro
APK="$1"
OUT=smoke_out
mkdir -p "$OUT"
FAIL=0

adb install -r "$APK" || { echo "::error::APK install failed"; exit 1; }
adb logcat -c
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 | tee "$OUT/launch.txt"
sleep 8
adb exec-out screencap -p > "$OUT/1_splash_or_home.png"
sleep 12
adb exec-out screencap -p > "$OUT/2_home.png"

PID=$(adb shell pidof "$PKG" | tr -d '\r')
if [ -z "$PID" ]; then
  echo "::error::App process is not running ~20s after launch (it crashed or exited)"
  FAIL=1
fi

# the app must be the foreground activity (a live process alone is not enough)
adb shell dumpsys activity activities > "$OUT/activities.txt"
if ! grep -E "mResumedActivity|topResumedActivity" "$OUT/activities.txt" | grep -q "$PKG"; then
  echo "::error::$PKG is not the resumed (foreground) activity after launch"
  FAIL=1
fi

# user-like stress: 400 random taps/gestures inside the app only; monkey stops and prints on a crash
adb shell monkey -p "$PKG" -s 7 --throttle 200 --pct-syskeys 0 --pct-appswitch 0 400 > "$OUT/monkey.txt" 2>&1
adb exec-out screencap -p > "$OUT/3_after_monkey.png"
if grep -Eq "// CRASH|ANR in|Monkey aborted" "$OUT/monkey.txt"; then
  echo "::error::Monkey run crashed the app"; FAIL=1
fi

adb logcat -d > "$OUT/logcat_full.txt"
adb logcat -d -b crash > "$OUT/logcat_crash.txt"
if grep -q "FATAL EXCEPTION" "$OUT/logcat_full.txt"; then
  echo "::error::FATAL EXCEPTION found in logcat - first occurrence:"
  grep -m1 -B3 -A40 "FATAL EXCEPTION" "$OUT/logcat_full.txt"
  FAIL=1
fi
grep -E "BBP |flutter|AndroidRuntime" "$OUT/logcat_full.txt" | tail -80 > "$OUT/logcat_app_tail.txt"
echo "--- app log tail ---"; cat "$OUT/logcat_app_tail.txt"
exit $FAIL
