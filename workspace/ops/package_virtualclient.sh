#!/usr/bin/env bash
# Package the virtual client kit for seal generation <G> (ops/seal_passmap.sh runs it):
#   inputs/tools/gxb-virtual-client-kit-p<G>-<head7>.zip (+ .sha256), replacing the previous kit there. It holds
#   bin/                gxb-api (-tags postgres,river), gxb-realtime (-tags postgres) and every virtualclient command, built from a clean `git archive HEAD`
#   go-mod-download/    the virtualclient module's third-party module cache, so it rebuilds offline
#   testing/, TESTING_GUIDE.md, KIT_README.md
# The virtualclient source is in the backend zips (backend/virtualclient); the runtime inputs are rebuilt by
# testing/setup_virtualclient.sh from inputs/client_baseline and Supplimental_Materials/Game-Assets.
# Usage: ops/package_virtualclient.sh <generation>
set -euo pipefail
generation=$1
root=$(cd "$(dirname "$0")/.." && pwd)
backend=$root/work/backend_i7c4_full/backend
head=$(git -C "$backend" rev-parse --short=7 HEAD)
name=gxb-virtual-client-kit-p$generation-$head
staging=$root/tmp/package_virtualclient_$generation
kit=$staging/$name
rm -rf "$staging" && mkdir -p "$staging/backend" "$kit/bin"
git -C "$backend" archive HEAD | tar -x -C "$staging/backend"
(
  . "$root/ops/testing/goenv.sh"
  cd "$staging/backend"
  go build -tags postgres,river -o "$kit/bin/gxb-api" ./cmd/gxb-api
  go build -tags postgres -o "$kit/bin/gxb-realtime" ./cmd/gxb-realtime
  export GOMODCACHE=$root/tmp/cache/virtualclient/go-mod GOCACHE=$root/tmp/cache/virtualclient/go-build
  export GOPROXY=file://$root/tmp/cache/virtualclient/go-mod/cache/download,file://$T/cache/go-mod/cache/download
  cd virtualclient
  go build -o "$kit/bin/" ./cmd/...
)
cp -a "$root/tmp/cache/virtualclient/go-mod/cache/download" "$kit/go-mod-download"
cp -a "$root/ops/testing" "$kit/testing"
cp "$root/ops/TESTING_GUIDE.md" "$kit/"
cat > "$kit/KIT_README.md" <<EOF
# GXB virtual client kit, seal $generation, backend $(git -C "$backend" rev-parse HEAD)

The emulated stock client (I8.5-4/5) ready to run against gxb-api. See TESTING_GUIDE.md section 3.
- bin/ was built from that backend commit with the r4 toolchain (Go 1.27.3); its source is backend/virtualclient in
  the backend zips (inputs/backend/*-p$generation-*).
- Rebuild the runtime directory: copy testing/ to ops/testing/ of the workspace, then
  \`GOMOD_DOWNLOAD=<this kit>/go-mod-download ops/testing/setup_virtualclient.sh\` (src_64, apk/res, update-tree, bin).
- Or use bin/ directly: create tmp/virtualclient, copy bin/ in, and run only the src_64/apk/update-tree steps of
  setup_virtualclient.sh.
- Recovery of the whole workspace: inputs/RECOVERY.md.
EOF
(cd "$kit" && find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS)
rm -f "$root"/inputs/tools/gxb-virtual-client-kit-p*.zip "$root"/inputs/tools/gxb-virtual-client-kit-p*.sha256
(cd "$staging" && zip -qr -X "$root/inputs/tools/$name.zip" "$name")
unzip -tq "$root/inputs/tools/$name.zip" > /dev/null
(cd "$root/inputs/tools" && sha256sum "$name.zip" > "$name.sha256")
rm -rf "$staging"
echo "VIRTUAL_CLIENT_KIT inputs/tools/$name.zip"
