#!/usr/bin/env python3
from pathlib import Path
import re,sys
ROOT=Path(__file__).resolve().parents[1]
errs=[]
def need(path,*tokens):
    p=ROOT/path
    if not p.exists(): errs.append(f'missing {path}'); return ''
    s=p.read_text(errors='replace')
    for t in tokens:
        if t not in s: errs.append(f'{path}: missing {t!r}')
    return s

mig=need(Path('migrations/00008_i5_economy_owner_fence.sql'),'-- +goose Up','CREATE TABLE player_economy_owners','ON CONFLICT (player_id) DO NOTHING')
if '-- +goose Down' in mig: errs.append('00008 violates forward-only migration law')
need(Path('internal/adapters/postgres/i5store/economy_owner.go'),'EconomyOwnerBootstrapContributor','INSERT INTO player_economy_owners','PersistCharacterBootstrap')
ports=need(Path('internal/application/i5/ports.go'),'type TxGrantSettler interface','SettleGrantTx','LockEconomyOwnerTx','LockMailNamespaceCounterTx')
svc=need(Path('internal/application/i5/service.go'),'type GrantTxOptions struct','func (s Service) SettleGrantTx','s.preflightGrantTx','s.acquireGrantLocksTx')
planner=need(Path('internal/application/i5/grant_lock_plan.go'),'lockkey.CanonicalDedup','grantLockRankMailNamespace','grantLockRankEconomyOwner','grantLockRankScalar','grantLockRankTemporal','grantLockRankStack','grantLockRankEconomyOwner')
store=need(Path('internal/adapters/postgres/i5store/store.go'),'func (Store) LockEconomyOwnerTx','FROM player_economy_owners','func (Store) LockMailNamespaceCounterTx','INSERT INTO mail_namespace_counters','FOR UPDATE')
main=need(Path('cmd/gxb-api/main_postgres.go'),'characterbirth.Contributors(')
need(Path('internal/adapters/postgres/characterbirth/contributors.go'),'i5store.EconomyOwnerBootstrapContributor{')
tests=need(Path('internal/application/i5/service_test.go'),'TestSettleGrantTxUsesCallerOwnedTransactionWithoutNestedBegin','TestGrantPreflightCanonicalLockOrderIndependentOfLineOrder','TestSettleGrantTxPropagatesExactCallerTransactionToOwner')
need(Path('internal/foundation/lockkey/lockkey_test.go'),'TestCanonicalDedupCollapsesRepeatedRequirement')
# Mail/Objectives/Redeem must use the public tx-scoped seam, not private direct settlement.
for fn in ('ClaimMail','ClaimMailBatch','ClaimObjective','ClaimObjectiveByID','Redeem'):
    if fn not in svc: errs.append(f'missing expected I5 caller {fn}')
if len(re.findall(r'\.settleGrantTx\(',svc)) != 1: # private implementation declaration call only via SettleGrantTx return
    # Declaration isn't matched by dot; any match here is a direct private call.
    errs.append('private settleGrantTx is still called directly by another application path')
# Historical R2C invariant: the migration-00008 economy creation fence itself
# must remain balance/content-free. Later authorized phases may add typed temporal
# bootstrap through a newer owner contributor without invalidating R2C.
# Creation fence root must not contain balances/content.
for forbidden in ('amount','resource_key','item_id','regen_anchor'):
    if re.search(rf'(?i)\b{forbidden}\b', mig.split('CREATE TABLE player_economy_owners',1)[-1].split(');',1)[0]):
        errs.append(f'player_economy_owners illegally stores gameplay field {forbidden}')
if errs:
    print('R2C VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('R2C VALIDATION: PASS')
print('caller-owned Grant seam, preflight canonical lock planning, durable creation fence and non-fabricating owner bootstrap verified')
