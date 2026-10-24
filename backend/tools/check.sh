#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
failures=0
run() {
  printf '\n==> %s\n' "$*"
  "$@"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    printf 'FAILED (%d): %s\n' "$rc" "$*"
    failures=$((failures+1))
  fi
  return 0
}

run python3 tools/check_dependency_policy.py
run python3 tools/check_content_generation_policy.py
run python3 tools/generate_resolved_sbom.py --check
run python3 tools/check_sqlc_generation_policy.py
if [ "${GXB_COMPAT_SCRATCH:-0}" = "1" ]; then
  printf '\n==> python3 tools/check_connected_candidate.py\nSKIP: disposable compatibility clone intentionally relaxes canonical Go toolchain pins; canonical preseal remains separate.\n'
else
  run python3 tools/check_connected_candidate.py
fi
run python3 tools/verify_oracles.py --root "${GXB_ORACLE_ROOT:-/mnt/data}"
run python3 tools/check_i2_oracle_wire.py "${GXB_ORACLE_ROOT:-/mnt/data}"
run python3 tools/check_i3_oracle_bootstrap.py "${GXB_ORACLE_ROOT:-/mnt/data}"
run python3 tools/check_i4_oracle_wave_s.py "${GXB_ORACLE_ROOT:-/mnt/data}"
run python3 tools/check_i7a4d_source_oracle.py "${GXB_ORACLE_ROOT:-/mnt/data}"
run python3 tools/check_i5_oracle_player_core.py "${GXB_ORACLE_ROOT:-/mnt/data}"
run python3 tools/check_i6a_source_oracle.py "${GXB_ORACLE_ROOT:-/mnt/data}"
run python3 tools/check_i6b_source_oracle.py "${GXB_ORACLE_ROOT:-/mnt/data}"
run python3 tools/check_i6c_source_oracle.py "${GXB_ORACLE_ROOT:-/mnt/data}"
run python3 tools/check_ca3_3_source_oracle.py "${GXB_ORACLE_ROOT:-/mnt/data}"
run python3 tools/check_ca4_1_source_oracle.py "${GXB_ORACLE_ROOT:-/mnt/data}"
run python3 tools/check_ca7_3_source_oracle.py "${GXB_ORACLE_ROOT:-/mnt/data}"
run python3 tools/check_ca7_4_source_oracle.py "${GXB_ORACLE_ROOT:-/mnt/data}"
run python3 tools/check_ca7_5_source_oracle.py "${GXB_ORACLE_ROOT:-/mnt/data}"
run python3 tools/check_ca7_6_source_oracle.py "${GXB_ORACLE_ROOT:-/mnt/data}"
run python3 tools/check_ca8_6_source_oracle.py "${GXB_ORACLE_ROOT:-/mnt/data}"
run python3 tools/check_ca8_7_source_oracle.py "${GXB_ORACLE_ROOT:-/mnt/data}"
run python3 tools/check_ca8_8_source_oracle.py "${GXB_ORACLE_ROOT:-/mnt/data}"
run python3 tools/generate_mid_registry.py --root "${GXB_ORACLE_ROOT:-/mnt/data}" --check
run python3 tools/generate_pass353_wire_fixtures.py --root "${GXB_ORACLE_ROOT:-/mnt/data}" --check
run python3 tools/generate_kernel_querytext.py --check
run python3 tools/generate_content_querytext.py --check
run python3 tools/generate_character_querytext.py --check
run python3 tools/check_schema_query_ownership.py
run python3 tools/validate_foundation_trace.py

# Never rewrite canonical source during a check. Formatting drift is a failure.
fmt_out="$(gofmt -l $(find . -name '*.go' -not -path './vendor/*'))"
if [ -n "$fmt_out" ]; then
  printf '\n==> gofmt -l\nFAILED: unformatted Go files:\n%s\n' "$fmt_out"
  failures=$((failures+1))
else
  printf '\n==> gofmt -l\nPASS\n'
fi

export GOTOOLCHAIN=local
run go test ./...
run go vet ./...
run go test ./internal/archguard
run python3 tools/validate_i1.py
run python3 tools/validate_i2.py
run python3 tools/validate_i3.py
run python3 tools/validate_i4.py
run python3 tools/validate_i5.py
run python3 tools/validate_r0.py
run python3 tools/validate_r1a.py
run python3 tools/validate_r1b.py
run python3 tools/validate_r2a.py
run python3 tools/validate_r2b.py
run python3 tools/validate_r2c.py
run python3 tools/validate_r2d.py
run python3 tools/validate_r3a.py
run python3 tools/validate_r3b.py
run python3 tools/validate_r3c.py
run python3 tools/validate_r4a.py
run python3 tools/validate_r4b.py
run python3 tools/validate_r4c.py
run python3 tools/validate_r4d.py
run python3 tools/validate_r5.py --cumulative
run python3 tools/validate_ca3_3.py --cumulative
run python3 tools/validate_ca4_1.py
run python3 tools/validate_ca7_3.py
run python3 tools/validate_ca7_4.py
run python3 tools/validate_ca7_5.py
run python3 tools/validate_ca7_6.py
run python3 tools/validate_ca8_6.py
run python3 tools/validate_ca8_7.py
run python3 tools/validate_ca8_8.py
run python3 tools/validate_current_candidate.py

if [ "$failures" -ne 0 ]; then
  printf '\nFOUNDATION CHECK: RED (%d failing checks). Cumulative candidate or retained historical phase invariants are not green.\n' "$failures"
  exit 1
fi
printf '\nFOUNDATION CHECK: GREEN (Go %s compatibility run; pinned Go 1.27.3 and required live PostgreSQL/River/client gates remain separately authoritative).\n' "$(go version | awk '{print $3}')"
