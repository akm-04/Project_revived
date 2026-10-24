#!/usr/bin/env bash
# v2 build: the stock APK pointed at a GXB v2 backend (gxb-api) and its SDK endpoint.
# Only the eight origin-bearing Lua files (UpdateScene(_64).lua, data/tables/misc(1).lua in src_32 and src_64) are replaced, by
# their decompiled plaintext in origin_lua/ (identical to the client baseline decompile) with the stock origins rewritten;
# everything else stays stock bytecode. The Xinyd SDK base URL and getGoogleDNS point at the SDK endpoint. No Lua probes: v2 logs
# through the stock ErrorLogPoster and the per-session log_url that MID1 issues (client_log_uploads, request_journal), so the v1
# probe patches are not needed. MODS=1 also overlays mods/. www.game168.tw (store link of the update dialog) and
# girls.game168.com.tw (voice-actor web page) are browser links, not server calls, so they stay stock (v1 rewrote them too).
# Needs Java 17+ and python3; no wine (the decompiled Lua is in origin_lua/).
# usage: patch_game_v2.sh <engine origin, e.g. http://10.0.2.2:18853> <sdk origin, e.g. http://10.0.2.2:18855/> [build dir]
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ENGINE=${1:?engine origin}
SDK=${2:?sdk origin}
B=$(realpath -m "${3:-$HERE/build_v2}")
shopt -s nullglob
APKS=("$HERE"/app/*.apk)
[ ${#APKS[@]} -eq 1 ] || { echo "need exactly one APK in $HERE/app (found ${#APKS[@]})" >&2; exit 1; }
SDK_HOST=$(echo "$SDK" | sed -E 's#^[a-z]+://([^:/]+).*#\1#')

rm -rf "$B/decoded" "$B/signed" "$B/unsigned.apk"
java -jar "$HERE/tools/apktool.jar" d "${APKS[0]}" -o "$B/decoded" -f

for abi in src_32 src_64; do
  for file in UpdateScene.lua UpdateScene_64.lua data/tables/misc.lua data/tables/misc1.lua; do
    target=$B/decoded/assets/$abi/$file
    [ -f "$target" ] || { echo "missing stock $target" >&2; exit 1; }
    sed -e "s|http://xuemeien.carolgames.com:9000|$ENGINE|g" -e "s|http://119.81.215.217:9000|$ENGINE|g" \
        -e "s|http://203.74.199.17:9000|$ENGINE|g" "$HERE/origin_lua/$abi/$file" > "$target"
  done
done

CONSTANT=$B/decoded/smali/com/xyd/platform/android/Constant.smali
grep -q 'https://mhome.carolgames.com/' "$CONSTANT"
sed -i -E "s#https?://mhome.carolgames.com/#$SDK#g" "$CONSTANT"
python3 -I -B "$HERE/patch_google_dns.py" "$B/decoded/smali/com/xyd/platform/android/utility/XinydUtils.smali" "$SDK_HOST"
# Stock res/xml/network_security_config.xml already permits cleartext, so http origins need no manifest change.
grep -q 'cleartextTrafficPermitted="true"' "$B/decoded/res/xml/network_security_config.xml"

if [ "${MODS:-0}" = 1 ]; then
  (cd "$HERE/mods" && find . -type f) | while read -r relative; do
    if [ -f "$B/decoded/$relative" ]; then cp "$HERE/mods/$relative" "$B/decoded/$relative"; fi
  done
fi

java -jar "$HERE/tools/apktool.jar" b "$B/decoded" -o "$B/unsigned.apk"
java -jar "$HERE/tools/uber-apk-signer.jar" -a "$B/unsigned.apk" -o "$B/signed"
ls "$B/signed/"*.apk
