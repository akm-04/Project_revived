#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
want="go1.27.2"
got="$(GOTOOLCHAIN=go1.27.2 go version | awk '{print $3}')"
[[ "$got" == "$want" ]] || { echo "expected $want got $got"; exit 1; }
GOTOOLCHAIN=go1.27.2 go test ./...
GOTOOLCHAIN=go1.27.2 go vet ./...
command -v govulncheck >/dev/null || { echo 'govulncheck missing'; exit 1; }
GOTOOLCHAIN=go1.27.2 govulncheck -db "${GXB_VULN_DB:-https://vuln.go.dev}" ./...
echo 'PINNED TOOLCHAIN/SECURITY CHECK: PASS'
