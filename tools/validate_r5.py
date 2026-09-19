#!/usr/bin/env python3
"""Candidate-bound R5 static implementation guard.

This verifies the accepted Pass480 R5 contract is represented in the current
candidate. It is static/local evidence only: native PostgreSQL/River and stock
client acceptance remain separate gates.
"""
from pathlib import Path
import argparse, hashlib, json, os, re, sys
R=Path(__file__).resolve().parents[1]
ap=argparse.ArgumentParser()
ap.add_argument("--cumulative", action="store_true", help="retain R5 semantics while permitting a later content compiler generation")
args=ap.parse_args()
errs=[]

def need(rel,*tokens):
    p=R/rel
    if not p.exists():
        errs.append(f'missing {rel}'); return ''
    s=p.read_text(errors='replace')
    for t in tokens:
        if t not in s: errs.append(f'{rel}: missing {t!r}')
    return s

# Historical R4 database repairs are immutable prerequisites.
for rel,want in {
    'migrations/00009_r4_immutable_content_revisions.sql':'b67018f5ca39e5ad05379e9df16c52e1cda5eb54918ab0db14319609d76237e4',
    'migrations/00010_r4_manifest_identity_not_null.sql':'305822dc72d03f6194332b38ee9cea9dba9223282bd8ac75c42aa480a0a4cf01',
}.items():
    p=R/rel
    if not p.exists() or hashlib.sha256(p.read_bytes()).hexdigest()!=want:
        errs.append(f'historical migration drift: {rel}')

m11=need('migrations/00011_r5_foundation_repairs.sql',
    '-- +goose Up','ALTER COLUMN regen_anchor_at DROP NOT NULL',
    'CREATE TABLE player_function_state_owners','CREATE TABLE player_function_eligibility',
    'CREATE TABLE gxb_content_function_gates')
if '-- +goose Down' in m11: errs.append('00011 violates forward-only migration law')

# Current immutable source revision is exact-current-src64 and explicitly R5-qualified.
try:
    man=json.loads((R/'internal/content/builtin/generated/manifest.json').read_text())
    if man.get('source_archive_sha256')!='c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf': errs.append('R5 builtin source archive drift')
    if man.get('compiler_version')!='r5-1' and not (args.cumulative and man.get('compiler_version') in {'ca2-1','ca2-2','ca2-3','ca3-1','ca3-2','ca3-3','ca4-1','ca4-2a','ca4-4a-i1','ca4-4b-i1','ca4-5-i1','ca6-2-practice-foundation'}): errs.append('R5 compiler version drift')
    caps=set(man.get('enabled_capabilities') or [])
    for cap in ['PLAYER_EXP_R5','TEMPORAL_ENERGY_R5','TEMPORAL_SPIRIT_ENERGY_R5','TEMPORAL_SKILL_POINT_R5','FUNCTION_LEVEL_ELIGIBILITY_R5']:
        if cap not in caps: errs.append(f'missing R5 capability {cap}')
    if 'TEMPORAL_INVITATION_R5' in caps: errs.append('Invitation must remain fail-closed')
    basis=dict(man); rid=basis.pop('revision_id',None)
    got=hashlib.sha256(json.dumps(basis,ensure_ascii=False,separators=(',',':'),sort_keys=True).encode()).hexdigest()
    if rid!=got: errs.append('R5 manifest revision digest mismatch')
    if (man.get('diagnostics') or {}).get('function_rows')!=99: errs.append('function-gate count drift')
except Exception as e: errs.append(f'R5 manifest unreadable: {e}')

need('internal/domain/player/core.go','type ProgressionPolicy struct','PlanCreditExp','AwardEnergy','MaxCanonicalExp')
need('internal/domain/economy/resources.go','RegenAnchorAt','ApplyLevelTransition','RebindLegacyPolicy')
need('internal/application/i5/temporal_rebind.go','RebindLegacyTemporal','gxb.i5.temporal-rebind.v1','RebindTemporalTx','ErrTemporalRebindStateWithoutReceipt')
need('internal/adapters/postgres/i5store/store.go','ResolveLegacyTemporalPolicyTx','RebindTemporalTx','content_revision IS NULL')
need('internal/domain/economy/stack_adjustment.go','PlanAdjustment')
need('internal/application/bootstrap/persistence_contributor.go','CharacterBootstrapOperationBinder')
need('internal/adapters/postgres/i5store/economy_owner.go','EconomyOwnerBootstrapContributor','r5.bootstrap.v1','energy','spirit_energy','skill_point','bound content revision')
need('internal/application/i5/r5_policy.go','PrivilegeSnapshotProvider','PROVISIONAL_REPLACE_ON_COMMERCE_OWNER/v1','NoFunctionAnnouncements','r5.function-announcement.none.v1')
need('internal/application/i5/ports.go','FunctionAnnouncementProvider','DirectoryLevelProjectionPort')
need('internal/application/i5/grant_lock_plan.go','grantLockRankFunction','grantLockRankDirectory','730','740')
need('internal/application/i5/service.go','gxb.i5.grant.v2','ApplyLevelTransition','InsertFunctionEligibilityTx','SetLevelTx')
need('internal/application/i5/stack_adjustment.go','func (s Service) AdjustStack','receipt.Resolver','DeleteStackTx','ErrStackAdjustmentOverflowRequiresGrant')
need('internal/application/i5/settlement_projection.go','SettlementProjection','RepeatableRead','NewFunctionIDs')
need('internal/adapters/stockruntime/i5_dispatcher.go','applySettlementProjection','StockRepresentableBulkAwards','case 161:','case 230:','case 369:','case 370:')
need('internal/adapters/postgres/i5store/bootstrap_projection.go','stockAnchor','skill_time','max_lev','ResolveProgressionPolicyTx','ResolveResourceTx')
need('internal/adapters/postgres/i4store/directory_level_projection.go','SetLevelTx')
need('internal/adapters/postgres/contentstore/store.go','ResolveProgressionPolicyTx','ResolveFunctionGatePolicyTx','ENABLED_R5')
need('sql/content/content.sql','InsertContentFunctionGates','ReadContentPlayerProgressionPolicy','ReadContentFunctionGatePolicy')

# Canonical toolchain pins remain strict in normal mode. A disposable compatibility
# copy may explicitly relax only these byte/toolchain assertions; every R5 semantic
# and migration invariant above still runs. COMPATIBILITY_COPY_ONLY is never native proof.
gm=(R/'go.mod').read_text(errors='replace')
compat_scratch=os.environ.get('GXB_COMPAT_SCRATCH')=='1'
if not compat_scratch:
    if 'go 1.26.0' not in gm or 'toolchain go1.27.1' not in gm: errs.append('canonical Go pins drifted')
    if (R/'.go-version').read_text().strip()!='1.27.1': errs.append('.go-version pin drifted')

if errs:
    print('R5 VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('R5 VALIDATION: PASS' + (' (CUMULATIVE MODE)' if args.cumulative else ''))
print('static progression/temporal/bootstrap/function/directory/receipt/wire/stack R5 seams present; historical compiler pin remains strict outside cumulative mode; native PostgreSQL/River/W2 remain separate')
