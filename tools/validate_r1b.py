#!/usr/bin/env python3
from pathlib import Path
import sys,re
ROOT=Path(__file__).resolve().parents[1]
p=ROOT/'internal/adapters/postgres/i4store/bootstrap_runtime.go'
s=p.read_text(errors='replace')
errors=[]
def need(x,msg=None):
    if x not in s: errors.append(msg or f'missing {x!r}')

def forbid(x,msg=None):
    if x in s: errors.append(msg or f'forbidden {x!r}')

need('mid1ReceiptSchemaV2 = "gxb.mid1.select.v2"')
need('type mid1SelectionReceiptPayload struct')
need('DerivationKeyID         string')
need('BootstrapProfileVersion string')
# The v2 selection payload must not define mutable/secret fields.
m=re.search(r'type mid1SelectionReceiptPayload struct \{(.*?)\n\}',s,re.S)
if not m: errors.append('cannot locate v2 receipt struct')
else:
    body=m.group(1)
    for f in ('Token','Detail','IsNew'):
        if re.search(r'\b'+f+r'\b',body): errors.append(f'v2 receipt stores forbidden mutable/secret field {f}')
need('return s.hydrateCommittedMID1(ctx, req, stored)')
need('selectGameplayCredentialForContext')
need('storedKeyID')
need('key, err := s.resolveBearerKey(txctx, storedKeyID)')
need('identity.DeriveGameplayBearer(key.Secret, *live)')
need('committed MID1 context has no matching derivable gameplay credential')
need('verifyGameplayCredential')
need('IsNew: logicalserver.MID1IsNew(*player)')
need('out = planned')
forbid('decodeMID1Receipt(', 'stale full MID1 receipt decoder still reachable')
need('FROM logical_servers WHERE logical_server_id=$1 FOR SHARE')
need('FROM logical_servers WHERE logical_server_id=$1 FOR UPDATE')
need('serverAdmissionFenceQuery(true)')
need('serverAdmissionFenceQuery(false)')
# Creation path must recheck after exclusive fence.
ix=s.find('func loadServerForMID1Admission')
if ix<0: errors.append('missing loadServerForMID1Admission')
else:
    block=s[ix:s.find('\nfunc loadPlayer(',ix)]
    if block.find('serverAdmissionFenceQuery(false)')<0 or block.find('rechecked, err := loadPlayer')<0:
        errors.append('creation path missing exclusive fence + post-fence player recheck')
# New receipt builder must emit v2, never legacy v1.
b=s[s.find('func buildMID1Receipt'):s.find('func validateStoredMID1Selection')]
if 'ResultSchema: mid1ReceiptSchemaV2' not in b: errors.append('new receipt builder does not emit v2 selection schema')
if 'mid1ReceiptSchemaV1' in b: errors.append('new receipt builder still emits v1')
# Historical v1 is accepted only through minimal immutable-field parser.
need('type legacyMID1ReceiptPayload struct')
need('case mid1ReceiptSchemaV1:')
need('never return or log the historical secret-bearing payload')
# Tests proving mutability and lock split.
t=(ROOT/'internal/adapters/postgres/i4store/bootstrap_runtime_test.go').read_text(errors='replace')
for name in ['TestMID1V2ReceiptContainsSelectionOnlyAndSurvivesMutableHydrationChange','TestLegacyMID1V1ReceiptIsSelectionEvidenceNotHydrationTruth','TestMID1ServerAdmissionFenceSeparatesExistingAndCreationPaths']:
    if name not in t: errors.append('missing test '+name)
if errors:
    print('R1B VALIDATION: FAIL')
    for e in errors: print(' -',e)
    sys.exit(1)
print('R1B VALIDATION: PASS')
print('MID1 immutable selection receipt/current hydration/secret retention and shared-vs-exclusive server fence verified structurally')
