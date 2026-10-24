#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
: "${GXB_I7A6A_TEST_DSN:?Name a disposable migrated PostgreSQL18.6 database}"
: "${GXB_I7A6A_GATE_OUTPUT:?Name an output directory outside the candidate}"
: "${GXB_ORACLE_ROOT:?Name the verified immutable source-oracle directory}"
mkdir -p "$GXB_I7A6A_GATE_OUTPUT"
cd "$ROOT"
export GOTOOLCHAIN=local GOPROXY=off GOSUMDB=off GOTELEMETRY=off
export GXB_I7A4D_TEST_DSN="$GXB_I7A6A_TEST_DSN"
export GXB_I7A4B_TEST_DSN="$GXB_I7A6A_TEST_DSN"
export GXB_I7A4C_TEST_DSN="$GXB_I7A6A_TEST_DSN"
python3 tools/candidate_identity.py --verify-snapshot --json > "$GXB_I7A6A_GATE_OUTPUT/before-identity.json"
go version > "$GXB_I7A6A_GATE_OUTPUT/go-version.txt"
pg_config --version > "$GXB_I7A6A_GATE_OUTPUT/pg-version.txt"
sqlc version > "$GXB_I7A6A_GATE_OUTPUT/sqlc-version.txt"
goose --version > "$GXB_I7A6A_GATE_OUTPUT/goose-version.txt"
go build -buildvcs=false -tags postgres -o "$GXB_I7A6A_GATE_OUTPUT/gxb-api" ./cmd/gxb-api
go build -buildvcs=false -tags postgres -o "$GXB_I7A6A_GATE_OUTPUT/gxb-realtime" ./cmd/gxb-realtime
export GXB_I7A4D_API_BINARY="$GXB_I7A6A_GATE_OUTPUT/gxb-api"
export GXB_I7A4D_REALTIME_BINARY="$GXB_I7A6A_GATE_OUTPUT/gxb-realtime"
go test -json -count=1 -p 1 -timeout 2m -tags 'postgres socialintegration channelintegration' ./internal/integration/... > "$GXB_I7A6A_GATE_OUTPUT/native.jsonl"
go test -json -count=1 -p 1 -timeout 2m -tags 'postgres river' ./... > "$GXB_I7A6A_GATE_OUTPUT/postgres-river-tagged.jsonl"
go test -race -json -count=1 -p 1 -timeout 2m -tags 'postgres socialintegration channelintegration' ./internal/integration/socialactivation ./internal/adapters/stockruntime ./internal/protocol/... ./internal/application/frienddm ./internal/application/socialfriendbase > "$GXB_I7A6A_GATE_OUTPUT/race.jsonl"
go vet -tags 'postgres river' ./... > "$GXB_I7A6A_GATE_OUTPUT/vet.log" 2>&1
go test ./internal/domain/friendmessage -run '^$' -fuzz FuzzPrivatePayload -fuzztime 10s -parallel 2 > "$GXB_I7A6A_GATE_OUTPUT/private-fuzz.log" 2>&1
bash tools/check.sh > "$GXB_I7A6A_GATE_OUTPUT/foundation.log" 2>&1
python3 tools/check_connected_candidate.py --execute > "$GXB_I7A6A_GATE_OUTPUT/connected.log" 2>&1
python3 tools/check_i7a6a_source_oracle.py "$GXB_ORACLE_ROOT" > "$GXB_I7A6A_GATE_OUTPUT/source-oracle.log" 2>&1
python3 tools/candidate_identity.py --verify-snapshot --json > "$GXB_I7A6A_GATE_OUTPUT/after-identity.json"
cmp "$GXB_I7A6A_GATE_OUTPUT/before-identity.json" "$GXB_I7A6A_GATE_OUTPUT/after-identity.json"
printf '%s\n' 'I7A6A exact native/static gate commands completed; matrix/reality/closure adjudication remains separate.'
