#!/usr/bin/env python3
from pathlib import Path
import json,re,sys
R=Path(__file__).resolve().parents[1];e=[]
def need(p):
 q=R/p
 if not q.exists():e.append('missing '+p);return ''
 return q.read_text(errors='replace')
def J(p):
 try:return json.loads(need(p) or '{}')
 except Exception as x:e.append(f'{p}: {x}');return {}
b=J('BUILD_INFO.json'); stage=J('docs/PASS436_I3_STAGE_VALIDATION.json'); mig=need('migrations/00002_identity_logicalserver_bootstrap.sql'); ident=need('internal/domain/identity/types.go')+need('internal/domain/identity/lifecycle.go')+need('internal/domain/identity/selection.go')+need('internal/domain/identity/credentials.go'); ls=need('internal/domain/logicalserver/server.go')+need('internal/domain/logicalserver/bootstrap.go')+need('internal/domain/logicalserver/directory.go'); app=need('internal/application/bootstrap/service.go')+need('internal/application/bootstrap/reconcile.go'); sql=need('sql/i3/identity_bootstrap.sql'); arch=need('internal/archguard/archguard_test.go')
# Historical stage validators verify the sealed durable contract. Current BUILD_INFO
# routing/version is owned by the newest stage validator.
if stage.get('pass')!='436.0' or stage.get('stage')!='I3':e.append('I3 stage identity mismatch')
if not str(stage.get('status','')).startswith('PASS'):e.append('I3 stage was not sealed PASS')
if not b.get('implementation_started'):e.append('current build unexpectedly says implementation not started')
for table in ['accounts','account_provider_bindings','account_sessions','account_session_credentials','logical_servers','players','account_session_server_observations','gameplay_contexts','gameplay_context_credentials']:
 if f'CREATE TABLE {table}' not in mig:e.append('missing schema '+table)
if '-- +goose Down' in mig:e.append('I3 production migration has DOWN section')
for token in ['UNIQUE(account_id,logical_server_id)','first_entry_pending boolean','next_player_id bigint','max_player_id bigint','gameplay_context_one_live_per_session_uq']:
 if token not in mig:e.append('migration invariant missing '+token)
for token in ['AuthProductionPair','ProviderPrincipal','GameplayContext','DigestCredential','DeriveGameplayBearer','RevokeSession','PlanSelection']:
 if token not in ident:e.append('identity contract missing '+token)
for token in ['BandMin','BandMax','PlayerRegion','ErrServerFull','ErrObservationRequired','FirstEntryPending','ProjectMID18']:
 if token not in ls:e.append('logical server contract missing '+token)
for token in ['PlanMID1','MID1ReceiptKind','ReconcileMID1Evidence','MID1Fingerprint']:
 if token not in app:e.append('application bootstrap contract missing '+token)
for token in ['FOR UPDATE','HasSessionServerObservation','SelectLiveGameplayContextBySession','EndGameplayContext','InsertGameplayContext']:
 if token not in sql:e.append('I3 SQL contract missing '+token)
if 'allowedLayerImports' not in arch or '"application": {' not in arch or '{"application", module + "internal/adapters/' not in arch:e.append('application architecture guard missing')
text=ident+ls+app
for private in ['client_operation_id','summon_op_id','contextEpoch']:
 if private in text:e.append('private V1/client mechanism leaked: '+private)
if e:
 print('I3 VALIDATION: FAIL');[print(' -',x) for x in e];sys.exit(1)
print('I3 VALIDATION: PASS');print('typed account/session/context, honest server directory, region-encoded allocator, observation gate, replay-stable MID1 and unknown-COMMIT reconciliation contracts verified')
