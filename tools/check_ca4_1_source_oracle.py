#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
import base64, csv, fnmatch, hashlib, io, json, re, subprocess, sys, zipfile

ROOT = Path(__file__).resolve().parents[1]
OROOT = Path(sys.argv[1] if len(sys.argv) > 1 else '/mnt/data')
LOCK = json.loads((ROOT / 'oracles.lock.json').read_text())
ERRS: list[str] = []

def sha(p: Path) -> str:
    h=hashlib.sha256()
    with p.open('rb') as f:
        for b in iter(lambda:f.read(1<<20),b''): h.update(b)
    return h.hexdigest()

def locate(oid: str) -> Path:
    entry=next(x for x in LOCK['oracles'] if x['id']==oid)
    for p in sorted(OROOT.iterdir()):
        if p.is_file() and any(fnmatch.fnmatch(p.name,pat) for pat in entry['filename_patterns']) and sha(p)==entry['sha256']:
            return p
    raise SystemExit(f'{oid}: verified oracle unavailable')

def parse_encoded_tsv(raw: bytes) -> dict[int,dict[str,str]]:
    text=raw.decode('utf-8-sig','replace')
    m=re.fullmatch(r'\s*return\s+"([A-Za-z0-9+/=\r\n]+)"\s*', text, re.S)
    if not m: raise ValueError('item.lua is not expected encoded table wrapper')
    decoded=base64.b64decode(m.group(1)).decode('utf-8-sig','replace')
    rd=csv.reader(io.StringIO(decoded), delimiter='\t')
    next(rd)  # localized/human header
    keys=next(rd)
    out={}
    for row in rd:
        if not row or not row[0]: continue
        if len(row)<len(keys): row += ['']*(len(keys)-len(row))
        rec=dict(zip(keys,row))
        try: iid=int(float(rec['id']))
        except Exception: continue
        out[iid]=rec
    return out

def iv(v, default=0):
    try:return int(float(v or default))
    except Exception:return default

def seq(v):
    return [int(x) for x in str(v or '').split('|') if x and x not in ('0','-1')]

def fail(msg): ERRS.append(msg)

cur=locate('current_src64')
with zipfile.ZipFile(cur) as z:
    item_path='app-assets/output/assets/src_64/data/tables/item.lua'
    raw=z.read(item_path)
    item_sha=hashlib.sha256(raw).hexdigest()
    if item_sha!='59b668c28a372543da0c36d7a8d84291cc5b93fa0d92b7cc389a645e96e7b7cc': fail(f'authoritative item.lua hash drift {item_sha}')
    items=parse_encoded_tsv(raw)

roots={i for i,r in items.items() if iv(r.get('type')) in (1,8)}
if len(roots)!=604: fail(f'equipment root count {len(roots)} != 604')
edges={}
for iid,r in items.items():
    comps=seq(r.get('compose'))
    counts=seq(r.get('compose_num'))
    if comps:
        if len(comps)!=len(counts): fail(f'compose/count length mismatch item {iid}'); continue
        edges[iid]=list(zip(comps,counts))
closure=set(); stack=list(roots); visiting=set()
def visit(n:int):
    if n in closure:return
    if n in visiting: fail(f'recipe cycle at {n}'); return
    if n not in items: fail(f'missing recipe item {n}'); return
    visiting.add(n)
    for c,_ in edges.get(n,[]): visit(c)
    visiting.remove(n); closure.add(n)
for n in roots: visit(n)
recipe_nodes=sum(1 for n in closure if n in edges)
edge_count=sum(len(edges[n]) for n in closure if n in edges)
repeated=sum(1 for n in closure if n in edges and len({c for c,_ in edges[n]})<len(edges[n]))
for got,want,label in [(len(closure),1176,'closure'),(recipe_nodes,797,'recipe_nodes'),(edge_count,1934,'recipe_edges'),(repeated,29,'repeated_component_recipes')]:
    if got!=want: fail(f'{label} {got} != {want}')

