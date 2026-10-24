#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,sys
R=Path(__file__).resolve().parents[1]
errs=[]
def req(x,msg):
    if not x: errs.append(msg)

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

oracle=R/'testdata/sourcefacts/pass542_ca4_3a_fumo_oracle.json'
want='42c10c67be67278d83e81512403b0b3318d30ae9f957e878dbc1c9ee0596dbd0'
req(oracle.is_file(),'sealed Pass542 Fumo source oracle missing')
if oracle.is_file():
    req(sha(oracle)==want,f'sealed Fumo source oracle hash drift: {sha(oracle)}')
    o=json.loads(oracle.read_text())
else:
    o={}
generated=json.loads((R/'internal/content/builtin/generated/hero_fumo_catalog.json').read_text())
source_targets=o.get('hero_target_policy',{}).get('targets',[])
projected=[]
for t in source_targets:
    projected.append({
        'attr_ids':t['attr_ids'],
        'item_id':t['item_id'],
        'mana_per_fumo':t['mana_per_fumo'],
        'stage_delta_by_attr':t['stage_delta_by_attr'],
        'threshold_increments':t['threshold_increments'],
        'total_cap':t['total_cap'],
    })
req(generated.get('targets')==projected,'generated Fumo targets differ from sealed source oracle projection')
materials=o.get('hero_material_policy',{}).get('eligible_materials',[])
req(generated.get('materials')==materials,'generated Hero Fumo materials differ from sealed source oracle')
req(len(projected)==359,f'target count drift: {len(projected)}')
req(len(materials)==516,f'material count drift: {len(materials)}')
# Preserve source-backed sparse/fractional semantics explicitly.
sparse=sum(1 for t in projected for stage in t['stage_delta_by_attr'] if len(stage)<len(t['attr_ids']))
frac=sum(1 for t in projected for stage in t['stage_delta_by_attr'] for v in stage.values() if '.' in str(v))
req(sparse==40,f'sparse reachable stage-row drift: {sparse}')
req(frac==14,f'fractional reachable value drift: {frac}')
if errs:
    print('CA4-3A SOURCE ORACLE CHECK: FAIL')
    [print(' -',e) for e in errs]
    sys.exit(1)
print('CA4-3A SOURCE ORACLE CHECK: PASS')
print('sealed Pass542 current-source oracle -> 359 target policies / 516 Hero-Fumo materials; generated catalog preserves sparse exact-decimal source deltas')
