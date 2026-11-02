#!/usr/bin/env bash
# Signed APK for real phones, built from the workshop v2 patcher on a copy with the harness origins. Output: test_harness/apk/.
# usage: build_apk.sh [engine origin] [sdk origin]
set -euo pipefail
harness=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(dirname "$harness")
engine=${1:-https://gxbv2engine.shares.zrok.io}
sdk=${2:-https://gxbv2sdk.shares.zrok.io/}
build=$harness/runtime/apk_build
export PATH=$root/.toolchain/bin:$PATH
rm -rf "$build"
mkdir -p "$build/repack" "$harness/apk"
git -C "$root/inputs/Supplimental_Materials/gxb_workshop" archive v2 app_repack | tar -x -C "$build/repack" --strip-components=1
(cd "$root/inputs/client_baseline" && sha256sum -c --quiet SHA256SUMS)
cp "$root/inputs/client_baseline/base.apk" "$build/repack/app/"
bash "$build/repack/patch_game_v2.sh" "$engine" "$sdk" "$build"
cp "$build"/signed/*.apk "$harness/apk/gxb-v2-playtest.apk"
sha256sum "$harness/apk/gxb-v2-playtest.apk"
