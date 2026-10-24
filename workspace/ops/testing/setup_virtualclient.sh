#!/bin/bash
# Rebuilds the virtual client runtime (default tmp/virtualclient) from inputs/ and the backend checkout alone:
#   src_64       stock decompiled client Lua   <- inputs/client_baseline/base-apk-lua-decompiled-plaintext.zip (assets/src_64)
#   apk/res      stock APK assets              <- inputs/client_baseline/base-apk-apktool-decoded-unmodified.zip (decoded_gxb/assets/res)
#   update-tree  lazy assets, MD5-verified     <- Supplimental_Materials/Game-Assets tarball + catalog via gxb-asset-tree (D30, D31, D53)
#   bin/         gxb-api (-tags postgres,river), gxb-realtime and the virtualclient commands, built from the backend working tree
# Needs the r4 toolchain at tmp/tools_r4_accept (unzipped from inputs/tools if missing) and the virtualclient module cache
# (tmp/cache/virtualclient, or the go-mod-download/ of a kit zip: GOMOD_DOWNLOAD=<dir>).
# usage: setup_virtualclient.sh [destination]
set -euo pipefail
W=/home/akm/Chatgpt/EOL_Game
V=$(realpath -m "${1:-$W/tmp/virtualclient}")
BASELINE=$W/inputs/client_baseline
GAME_ASSETS=$W/inputs/Supplimental_Materials/Game-Assets
[ -e "$V" ] && { echo "$V exists; remove it or pass another destination" >&2; exit 1; }
if [ ! -d "$W/tmp/tools_r4_accept/gxb-e2e-self-contained" ]; then
  mkdir -p "$W/tmp/tools_r4_accept"
  unzip -q "$W/inputs/tools/gxb-backend-v2-e2e-tools-r4-go1.27.3-linux-amd64.zip" -d "$W/tmp/tools_r4_accept"
fi
(cd "$BASELINE" && sha256sum -c --quiet SHA256SUMS)
mkdir -p "$V/bin" "$V/runs" "$V/unpack"
unzip -q "$BASELINE/base-apk-lua-decompiled-plaintext.zip" 'assets/src_64/*' -d "$V/unpack"
mv "$V/unpack/assets/src_64" "$V/src_64"
unzip -q "$BASELINE/base-apk-apktool-decoded-unmodified.zip" 'decoded_gxb/assets/res/*' -d "$V/unpack"
mkdir -p "$V/apk" && mv "$V/unpack/decoded_gxb/assets/res" "$V/apk/res"
rm -rf "$V/unpack"
(
  . "$W/ops/testing/goenv.sh"
  go build -tags postgres,river -o "$V/bin/gxb-api" ./cmd/gxb-api
  go build -tags postgres -o "$V/bin/gxb-realtime" ./cmd/gxb-realtime
  . "$W/ops/testing/vcenv.sh"
  if [ -n "${GOMOD_DOWNLOAD:-}" ]; then export GOPROXY=file://$GOMOD_DOWNLOAD,$GOPROXY; fi
  go build -o "$V/bin/" ./cmd/...
)
"$V/bin/gxb-asset-tree" -tarball "$GAME_ASSETS/gxb1_lazy_unified_assets_verified_1.631.0_25420.tar.zst" \
  -catalog "$GAME_ASSETS/current_lazy_catalog_pass283.csv" -out "$V/update-tree"
echo "VIRTUAL_CLIENT_READY $V (src_64 $(find "$V/src_64" -type f | wc -l) files, res $(find "$V/apk/res" -type f | wc -l) files)"