manifest=json.loads((ROOT/'internal/content/builtin/generated/manifest.json').read_text())
if manifest.get('source_archive_sha256')!=sha(cur): fail('generated manifest source archive hash drift')
compiler_parser=(manifest.get('compiler_version'),manifest.get('parser_version'))
if compiler_parser not in {('ca4-2a','lua-generated-v7-hero-equipment'), ('ca4-4a-i1','lua-generated-v10-pet-equipment'), ('ca4-4b-i1','lua-generated-v11-pet-restoration'), ('ca4-5-i1','lua-generated-v12-super-equipment'), ('ca6-2-practice-foundation','lua-generated-v13-practice')}: fail(f'compiler/parser successor drift {compiler_parser!r}')
if 'EQUIPMENT_PRIMITIVES_CA4' not in manifest.get('enabled_capabilities',[]): fail('EQUIPMENT_PRIMITIVES_CA4 capability absent')
diag=manifest.get('diagnostics',{})
for key,want in {'equipment_roots':604,'equipment_closure_items':1176,'equipment_recipe_nodes':797,'equipment_recipe_edges':1934,'equipment_repeated_component_recipes':29}.items():
    if diag.get(key)!=want: fail(f'manifest diagnostic {key}={diag.get(key)!r} want {want}')
source_map={x.get('path'):x.get('sha256') for x in manifest.get('sources',[])}
if source_map.get('data/tables/item.lua')!=item_sha: fail('manifest item.lua source pin drift')

cat=json.loads((ROOT/'internal/content/builtin/generated/equipment_primitives_catalog.json').read_text())
if set(cat.get('root_item_ids',[]))!=roots: fail('generated equipment root set differs from direct source')
cat_items={int(x['item_id']):x for x in cat.get('items',[])}
if set(cat_items)!=closure: fail('generated equipment closure differs from direct source')
cat_edges=[(int(x['parent_item_id']),int(x['ordinal']),int(x['component_item_id']),int(x['component_count'])) for x in cat.get('recipe_edges',[])]
direct_edges=[]
for parent in sorted(closure):
    for ordinal,(component,count) in enumerate(edges.get(parent,[]), start=1):
        direct_edges.append((parent,ordinal,component,count))
if cat_edges!=direct_edges: fail('generated ordered recipe edges differ from direct source')
for iid,row in cat_items.items():
    src=items[iid]
    if int(row['source_item_type'])!=iv(src.get('type')) or int(row['required_level'])!=iv(src.get('level')) or int(row['compose_mana'])!=iv(src.get('compose_mana')):
        fail(f'primitive field drift for item {iid}'); break
resources=json.loads((ROOT/'internal/content/builtin/generated/resource_catalog.json').read_text()).get('resources',[])
qualified={int(r['item_id']) for r in resources if r.get('class')=='STACK_ITEM' and r.get('catalog_status')=='QUALIFIED' and r.get('settlement_activation')=='ENABLED_R4' and r.get('item_id') is not None}
missing=sorted(closure-qualified)
if missing: fail(f'{len(missing)} equipment closure items not I5-qualified, first={missing[:10]}')

# Regenerate/check all immutable artifacts from exact source bytes. This is kept
# as a second path so a hand-edited checked-in catalog cannot satisfy only the
# structural assertions above.
r=subprocess.run([sys.executable,str(ROOT/'tools/generate_builtin_content.py'),'--source-archive',str(cur),'--check'],cwd=ROOT)
if r.returncode!=0: fail('exact-source immutable content regeneration check failed')

if ERRS:
    print('CA4-1 SOURCE ORACLE CHECK: FAIL')
    for e in ERRS: print(' -',e)
    raise SystemExit(1)
print('CA4-1 SOURCE ORACLE CHECK: PASS')
print(f'exact current src_64 {sha(cur)} -> roots=604 closure=1176 recipe_nodes=797 ordered_edges=1934 repeated_recipes=29; generated CA4-1 catalog is byte-regenerable and all closure items remain I5-qualified')
