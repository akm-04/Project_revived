#!/usr/bin/env python3
import argparse,json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
LOCK=ROOT/'DEPENDENCIES.lock.json'; OUT=ROOT/'SBOM.spdx.json'
def build():
    lock=json.loads(LOCK.read_text()); mods=lock.get('resolved_go_modules',[])
    gomod=(ROOT/'go.mod').read_text()
    requires=dict(re.findall(r'^\s*([^\s()]+)\s+(v[^\s]+)(?:\s+// indirect)?$', gomod, re.M))
    locked={x['module']:x['version'] for x in mods}
    if requires != locked: raise SystemExit(f'RESOLVED SBOM: FAIL module lock mismatch go.mod={requires!r} lock={locked!r}')
    packages=[{'SPDXID':'SPDXRef-GXB','name':'gxb-backend-v2','versionInfo':json.loads((ROOT/'BUILD_INFO.json').read_text())['version'],'downloadLocation':'NOASSERTION','licenseConcluded':'NOASSERTION','licenseDeclared':'NOASSERTION','supplier':'NOASSERTION','filesAnalyzed':False,'primaryPackagePurpose':'APPLICATION'}]
    rels=[]
    for i,m in enumerate(mods,1):
        sid=f'SPDXRef-GoModule-{i}'
        packages.append({'SPDXID':sid,'name':m['module'],'versionInfo':m['version'],'downloadLocation':f'https://{m["module"]}','licenseConcluded':m['license'],'licenseDeclared':m['license'],'supplier':'NOASSERTION','filesAnalyzed':False,'primaryPackagePurpose':'LIBRARY'})
        rels.append({'spdxElementId':'SPDXRef-GXB','relationshipType':'DEPENDS_ON','relatedSpdxElement':sid})
    resolved_names={m['module'] for m in mods}; idx=len(packages)
    for dep in lock['dependencies']:
        if dep.get('module') in resolved_names: continue
        idx+=1; sid=f'SPDXRef-Qualified-{idx}'
        packages.append({'SPDXID':sid,'name':dep['name'],'versionInfo':dep['version'],'downloadLocation':'NOASSERTION','licenseConcluded':dep['license'],'licenseDeclared':dep['license'],'supplier':'NOASSERTION','filesAnalyzed':False})
    build=json.loads((ROOT/'BUILD_INFO.json').read_text())
    created=build.get('sbom_created_at','2026-09-10T13:13:00Z')
    return {'spdxVersion':'SPDX-2.3','dataLicense':'CC0-1.0','SPDXID':'SPDXRef-DOCUMENT','name':'gxb-backend-v2-resolved','documentNamespace':'https://local.invalid/gxb/backend/v2/resolved','creationInfo':{'created':created,'creators':['Tool: GXB-V2-resolved-SBOM-generator']},'packages':packages,'relationships':rels,'annotations':[{'annotationType':'OTHER','annotator':'Tool: GXB-V2-resolved-SBOM-generator','annotationDate':created,'comment':'Resolved runtime Go module closure is generated from the current BUILD_INFO version and DEPENDENCIES.lock.json; qualified non-linked tooling/services remain separately classified.'}]}
def rendered(): return json.dumps(build(),indent=2,ensure_ascii=False)+'\n'
def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--check',action='store_true'); a=ap.parse_args(); want=rendered()
    if a.check:
        if not OUT.exists() or OUT.read_text()!=want: raise SystemExit('RESOLVED SBOM: FAIL (regenerate tools/generate_resolved_sbom.py)')
        print('RESOLVED SBOM: PASS'); return
    OUT.write_text(want); print(OUT)
if __name__=='__main__': main()
