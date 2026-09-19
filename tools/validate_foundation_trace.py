#!/usr/bin/env python3
from pathlib import Path
import json,sys
root=Path(__file__).resolve().parents[1]
status_path=root/'docs/foundation_repair_status.json'
trace_path=root/'docs/PASS450_FOUNDATION_TRACE_MATRIX.json'
errs=[]
try: status=json.loads(status_path.read_text())
except Exception as e: status={}; errs.append(f'status load: {e}')
try: trace=json.loads(trace_path.read_text())
except Exception as e: trace={}; errs.append(f'trace load: {e}')
required={'stage','owner','contracts','production_paths','persistence','projection_or_wire','tests','evidence_level','open_findings','extension_seam'}
records=trace.get('records',[])
if not records: errs.append('trace has no records')
for i,r in enumerate(records):
    miss=required-set(r)
    if miss: errs.append(f'record {i} missing {sorted(miss)}')
    if r.get('evidence_level') in {'PASS','GREEN','COMPLETE'}:
        errs.append(f"record {i} uses ambiguous evidence level {r.get('evidence_level')}")
findings={x.get('id'):x for x in status.get('findings',[])}
expected={f'RF-{i:03d}' for i in range(1,25)}
if set(findings)!=expected: errs.append(f'finding register mismatch: missing={sorted(expected-set(findings))} extra={sorted(set(findings)-expected)}')
# Repair findings must no longer be represented as open after Pass489. Extension limits are tracked separately.
open_rf={fid for fid,x in findings.items() if str(x.get('status','')).startswith(('OPEN_','IN_PROGRESS_'))}
if open_rf: errs.append('stale open repair findings after Pass489: '+', '.join(sorted(open_rf)))
if status.get('foundation_status')!='GREEN_R0_R7_PHASE_ACCEPTED_PASS489': errs.append('foundation current truth must record Pass489 R0-R7 acceptance')
if status.get('I6')!='PHASE_ACCEPTED_PASS509_AFTER_I6E': errs.append('parent I6 current truth must record Pass509 I6E acceptance')
for fid in ('RF-013','RF-014','RF-015','RF-019'):
    if 'PASS485' not in str(findings.get(fid,{}).get('status','')): errs.append(f'{fid} must retain R5/Pass485 closure provenance')
for fid in ('RF-016','RF-023'):
    if 'PASS477' not in str(findings.get(fid,{}).get('status','')): errs.append(f'{fid} must retain R4/Pass477 closure provenance')
for fid in ('RF-017','RF-024'):
    if 'PASS487' not in str(findings.get(fid,{}).get('status','')): errs.append(f'{fid} must retain R6/Pass487 closure provenance')
rf18=findings.get('RF-018',{})
if not str(rf18.get('status','')).startswith('SUPERSEDED_'): errs.append('RF-018 must remain explicitly superseded, not silently converted')
rf12=findings.get('RF-012',{})
if not str(rf12.get('status','')).startswith('RESOLVED_R0_'): errs.append('RF-012 must retain explicit R0 resolution provenance')
if errs:
 print('FOUNDATION TRACE: FAIL')
 for e in errs: print(' -',e)
 sys.exit(1)
ext_open=[x.get('id') for x in status.get('extension_limits',[]) if str(x.get('status','')).startswith('OPEN_')]
print(f'FOUNDATION TRACE: PASS ({len(records)} historical lifecycle records; 24/24 RF findings dispositioned; R0-R7 accepted Pass489; I6 accepted Pass509; {len(ext_open)} future extension limits remain explicit; W2 separate)')
