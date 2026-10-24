#!/usr/bin/env python3
"""CA2-2 static scope/ownership/content guard."""
from pathlib import Path
import json,re,sys
CUMULATIVE='--cumulative' in sys.argv[1:]
ROOT=Path(__file__).resolve().parents[1]; errs=[]
def read(p): return (ROOT/p).read_text(errors='replace')
if not (ROOT/'migrations/00015_ca2_hero_progression_content.sql').exists(): errs.append('migration 00015 missing')
else:
 mig=read('migrations/00015_ca2_hero_progression_content.sql')
 if 'gxb_content_hero_exp_items' not in mig: errs.append('revision-bound Hero EXP item relation missing')
 if 'need_hero_num' not in mig: errs.append('Super prerequisite-count normalization missing')
 for bad in ['hero_capacity','capacity_limit','starter_hero']:
  if re.search(rf'\b{bad}\b',mig,re.I): errs.append(f'CA2-2 fabricates forbidden {bad}')
manifest=json.loads(read('internal/content/builtin/generated/manifest.json'))
if manifest.get('schema_version')!=1: errs.append('content schema version drifted from 1')
if manifest.get('compiler_version')!='ca2-2': errs.append('content compiler generation is not ca2-2')
for cap in ['HERO_CORE_CA2','HERO_PROGRESSION_CA2']:
 if cap not in manifest.get('enabled_capabilities',[]): errs.append(f'{cap} capability missing')
cat=json.loads(read('internal/content/builtin/generated/hero_core_catalog.json'))
if len(cat.get('exp_items',[])) != 5: errs.append('Hero EXP item catalog must contain exactly five source-qualified items')
main=read('cmd/gxb-api/main_postgres.go')
if '[]uint16{49, 52, 55, 63, 67, 89}' not in main: errs.append('production Hero route set is not exactly CA2-1 + CA2-2')
for mid in ['59','64','66','305']:
 if re.search(rf'\bmustRegister\({mid}\b|\[\]uint16\{{[^}}]*\b{mid}\b',main): errs.append(f'deferred/capacity-gated MID {mid} registered early')
disp=read('internal/adapters/stockruntime/hero_dispatcher.go')
for token in ['case 52:','case 55:','case 63:','case 67:']:
 if token not in disp: errs.append(f'Hero dispatcher missing {token}')
for token in (['case 64:','case 66:'] if CUMULATIVE else ['case 59:','case 64:','case 66:','case 305:']):
 if token in disp: errs.append(f'Hero dispatcher leaked deferred operation {token}')
app=read('internal/application/characterhero/progression.go')+'\n'+read('internal/application/characterhero/service.go')+'\n'+read('internal/application/i5/hero_progression.go')
for token in ['TxHeroProgressionDebiter','HeroProgressionActive','HeroProgressionRevision','pass516-ca2-2','receipt.New','DebitHeroExpItemsTx','DebitHeroEvolutionTx']:
 if token not in app: errs.append(f'CA2-2 application seam/evidence missing {token}')
if 'HERO_PROGRESSION_CA2' not in read('internal/adapters/postgres/contentstore/hero_progression.go'): errs.append('progression capability is not fail-closed in content adapter')
# Character adapters must never own I5 tables.
for p in [ROOT/'internal/adapters/postgres/characterstore/store.go', ROOT/'sql/character/hero.sql']:
 txt=p.read_text(errors='replace')
 for foreign in ['player_item_stacks','player_currency_balances','player_progression']:
  if foreign in txt: errs.append(f'foreign-owner SQL {foreign} found in {p.relative_to(ROOT)}')
# No speculative capacity/acquisition activation in Character progression code.
for bad in ['MID64','hero_slots_expand','capacity_limit','MID59','MID305']:
 if bad in app: errs.append(f'CA2-2 application contains deferred {bad}')
if errs:
 print('CA2-2 STATIC VALIDATION: FAIL'); [print(' -',e) for e in errs]; raise SystemExit(1)
print('CA2-2 STATIC VALIDATION: PASS' + (' (cumulative)' if CUMULATIVE else ''))
print('Hero EXP/base-star progression and MID67 projection are bounded to qualified source/content/I5 owner seams; capacity/acquisition/later mutations remain deferred')
