#!/usr/bin/env python3
"""CA2-1 static scope/ownership guard."""
from pathlib import Path
import json,re,sys
CUMULATIVE="--cumulative" in sys.argv[1:]
ROOT=Path(__file__).resolve().parents[1]
errs=[]

def read(p): return (ROOT/p).read_text(errors='replace')
if not (ROOT/'migrations/00014_ca2_hero_foundation.sql').exists(): errs.append('migration 00014 missing')
mig=read('migrations/00014_ca2_hero_foundation.sql')
for bad in ['max_hero','hero_capacity','capacity_limit','starter_hero']:
    if re.search(rf'\b{bad}\b',mig,re.I): errs.append(f'migration fabricates forbidden {bad}')
for required in ['player_hero_roots','player_heroes','gxb_content_hero_templates']:
    if required not in mig: errs.append(f'migration missing {required}')
if 'gxb_content_hero_acquisition_items' in mig: errs.append('migration duplicates existing resource partner_id acquisition mapping')
if re.search(r'\bskill_levels\b|\bhero_kind\b', mig): errs.append('player Hero persistence contains deferred/derived fields')
if not re.search(r'star\s+smallint\s+NOT NULL CHECK \(star BETWEEN 1 AND 8\)', mig): errs.append('player Hero star ceiling is not sealed 1..8')
if 'REFERENCES player_hero_roots(player_id) ON DELETE CASCADE' not in mig: errs.append('player_heroes does not depend on Hero root owner')
hero=read('internal/domain/character/hero.go')
for name,val in [('HeroRootLockRank','400'),('HeroInstanceLockRank','410'),('MaxSortType','8191')]:
    if not re.search(rf'\b{name}\s*=\s*{val}\b', hero): errs.append(f'Hero contract missing {name}={val}')
main=read('cmd/gxb-api/main_postgres.go')
if not CUMULATIVE and '[]uint16{49, 89}' not in main: errs.append('production Hero route set is not exactly CA2-1 MID49/MID89')
if CUMULATIVE and '[]uint16{49, 52, 55, 63, 67, 89}' not in main: errs.append('cumulative Hero route set does not preserve CA2-1 plus qualified CA2-2 routes')
for mid in (['59','305','64','66'] if CUMULATIVE else ['52','55','59','63','67','305','64','66']):
    if re.search(rf'\bmustRegister\({mid}\b|\[\]uint16\{{[^}}]*\b{mid}\b', main): errs.append(f'deferred MID {mid} registered early')
if 'PartnerEntities:' in main: errs.append('CA2-3 PartnerEntity provider activated during CA2-1')
disp=read('internal/adapters/stockruntime/hero_dispatcher.go')
for token in ['case 49:', 'case 89:']:
    if token not in disp: errs.append(f'Hero dispatcher missing {token}')
for token in ([] if CUMULATIVE else ['case 52:','case 55:','case 59:','case 63:','case 67:','case 305:']):
    if token in disp: errs.append(f'Hero dispatcher leaked deferred operation {token}')
proj=read('internal/projection/hero/stock.go')
if 'out["partner_type"] = int64(2)' not in proj: errs.append('Super MID49 partner_type=2 missing')
if '"spirit_item":' in proj: errs.append('spirit_item must be omitted')
for shape in ['"equips"','"fumos"','"skills"','"skill_ids"','"practice_attr"']:
    if shape not in proj: errs.append(f'projection missing source-safe shape {shape}')
if 'h.SkillLevels' in proj: errs.append('MID49 projection reads deferred persisted skill state')
if not re.search(r'skills\s*:=\s*\[\]any\{(?:int64\(1\),?\s*){6}\}', proj): errs.append('MID49 skills are not fixed neutral six ones')
if (ROOT/'internal/adapters/postgres/characterstore/bootstrap_projection.go').exists(): errs.append('CA2 illegally contributes Hero roster to MID1 detail')
if 'characterstore.BootstrapProjection' in main: errs.append('production MID1 wires forbidden CA2 Hero projection contributor')
content_sql=read('sql/content/content.sql')
if 'FROM gxb_content_resource_definitions' not in content_sql or 'partner_id AS origin_table_id' not in content_sql:
    errs.append('Hero acquisition verification does not reuse resource_definitions.partner_id')
manifest=json.loads((ROOT/'internal/content/builtin/generated/manifest.json').read_text())
if manifest.get('schema_version')!=1: errs.append('content schema version drifted from 1')
if 'HERO_CORE_CA2' not in manifest.get('enabled_capabilities',[]): errs.append('HERO_CORE_CA2 capability missing')
hero_cat=json.loads((ROOT/'internal/content/builtin/generated/hero_core_catalog.json').read_text())
counts=(len(hero_cat['templates']),len(hero_cat['exp_rows']),len(hero_cat['normal_star_rows']),len(hero_cat['super_star_rows']),len(hero_cat['super_prerequisites']),len(hero_cat['acquisition_items']))
if counts!=(568,100,5,10,70,291): errs.append(f'Hero catalog count drift {counts}')
# Durable one-family invariant and no second materialization ledger.
if 'UNIQUE(player_id, origin_table_id)' not in mig: errs.append('origin-family uniqueness missing')
for p in (ROOT/'migrations').glob('*.sql'):
    if re.search(r'hero_.*materiali[sz]ation|materiali[sz]ation_.*hero',p.read_text(errors='replace'),re.I): errs.append(f'duplicate Hero materialization ledger in {p.name}')
if errs:
    print('CA2-1 STATIC VALIDATION: FAIL'); [print(' -',e) for e in errs]; sys.exit(1)
print('CA2-1 STATIC VALIDATION: PASS' + (' (cumulative)' if CUMULATIVE else ''))
print('CA2-1 foundation/projection invariants preserved' + (' while later-stage diagnostic handlers may exist without production activation' if CUMULATIVE else '; progression/acquisition/later owners remain deferred'))
