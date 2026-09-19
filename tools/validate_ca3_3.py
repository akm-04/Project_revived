#!/usr/bin/env python3
from __future__ import annotations
import argparse, hashlib, json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ap=argparse.ArgumentParser()
ap.add_argument('--cumulative', action='store_true', help='retain CA3-3 semantics while permitting qualified later content/migrations')
args=ap.parse_args()
errs: list[str] = []

def read(rel: str) -> str:
    p=ROOT/rel
    if not p.exists():
        errs.append(f'missing {rel}'); return ''
    return p.read_text()

def need(rel: str, *tokens: str) -> str:
    s=read(rel)
    for tok in tokens:
        if tok not in s: errs.append(f'{rel}: missing {tok!r}')
    return s

manifest=json.loads(read('internal/content/builtin/generated/manifest.json') or '{}')
compiler_parser=(manifest.get('compiler_version'),manifest.get('parser_version'))
allowed={('ca3-3','lua-generated-v5-pet-progression')}
if args.cumulative:
    allowed.update({('ca4-1','lua-generated-v6-equipment-primitives'), ('ca4-2a','lua-generated-v7-hero-equipment'), ('ca4-4a-i1','lua-generated-v10-pet-equipment'), ('ca4-4b-i1','lua-generated-v11-pet-restoration'), ('ca4-5-i1','lua-generated-v12-super-equipment'), ('ca6-2-practice-foundation','lua-generated-v13-practice')})
if compiler_parser not in allowed:
    errs.append(f'CA3-3 compiler/parser identity drift {compiler_parser!r}')
for cap in ('PET_CORE_CA3','PET_ACQUISITION_CA3','PET_PROGRESSION_CA3'):
    if cap not in manifest.get('enabled_capabilities',[]): errs.append(f'missing content capability {cap}')
diag=manifest.get('diagnostics',{})
for key,want in {'pet_progression_templates':54,'pet_progression_skill_slots':270,'pet_exp_rows':100,'pet_skill_book_rows':130}.items():
    if diag.get(key)!=want: errs.append(f'{key} drift {diag.get(key)!r}')

mig=need('migrations/00018_ca3_pet_progression.sql','skill_1 bigint NOT NULL DEFAULT 1 CHECK (skill_1 >= 1)','skill_5 bigint NOT NULL DEFAULT 1 CHECK (skill_5 >= 1)','gxb_content_pet_progression','gxb_content_pet_skill_slots','gxb_content_pet_exp','gxb_content_pet_exp_items','gxb_content_pet_skill_books','gxb_content_pet_skill_slot_policy','gxb_content_pet_evolution','gxb_content_pet_progression_policy')
if 'DROP COLUMN' in mig.upper(): errs.append('00018 contains destructive contraction')
pet=need('internal/domain/character/pet.go','type PetSkillLevels [5]int64','DefaultPetSkillLevels')
_ = pet
charstore=need('internal/adapters/postgres/characterstore/pet.go','p.Skills[0]','p.Skills[4]','SavePetProgressionTx')
_ = charstore
if args.cumulative:
    need('sql/character/pet.sql','SavePetState','skill_1','skill_5','state_version')
else:
    need('sql/character/pet.sql','SavePetProgression','skill_1','skill_5','state_version')

contentq=need('sql/content/content.sql','InsertContentPetProgression','ReadPetProgression','expected_pet_progression','stored_pet_progression','expected_pet_skill_slots','stored_pet_skill_slots','expected_pet_exp','stored_pet_exp','expected_pet_skill_books','stored_pet_skill_books')
_ = contentq
need('internal/adapters/postgres/contentstore/pet_progression.go','PetProgressionActive','PetExpItemTx','PetExpPolicyTx','PetSkillBookCostTx')
need('internal/content/registry/types.go','"PET_PROGRESSION_CA3"','PetProgressionCount')

prog=need('internal/application/characterpet/progression.go','progressionReceiptReplayTx','LockPetByIDTx','PreparePetExpDebitTx','ApplyPetExpDebitTx','PetSkillSlotPolicyTx')
if args.cumulative:
    if 'SavePetStateTx' not in prog: errs.append("internal/application/characterpet/progression.go: missing 'SavePetStateTx' cumulative cohesive CAS")
else:
    if 'SavePetProgressionTx' not in prog: errs.append("internal/application/characterpet/progression.go: missing 'SavePetProgressionTx'")
# Three mutation families each need pre-lock and post-lock transaction receipt fences.
if prog.count('progressionReceiptReplayTx(') < 7: # helper definition + >=6 calls
    errs.append('progression mutation receipt fence count too small')
