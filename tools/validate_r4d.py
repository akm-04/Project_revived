#!/usr/bin/env python3
"""Candidate-bound static R4D immutable-content consumption guard.

This validator intentionally does not implement or waive R5 RF-015. It guards
only the R4D code seams frozen by PASS476 preimplementation research.
"""
from pathlib import Path
import os, re, sys
R=Path(__file__).resolve().parents[1]
errs=[]

def need(path, *tokens):
    text=(R/path).read_text()
    for token in tokens:
        if token not in text:
            errs.append(f"{path}: missing {token!r}")
    return text

ports=need('internal/application/i5/ports.go','type ContentRuntime interface {','ActiveRevision(context.Context, tx.Queryer)','ResolveResourceTx(context.Context, tx.Queryer, string, grant.Line)','ResolveObjectiveTx(context.Context, tx.Queryer, string, string, int64, string)')
binding=need('internal/application/i5/content_binding.go','contentPolicyRefName = "content"','prepareGrantOperationTx','findGrantReceiptTx','bindActiveContentTx')
receipts=need('internal/application/i5/grant_receipts.go','ErrGrantDualReceiptConflict','ReceiptIdentities()','compatibleGrantReceipts')
plan=need('internal/domain/grant/plan.go','LegacySemanticKeyV1','ReceiptIdentities','grant-overflow:v2:','LegacyOverflowMailSourceKeyV1')
store=need('internal/adapters/postgres/contentstore/store.go','ReadContentResourceByResourceKey','ReadContentResourceByItemID','ReadContentObjectiveDefinition','ENABLED_R5')
i5=need('internal/adapters/postgres/i5store/store.go','ResolveLegacyTemporalPolicyTx','content_revision IS NULL','d.definition_revision=i.definition_revision')
boot=need('internal/adapters/postgres/i5store/bootstrap_projection.go','r.ContentRevision == ""','ResolveLegacyTemporalPolicyTx','ResolveResourceTx','ResolveProgressionPolicyTx')
main=need('cmd/gxb-api/main_postgres.go','contentstore.Store{Queryer: pool}')
queries=need('sql/content/content.sql','revision_id=$1 AND class=$2 AND resource_key=$3','revision_id=$1 AND item_id=$2','revision_id=$1 AND program_id=$2 AND objective_id=$3 AND definition_revision=$4')
svc=need('internal/application/i5/service.go','prepareGrantOperationTx','resolveObjectiveDefinitionTx')
tests=need('internal/application/i5/service_test.go','TestSettleGrantRetryPinsFirstBoundContentRevision','TestSettleGrantLegacyV1ReceiptReplaysWithoutActiveContentLookup','TestSettleGrantConflictingV2AndV1ReceiptsFailClosedBeforeContentLookup','TestContentBackedObjectiveClaimUsesPersistedRevisionForDefinitionAndNestedGrant')
adapter_tests=need('internal/adapters/postgres/contentstore/store_test.go','TestR4DActiveRevisionAndExactResourceReads','TestR4DResolveObjectiveUsesExactRevisionTuple')
# Hidden active/current reads are forbidden in operational R4D consumption paths.
for rel in ['internal/application/i5','internal/adapters/postgres/i5store','internal/adapters/postgres/contentstore']:
    for p in (R/rel).rglob('*.go'):
        if p.name.endswith('_test.go'): continue
        text=p.read_text()
        if re.search(r'active\s*=\s*true|active=true', text, re.I):
            errs.append(f"{p.relative_to(R)}: hidden active=true runtime read remains")
# Canonical module/toolchain pins must remain pristine.
gm=(R/'go.mod').read_text()
compat_scratch=os.environ.get('GXB_COMPAT_SCRATCH')=='1'
if not compat_scratch:
    if 'go 1.26.0' not in gm or 'toolchain go1.27.1' not in gm:
        errs.append('canonical Go language/toolchain pins drifted')
    if (R/'.go-version').read_text().strip()!='1.27.1': errs.append('.go-version pin drifted')
if errs:
    print('R4D VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('R4D VALIDATION: PASS')
print('immutable revision binding/replay/exact-read/restart guards present; R5 temporal/bootstrap remains intentionally out of scope')
