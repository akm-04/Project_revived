#!/usr/bin/env python3
from pathlib import Path
import hashlib, json, re, sys
ROOT=Path(__file__).resolve().parents[1]
errs=[]
def text(rel):
    p=ROOT/rel
    if not p.exists(): errs.append(f'missing {rel}'); return ''
    return p.read_text(errors='replace')
def need(rel,*parts):
    s=text(rel)
    for part in parts:
        if part not in s: errs.append(f'{rel}: missing {part!r}')
    return s

mig=need('migrations/00028_ca5_2_saved_presets.sql','player_saved_preset_roots','player_saved_preset_lanes','player_saved_preset_heroes','player_saved_preset_lanes_pet_ref_idx','player_saved_preset_heroes_hero_ref_idx')
if '-- +goose Down' in mig: errs.append('00028 must be forward-only')
for bad in ['REFERENCES player_heroes','REFERENCES player_pets']:
    if bad in mig: errs.append(f'00028 cross-owner FK {bad}')
preset=need('sql/character/preset.sql','-- owner: character/saved-preset','ReadSavedPresetAggregate','LockSavedPresetRoot','DeleteSavedPresetLanes','SaveSavedPresetRootVersion')
for bad in ['player_heroes','player_pets']:
    if bad in preset: errs.append(f'preset.sql foreign-owner access {bad}')
need('internal/domain/character/saved_preset.go','type SavedPresetAggregate','type SavedPresetLane','strings.Contains(l.Name, "|||")')
need('internal/adapters/postgres/characterstore/saved_preset.go','ReplaceSavedPresetAggregateTx','EnsureSavedPresetRootTx','SavedPresetBootstrapContributor')
proj=need('internal/adapters/postgres/characterstore/saved_preset_projection.go','17.save_team','17.save_team_name','17.save_pet')
if '17.formation' in proj: errs.append('CA5-2 projection claimed 17.formation')
need('internal/application/charactersavedpreset/legacy_import.go','MapLegacy','ImportLegacyTx','UNRESOLVED_HERO','UNRESOLVED_PET','ErrImportConflict')
main=need('cmd/gxb-api/main_postgres.go','SavedPresetBootstrapContributor{}','SavedPresetBootstrapProjection{}')

boot=text('internal/adapters/postgres/i4store/bootstrap_runtime.go')
if boot.count('projectMID1Detail(') < 3 or 'hydrateCommittedMID1' not in boot:
    errs.append('MID1 committed reconciliation no longer rehydrates through current detail contributors')
qgen=need('internal/adapters/postgres/characterqueries/querytext_gen.go','PresetSourceSHA256','ReadSavedPresetAggregate')
expected=hashlib.sha256((ROOT/'sql/character/preset.sql').read_text().encode()).hexdigest()
m=re.search(r'const PresetSourceSHA256 = "([0-9a-f]{64})"',qgen)
if not m or m.group(1)!=expected: errs.append('generated preset query source hash stale')
own=json.loads(text('docs/architecture/CANONICAL_TABLE_OWNERSHIP.json') or '{}').get('tables',{})
for table in ['player_saved_preset_roots','player_saved_preset_lanes','player_saved_preset_heroes']:
    e=own.get(table,{})
    if e.get('owner')!='character/saved-preset' or e.get('migration')!='migrations/00028_ca5_2_saved_presets.sql': errs.append(f'{table}: ownership drift')
lock=json.loads(text('docs/architecture/CUMULATIVE_MIGRATION_LOCK.json') or '{}')
fn='00028_ca5_2_saved_presets.sql'; h=hashlib.sha256((ROOT/'migrations'/fn).read_bytes()).hexdigest()
if lock.get('highest_migration')!=fn or lock.get('migrations',{}).get(fn)!=h: errs.append('00028 cumulative migration lock drift')
stock=ROOT/'internal/adapters/stockruntime'
for p in stock.rglob('*.go'):
    s=p.read_text(errors='replace')
    for bad in ['case 208:','case 209:']:
        if bad in s: errs.append(f'{p.relative_to(ROOT)} activated {bad}')
# CA5-3 successor-qualifies only MID1793 and its saved-preset replay family.
# This validator continues to guard CA5-2 ownership/schema/projection boundaries
# and unqualified successor MIDs rather than pretending the cumulative tree is
# still frozen at the Pass562 activation surface.
if errs:
    print('CA5-2 VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA5-2 VALIDATION: PASS')
print('saved-preset owner/schema/query/bootstrap/MID1/import seams present; CA5-3 MID1793/replay successor qualification allowed; unqualified scopes remain inactive')