pos_lock=prog.find('pet, found, err := s.Store.LockPetByIDTx')
if pos_lock < 0: errs.append('typed Pet lock/found contract missing from progression service')
if prog.count('pet, found, err := s.Store.LockPetByIDTx') < 3 or prog.count('if !found {') < 3:
    errs.append('progression Pet lock does not separate missing rows from infrastructure errors')
# EXP source lookup must occur after a lock in the useExp function.
use=prog[prog.find('func (s Service) useExp'):prog.find('func (s Service) UpgradeSkills')]
if use:
    if use.find('LockPetByIDTx') < 0 or use.find('PetExpItemTx') < 0 or use.find('LockPetByIDTx') > use.find('PetExpItemTx'):
        errs.append('EXP item content is not resolved after Pet lock')

need('internal/application/i5/pet_progression.go','PreparePetExpDebitTx','ApplyPetExpDebitTx','PetExpDebitPlan','PlayerLevel')
disp=need('internal/adapters/stockruntime/pet_dispatcher.go','case 786:','case 787:','case 134:','case 791:','requiredPetInt64','CurrentScalar(ctx, actor.PlayerID, "crystal"')
if not args.cumulative:
    for bad in ('case 783:','case 784:','case 785:','case 788:','case 790:','case 792:'):
        if bad in disp: errs.append(f'CA3-3 unexpectedly implements deferred {bad}')
    main=need('cmd/gxb-api/main_postgres.go','[]uint16{134, 780, 781, 782, 786, 787, 789, 791}')
else:
    main=need('cmd/gxb-api/main_postgres.go','petD := stockruntime.PetDispatcher','mustRegister(mid, petD)')
    import re
    m=re.search(r'(?s)for _, mid := range \[\]uint16\{([^}]*)\} \{\s*mustRegister\(mid, petD\)', main)
    if not m: errs.append('cumulative Pet production registration block missing')
    else:
        for mid in (134,780,781,782,786,787,789,791):
            if re.search(rf'(^|\D){mid}(\D|$)',m.group(1)) is None: errs.append(f'cumulative Pet registration lost CA3-3 MID {mid}')
_ = main

# Shared CA3 timing/revision repairs that CA3-3 must preserve.
for rel,toks in {
    'internal/application/characterpet/acquisition.go':('DecisionAt()','CreationContentRevision','StartedAt'),
    'internal/application/characterpet/hatch.go':('DecisionAt()','CreationContentRevision'),
}.items(): need(rel,*toks)
hatch=read('internal/application/characterpet/hatch.go')
if hatch.count('pet, found, err := s.Store.LockPetByIDTx') < 2 or hatch.count('if !found {') < 2:
    errs.append('timed Pet lock does not separate missing rows from infrastructure errors')

own=json.loads(read('docs/architecture/CANONICAL_TABLE_OWNERSHIP.json') or '{}')
for table in ('gxb_content_pet_progression','gxb_content_pet_skill_slots','gxb_content_pet_exp','gxb_content_pet_exp_items','gxb_content_pet_skill_books','gxb_content_pet_skill_slot_policy','gxb_content_pet_evolution','gxb_content_pet_progression_policy'):
    row=own.get('tables',{}).get(table)
    if not row or row.get('owner')!='content-registry' or row.get('migration')!='migrations/00018_ca3_pet_progression.sql': errs.append(f'ownership drift for {table}')
lock=json.loads(read('docs/architecture/CUMULATIVE_MIGRATION_LOCK.json') or '{}')
p=ROOT/'migrations/00018_ca3_pet_progression.sql'; want=hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else ''
if lock.get('migrations',{}).get(p.name)!=want:
    errs.append('migration lock does not seal 00018 exact bytes')
if not args.cumulative and lock.get('highest_migration')!=p.name:
    errs.append('historical CA3-3 migration high-water is not 00018')
if args.cumulative and str(lock.get('highest_migration','')) < p.name:
    errs.append('cumulative migration high-water predates 00018')

# Focused regression tests must exist for the contract-specific repairs.
need('internal/application/characterpet/progression_test.go','TestProgressionMutationsRecheckReceiptAfterPetLock','TestFeedLocksPetBeforeResolvingRationContent')
need('internal/application/i5/pet_progression_test.go','PreparePetExpDebitTx','ApplyPetExpDebitTx')
need('internal/adapters/stockruntime/pet_dispatcher_test.go','TestPetProgressionRejectsStringTypedIntegers','TestPetDispatcherAcceptsStockEnvelopeMetadataButRejectsUnknownGameplayField')

if errs:
    print('CA3-3 VALIDATION: FAIL')
    for e in errs: print(' -',e)
    raise SystemExit(1)
print('CA3-3 VALIDATION: PASS')
print('Pet progression persistence/content/I5/service/strict-wire/timing seams and contract-specific regression guards are present; live aggregate acceptance remains separate')
