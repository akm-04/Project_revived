#!/usr/bin/env python3
from pathlib import Path
import hashlib, json, re, sys

R = Path(__file__).resolve().parents[1]
errs=[]
def req(ok,msg):
    if not ok: errs.append(msg)
def text(p): return (R/p).read_text()
def sha(p): return hashlib.sha256((R/p).read_bytes()).hexdigest()

# Canonical pins must remain pristine under normal-chat compatibility testing.
req(sha('go.mod')=='313c574368bb56dc570bc3427b65f59b059e492f909fe43b7d0291b5ced21dc4','go.mod canonical pin drift')
req(sha('go.sum')=='efbf6753542d66e2fefcb2ab5e2ade7c9d28f2206a1113d1eb9568f2cb75808d','go.sum canonical pin drift')
req(sha('.go-version')=='a8844fbc8c3eb51c26ed00aec4cd5a5a9d647f849c6ead07bcc83ed24c4a7718','.go-version canonical pin drift')

manifest=json.loads(text('internal/content/builtin/generated/manifest.json'))
cat=json.loads(text('internal/content/builtin/generated/super_equipment_catalog.json'))
req(manifest.get('revision_id')=='6ba22017fab270d38fbb68ab30bea0afe61442a979f74084fd7f5027a184e116','CA4-5 content revision drift')
req('SUPER_EQUIPMENT_CA4_5' in manifest.get('enabled_capabilities',[]),'Super equipment capability missing')
pos=cat.get('positions',[]); caps=cat.get('enhancement_caps',[]); tiers=cat.get('enhancement_tiers',[])
req(len(pos)==84 and len({x.get('hero_table_id') for x in pos})==14 and len({x.get('item_id') for x in pos})==12,'Super topology not 14x6/84/12')
req([(x.get('star'),x.get('max_enhancement'),x.get('effective_client_reachable')) for x in caps]==[(1,10,True),(2,10,True),(3,10,True),(4,10,True),(5,10,True),(6,20,True),(7,30,True),(8,40,True),(9,50,False),(10,60,False)],'Super cap policy drift')
req([(x.get('tier'),x.get('min_star'),x.get('duplicate_count'),x.get('effective_client_reachable')) for x in tiers]==[(1,1,1,True),(2,6,1,True),(3,7,1,True),(4,8,1,True),(5,9,2,False),(6,10,2,False)],'Super tier policy drift')

mig=text('migrations/00027_ca4_5_super_equipment_content.sql').lower()
req('create table gxb_content_super_equipment_positions' in mig and 'create table gxb_content_super_equipment_caps' in mig and 'create table gxb_content_super_equipment_tiers' in mig,'CA4-5 content tables missing')
req('player_super' not in mig and 'player_heroes' not in mig.replace('-- player-owned super equipment state remains single-owned by player_heroes equip_1..equip_6.',''),'CA4-5 migration introduced player-state ownership')

svc=text('internal/application/characterhero/equipment_service.go')
stock=text('internal/adapters/stockruntime/hero_dispatcher.go')
main=text('cmd/gxb-api/main_postgres.go')
domain=text('internal/domain/character/hero.go')

for tok in ['heroEquipmentMID54NormalV1','heroEquipmentMID54SuperV2','heroEquipmentMID62NormalV1','heroEquipmentMID304SuperV1']:
    req(tok in svc,f'missing receipt schema {tok}')
req('case character.SuperHero:' in svc and 'SuperEquipmentPositionTx' in svc,'MID54 Super fixed-topology branch missing')
req('validateNormalHeroForEquipment' in svc,'MID62 Normal qualification missing')
req('func (s Service) EnhanceSuperEquipment' in svc,'MID304 service missing')
req('MaxHeroStar                   = 8' in domain,'effective-client star8 ceiling drift')

# Shared MID54 must stay direct: one finished stack item, no recursive composition or Mana.
equip_seg=svc.split('func (s Service) EquipItem',1)[1].split('func (s Service) EnhanceSuperEquipment',1)[0]
req('DebitMaterialCostTx' in equip_seg and 'Amount: 1' in equip_seg,'MID54 direct one-item debit missing')
req('EquipmentRecipeEdgesTx' not in equip_seg,'MID54 unexpectedly composes recipe components')
req('ScalarMaterialCost' not in equip_seg and '"mana"' not in equip_seg.lower(),'MID54 unexpectedly charges Mana')
req('.Derive(' not in equip_seg and 'spirit' not in equip_seg.lower() and 'horcrux' not in equip_seg.lower(),'MID54 leaks RNG/Spirit/Horcrux')

