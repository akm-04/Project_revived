#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT=Path(__file__).resolve().parents[1]
errs=[]
def req(ok,msg):
    if not ok: errs.append(msg)

def read(rel): return (ROOT/rel).read_text()

service=read('internal/application/characterhero/live_service.go')
svcroot=read('internal/application/characterhero/service.go')
dispatch=read('internal/adapters/stockruntime/hero_dispatcher.go')
main=read('cmd/gxb-api/main_postgres.go')
store=read('internal/adapters/postgres/characterstore/appearance.go')
replay=read('internal/foundation/replaycatalog/catalog.go')
check=read('tools/check.sh')

for tok in [
    'func (s Service) UnlockLIVE(', 'func (s Service) SetLIVEShow(',
    'HeroLIVEMutationStore', 'tx.Serializable', 'RetryDefiniteAbort: true',
    'FenceActorTx', 'AppearanceRevisionTx', 'LockHeroByPartnerIDTx',
    'DebitMaterialCostTx', 'SaveHeroLIVEEntitlementTx',
    'liveUnlockReceiptSchema', 'liveShowReceiptSchema',
]: req(tok in service, f'CA7-4 service marker missing {tok!r}')
req('LIVEMutationStore         HeroLIVEMutationStore' in svcroot,'CA7-4 LIVE mutation seam not wired into Character service')
req('h.Kind != character.NormalHero' in service,'CA7-4 paid LIVE NormalHero qualification missing')
req('def.HeroOriginTableID != h.OriginTableID' in service,'CA7-4 paid LIVE origin qualification missing')
req('IsShow: true' in service,'CA7-4 first-unlock initial show=true policy missing')
req('if !owned {' in service and 'debitLIVEUnlockTx' in service,'CA7-4 current-state convergence/no-second-debit branch missing')
req('current.IsShow != isShow' in service,'CA7-4 explicit show assignment/no-op check missing')

for tok in ['case 68:', 'case 69:', 'requiredJSONBit', '"unlocked_dynamic_card"', '"dynamic_card_state"', '"economy_"', '"crystal"']:
    req(tok in dispatch, f'CA7-4 stock dispatcher marker missing {tok!r}')
req('raw.(json.Number)' in dispatch and 'v != 0 && v != 1' in dispatch,'MID69 strict numeric 0/1 parser missing')
for invented in ['"remove_item"', '"activation_item"', '"server_time"']:
    # Those words may exist for older MIDs; constrain the CA7-4 block instead.
    block=dispatch[dispatch.find('case 68:'):dispatch.find('case 69:')]
    req(invented not in block,f'MID68 invented response field present {invented}')

req('LIVEMutationStore: heroDB' in main and 'LIVE: heroSvc' in main,'CA7-4 production composition missing')
req('67, 68, 69, 89' in main,'CA7-4 production MID registration missing')
for forbidden in ['case 1893:', 'case 1894:', 'case 1895:']:
    req(forbidden not in dispatch,f'Pet-owned CA7-5 route leaked into Hero dispatcher: {forbidden}')

for tok in ['UpsertHeroLIVEEntitlement', 'TouchHeroAppearanceVersion']:
    req(tok in store,f'CA7-4 Hero-owned single-CAS LIVE persistence marker missing {tok!r}')
for tok in ['ca7.hero-live-unlock', 'CurrentStateConvergence', 'gxb.ca7-4.live-unlock.v1', 'ca7.hero-live-show', 'ParameterStateSet', 'gxb.ca7-4.live-show.v1']:
    req(tok in replay,f'CA7-4 replay catalog marker missing {tok!r}')
req('check_ca7_4_source_oracle.py' in check and 'validate_ca7_4.py' in check,'CA7-4 retained guards are not wired into cumulative check')

# No CA7-4 schema migration is allowed.
migrations=list((ROOT/'migrations').glob('*ca7_4*')) if (ROOT/'migrations').exists() else []
req(not migrations,'CA7-4 unexpectedly introduced a schema migration')

if errs:
    print('CA7-4 VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA7-4 VALIDATION: PASS')
print('Hero-owned paid LIVE unlock/show seams, current-state convergence, strict wire parsing, I5 composition, single CAS, replay classes, production routing and CA7-5 Pet-owner separation preserved')
