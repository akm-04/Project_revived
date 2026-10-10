#!/usr/bin/env python3
"""Candidate-bound R6 static implementation guard.

R6 repairs stock projection, bounded replay/evidence classification, and the
foundation lifecycle/runtime boundaries needed before R7. This is static/local
evidence only; PostgreSQL SSI/advisory ownership/River and later stock-client
acceptance remain separate gates.
"""
from pathlib import Path
import argparse, hashlib, sys
R=Path(__file__).resolve().parents[1]
ap=argparse.ArgumentParser(description="Validate the historical R6 snapshot contract; --cumulative permits later independently accepted migrations while retaining every R6 invariant.")
ap.add_argument("--cumulative", action="store_true")
ap.add_argument("--compat-scratch", action="store_true", help="diagnostic disposable-copy mode; allowed only with --cumulative and never valid as canonical/native evidence")
args=ap.parse_args()
if args.compat_scratch and not args.cumulative:
    ap.error("--compat-scratch requires --cumulative")
errs=[]

def need(rel,*tokens):
    p=R/rel
    if not p.exists():
        errs.append(f'missing {rel}'); return ''
    s=p.read_text(errors='replace')
    for t in tokens:
        if t not in s: errs.append(f'{rel}: missing {t!r}')
    return s

# Historical R6 itself must not invent a later schema migration. Current cumulative
# candidates may contain independently researched/accepted later migrations, but only
# through the separate cumulative validator which invokes this guard with --cumulative.
if not args.cumulative and list((R/'migrations').glob('00012*')):
    errs.append('unexpected migration00012: historical R6 contract is no-schema-change unless research is reopened')

# R5 accepted database/content prerequisites remain immutable.
for rel,want in {
    'migrations/00009_r4_immutable_content_revisions.sql':'b67018f5ca39e5ad05379e9df16c52e1cda5eb54918ab0db14319609d76237e4',
    'migrations/00010_r4_manifest_identity_not_null.sql':'305822dc72d03f6194332b38ee9cea9dba9223282bd8ac75c42aa480a0a4cf01',
    'migrations/00011_r5_foundation_repairs.sql':'ffe15e505faa77e9e7d93c49abb95d59db58ee15021ad562b0cc121528fd995b',
}.items():
    p=R/rel
    if not p.exists() or hashlib.sha256(p.read_bytes()).hexdigest()!=want:
        errs.append(f'accepted migration drift: {rel}')

# C01/C02/C04 stock projection completeness.
need('internal/projection/backpack/shapes.go','AcquiredAt','table_id','item_num','time','spirit_list')
need('internal/adapters/postgres/i5store/store.go','ListStacks','acquired_at','updated_at')
need('internal/adapters/postgres/i5store/bootstrap_projection.go','"81"','magic_exp','degree_cer','graduate_cer','patent_cer','skill_point','skill_time')
need('internal/adapters/stockruntime/i5_dispatcher.go','case 81:','ListBackpack')
need('cmd/gxb-api/main_postgres.go','81','Backpack: i5db')
need('internal/projection/lobby/shapes.go','RegionName','region_name')
need('internal/adapters/postgres/i4store/bootstrap_runtime.go','RegionName: planned.Server.Name')

# C03 selective directory reconciliation with typed owner separation.
need('internal/application/directorysync/service.go','ReconcileDirectoryTx','CanonicalSource','ProjectionSink','SERIALIZABLE')
need('internal/adapters/postgres/i5store/store.go','ReadCanonicalDirectoryTx','player_profiles','player_progression')
dirsrc=need('internal/adapters/postgres/i4store/directory_level_projection.go','LockOwnedDirectoryTx','ApplyOwnedDirectoryTx','avatar_frame_id','state_version')
for forbidden in ['vip=', 'conquer_lev=', 'conquer_loop_id=']:
    if forbidden in dirsrc.replace(' ', '').lower():
        errs.append(f'directory reconciler may overwrite unowned field: {forbidden}')
need('internal/adapters/postgres/i4store/bootstrap_runtime.go','DirectoryReconciler','ReconcileDirectoryTx','tx.Serializable')

