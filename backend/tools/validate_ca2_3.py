#!/usr/bin/env python3
"""CA2-3 static scope/activation/ownership guard."""
from pathlib import Path
import json,re,sys
ROOT=Path(__file__).resolve().parents[1]; errs=[]
def read(p): return (ROOT/p).read_text(errors='replace')
# No new immutable content or guessed capacity migration is authorized.
if (ROOT/'migrations/00016_ca2_hero_acquisition.sql').exists(): errs.append('unauthorized CA2-3 migration 00016 exists')
for p in (ROOT/'migrations').glob('*.sql'):
 txt=p.read_text(errors='replace')
 if re.search(r'hero_capacity|capacity_limit|max_hero_slots|hero_slot_price',txt,re.I): errs.append(f'guessed Hero capacity persistence in {p.name}')
manifest=json.loads(read('internal/content/builtin/generated/manifest.json'))
if manifest.get('compiler_version')!='ca2-2': errs.append('CA2-3 unexpectedly changed content compiler generation')
if manifest.get('schema_version')!=1: errs.append('CA2-3 unexpectedly changed content schema version')
main=read('cmd/gxb-api/main_postgres.go')
if '[]uint16{49, 52, 55, 63, 67, 89}' not in main: errs.append('production Hero route set changed from approved CA2-2 set')
for mid in ['59','305','64','66']:
 if re.search(rf'\bmustRegister\({mid}\b|\[\]uint16\{{[^}}]*\b{mid}\b',main): errs.append(f'capacity/deferred MID {mid} registered in production')
if re.search(r'PartnerEntities\s*:',main): errs.append('production I5 PartnerEntity Hero provider installed while capacity UNKNOWN')
# Diagnostic handlers must exist but remain unregistered.
disp=read('internal/adapters/stockruntime/hero_dispatcher.go')
for token in ['case 59:','case 305:']:
 if token not in disp: errs.append(f'CA2-3 diagnostic handler missing {token}')
app='\n'.join(read(x) for x in ['internal/application/characterhero/acquisition.go','internal/application/characterhero/materializer.go','internal/application/characterhero/progression.go'])
for token in ['character.hero','ca2-3.v1','gxb.ca2.hero-materialization.v1','ErrHeroCapacityUnavailable','HeroRootLockRank','AuthorizeHeroAddition','DebitMaterialCostTx','PlayerLevelTx']:
 if token not in app: errs.append(f'CA2-3 seam/evidence missing {token}')
if 'sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })' not in read('internal/application/characterhero/progression.go'):
 errs.append('HeroInstance canonical partner ordering is not numeric')
if 'LockRootTx(txctx, scope.Tx, actor.PlayerID)' not in read('internal/application/characterhero/progression.go'):
 errs.append('Super low-star evolution lacks HeroRoot stabilization')
# Character SQL remains owner-pure.
for p in [ROOT/'internal/adapters/postgres/characterstore/store.go', ROOT/'sql/character/hero.sql']:
 txt=p.read_text(errors='replace')
 for foreign in ['player_item_stacks','player_currency_balances','player_progression']:
  if foreign in txt: errs.append(f'foreign-owner SQL {foreign} found in {p.relative_to(ROOT)}')
# Existing CA1 receipt remains semantic materialization authority; no second ledger.
for p in (ROOT/'migrations').glob('*.sql'):
 if re.search(r'hero_.*materiali[sz]ation|materiali[sz]ation_.*hero',p.read_text(errors='replace'),re.I): errs.append(f'duplicate Hero materialization ledger in {p.name}')
if errs:
 print('CA2-3 STATIC VALIDATION: FAIL'); [print(' -',e) for e in errs]; raise SystemExit(1)
print('CA2-3 STATIC VALIDATION: PASS')
print('acquisition mechanics exist behind owner-shaped seams while capacity-dependent production activation remains fail-closed')
