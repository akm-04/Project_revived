#!/usr/bin/env python3
from pathlib import Path
import hashlib,re,sys
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

dto=need('internal/application/characterasset/saved_preset_reference_state.go','type SavedPresetReferenceState','StateVersion int64','type SavedPresetReferenceLoadout','[]character.HeroRef','*character.PetRef','func (s SavedPresetReferenceState) Clone()')
for bad in ['Name string','Formation','BattleStat','SelectedPreset']:
    if bad in dto: errs.append(f'reference DTO leaked {bad!r}')
reader=need('internal/application/charactersavedpreset/reference_state.go','ReferenceStateStore','SavedPresetReferenceStateTx','ReadSavedPresetAggregateTx','StateVersion: agg.Root.StateVersion')
for bad in ['lane.Name','17.formation','DecisionAt']:
    if bad in reader: errs.append(f'reference-state reader leaked {bad!r}')
guard=need('internal/application/charactersavedpreset/reference_guard.go','SavedPresetReferenceGuardProviderID = "ca5.saved-presets"','PreflightHeroRemovalTx','PreflightPetRemovalTx','SavedPresetRootLockKey','LockReferenceGuardKeyTx','SavedPresetReferencesHeroTx','SavedPresetReferencesPetTx','ErrReferenceInUse')
for bad in ['player_heroes','player_pets','DELETE FROM','Detach','RemoveHero','RemovePet']:
    if bad in guard: errs.append(f'reference guard leaked {bad!r}')
preset=need('sql/character/preset.sql','-- owner: character/saved-preset','SavedPresetReferencesHero','SavedPresetReferencesPet','SELECT EXISTS')
for bad in ['player_heroes','player_pets']:
    if bad in preset: errs.append(f'preset SQL foreign-owner access {bad}')
store=need('internal/adapters/postgres/characterstore/saved_preset.go','SavedPresetReferencesHeroTx','SavedPresetReferencesPetTx','characterqueries.SavedPresetReferencesHero','characterqueries.SavedPresetReferencesPet')
qgen=need('internal/adapters/postgres/characterqueries/querytext_gen.go','PresetSourceSHA256','SavedPresetReferencesHero','SavedPresetReferencesPet')
expected=hashlib.sha256((ROOT/'sql/character/preset.sql').read_text().encode()).hexdigest()
m=re.search(r'const PresetSourceSHA256 = "([0-9a-f]{64})"',qgen)
if not m or m.group(1)!=expected: errs.append('generated preset query source hash stale')
for p in (ROOT/'migrations').glob('00029_*'): errs.append(f'unauthorized CA5-4 migration {p.name}')
stock=ROOT/'internal/adapters/stockruntime'
for p in stock.rglob('*.go'):
    s=p.read_text(errors='replace')
    for bad in ['case 66:','case 208:','case 209:']:
        if bad in s: errs.append(f'{p.relative_to(ROOT)} activated {bad}')
main=text('cmd/gxb-api/main_postgres.go')
for bad in ['mustRegister(66','mustRegister(208','mustRegister(209']:
    if bad in main: errs.append(f'production registered {bad}')
proj=text('internal/adapters/postgres/characterstore/saved_preset_projection.go')
if '17.formation' in proj: errs.append('CA5-4 claimed 17.formation')
for rel in ['sql/character/hero.sql','sql/character/pet.sql']:
    s=text(rel)
    for bad in ['DELETE FROM player_heroes','DELETE FROM player_pets']:
        if bad in s: errs.append(f'{rel}: destructive source-owner SQL {bad}')
if errs:
    print('CA5-4 VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA5-4 VALIDATION: PASS')
print('revisioned saved-reference DTO/read, rank440 reverse guard provider and indexed existence seams present; destructive/formation/mode scopes remain inactive')
