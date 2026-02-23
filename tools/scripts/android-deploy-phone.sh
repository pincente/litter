#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ANDROID_DIR="$REPO_DIR/apps/android"
MAIN_ACTIVITY="com.sigkitten.litter.android/com.litter.android.MainActivity"

usage() {
  cat <<'EOF'
Usage: tools/scripts/android-deploy-phone.sh [onDevice|remoteOnly]

Builds the selected debug flavor, installs it to a connected Android device,
and launches the app.

Defaults:
  flavor: onDevice

Environment:
  ANDROID_SERIAL  Optional. Target specific device serial when multiple devices are connected.
EOF
}

resolve_device_args() {
  local -a devices
  mapfile -t devices < <(adb devices | awk 'NR > 1 && $2 == "device" { print $1 }')

  if [ -n "${ANDROID_SERIAL:-}" ]; then
    if ! printf '%s\n' "${devices[@]}" | grep -Fxq "$ANDROID_SERIAL"; then
      echo "error: ANDROID_SERIAL is set to '$ANDROID_SERIAL' but that device is not connected." >&2
      exit 1
    fi
    printf '%s' "-s $ANDROID_SERIAL"
    return
  fi

  if [ "${#devices[@]}" -eq 0 ]; then
    echo "error: no connected Android devices. Check 'adb devices' and USB/wireless debugging." >&2
    exit 1
  fi

  if [ "${#devices[@]}" -gt 1 ]; then
    echo "error: multiple devices connected. Set ANDROID_SERIAL to target one device." >&2
    printf 'connected devices:\n' >&2
    printf '  %s\n' "${devices[@]}" >&2
    exit 1
  fi

  printf '%s' "-s ${devices[0]}"
}

flavor="${1:-onDevice}"
if [ "$flavor" = "-h" ] || [ "$flavor" = "--help" ]; then
  usage
  exit 0
fi

assemble_task=""
apk_path=""
case "$flavor" in
  onDevice)
    assemble_task=":app:assembleOnDeviceDebug"
    apk_path="$ANDROID_DIR/app/build/outputs/apk/onDevice/debug/app-onDevice-debug.apk"
    ;;
  remoteOnly)
    assemble_task=":app:assembleRemoteOnlyDebug"
    apk_path="$ANDROID_DIR/app/build/outputs/apk/remoteOnly/debug/app-remoteOnly-debug.apk"
    ;;
  *)
    echo "error: unknown flavor '$flavor'." >&2
    usage >&2
    exit 1
    ;;
esac

if [ ! -x "$ANDROID_DIR/gradlew" ]; then
  echo "error: missing Gradle wrapper at $ANDROID_DIR/gradlew" >&2
  echo "run: gradle -p apps/android wrapper --gradle-version 9.3.1" >&2
  exit 1
fi

device_args="$(resolve_device_args)"

echo "==> Building $flavor debug APK..."
"$ANDROID_DIR/gradlew" -p "$ANDROID_DIR" "$assemble_task"

if [ ! -f "$apk_path" ]; then
  echo "error: expected APK not found: $apk_path" >&2
  exit 1
fi

echo "==> Installing APK..."
# shellcheck disable=SC2086
adb $device_args install -r "$apk_path"

echo "==> Launching app..."
# shellcheck disable=SC2086
adb $device_args shell am start -n "$MAIN_ACTIVITY"

echo "==> Done."
