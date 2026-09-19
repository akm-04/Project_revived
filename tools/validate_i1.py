#!/usr/bin/env python3
from __future__ import annotations
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

def need(path: str) -> str:
    p = ROOT / path
    if not p.exists():
        errors.append(f"missing {path}")
        return ""
    return p.read_text(errors="replace")

build = json.loads(need("BUILD_INFO.json") or "{}")
stage = json.loads(need("docs/PASS434_I1_STAGE_VALIDATION.json") or "{}")
lock = json.loads(need("DEPENDENCIES.lock.json") or "{}")
migration = need("migrations/00001_kernel_receipts.sql")
query = need("sql/kernel/receipts.sql")
runner = need("internal/foundation/tx/runner.go")
types = need("internal/foundation/tx/types.go")
atomic = need("internal/foundation/tx/atomic.go")
pgx = need("internal/adapters/postgres/pgx_adapter.go")
river = need("internal/adapters/river/river_adapter.go")
arch = need("internal/archguard/archguard_test.go")

# Historical stage validators must validate durable contracts, not demand that
# BUILD_INFO remains pinned to the stage forever. Current routing/version is
# owned by the newest stage validator.
if stage.get("pass") != "434.0" or stage.get("stage") != "I1":
    errors.append("stage validation identity mismatch")
if not str(stage.get("status", "")).startswith("PASS"):
    errors.append("I1 stage was not sealed PASS")
if not build.get("implementation_started"):
    errors.append("current build unexpectedly says implementation not started")
if not str(lock.get("pass", "")).startswith(("434.0-I1", "435.0-I2", "436.0-I3", "437.0-I4", "438.0-I4")):
    errors.append("dependency lock predates I1 or has unknown stage identity")

# Minimal kernel schema; no generic authority tables.
created = re.findall(r"(?im)^\s*CREATE\s+TABLE\s+([a-zA-Z0-9_]+)", migration)
if created != ["gxb_operation_receipts"]:
    errors.append(f"unexpected I1 CREATE TABLE set: {created}")
for bad in ("resource_lock", "state_versions", "generic_outbox", "player_state", "account_state"):
    if re.search(rf"(?i)create\s+table[^;]*\b{re.escape(bad)}\b", migration):
        errors.append(f"forbidden generic authority table {bad}")
if re.search(r"(?im)^\s*--\s*\+goose\s+Down\b", migration):
    errors.append("destructive goose Down section present")
if "ON CONFLICT (owner_kind, owner_key, domain, operation, semantic_key)" not in query or "DO NOTHING" not in query:
    errors.append("receipt insert is not conflict-safe ON CONFLICT DO NOTHING")

# No blind replay across unknown commit.
for token in ("UnknownCommitOutcome", "context.WithoutCancel", "AllowReplayAfterAuthoritativeNegative", "IsDefiniteAbortError"):
    if token not in runner:
        errors.append(f"transaction runner missing {token}")
for token in ("ReconcileTimeout", "OperationTimeout", "TransactionTimeout"):
    if token not in types:
        errors.append(f"finite transaction profile missing {token}")
if "type FactAppender[T any]" not in atomic or "AppendFactTx(context.Context, Tx, T)" not in atomic:
    errors.append("typed same-transaction fact appender port missing")

# Driver/queue boundaries remain adapter-only and build-tagged.
if not pgx.startswith("//go:build postgres"):
    errors.append("pgx adapter missing postgres build tag")
if "ErrTxCommitRollback" not in pgx or "MarkDefiniteAbort" not in pgx:
    errors.append("pgx definite rollback normalization missing")
if not river.startswith("//go:build postgres && river"):
    errors.append("River adapter missing postgres && river build tag")
if "InsertTx" not in river or "SemanticKey" not in river:
    errors.append("River same-tx semantic obligation insertion missing")
for token in (
    "TestNoExternalNetworkInsideTransactionOrDomain",
    "TestPgxAndRiverRemainAdapterOnly",
    "github.com/jackc/pgx",
    "github.com/riverqueue/river",
):
    if token not in arch:
        errors.append(f"architecture dependency/network boundary guard missing {token}")

if errors:
    print("I1 VALIDATION: FAIL")
    for e in errors:
        print(" -", e)
    sys.exit(1)
print("I1 VALIDATION: PASS")
print("minimal kernel schema, tx outcome/reconciliation, typed facts, adapter isolation and stage routing verified")
