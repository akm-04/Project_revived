#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
want="go1.27.1"
got="$(GOTOOLCHAIN=go1.27.1 go version | awk '{print $3}')"
[[ "$got" == "$want" ]] || { echo "expected $want got $got"; exit 1; }
GOTOOLCHAIN=go1.27.1 go test ./...
GOTOOLCHAIN=go1.27.1 go vet ./...
command -v govulncheck >/dev/null || { echo 'govulncheck missing'; exit 1; }
GOTOOLCHAIN=go1.27.1 govulncheck ./...
echo 'PINNED TOOLCHAIN/SECURITY CHECK: PASS'
