#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
from content_generation_policy import registered_pair_successor
import fnmatch, hashlib, json, sys, zipfile

ROOT = Path(__file__).resolve().parents[1]
OROOT = Path(sys.argv[1] if len(sys.argv) > 1 else '/mnt/data')
LOCK = json.loads((ROOT / 'oracles.lock.json').read_text())
errs: list[str] = []

def sha(p: Path) -> str:
    h = hashlib.sha256()
    with p.open('rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()

def locate(oid: str) -> Path:
    entry = next(x for x in LOCK['oracles'] if x['id'] == oid)
    for p in sorted(OROOT.iterdir()):
        if p.is_file() and any(fnmatch.fnmatch(p.name, pat) for pat in entry['filename_patterns']) and sha(p) == entry['sha256']:
            return p
    raise SystemExit(f'{oid}: verified oracle unavailable')

def text(z: zipfile.ZipFile, rel: str) -> str:
    return z.read('app-assets/output/assets/src_64/' + rel).decode('utf-8-sig', 'replace')

cur = locate('current_src64')
with zipfile.ZipFile(cur) as z:
    mid = text(z, 'app/common/network/mid.lua')
    pet = text(z, 'app/model/Pet.lua')
    add = text(z, 'app/windows/PetAddExpWindow.lua')
    main = text(z, 'app/windows/PetMainWindow.lua')
    enums = text(z, 'app/common/enums.lua')
    misc = text(z, 'app/common/tables/MiscTable.lua')
    checks = [
        ('MID786 identity', 'xyd.mid.PET_EVOLVE = 786' in mid),
        ('MID787 identity', 'xyd.mid.PET_FEED = 787' in mid),
        ('MID791 identity', 'xyd.mid.PET_UPGRADE_ALL_SKILL = 791' in mid),
        ('MID134 identity', 'xyd.mid.PET_USE_EXP_ITEMS = 134' in mid),
        ('evolve request is pet_id', 'pet_id = arg_82_0:getPetID()' in pet and 'request(var_0_2.mid.PET_EVOLVE' in pet),
        ('evolve source cost is next-star fragment table', 'StarLevelSuipian[arg_82_0:getStar() + 1]' in pet),
        ('feed uses caller payload item_id/item_num', 'request(var_0_2.mid.PET_FEED, arg_84_1' in pet and 'itemID = arg_84_1.item_id' in pet and 'itemNum = arg_84_1.item_num' in pet),
        ('skill wire vectors', 'skill_colors = var_100_0' in pet and 'skill_counts = var_100_1' in pet and 'PET_UPGRADE_ALL_SKILL' in pet),
        ('skill book source', 'itemID = var_0_2.tables.misc.skillBookItem' in pet and 'arg_6_0.skillBookItem = tonumber(var_6_1)' in misc),
        ('five projected skills', 'var_5_0.skills = var_5_1' in pet and 'PET_SKILL_EXTRA' in pet),
        ('three Pet ration ids', all(x in add for x in ('50001087','50001088','50001089'))),
        ('one-key rejects already max level', 'if var_20_0:getLevel() >= arg_20_0.maxLev then' in add),
        ('one-key target derives max-level total exp', 'xyd.tables.petExp:totalExp(arg_20_0.maxLev - 1)' in add),
        ('evolve UI uses same next-star cost', 'StarLevelSuipian[var_111_0:getStar() + 1]' in main),
        ('five stock skill indices exist', all(f'xyd.SKILL_INDEX.{x} =' in enums for x in ('Energy','Green','Blue','Purple','Awake'))),
    ]
    for label, ok in checks:
        if not ok:
            errs.append(label)

manifest = json.loads((ROOT / 'internal/content/builtin/generated/manifest.json').read_text())
compiler_parser=(manifest.get('compiler_version'), manifest.get('parser_version'))
if not registered_pair_successor(ROOT, compiler_parser[0], compiler_parser[1], 'ca3-3'):
    errs.append(f'CA3-3 cumulative compiler/parser identity drift: {compiler_parser!r}')
if manifest.get('source_archive_sha256') != sha(cur):
    errs.append('generated manifest source archive hash does not match exact current src_64')
if 'PET_PROGRESSION_CA3' not in manifest.get('enabled_capabilities', []):
    errs.append('PET_PROGRESSION_CA3 capability absent')
source_map = {x.get('path'): x.get('sha256') for x in manifest.get('sources', [])}
source_pins = {
    'app/model/Pet.lua': '214f4dcd93d0e494408d14a225810134c2e72a0dedd18a935a27dc62e0c00660',
    'data/tables/pet.lua': 'bc974045ec92fd7c0ebb2655d635d1b057eee7f74a871cfa2316b511ad55986e',
    'app/common/tables/PetExpTable.lua': '20bb5d6badb0245cdacaddc03db12625367f53262d667ffc3f5fafb27c6421f6',
    'data/tables/pet_exp.lua': '7ebc02c3ce25cd9048c516d958caa4277d04bfa289a71b14cfb6f2d9bfe9eb4f',
    'app/common/tables/PetSkillBookTable.lua': '1f80042a1e7855903a8ef0a3687722e809770f5b70a6a3630bc4449ba99d9903',
    'data/tables/pet_skillbook.lua': '708798a4e36f1cab67e6d96fbaae9df86fece9059ef2c367770a8ef0c22aa4e6',
    'data/tables/pet_star.lua': '6d64e726dea9e11456977c268870eb4a2b5646d4a725d2dcdb58310104b6f445',
    'app/common/tables/SkillTable.lua': '0184d2ea9bc63a93438f1f0029e4703e8979afd2101959d5a567f1859bd9befc',
    'data/tables/skill.lua': '7a2123ac10cb7f1ac0cd4da3fa8d3a076d1042cbc01e44c218ab4ea0b77ba45a',
    'app/windows/PetMainWindow.lua': 'fcebe7e4fa742d8a176c8da10502c410e5031720023369bebed01c7da3a99832',
    'app/windows/PetAddExpWindow.lua': '1b2a56e20ff47a9c94245a5d84466c13428815342f29d2959286e3fd549fb5a3',
}
for path, want in source_pins.items():
    if source_map.get(path) != want:
        errs.append(f'source pin drift {path}: {source_map.get(path)!r}')

diag = manifest.get('diagnostics', {})
for key, want in {'pet_progression_templates':54, 'pet_progression_skill_slots':270, 'pet_exp_rows':100, 'pet_skill_book_rows':130}.items():
    if diag.get(key) != want:
        errs.append(f'{key} diagnostic drift: {diag.get(key)!r}')

cat = json.loads((ROOT / 'internal/content/builtin/generated/pet_progression_catalog.json').read_text())
if len(cat.get('templates', [])) != 54 or len(cat.get('skill_slots', [])) != 270:
    errs.append('Pet progression template/skill-slot cardinality drift')
if len(cat.get('exp_rows', [])) != 100 or len(cat.get('skill_books', [])) != 130:
    errs.append('Pet EXP/skill-book cardinality drift')
if {(x['target_star'], x['stone_count']) for x in cat.get('evolution_rows', [])} != {(2,20),(3,50),(4,100),(5,150)}:
    errs.append('Pet evolution source costs drift')
if {x['item_id'] for x in cat.get('exp_items', [])} != {50001087,50001088,50001089}:
    errs.append('Pet EXP item identity drift')
slot_policy = {x['slot']:(x['effective_offset'],x['min_color'],x['requires_awakened']) for x in cat.get('slot_policy', [])}
if slot_policy != {1:(0,1,False),2:(0,2,False),3:(20,4,False),4:(40,7,False),5:(60,0,True)}:
    errs.append(f'Pet skill slot policy drift: {slot_policy}')
if int(cat.get('policy', {}).get('skill_book_item_id', 0)) != 50001090:
    errs.append('Pet skill book item identity drift')

if errs:
    print('CA3-3 SOURCE ORACLE CHECK: FAIL')
    for e in errs: print(' -', e)
    raise SystemExit(1)
print('CA3-3 SOURCE ORACLE CHECK: PASS')
print(f'exact current src_64 {sha(cur)} corroborates Pet progression MIDs, stock wire shapes, evolution/EXP/skill progression sources, and checked-in generated content pins')