# C05 replay/evidence classification and transport-write truthfulness.
catalog=need('internal/foundation/replaycatalog/catalog.go','var Enabled = []Family{','i5.save-story','i5.grant','i5.mail-claim','i5.mail-batch-claim','i5.objective-claim','i5.objective-stock-claim','i5.redeem','i5.stack-adjust','i5.temporal-rebind','i5.admin-mail','delayed identical stock intent')
need('internal/projection/lobby/manifest.go','TRANSPORT_WRITE_RECORDED','SERVER_WRITE')
rt=need('internal/adapters/stockruntime/realtime_server.go','PhaseTransportWriteRecorded')
if 'PhaseServerWrite' in rt:
    errs.append('new realtime path still emits legacy SERVER_WRITE')

# C06 terminal retirement.
need('internal/domain/logicalserver/server.go','ErrServerRetired','retired logical server cannot admit or advertise')
need('internal/domain/logicalserver/lifecycle.go','s.RetiredAt != nil','ErrServerRetired','state != Retired')

# C07 version-aware persisted-key resolution; single-key deployment remains valid.
need('internal/application/identitylifecycle/key_resolver.go','KeyringBearerKeyResolver','ResolveBearerKey','verify-only')
need('internal/adapters/postgres/i4store/bootstrap_runtime.go','BearerKeys','selectGameplayCredentialForContext','storedKeyID','resolveBearerKey','DerivationKeyID')
need('internal/adapters/postgres/i4store/realtime_authority.go','BearerKeys','derivation_key_id','resolveBearerKey(ctx, keyID)')

# C08 explicit single realtime owner, with no multi-replica claim.
need('internal/adapters/postgres/realtime_owner.go','pg_try_advisory_lock','RealtimeOwnerAdvisoryKey','ErrRealtimeOwnerAlreadyHeld')
need('cmd/gxb-realtime/main_postgres.go','AcquireRealtimeOwner','realtime single-owner acquisition failed')

# C09 encode before headers and no redispatch-on-encode-failure behavior.
http=need('internal/protocol/httpedge/handler.go','json.Marshal(body)','response_encoding','WriteHeader(status)')
if http.find('json.Marshal(body)') > http.find('w.WriteHeader(status)'):
    errs.append('HTTP response headers still commit before JSON encoding')
need('internal/protocol/httpedge/decode_test.go','TestHandlerResponseEncodingFailureDoesNotRedispatch','dispatcher calls=')

# C10 bounded configurable transaction evidence sink using approved metrics labels.
need('internal/foundation/observability/metrics_jsonl.go','GXB_TX_METRICS_JSONL','GXB_TX_METRICS_MAX_BYTES','0o600','MaxBytes','m.full = true')
need('cmd/gxb-api/main_postgres.go','JSONLMetricsConfigFromEnv','observability.TxHooks','GXB')
need('internal/foundation/observability/metrics.go','forbiddenMetricFragments','operation_id','receipt','player')

# Historical R6 snapshot pins the exact module closure. A cumulative candidate may
# legitimately add later researched dependencies, so whole-file go.mod/go.sum hashes
# are snapshot-only there; the current dependency/SBOM validators own cumulative
# module closure. The canonical Go toolchain pin itself remains immutable.
toolchain_pins = {
    'go.mod':'ecafe7641bc26c7ef91bdc5c21a5f71aa432bd162ed6fe1725004b501172a949',
    'go.sum':'efbf6753542d66e2fefcb2ab5e2ade7c9d28f2206a1113d1eb9568f2cb75808d',
    '.go-version':'a8844fbc8c3eb51c26ed00aec4cd5a5a9d647f849c6ead07bcc83ed24c4a7718',
}
for rel,want in toolchain_pins.items():
    if args.cumulative and rel in {'go.mod','go.sum'}:
        continue
    if args.compat_scratch and rel == '.go-version':
        continue
    p=R/rel
    if not p.exists() or hashlib.sha256(p.read_bytes()).hexdigest()!=want:
        errs.append(f'canonical toolchain pin drift: {rel}')
if args.cumulative:
    if args.compat_scratch:
        need('go.mod')
    else:
        need('go.mod','go 1.26.0','toolchain go1.27.2')
    if not (R/'go.sum').exists():
        errs.append('current cumulative go.sum missing')

if errs:
    print('R6 VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('R6 VALIDATION: PASS' + (' (CUMULATIVE COMPATIBILITY-SCRATCH MODE)' if args.compat_scratch else (' (CUMULATIVE MODE)' if args.cumulative else ' (HISTORICAL SNAPSHOT MODE)')))
print('static projection/directory/replay/lifecycle/key/single-owner/http/observability R6 seams present; cumulative mode permits later migrations but does not weaken historical R6 pins')
