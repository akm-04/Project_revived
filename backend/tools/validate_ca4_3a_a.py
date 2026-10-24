#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,re,sys
R=Path(__file__).resolve().parents[1]; errs=[]
def need(rel,*tokens):
 p=R/rel
 if not p.exists(): errs.append(f'missing {rel}'); return ''
 s=p.read_text(errors='replace')
 for t in tokens:
  if t not in s: errs.append(f'{rel}: missing {t!r}')
 return s
def req(x,msg):
 if not x: errs.append(msg)

m=json.loads(need('internal/content/builtin/generated/manifest.json') or '{}')
later = 'HERO_PROMOTION_RESTORATION_CA4_3B' in m.get('enabled_capabilities',[])
if later:
 req((m.get('compiler_version'),m.get('parser_version')) in {('ca4-3b','lua-generated-v9-hero-promotion-restoration'),('ca4-4a-i1','lua-generated-v10-pet-equipment'), ('ca6-2-practice-foundation','lua-generated-v13-practice')},'cumulative compiler/parser drift beyond CA4-3A')
else:
 req((m.get('compiler_version'),m.get('parser_version'))==('ca4-3a','lua-generated-v8-hero-fumo'),'CA4-3A compiler/parser drift')
 req(m.get('revision_id')=='aa89ed03a9315a9faf8392b9beb4141594ad911033483659ea0c31674a79dc83','CA4-3A content revision drift')
req('HERO_FUMO_CA4_3A' in m.get('enabled_capabilities',[]),'CA4-3A capability absent')
d=m.get('diagnostics',{})
req(d.get('hero_fumo_targets')==359,f'Hero Fumo target count drift {d.get("hero_fumo_targets")!r}')
req(d.get('hero_fumo_materials')==516,f'Hero Fumo material count drift {d.get("hero_fumo_materials")!r}')
cat=json.loads(need('internal/content/builtin/generated/hero_fumo_catalog.json') or '{}')
req(len(cat.get('targets',[]))==359,'Fumo target artifact count drift')
req(len(cat.get('materials',[]))==516,'Fumo material artifact count drift')

mig=need('migrations/00021_ca4_3a_hero_fumo.sql','CREATE TABLE gxb_content_hero_fumo_targets','CREATE TABLE gxb_content_hero_fumo_materials','ALTER TABLE player_heroes','fumo_1 bigint NOT NULL DEFAULT 0 CHECK (fumo_1 >= 0)','fumo_6 bigint NOT NULL DEFAULT 0 CHECK (fumo_6 >= 0)')
req('-- +goose Down' not in mig,'00021 violates forward-only migration law')
lock=json.loads(need('docs/architecture/CUMULATIVE_MIGRATION_LOCK.json') or '{}')
p=R/'migrations/00021_ca4_3a_hero_fumo.sql'
req(str(lock.get('highest_migration','')) >= p.name,'cumulative migration high-water predates CA4-3A-A')
req(lock.get('migrations',{}).get(p.name)==hashlib.sha256(p.read_bytes()).hexdigest(),'00021 migration hash not sealed')
own=json.loads(need('docs/architecture/CANONICAL_TABLE_OWNERSHIP.json') or '{}').get('tables',{})
for table in ['gxb_content_hero_fumo_targets','gxb_content_hero_fumo_materials']:
 row=own.get(table)
 req(bool(row) and row.get('owner')=='content-registry' and row.get('migration')=='migrations/00021_ca4_3a_hero_fumo.sql',f'{table} ownership drift')

need('internal/domain/character/equipment.go','type HeroFumoSlots [HeroEquipmentSlotCount]int64','type HeroFumoTarget struct','type HeroFumoMaterial struct')
need('internal/domain/character/hero.go','Fumo                    HeroFumoSlots','h.Fumo.Validate()')
need('sql/character/hero.sql','fumo_1','fumo_6','SaveHeroState','fumo_1=$12','fumo_6=$17')
need('internal/adapters/postgres/characterstore/store.go','h.Fumo[0]','h.Fumo[5]')
need('internal/adapters/postgres/contentstore/hero_fumo.go','HeroFumoTargetTx','HeroFumoMaterialTx','HERO_FUMO_CA4_3A')
need('internal/application/characterhero/equipment_state.go','RawFumo: rawFumo')
stock=need('internal/projection/hero/stock.go','fumos := make([]any, character.HeroEquipmentSlotCount)','fumos[i] = h.Fumo[i]','"fumos": fumos')
if later:
 req('func StockHeroWithFumoLevels' in stock and 'out["fumo_levels"] = wireLevels' in stock,'qualified CA4-3B derived reload projection missing')
 roster=need('internal/application/characterhero/service.go','func (s Service) RosterView','FumoLevels character.HeroFumoSlots')
 req('deriveFumoLevelsRead' in need('internal/application/characterhero/fumo_service.go'),'qualified CA4-3B derived Fumo read missing')
 for rel in ['internal/domain/character/hero.go','sql/character/hero.sql','internal/adapters/postgres/characterstore/store.go','migrations/00021_ca4_3a_hero_fumo.sql','migrations/00022_ca4_3b_hero_promotion_restoration.sql']:
  req('fumo_levels' not in need(rel),f'{rel}: derived fumo_levels became durable authority')
else:
 req('"fumo_levels"' not in stock,'A-stage general reload invented fumo_levels authority')

# Historical A-stage leak guard applies only to the exact A-stage snapshot.
# A cumulative qualified later capability is allowed to contain the accepted B
# gameplay while all A durability/content facts above remain mandatory.
if not later:
 for root in [R/'internal',R/'cmd']:
  for pth in root.rglob('*.go'):
   if pth.name.endswith('_test.go'): continue
   s=pth.read_text(errors='replace')
   if re.search(r'\bcase\s+58\s*:',s): errs.append(f'CA4-3A-A leaked MID58 dispatcher case into {pth.relative_to(R)}')
 for token in ['FumoEquipment(', 'EnhanceFumo(']:
  for pth in (R/'internal/application').rglob('*.go'):
   if pth.name.endswith('_test.go'): continue
   if token in pth.read_text(errors='replace'): errs.append(f'CA4-3A-B gameplay leaked into {pth.relative_to(R)}: {token}')
 for pth in (R/'internal/application/characterhero').rglob('*.go'):
  if pth.name.endswith('_test.go'): continue
  if re.search(r'\bMID58\b',pth.read_text(errors='replace')): errs.append(f'CA4-3A-B MID58 marker leaked into {pth.relative_to(R)}')

expected={
 '.go-version':'a8844fbc8c3eb51c26ed00aec4cd5a5a9d647f849c6ead07bcc83ed24c4a7718',
 'go.mod':'313c574368bb56dc570bc3427b65f59b059e492f909fe43b7d0291b5ced21dc4',
 'go.sum':'efbf6753542d66e2fefcb2ab5e2ade7c9d28f2206a1113d1eb9568f2cb75808d'}
for rel,want in expected.items():
 got=hashlib.sha256((R/rel).read_bytes()).hexdigest(); req(got==want,f'canonical pin changed {rel}: {got}')

if errs:
 print('CA4-3A-A VALIDATION: FAIL'); [print(' -',e) for e in errs]; sys.exit(1)
print('CA4-3A-A VALIDATION: PASS')
print('immutable Fumo content + six raw Hero Fumo values + cohesive CAS/reload/raw-state projection are present; cumulative later gameplay is permitted only when a qualified later capability is present' if later else 'immutable Fumo content + six raw Hero Fumo values + cohesive CAS/reload/raw-state projection are present; MID58 gameplay/route activation remains absent')
