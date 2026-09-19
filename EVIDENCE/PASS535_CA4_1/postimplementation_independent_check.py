from __future__ import annotations
from pathlib import Path
import hashlib, json, re, subprocess, sys
ROOT=Path('/mnt/data/ca4_1_impl/backend_src')
BASE=Path('/mnt/data/ca4_1_impl/baseline_0671')
CONTRACT=Path('/mnt/data/gxb_ca4_pass534/hot/00_PASSMAP/PASS534_CA4_1_IMPLEMENTATION_CONTRACT.json')
MATRIX=Path('/mnt/data/gxb_ca4_pass534/hot/00_PASSMAP/PASS534_CA4_1_ACCEPTANCE_MATRIX.json')
SRC=Path('/mnt/data/all-assest-rechecked-1.zip')
errs=[]; checks=[]
def ck(ok,msg):
    checks.append((ok,msg))
    if not ok: errs.append(msg)
def sha(p):
    h=hashlib.sha256();
    with p.open('rb') as f:
        for b in iter(lambda:f.read(1<<20),b''): h.update(b)
    return h.hexdigest()
ck(CONTRACT.is_file(),'Pass534 implementation contract present')
ck(MATRIX.is_file(),'Pass534 acceptance matrix present')
ck(SRC.is_file() and sha(SRC)=='c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf','exact current src_64 archive hash')
ck((ROOT/'go.mod').read_text().find('go 1.26.0')>=0 and 'toolchain go1.27.1' in (ROOT/'go.mod').read_text() and (ROOT/'.go-version').read_text().strip()=='1.27.1','canonical Go/toolchain pins pristine')
# Changed path census.
proc=subprocess.run(['diff','-qr',str(BASE),str(ROOT)],text=True,capture_output=True)
lines=[x for x in proc.stdout.splitlines() if x.strip() and '__pycache__' not in x and not x.endswith('.pyc')]
allowed_prefixes=(
 'docs/architecture/CANONICAL_TABLE_OWNERSHIP.json','docs/architecture/CUMULATIVE_MIGRATION_LOCK.json',
 'internal/adapters/postgres/contentqueries/querytext_gen.go','internal/adapters/postgres/contentstore/',
 'internal/application/characterasset','internal/application/characterasset/','internal/application/i5/grant_lock_plan.go','internal/application/i5/material_cost.go',
 'internal/application/i5/material_exchange.go','internal/application/i5/material_exchange_test.go','internal/archguard/ca4_1_contract_test.go',
 'internal/content/builtin/','internal/content/registry/','internal/domain/character/equipment.go','internal/domain/character/equipment_test.go',
 'migrations/00019_ca4_equipment_primitives.sql','sql/content/content.sql','tools/check.sh','tools/check_ca3_3_source_oracle.py',
 'tools/check_ca4_1_source_oracle.py','tools/generate_builtin_content.py','tools/validate_ca3_3.py','tools/validate_ca4_1.py','tools/validate_r5.py'
)
def rel_from_diff(line):
    # "Files BASE/x and ROOT/x differ"
    if line.startswith('Files '):
        right=line.split(' and ',1)[1]
        if right.endswith(' differ'): right=right[:-7]
        return str(Path(right).relative_to(ROOT))
    # "Only in ROOT/dir: name"
    m=re.match(r'Only in (.*): (.*)$',line)
    if m:
        d=Path(m.group(1)); name=m.group(2)
        if str(d).startswith(str(ROOT)):
            return str((d/name).relative_to(ROOT))
        if str(d).startswith(str(BASE)):
            return str((d/name).relative_to(BASE))
    return line
