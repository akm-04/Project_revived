#!/bin/bash
# I8.5-7 (D48, D68): rebuilds the stock APK for the Android emulator with the workshop repo's v2 build. app_repack is taken from
# branch v2 with git archive (the checked-out branch does not matter) and run from a copy, so nothing executes inside the supplied
# repo; the stock APK is the repo's untracked app_repack/app/base.apk. Output: tmp/android/apk_build/signed/*.apk.
# usage: build_emulator_apk.sh [engine-origin] [sdk-origin]
set -euo pipefail
W=/home/akm/Chatgpt/EOL_Game
REPO=$W/inputs/Supplimental_Materials/gxb_workshop
B=$W/tmp/android/apk_build
ENGINE=${1:-http://10.0.2.2:18853}
SDK=${2:-http://10.0.2.2:18855/}
export PATH=$W/.toolchain/bin:$PATH

rm -rf "$B" && mkdir -p "$B/repack/app"
git -C "$REPO" archive v2 app_repack | tar -x -C "$B/repack" --strip-components=1
cp "$REPO/app_repack/app/base.apk" "$B/repack/app/"
echo "workshop v2 $(git -C "$REPO" rev-parse v2)" > "$B/INPUTS.sha256"
(cd "$B/repack" && find . -type f | sort | xargs sha256sum) >> "$B/INPUTS.sha256"
bash "$B/repack/patch_game_v2.sh" "$ENGINE" "$SDK" "$B"
