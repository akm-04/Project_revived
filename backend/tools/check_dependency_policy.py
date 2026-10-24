#!/usr/bin/env python3
import json,re,sys
from pathlib import Path
R=Path(__file__).resolve().parents[1]; d=json.loads((R/'DEPENDENCIES.lock.json').read_text()); errs=[]
required={'github.com/jackc/pgx/v5','github.com/sqlc-dev/sqlc','github.com/pressly/goose/v3','github.com/riverqueue/river','github.com/go-chi/chi/v5','github.com/testcontainers/testcontainers-go','go.opentelemetry.io/otel','github.com/prometheus/client_golang'}
mods={x.get('module') for x in d['dependencies']}
if not required<=mods: errs.append('required dependency candidates missing')
for x in d['dependencies']:
    if x['kind'] not in {'toolchain','service'} and not re.match(r'^v\d+\.\d+\.\d+',x['version']): errs.append(f"unpinned semver: {x['name']} {x['version']}")
    if not x.get('license'): errs.append('missing license: '+x['name'])
river=next(x for x in d['dependencies'] if x['name']=='River')
if river['license']!='MPL-2.0' or river['version']!='v0.47.0': errs.append('River v0.47.0/MPL-2.0 qualification drift')
amf=next(x for x in d['dependencies'] if x['name']=='goAMF3')
if amf['status']!='NOT_RUNTIME_APPROVED': errs.append('goAMF3 promoted without differential proof')
# Reproducible Go closure: exact require set must equal resolved_go_modules.
gomod=(R/'go.mod').read_text(); req=dict(re.findall(r'^\s*([^\s()]+)\s+(v[^\s]+)(?:\s+// indirect)?$',gomod,re.M))
resolved=d.get('resolved_go_modules',[]); locked={x['module']:x['version'] for x in resolved}
if req!=locked: errs.append(f'go.mod/resolved module lock mismatch: {req!r} != {locked!r}')
if not (R/'go.sum').exists() or len((R/'go.sum').read_text().splitlines()) < 40: errs.append('go.sum content closure missing/truncated')
for x in resolved:
    if not x.get('license'): errs.append('resolved module missing license: '+x['module'])
# Stale notice/version text is a release failure.
for path in ('THIRD_PARTY_NOTICES.md','docs/I0_DEPENDENCY_REVIEW.md'):
    txt=(R/path).read_text()
    if 'River v0.45.0' in txt: errs.append(f'stale River v0.45.0 notice in {path}')
    if 'River v0.47.0' not in txt and 'river v0.47.0' not in txt: errs.append(f'River v0.47.0 not documented in {path}')
if errs:
    print('DEPENDENCY POLICY: FAIL'); [print(' -',x) for x in errs]; sys.exit(1)
print('DEPENDENCY POLICY: PASS')
print('resolved_go_modules',len(resolved),'qualified_candidates',sum(x['status']=='QUALIFIED_CANDIDATE' for x in d['dependencies']))