mid304=svc.split('func (s Service) EnhanceSuperEquipment',1)[1].split('func (s Service) loadOneKeyContentTx',1)[0]
for tok in ['SuperEquipmentPositionTx','SuperEquipmentCapTx','SuperEquipmentTierTx','DebitMaterialCostTx','SaveHeroStateTx','duplicateCount != enhanceTimes']:
    req(tok in mid304,f'MID304 path missing {tok}')
req('ScalarMaterialCost' not in mid304 and '"mana"' not in mid304.lower(),'MID304 unexpectedly charges Mana')
req('EquipmentRecipeEdgesTx' not in mid304,'MID304 unexpectedly composes recipe components')
req('.Derive(' not in mid304,'MID304 unexpectedly consumes operation entropy')
req('spirit' not in mid304.lower() and 'horcrux' not in mid304.lower(),'MID304 leaks Spirit/Horcrux lifecycle')

for tok in ['case 54:','case 62:','case 304:','onlyStockGameplayParams(req.Envelope.Params, "partner_id", "equip_index", "enhance_times")','Body: map[string]any{}']:
    req(tok in stock,f'stock wire missing {tok}')
route=re.search(r'for _, mid := range \[\]uint16\{([^}]*)\} \{\s*mustRegister\(mid, heroD\)',main,re.S)
req(bool(route),'Hero production registration block missing')
if route:
    for mid in (54,62,304): req(re.search(rf'(^|\D){mid}(\D|$)',route.group(1)) is not None,f'MID{mid} production registration missing')

# Test names are acceptance-proof anchors; execution is a separate gate.
tests='\n'.join(text(p) for p in [
 'internal/application/characterhero/equipment_service_test.go',
 'internal/application/characterhero/ca4_5_recovery_test.go',
 'internal/adapters/stockruntime/hero_ca4_2_test.go',
 'internal/projection/hero/stock_test.go',
])
for name in [
 'TestCA45EquipmentReceiptValidationIsFamilyQualified',
 'TestCA45EquipmentReceiptValidationRejectsTamperedPayload',
 'TestCA45SuperEquipItemUsesFixedTopologyAndFamilyReceiptReplay',
 'TestCA45SuperEquipItemLevelGateAndAlreadyEquippedCompatibility',
 'TestCA45OneKeySuperFailsClosed',
 'TestCA45EnhanceSuperEquipmentCrossTierAndReceiptReplay',
 'TestCA45EnhanceSuperEquipmentMultiLevelDebitAcrossReachableTiers',
 'TestCA45EnhanceSuperEquipmentExactStarCaps',
 'TestCA45EnhanceSuperEquipmentRejectsWrongFamilyUncollectedAndInvalidCount',
 'TestCA45EnhanceSuperEquipmentRejectsOutsideEffectiveStarRangeBeforeDebit',
 'TestCA45MID304LateReceiptFailureRollsBackHeroAndDebitTogether',
 'TestCA45MID304AmbiguousCommitReconcilesOnlyThroughOuterReceipt',
 'TestCA45MID304AmbiguousCommitWithoutOuterReceiptIsUnknownNoBlindReplay',
 'TestCA45MID304ConcurrentSameHeroSerializesWithoutLostUpdate',
 'TestCA45SuperMID54AmbiguousCommitReconcilesThroughReceipt',
 'TestCA45SuperMID54AmbiguousCommitWithoutReceiptIsUnknownNoBlindReplay',
 'TestCA45ConcurrentSuperEquipAndEnhanceSerializeWithoutLostSlots',
 'TestCA45MID304StrictShapeAndEmptySuccess',
 'TestCA45MID49ReconnectPreservesRawSuperEquipmentValues',
 'TestStockHeroProjectsDurableEquipmentValues',
]: req(name in tests,f'acceptance proof test missing {name}')

# No CA4-5 production file may claim a new Super durable owner.
own=json.loads(text('docs/architecture/CANONICAL_TABLE_OWNERSHIP.json'))
blob=json.dumps(own).lower()
req('gxb_content_super_equipment_positions' in blob and 'gxb_content_super_equipment_caps' in blob and 'gxb_content_super_equipment_tiers' in blob,'content ownership entries missing')
req('player_super' not in blob,'invented Super player owner present')

if errs:
    print('CA4-5 VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA4-5 VALIDATION: PASS')
print('fixed Super content, family-safe MID54, Normal-only MID62, deterministic MID304, no new player owner/RNG/Horcrux path, and acceptance proof anchors present')
