#!/usr/bin/env python3
from pathlib import Path
import re
import sys
ROOT=Path(__file__).resolve().parents[1]
errs=[]
def req(ok,msg):
    if not ok: errs.append(msg)
service=(ROOT/'internal/application/characterhero/appearance_service.go').read_text()
materializer=(ROOT/'internal/application/characterhero/appearance_materializer.go').read_text()
store=(ROOT/'internal/adapters/postgres/characterstore/appearance.go').read_text()
dispatch=(ROOT/'internal/adapters/stockruntime/hero_dispatcher.go').read_text()
main=(ROOT/'cmd/gxb-api/main_postgres.go').read_text()
replay=(ROOT/'internal/foundation/replaycatalog/catalog.go').read_text()
arch=(ROOT/'internal/archguard/ca7_2_contract_test.go').read_text()
for tok in ['func (s Service) SkinOn(', 'func (s Service) SkinCancel(', 'func (s Service) UseIllusionSkinItem(', 'BuildEffectiveHeroAppearanceTx', 'tx.Serializable', 'DecisionAt()']:
    req(tok in service, f'CA7-3 service contract marker missing {tok!r}')
for tok in ['SaveHeroAppearanceMutationTx', 'UpsertHeroSkinEntitlement', 'SaveHeroAppearanceSelectors']:
    req(tok in store, f'CA7-3 cohesive Hero CAS marker missing {tok!r}')
req('type TxPermanentSkinMaterializer interface' in materializer and 'GrantPermanentSkinTx' in materializer, 'future Commerce typed permanent-skin materializer missing')
for tok in ['case 60:', 'case 61:', 'case 2979:']:
    req(tok in dispatch, f'CA7-3 dispatcher route missing {tok}')
for tok in ['case 1893:', 'case 1894:', 'case 1895:']:
    req(tok not in dispatch, f'Pet-owned CA7-5 route leaked into Hero dispatcher: {tok}')
registered = {int(mid) for block in re.findall(r'range \[\]uint16\{([0-9, ]+)\}', main) for mid in block.split(',')}
req({58, 60, 61, 62, 67, 68, 69, 89, 304, 2979} <= registered, 'CA7-3/4 production registration drift')
for tok in ['ca7.hero-skin-on', 'ca7.hero-skin-cancel', 'ca7.hero-illusion-select']:
    req(tok in replay, f'CA7-3 replay family missing {tok!r}')
req('CurrentStateConvergence' in replay, 'MID60 current-state convergence replay classification missing')
req('TestCA75AppearanceActivationPreservesOwnerAndSuccessorFences' in arch, 'evolved CA7 architecture ownership fence missing')
if errs:
    print('CA7-3 VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA7-3 VALIDATION: PASS')
print('Hero-owned ordinary/timed/illusion mutation seams, cohesive CAS, replay classes, future Commerce typed materializer, production routing and Pet-owner separation preserved')
