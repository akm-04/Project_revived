#!/usr/bin/env python3
from pathlib import Path
import json,sys,re
ROOT=Path(__file__).resolve().parents[1]
errs=[]
def need(path,*needles):
 p=ROOT/path
 if not p.exists(): errs.append(f'missing {path}'); return ''
 s=p.read_text(errors='replace')
 for n in needles:
  if n not in s: errs.append(f'{path}: missing {n!r}')
 return s
svc=need(Path('internal/application/identitylifecycle/service.go'),
 'func (s Service) BindPrincipal(', 'func (s Service) IssueSession(', 'func (s Service) RevokeSession(', 'func (s Service) TouchActivity(',
 'context.WithTimeout(context.WithoutCancel(ctx)', 'IdleExpiryEnabled', 'ActivityTouchInterval')
ports=need(Path('internal/application/identitylifecycle/ports.go'),
 'LockAccountTx', 'InsertProviderBindingTx', 'InsertSessionTx', 'InsertSessionCredentialTx', 'LockSessionTx', 'LockLiveContextTx',
 'SaveRevokedSessionTx', 'SaveEndedContextTx', 'RevokeSessionCredentialsTx', 'RevokeGameplayCredentialsTx', 'TouchSessionActivityTx')
key=need(Path('internal/application/identitylifecycle/key_resolver.go'),'type BearerKeyResolver interface','ResolveBearerKey','StaticBearerKeyResolver')
adapter=need(Path('internal/adapters/postgres/identitystore/store.go'),
 'FROM account_sessions WHERE session_id=$1 FOR UPDATE',
 'FROM gameplay_contexts WHERE session_id=$1 AND ended_at IS NULL FOR UPDATE',
 'UPDATE account_session_credentials SET revoked_at=$2',
 'UPDATE gameplay_context_credentials SET revoked_at=$2',
 'idle_timeout_seconds IS NOT NULL AND last_activity_at <= $2')
# Preserve required lock ordering in service source.
i_sess=svc.find('LockSessionTx('); i_ctx=svc.find('LockLiveContextTx('); i_sc=svc.find('RevokeSessionCredentialsTx('); i_gc=svc.find('RevokeGameplayCredentialsTx(')
if min(i_sess,i_ctx,i_sc,i_gc)<0 or not (i_sess < i_ctx < i_sc < i_gc): errs.append('revocation lock/update order is not session -> context -> credentials')
# Provider/SDK ingress must stay out of application identity transaction code.
for forbidden in ('net/http','internal/adapters/provider','github.com/jackc/pgx'):
 if forbidden in svc+ports+key: errs.append(f'identity lifecycle application boundary imports forbidden mechanism {forbidden}')
# Forward-only relation constraints express existing typed relationships.
mig=need(Path('migrations/00007_identity_lifecycle_constraints.sql'), '-- +goose Up',
 'accounts_status_disabled_at_consistent_chk','account_sessions_revocation_consistent_chk','gameplay_contexts_end_consistent_chk',
 'gameplay_context_session_account_fk','gameplay_context_player_account_server_fk','gameplay_context_credential_parent_fk')
if '-- +goose Down' in mig: errs.append('R2A migration contains forbidden DOWN section')
# Ensure the concrete owner adapter is actually admitted by R0 table ownership contract.
try: own=json.loads((ROOT/'docs/architecture/CANONICAL_TABLE_OWNERSHIP.json').read_text())
except Exception as e: own={}; errs.append(f'ownership contract unreadable: {e}')
for table in ('accounts','account_provider_bindings','account_sessions','account_session_credentials','gameplay_contexts','gameplay_context_credentials'):
 e=own.get('tables',{}).get(table,{})
 if 'internal/adapters/postgres/identitystore/' not in e.get('allowed_write_paths',[]): errs.append(f'{table}: identitystore not registered write owner path')
# Tests proving core acceptance conditions.
tests=need(Path('internal/application/identitylifecycle/service_test.go'),
 'TestBindPrincipalReplayCreatesOnce','TestIssueSessionFailureRollsBackPartialState','TestIssueSessionReplayDoesNotDuplicate',
 'TestRevokeSessionAtomicLockOrderAndPostCommitHint','TestRevokeSessionFailureRollsBackAllDurableChanges',
 'TestActivityTouchDisabledByDefaultAndCoalescedWhenEnabled','TestStaticBearerKeyResolverFailsClosedForUnknownVersion')
if errs:
 print('R2A VALIDATION: FAIL')
 for e in errs: print(' -',e)
 sys.exit(1)
print('R2A VALIDATION: PASS')
print('transactional provider/session/revocation lifecycle, coalesced optional activity, key seam and cross-identity constraints verified structurally')
