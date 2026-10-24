#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,re,sys
R=Path(__file__).resolve().parents[1]
errs=[]
def read(rel):
 p=R/rel
 if not p.exists(): errs.append(f'missing {rel}'); return ''
 return p.read_text(errors='replace')
def req(ok,msg):
 if not ok: errs.append(msg)

# Stage A/B/C must remain qualified.
for script in ['tools/validate_ca4_3b.py','tools/validate_ca4_3b_stage_c.py']:
 req((R/script).exists(),f'missing prerequisite validator {script}')

svc=read('internal/application/characterhero/service.go')
for tok in ['type HeroRosterProjectionContent interface','type HeroRosterView struct','RosterProjection    HeroRosterProjectionContent','func (s Service) RosterView','HeroEquipmentRevision(ctx, revision)','HeroFumoRevision(ctx, revision)','deriveFumoLevelsRead(ctx, revision']:
 req(tok in svc,f'roster view contract missing {tok!r}')
fumo=read('internal/application/characterhero/fumo_service.go')
for tok in ['func (s Service) deriveFumoLevelsRead','HeroEquipmentPosition(ctx, revision','HeroFumoTarget(ctx, revision','deriveFumoLevel(raw, target)']:
 req(tok in fumo,f'derived Fumo reload seam missing {tok!r}')
for rel,toks in {
 'internal/adapters/postgres/contentstore/hero_equipment.go':['func (s Store) HeroEquipmentPosition(','HeroEquipmentPositionTx(ctx, s.Queryer'],
 'internal/adapters/postgres/contentstore/hero_fumo.go':['func (s Store) HeroFumoTarget(','HeroFumoTargetTx(ctx, s.Queryer'],
}.items():
 txt=read(rel)
 for tok in toks: req(tok in txt,f'{rel}: missing {tok!r}')

proj=read('internal/projection/hero/stock.go')
for tok in ['type RosterHeroView struct','func StockHeroWithFumoLevels','out["fumo_levels"] = wireLevels','func StockRosterView']:
 req(tok in proj,f'Hero reload projection missing {tok!r}')
# Derived levels must not become durable authority.
for rel in ['internal/domain/character/hero.go','sql/character/hero.sql','internal/adapters/postgres/characterstore/store.go','migrations/00021_ca4_3a_hero_fumo.sql','migrations/00022_ca4_3b_hero_promotion_restoration.sql']:
 req('fumo_levels' not in read(rel),f'{rel}: fumo_levels leaked into durability')

d=read('internal/adapters/stockruntime/hero_dispatcher.go')
for tok in ['case 51: // POWERUP_HERO','PowerUpHero(ctx, actor','case 57: // ONE_CLICK_JINJIE','OneClickJinjie(ctx, actor','heroPromotionResponse(got)','RosterView(ctx, actor)','StockRosterView']:
 req(tok in d,f'dispatcher missing {tok!r}')
# Response is sparse and MID57 must not perform postcommit scalar projection.
sec57=d.split('case 57:',1)[1].split('case 52:',1)[0] if 'case 57:' in d and 'case 52:' in d else ''
req('CurrentScalar(' not in sec57,'MID57 performs forbidden postcommit scalar read')
resp=d.split('func heroPromotionResponse',1)[1].split('func badHero',1)[0] if 'func heroPromotionResponse' in d else ''
for tok in ['"restore_items"','"table_id": award.TableID','"item_num": award.ItemNum','"economy_"','"mana": *got.ManaAfter']:
 req(tok in resp,f'promotion response helper missing {tok!r}')
for bad in ['"equips"','"color"','"lev"','"exp"']:
 req(bad not in resp,f'promotion response invented broad Hero field {bad}')

main=read('cmd/gxb-api/main_postgres.go')
for tok in ['Promotion: contentDB','PromotionResources: i5svc','StrictRestoration: i5svc','MaxHeroColorPolicy: maxHeroColorPolicy','RestorationModifier: characterasset.IdentityRestorationModifier{}','RosterProjection: contentDB']:
 req(tok in main,f'production composition missing {tok!r}')
manifest=json.loads(read('internal/content/builtin/generated/manifest.json') or '{}')
ca45='SUPER_EQUIPMENT_CA4_5' in manifest.get('enabled_capabilities',[])
route=re.search(r'for _, mid := range \[\]uint16\{([^}]*)\} \{\s*mustRegister\(mid, heroD\)',main,re.S)
req(bool(route),'Hero production route set not found')
if route:
 nums=[int(x) for x in re.findall(r'\d+',route.group(1))]
 for need in [49,51,57,58]: req(need in nums,f'required Hero MID {need} not registered')
 for shared in [54,62]:
  req((shared in nums) if ca45 else (shared not in nums), f'CA4-5 shared Hero MID {shared} registration mismatch')

# Required adversarial and reconnect tests exist.
tests=read('internal/adapters/stockruntime/hero_ca4_3b_test.go')+read('internal/application/characterhero/service_test.go')+read('internal/projection/hero/stock_test.go')
for tok in ['TestCA43BMID49ProjectsDerivedFumoLevelsAfterReconnect','TestCA43BMID51StrictSparseRestoreResponse','TestCA43BMID57UsesReceiptManaAndDoesNotPostReadEconomy','TestRosterViewPinsActiveRevisionAndDerivesSixNormalHeroFumoLevels','TestStockRosterViewProjectsSixDerivedFumoLevelsForNormalHeroOnly']:
 req(tok in tests,f'missing Stage-D regression {tok}')

expected={
 '.go-version':'a8844fbc8c3eb51c26ed00aec4cd5a5a9d647f849c6ead07bcc83ed24c4a7718',
 'go.mod':'313c574368bb56dc570bc3427b65f59b059e492f909fe43b7d0291b5ced21dc4',
 'go.sum':'efbf6753542d66e2fefcb2ab5e2ade7c9d28f2206a1113d1eb9568f2cb75808d'}
for rel,want in expected.items():
 p=R/rel; req(p.exists() and hashlib.sha256(p.read_bytes()).hexdigest()==want,f'canonical pin changed {rel}')

if errs:
 print('CA4-3B STAGE D VALIDATION: FAIL')
 for e in errs: print(' -',e)
 sys.exit(1)
print('CA4-3B STAGE D VALIDATION: PASS')
print('MID49 derived reload projection, sparse MID51/MID57 wire behavior, production 51/57 registration, CA4-5-aware 54/62 boundary, and canonical pins are present')
