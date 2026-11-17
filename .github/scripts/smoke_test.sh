#!/usr/bin/env bash
set -e

echo "=== Smoke Testing Debug APK ==="
if [ -f "apks/app-x86_64-debug.apk" ]; then
  adb install -r apks/app-x86_64-debug.apk
  adb logcat -c
  adb shell monkey -p dev.elmahdi.mega -c android.intent.category.LAUNCHER 1
  sleep 20
  adb logcat -d > logcat-debug.txt
  DEBUG_PID=$(adb shell pidof dev.elmahdi.mega | tr -d '\r\n' || true)
  echo "Debug PID: $DEBUG_PID"
  adb uninstall dev.elmahdi.mega || true
fi

echo "=== Smoke Testing Release APK ==="
adb install -r apks/app-x86_64-release.apk
adb logcat -c
adb shell monkey -p dev.elmahdi.mega -c android.intent.category.LAUNCHER 1
sleep 20
adb logcat -d > logcat.txt

PID=$(adb shell pidof dev.elmahdi.mega | tr -d '\r\n' || true)
echo "Release PID: $PID"

if [ -z "$PID" ]; then
  echo "Error: Process dev.elmahdi.mega is not running after 20s!"
  exit 1
fi

if grep -E "FATAL EXCEPTION.*dev\.elmahdi\.mega|AndroidRuntime.*FATAL.*dev\.elmahdi\.mega" logcat.txt; then
  echo "Fatal exception detected in logcat for dev.elmahdi.mega!"
  exit 1
fi

echo "Smoke test passed successfully! Process running with PID $PID."
