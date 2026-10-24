#!/usr/bin/env python3
"""R4C static contract gate. Does not imply Go execution or PostgreSQL proof."""
from pathlib import Path
import json,re,subprocess,sys
R=Path(__file__).resolve().parents[1];errors=[]
def need(path):
 p=R/path
 if not p.is_file():errors.append('missing '+path);return ''
 return p.read_text()
sql=need('sql/content/content.sql');svc=need('internal/content/registry/service.go');types=need('internal/content/registry/types.go');startup=need('internal/content/registry/startup.go');api=need('cmd/gxb-api/main_postgres.go')
for name in ['LockContentRegistry','TryInsertContentRevision','InsertContentResources','InsertContentPlayerProgression','InsertContentObjectives','VerifyContentRevision','ReadContentActivation','ReadActiveContentSummary','BootstrapContentActivation','ActivateContentCAS']:
 if not re.search(r'-- name: '+name+r'\s+:',sql):errors.append('missing query '+name)
for table in ['revision','resource','progression','objective']:
 for side in ['missing','extra']:
  if table+'_'+side not in sql:errors.append('missing bidirectional '+table+' '+side)
for x in ['pg_advisory_xact_lock(1196966449, 1129206784)','activation_version=activation_version+1','revision_id=$4 AND activation_version=$5','ON CONFLICT (slot) DO NOTHING']:
 if x not in sql:errors.append('missing SQL contract '+x)
if 'ResolutionAbsent' in svc or 'AllowReplayAfterAuthoritativeNegative: true' in svc:errors.append('unknown commit replay enabled')
for x in ['tx.Serializable','scope.Operation.StartedAt.UTC()','s.Fresh','VerifyRevision','ErrStaleActivation']:
 if x not in svc:errors.append('missing service contract '+x)
if not re.search(r'manifest\s+builtin\.Manifest',types):errors.append('bundle metadata not private')
if 'm.EnabledCapabilities == nil' not in types:errors.append('missing/null capability array accepted')
if not (api.find('pool.Ping(')<api.find('.ValidateActiveReadiness(')<api.find('srv.ListenAndServe(')):errors.append('startup admission order wrong')
if 'goose' in api.lower() or 'ActivateBuiltin(' in api or 'ActivateBuiltin(' in startup:errors.append('startup migrates or explicitly switches')
if 'registry.DefaultProviderSet()' not in api:errors.append('providers not explicit at composition')
for p in ['internal/content/registry/service_test.go','internal/adapters/postgres/contentstore/store_test.go']:need(p)
# No new migrations or operation/policy/I5 pinning in R4C.
nums=sorted(int(p.name[:5]) for p in (R/'migrations').glob('*.sql'));
if nums[:10] != list(range(1,11)) or nums != list(range(1,max(nums)+1)):errors.append('historical R4C/Pass474 migration prefix changed or sequence is not contiguous')
for script in ['generate_content_querytext.py','check_schema_query_ownership.py','check_sqlc_generation_policy.py']:
 cmd=[sys.executable,str(R/'tools'/script)]+(['--check'] if script.startswith('generate_') else [])
 if subprocess.run(cmd,cwd=R).returncode:errors.append(script+' failed')
if errors:
 print('R4C STATIC VALIDATION: FAIL');print('\n'.join(errors));sys.exit(1)
print('R4C STATIC VALIDATION: PASS; executable and real-PG acceptance are separate evidence')
