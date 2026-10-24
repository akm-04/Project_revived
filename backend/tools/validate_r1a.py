#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
errors=[]

def need(path, needles):
    p=ROOT/path
    if not p.exists():
        errors.append(f"missing {path}")
        return ""
    s=p.read_text(errors='replace')
    for n in needles:
        if n not in s:
            errors.append(f"{path}: missing {n!r}")
    return s

runner=need(Path('internal/foundation/tx/runner.go'), [
    'finalizer := transactionFinalizer{profile: profile, tx: dbtx}',
    'defer finalizer.finish()',
    'context.WithTimeout(context.Background(), f.profile.CleanupTimeout)',
    'finalizer.markFinalized()',
])
receipt=need(Path('internal/foundation/receipt/receipt.go'), [
    'return tx.Resolution{State: tx.ResolutionUnknown}, nil',
    'Only an',
    'operation-specific resolver',
])
reconcile=need(Path('internal/application/bootstrap/reconcile.go'), [
    'AuthoritativeNegativeProven bool',
    'if e.AuthoritativeNegativeProven',
    'return tx.Resolution{State: tx.ResolutionUnknown, Evidence: e}',
])
i4=need(Path('internal/adapters/postgres/i4store/bootstrap_runtime.go'), [
    'ambiguous MID1 transaction cannot still become visible',
    'return tx.Resolution{State: tx.ResolutionUnknown}, nil',
])
types=need(Path('internal/foundation/tx/types.go'), [
    'ResolutionAbsent is not a generic "receipt not found" state',
])
tests=need(Path('internal/foundation/tx/runner_test.go'), [
    'TestPanicInBodyFinalizesTransactionAndRethrows',
    'TestUnknownCommitCleanupCannotRewriteOutcome',
    'TestResolutionUnknownNeverReplaysEvenWhenNegativeReplayPolicyEnabled',
    'TestExplicitAuthoritativeNegativeProofMayReplayWithPolicy',
])
need(Path('internal/foundation/receipt/receipt_test.go'), ['TestResolverCommittedMissingIsUnknownAndConflict'])
need(Path('internal/application/bootstrap/reconcile_test.go'), ['AuthoritativeNegativeProven: true'])

# Guard against regression to the old generic-miss-as-absence rule.
if 'if !ok {\n\t\treturn tx.Resolution{State: tx.ResolutionAbsent}' in receipt:
    errors.append('receipt resolver still treats generic miss as authoritative absence')
if 'if !ok {\n\t\treturn tx.Resolution{State: tx.ResolutionAbsent}' in i4:
    errors.append('MID1 receipt resolver still treats generic miss as authoritative absence')
if 'return tx.Resolution{State: tx.ResolutionAbsent, Evidence: e}\n}' in reconcile and 'AuthoritativeNegativeProven' not in reconcile:
    errors.append('MID1 reconciler has unconditional absence proof')

if errors:
    print('R1A VALIDATION: FAIL')
    for e in errors:
        print(' -',e)
    sys.exit(1)
print('R1A VALIDATION: PASS')
print('panic-safe transaction finalization and authoritative-negative semantics verified structurally')
