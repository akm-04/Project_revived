#!/bin/bash
# I8.5-7 emulator smoke (D37, D68): the rebuilt stock APK on the tmp/android AVD against gxb-api and gxb-sdk-harness.
# usage: emulator_smoke.sh up <database> | shot <name> | tap <x> <y> | text <string> | key <keycode> | remember-region <id> |
#        probe-errorlog [text] | down
# up expects a fresh, deployed database (the strict-gate recipe) and the binaries in tmp/virtualclient/bin.
set -euo pipefail
W=/home/akm/Chatgpt/EOL_Game
A=$W/tmp/android
V=$W/tmp/virtualclient
RUN=$A/run
export ANDROID_SDK_ROOT=$A/sdk ANDROID_HOME=$A/sdk ANDROID_USER_HOME=$A/home ANDROID_EMULATOR_HOME=$A/home ANDROID_AVD_HOME=$A/home/avd
ADB=$A/sdk/platform-tools/adb
APK=$A/apk_build/signed/unsigned-aligned-debugSigned.apk
PACKAGE=com.carolgames.gxb
GAME_FILES=/data/data/$PACKAGE/files
DEVICE_ORIGIN=http://10.0.2.2:18853

start() { "$@" & echo $! >> "$RUN/pids"; }

up() {
  local database=$1
  rm -rf "$RUN" && mkdir -p "$RUN/shots"
  local dsn="postgres://postgres@/$database?host=$W/tmp/test-databases/i853_dev&port=55853"
  export GXB_CREDENTIAL_DIGEST_SECRET=vc-fixture-digest-key-000000001
  start env GXB_POSTGRES_DSN="$dsn" GXB_HTTP_ADDR=127.0.0.1:18853 GXB_PUBLIC_ENGINE_URL=$DEVICE_ORIGIN/engine \
    GXB_CLIENT_LOG_URL=$DEVICE_ORIGIN/client-log GXB_REALTIME_PUBLIC_HOST=10.0.2.2 GXB_REALTIME_PUBLIC_PORT=18854 \
    GXB_GAMEPLAY_BEARER_SECRET=vc-fixture-bearer-key-000000001 GXB_REDEEM_DIGEST_SECRET=vc-fixture-redeem-key-000000001 \
    GXB_DERIVATION_KEY_ID=vc-native GXB_PROFILE_MEDIA_ROOT=$RUN/private-media GXB_PROFILE_MEDIA_PUBLIC_ORIGIN=$DEVICE_ORIGIN \
    GXB_COMBAT_ENTROPY_KEYS=vc1=7663000000000000000000000000000000000000000000000000000000000001 GXB_COMBAT_ENTROPY_KEY_CURRENT=vc1 \
    "$V/bin/gxb-api" > "$RUN/api.log" 2>&1
  start env GXB_POSTGRES_DSN="$dsn" GXB_REALTIME_ADDR=127.0.0.1:18854 GXB_REALTIME_PUBLIC_HOST=10.0.2.2 GXB_REALTIME_PUBLIC_PORT=18854 \
    GXB_GAMEPLAY_BEARER_SECRET=vc-fixture-bearer-key-000000001 GXB_DERIVATION_KEY_ID=vc-native "$V/bin/gxb-realtime" > "$RUN/realtime.log" 2>&1
  start "$V/bin/gxb-sdk-harness" -listen 127.0.0.1:18855 -database "$dsn" > "$RUN/sdk.log" 2>&1
  # swiftshader_indirect and guest segfault on this host (SELinux execheap denies the SwiftShader GLES JIT); swangle_indirect boots
  start "$A/sdk/emulator/emulator" -avd gxb30 -no-window -no-audio -no-boot-anim -no-snapshot -gpu "${EMU_GPU:-swangle_indirect}" > "$RUN/emulator.log" 2>&1
  "$ADB" wait-for-device
  until [ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ]; do sleep 2; done
  "$ADB" install -r "$APK"
  "$ADB" logcat -c
  "$ADB" logcat > "$RUN/logcat.log" 2>&1 & echo $! >> "$RUN/pids"
  "$ADB" shell am start -n $PACKAGE/org.cocos2dx.lua.AppActivity
  echo up
}

case "$1" in
  up) up "$2" ;;
  shot) "$ADB" exec-out screencap -p > "$RUN/shots/$2.png" && echo "$RUN/shots/$2.png" ;;
  tap) "$ADB" shell input tap "$2" "$3" ;;
  text) "$ADB" shell input text "$2" ;;
  key) "$ADB" shell input keyevent "$2" ;;
  remember-region)
    # H07: a fresh install picks regions[4] and our directory has two, so stock leaves no region; seed the row stock Meta:persist
    # writes (as the VC's RememberedRegion does). Then the "Click to switch" region window works and MID18 is sent in-session.
    "$ADB" root > /dev/null && sleep 2
    "$ADB" shell am force-stop $PACKAGE
    "$ADB" shell "sqlite3 $GAME_FILES/game.db \"INSERT OR REPLACE INTO meta (id, sid, regionID, regionName, playerID, playerName) VALUES (0, '', $2, 'Server $2', 0, '')\""
    "$ADB" shell am start -n $PACKAGE/org.cocos2dx.lua.AppActivity ;;
  probe-errorlog)
    # One row in stock's errorlog store, as ErrorLogPoster finds after a Lua error; it uploads within 30 s once MID1 issued log_url.
    "$ADB" root > /dev/null && sleep 2
    "$ADB" shell "sqlite3 $GAME_FILES/log.db \"INSERT INTO errorlog (time, app_v, version, isCrash, dump, log) VALUES (strftime('%s','now'), '1.631.0', '1.631.0', 0, '', '${2:-emulator probe}')\"" ;;
  down)
    "$ADB" emu kill || true
    [ -f "$RUN/pids" ] && xargs -r kill < "$RUN/pids" 2>/dev/null || true
    rm -f "$RUN/pids"
    echo down ;;
  *) echo "usage: $0 up <database> | shot <name> | tap <x> <y> | text <s> | key <code> | remember-region <id> | probe-errorlog [text] | down" >&2; exit 2 ;;
esac
