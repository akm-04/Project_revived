#!/usr/bin/env bash
# Signed APK for real phones, built from the workshop v2 patcher on a copy with the harness origins. Output: test_harness/apk/.
# usage: build_apk.sh [engine origin] [sdk origin] [--http-poll|--tcp]
# --http-poll installs the HTTP polling socket factory in Backend.lua for both ABIs; --tcp (default) keeps the stock LAN socket.
set -euo pipefail
harness=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(dirname "$harness")
positional=()
http_poll=0
for argument in "$@"; do
  case "$argument" in
    --http-poll) http_poll=1 ;;
    --tcp) http_poll=0 ;;
    *) positional+=("$argument") ;;
  esac
done
engine=${positional[0]:-https://gxbv2engine.shares.zrok.io}
sdk=${positional[1]:-https://gxbv2sdk.shares.zrok.io/}
build=${GXB_APK_BUILD_DIR:-$harness/runtime/apk_build}
output=${GXB_APK_OUTPUT:-$harness/apk/gxb-v2-playtest.apk}
export PATH=$root/.toolchain/bin:$PATH
rm -rf "$build"
mkdir -p "$build/repack" "$(dirname "$output")" "$build/stock"
git -C "$root/inputs/Supplimental_Materials/gxb_workshop" archive v2 app_repack | tar -x -C "$build/repack" --strip-components=1
(cd "$root/inputs/client_baseline" && sha256sum -c --quiet SHA256SUMS)
cp "$root/inputs/client_baseline/base.apk" "$build/repack/app/"
unzip -p "$root/inputs/client_baseline/base-apk-lua-decompiled-plaintext.zip" assets/src_64/app/common/network/Backend.lua > "$build/stock/Backend.lua"
unzip -p "$root/inputs/client_baseline/base-apk-lua-decompiled-plaintext.zip" assets/src_32/app/common/network/Backend.lua > "$build/stock/Backend.src_32.lua"
cmp -s "$build/stock/Backend.lua" "$build/stock/Backend.src_32.lua"
mode=tcp
if [ "$http_poll" = 1 ]; then
  mode=http-poll
fi
"$root/.toolchain/bin/python3" -B -I "$harness/apk_overlay/apply_backend_http_poll.py" \
  --stock "$build/stock/Backend.lua" --output "$build/stock/Backend.patched.lua" --mode "$mode"
for abi in src_32 src_64; do
  mkdir -p "$build/repack/mods/assets/$abi/app/common/network"
  cp "$build/stock/Backend.patched.lua" "$build/repack/mods/assets/$abi/app/common/network/Backend.lua"
done
bash "$build/repack/patch_game_v2.sh" "$engine" "$sdk" "$build"
cp "$build"/signed/*.apk "$output"
sha256sum "$output"
echo "transport=$mode engine=$engine"
