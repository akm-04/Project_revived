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
req((m.get('compiler_version'),m.get('parser_version')) in {('ca4-2a','lua-generated-v7-hero-equipment'),('ca4-4a-i1','lua-generated-v10-pet-equipment'), ('ca6-2-practice-foundation','lua-generated-v13-practice')},'CA4-2A cumulative compiler/parser drift')
req(m.get('revision_id')=='bd11a7482062dbaa851f3b495e3dc6efab88085011b3fe75d82105e127bba106','CA4-2A content revision drift')
req('HERO_EQUIPMENT_CA4_2' in m.get('enabled_capabilities',[]),'CA4-2A capability absent')
d=m.get('diagnostics',{})
for k,w in {'hero_equipment_positions':53280,'hero_equipment_ordinary_positions':50504,'hero_equipment_special_positions':1646,'hero_equipment_zero_positions':1130,'hero_equipment_unique_ordinary_items':214,'hero_equipment_unique_special_items':164}.items(): req(d.get(k)==w,f'{k} drift {d.get(k)!r}')
cat=json.loads(need('internal/content/builtin/generated/hero_equipment_catalog.json') or '{}'); req(len(cat.get('positions',[]))==53280,'Hero equipment artifact count drift')

mig=need('migrations/00020_ca4_2_hero_equipment.sql','CREATE TABLE gxb_content_hero_equipment','ALTER TABLE player_heroes','equip_1 bigint NOT NULL DEFAULT 0 CHECK (equip_1 >= 0)','equip_6 bigint NOT NULL DEFAULT 0 CHECK (equip_6 >= 0)')
req('equip_1 <= 1' not in mig and 'equip_6 <= 1' not in mig,'shared durable Hero slots incorrectly DB-constrained to Normal-Hero bits')
req('-- +goose Down' not in mig,'00020 violates forward-only migration law')
lock=json.loads(need('docs/architecture/CUMULATIVE_MIGRATION_LOCK.json') or '{}')
p=R/'migrations/00020_ca4_2_hero_equipment.sql'; req(lock.get('highest_migration')==p.name,'migration high-water not CA4-2A'); req(lock.get('migrations',{}).get(p.name)==hashlib.sha256(p.read_bytes()).hexdigest(),'00020 migration hash not sealed')
own=json.loads(need('docs/architecture/CANONICAL_TABLE_OWNERSHIP.json') or '{}').get('tables',{}).get('gxb_content_hero_equipment'); req(bool(own) and own.get('owner')=='content-registry' and own.get('migration')=='migrations/00020_ca4_2_hero_equipment.sql','Hero equipment content ownership drift')

need('internal/domain/character/equipment.go','type HeroEquipmentSlots [HeroEquipmentSlotCount]int64','ValidateNormal','type HeroEquipmentPosition struct')
need('internal/domain/character/hero.go','Equipment               HeroEquipmentSlots','h.Equipment.Validate()')
need('sql/character/hero.sql','ReadHeroByPartnerID','SaveHeroState','equip_1=$6','equip_6=$11','state_version=state_version+1')
need('internal/adapters/postgres/characterstore/store.go','ReadHeroByPartnerIDTx','SaveHeroStateTx','h.Equipment[5]')
need('internal/adapters/postgres/contentstore/hero_equipment.go','HeroEquipmentRevision','HeroEquipmentPositionTx','HERO_EQUIPMENT_CA4_2')
need('internal/application/characterhero/equipment_state.go','RawEquipmentStateTx','ValidateNormal','Family:       "HERO"','RawEquipmentSlot','ordinary slot contradicts current content mapping')
stock=need('internal/projection/hero/stock.go','equips := make([]any, character.HeroEquipmentSlotCount)','for i, v := range h.Equipment')
req('"equips": append([]any(nil), zero6...)' not in stock,'stock Hero still hardcodes zero equipment projection')

# Scope guard: A establishes content/persistence only. It must not implement or
# production-register shared gameplay MIDs, I5 CA4-2B prepared debit, or CA4-2C planner/service.
for root in [R/'internal',R/'cmd']:
 for p in root.rglob('*.go'):
  if p.name.endswith('_test.go'): continue
  s=p.read_text(errors='replace')
  if re.search(r'\bcase\s+(54|62)\s*:',s): errs.append(f'CA4-2A leaked MID54/MID62 dispatcher case into {p.relative_to(R)}')
for forbidden in ['TxHeroEquipmentPreparedDebiter','CA4_2_EQUIPMENT_PLANNER','EquipOneClick','MID54','MID62']:
 # Names in historical docs/tests do not count; production application code must remain absent.
 for p in (R/'internal/application').rglob('*.go'):
  if p.name.endswith('_test.go'): continue
  if forbidden in p.read_text(errors='replace'): errs.append(f'CA4-2B/C behavior leaked into {p.relative_to(R)}: {forbidden}')

if errs:
 print('CA4-2A VALIDATION: FAIL'); [print(' -',e) for e in errs]; sys.exit(1)
print('CA4-2A VALIDATION: PASS')
print('Normal-Hero immutable slot mapping, six-value Hero-owned durability/CAS, reload projection and raw CA4-1 stat seam are present; CA4-2B/C/D gameplay activation remains absent')
