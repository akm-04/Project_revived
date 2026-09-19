#!/usr/bin/env python3
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
store=(root/'internal/adapters/postgres/i5store/store.go').read_text()
test=(root/'internal/adapters/postgres/i5store/objective_lock_test.go').read_text()
svc=(root/'internal/application/i5/service.go').read_text()
errors=[]
start=store.find('const lockObjectiveForClaimQuery')
end=store.find('func (Store) LockObjectiveForClaimTx', start)
q=store[start:end] if start>=0 and end>start else ''
for needle,msg in [
 ('WITH candidate AS MATERIALIZED','stock objective candidate CTE is not materialized'),
 ('FROM player_mission_instances i','candidate does not select canonical mission rows'),
 ('FOR UPDATE OF i','candidate does not lock canonical mission rows'),
 ('(SELECT count(*) FROM candidate)=1','ambiguous candidate uniqueness check lost')]:
    if needle not in q: errors.append(msg)
# The locking clause must be in candidate, not on unique_candidate/outer query.
if 'FROM unique_candidate FOR UPDATE' in q or 'FROM unique_candidate\nFOR UPDATE' in q:
    errors.append('derived/outer objective query still carries misleading FOR UPDATE')
if 'SettleGrantTx(txctx, scope.Tx' not in svc:
    errors.append('Objective claim no longer composes Grant through caller-owned R2C seam')
if 'TestObjectiveStockClaimLocksBaseMissionRowsInsideCandidateCTE' not in test:
    errors.append('R2D SQL structural regression test missing')
if errors:
    for e in errors: print('R2D VALIDATION ERROR:',e)
    sys.exit(1)
print('R2D VALIDATION: PASS')
