#!/usr/bin/env python3
from pathlib import Path
import sys
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

codec=need('internal/application/charactersavedpreset/command_codec.go','PetPresent','ParseFullCommand','ResolveLegacyDelete','ErrAmbiguousLegacyDelete','SavedPresetLanesEqual')
service=need('internal/application/charactersavedpreset/service.go','tx.Options{Isolation: tx.ReadCommitted}','RetryDefiniteAbort: true','FenceActorTx','CollectReferences','UnionReferences','.Covers(','MarkDefiniteAbort','character-saved-preset','pet_present','gxb.ca5.saved-preset-replace.v1')
if 'tx.Options{Isolation: tx.Serializable}' in service: errs.append('saved-preset mutation regressed to SERIALIZABLE despite explicit lock-closed foundation contract')
for bad in ['player_heroes','player_pets','DecisionAt','17.formation']:
    if bad in service: errs.append(f'service leaked {bad!r}')
dispatch=need('internal/adapters/stockruntime/saved_preset_dispatcher.go','req.Envelope.MID != 1793','team_str','team_name_str','pet_str','PetPresent','"save_team"','"save_team_name"','"save_pet"')
if 'error_code' in dispatch: errs.append('dispatcher invented preset-specific stock error_code')
main=need('cmd/gxb-api/main_postgres.go','SavedPresetDispatcher','mustRegister(1793, savedPresetD)','MutationService','ReferenceOwners{Heroes: heroDB, Pets: heroDB}')
for bad in ['mustRegister(208','mustRegister(209']:
    if bad in main: errs.append(f'unqualified MID registered: {bad}')
catalog=need('internal/foundation/replaycatalog/catalog.go','ca5.saved-preset-replace','CurrentStateConvergence','stock nonce absent','gxb.ca5.saved-preset-replace.v1')
proj=text('internal/adapters/postgres/characterstore/saved_preset_projection.go')
if '17.formation' in proj: errs.append('CA5-3 claimed 17.formation')
for p in (ROOT/'migrations').glob('00029_*'):
    errs.append(f'unauthorized CA5-3 migration {p.name}')
if errs:
    print('CA5-3 VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA5-3 VALIDATION: PASS')
print('MID1793 narrow activation, typed owner reuse, current-state replay classification and negative-scope boundaries present')
