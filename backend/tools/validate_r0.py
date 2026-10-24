#!/usr/bin/env python3
from pathlib import Path
import json,subprocess,sys
root=Path(__file__).resolve().parents[1]
errs=[]

def run(cmd, expect=0, contains=None):
    p=subprocess.run(cmd,cwd=root,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    if p.returncode!=expect:
        errs.append(f"{' '.join(cmd)} exit={p.returncode} expected={expect}\n{p.stdout}")
    if contains and contains not in p.stdout:
        errs.append(f"{' '.join(cmd)} missing expected text {contains!r}\n{p.stdout}")
    return p

run(['python3','tools/check_schema_query_ownership.py','--self-test'])
# R0's guard must remain truthful as repairs close findings. Before R2B, RF-007
# is an explicit known-open violation; after R2B, strict ownership must pass and
# the allow-list record must be gone rather than becoming stale protection.
own=json.loads((root/'docs/architecture/CANONICAL_TABLE_OWNERSHIP.json').read_text())
rf007=any(v.get('finding_id')=='RF-007' for v in own.get('known_open_violations',[]))
if rf007:
    run(['python3','tools/check_schema_query_ownership.py','--allow-known-open'],contains='RF-007')
    run(['python3','tools/check_schema_query_ownership.py'],expect=1,contains='KNOWN OPEN RF-007')
else:
    run(['python3','tools/check_schema_query_ownership.py','--allow-known-open'])
    run(['python3','tools/check_schema_query_ownership.py'])
run(['python3','tools/validate_foundation_trace.py'])
arch=(root/'internal/archguard/archguard_test.go').read_text()
for token in ['allowedLayerImports','TestLayerMatrixNegativeFixtures','TestLayerMatrixPositiveFixtures','unregistered internal source layer']:
    if token not in arch: errs.append('archguard missing '+token)
check=(root/'tools/check.sh').read_text()
for token in ['validate_i5.py','check_i5_oracle_player_core.py','validate_foundation_trace.py','check_schema_query_ownership.py']:
    if token not in check: errs.append('tools/check.sh missing '+token)
readme=(root/'README.md').read_text()
if 'foundation repair' not in readme.lower() or 'I6' not in readme or 'Pass489' not in readme:
    errs.append('README does not expose completed foundation-repair lineage and current I6 truth')
if errs:
 print('R0 VALIDATION: FAIL')
 for e in errs: print(' -',e)
 sys.exit(1)
print('R0 VALIDATION: PASS (historical R0 guard preserved; cumulative foundation repair accepted at Pass489)')