rels=[rel_from_diff(x) for x in lines]
bad=[r for r in rels if not any(r==p or (p.endswith('/') and r.startswith(p)) for p in allowed_prefixes)]
ck(not bad,f'implementation delta limited to authorized CA4-1 surface bad={bad}')
# Migration ownership.
mig=(ROOT/'migrations/00019_ca4_equipment_primitives.sql').read_text()
ck('gxb_content_equipment_primitives' in mig and 'gxb_content_equipment_recipe_edges' in mig,'migration 00019 adds equipment content relations')
ck(not re.search(r'(?i)create\s+table\s+(?!if\s+not\s+exists\s+)?(?:gxb_)?(?:hero|pet|super|equipment_items|player_equipment)',mig),'migration 00019 creates no mutable Character equipment owner')
# Universal-owner/command leakage.
prod='\n'.join(p.read_text(errors='ignore') for p in ROOT.rglob('*.go') if '/vendor/' not in str(p) and not p.name.endswith('_test.go'))
ck('type Equipment struct' not in prod and 'equipment_items' not in prod,'no universal Equipment aggregate/table in product code')
ca=(ROOT/'internal/application/characterasset/contracts.go').read_text()
dom=(ROOT/'internal/domain/character/equipment.go').read_text()
for tok in ['HeroEquipmentSlotRef','PetEquipmentSlotRef','SuperEquipmentSlotRef','SpiritRef']:
    ck(tok in dom,f'character domain shared contract contains {tok}')
for tok in ['PlayerProgressionMaxHeroColorProvider','RestorationModifier']:
    ck(tok in ca,f'character application shared contract contains {tok}')
ck(not re.search(r'(?i)(create|upgrade|lock|unlock|destroy).*spirit|horcrux',ca),'borrowed Spirit boundary only')
# Combined exchange contract.
ex=(ROOT/'internal/application/i5/material_exchange.go').read_text()
for tok in ['PrepareMaterialExchangeTx','ApplyMaterialExchangeTx','canonicalGrantLockRequirements','ErrMaterialExchangeResourceCollision','ErrMaterialExchangeGrantAlreadySettled','preflightGrantTx','prepareMaterialDebitStateTx']:
    ck(tok in ex,f'I5 exchange contains {tok}')
ck('Begin(' not in ex and '.Commit(' not in ex and '.Rollback(' not in ex,'combined exchange does not own transaction lifecycle')
# Source topology artifact.
cat=json.loads((ROOT/'internal/content/builtin/generated/equipment_primitives_catalog.json').read_text())
ck(len(cat.get('root_item_ids',[]))==604,'equipment roots=604')
ck(len(cat.get('items',[]))==1176,'equipment closure=1176')
ck(len(cat.get('recipe_edges',[]))==1934,'ordered recipe edges=1934')
# Source oracle itself must independently pass.
r=subprocess.run([sys.executable,str(ROOT/'tools/check_ca4_1_source_oracle.py'),'/mnt/data'],cwd=ROOT,text=True,capture_output=True)
ck(r.returncode==0,'CA4-1 exact source oracle passes')
# Future MID activation forbidden by stage guard/source delta. We inspect new Character package and exchange only.
newtext='\n'.join((ROOT/p).read_text(errors='ignore') for p in [Path('internal/application/characterasset/contracts.go'),Path('internal/application/i5/material_exchange.go')])
for mid in ['54','62','58','51','57','783','792','785','790','304']:
    ck(not re.search(rf'(?<!\d){mid}(?!\d)',newtext),f'CA4-1 shared implementation does not activate MID{mid}')
# Final compatibility evidence summaries.
for fn,needle in [
 ('W4D_FINAL_FOCUSED_TESTS.log','ok  \tgxb.local/backend/v2/internal/archguard'),
 ('W4D_FOCUSED_RACE.log','ok  \tgxb.local/backend/v2/internal/archguard'),
 ('W4D_BOUNDED_REGRESSION.log','SUMMARY packages=92 failures=0'),
 ('W4D_BOUNDED_VET.log','SUMMARY packages=92 failures=0'),
 ('W4_CANONICAL_FINAL_VALIDATORS.log','CONNECTED CANDIDATE STATIC PRESEAL: PASS')]:
    p=Path('/mnt/data/ca4_1_impl/evidence')/fn
    ck(p.is_file() and needle in p.read_text(errors='ignore'),f'evidence {fn} contains expected GREEN marker')
print(f'CA4-1 POSTIMPLEMENTATION INDEPENDENT CHECK: {"PASS" if not errs else "FAIL"} ({sum(x for x,_ in checks)}/{len(checks)})')
for ok,msg in checks: print(('PASS ' if ok else 'FAIL ')+msg)
if errs: sys.exit(1)
