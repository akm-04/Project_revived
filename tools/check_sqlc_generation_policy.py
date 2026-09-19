#!/usr/bin/env python3
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
text=(root/'sqlc.yaml').read_text()
errs=[]
for out in ('../gxb-v2-sqlc-generated/kerneldb','../gxb-v2-sqlc-generated/i3db','../gxb-v2-sqlc-generated/i5db','../gxb-v2-sqlc-generated/contentdb','../gxb-v2-sqlc-generated/characterdb'):
    if f'out: "{out}"' not in text:
        errs.append(f'missing external build-artifact output {out}')
for bad in ('internal/adapters/postgres/kerneldb','internal/adapters/postgres/i3db','internal/adapters/postgres/i5db','internal/adapters/postgres/contentdb','internal/adapters/postgres/characterdb'):
    if (root/bad).exists(): errs.append(f'generated package leaked into sealed source tree: {bad}')
if any(f'queries: "{q}"' not in text for q in ('sql/kernel','sql/i3','sql/i5','sql/content','sql/character')):
    errs.append('owner-scoped sqlc inputs missing')

# sqlc v1.31.1 can analyze jsonb_to_recordset column definitions when the
# verification CTE projects the record as a whole, but it does not reliably
# resolve those synthetic output-column names in an explicit SELECT list.
# Keep pure pass-through verification rows as SELECT *; computed rows must use
# jsonb_array_elements + explicit typed extraction instead. This guard is scoped
# to VerifyContentRevision so insert/load SQL is not unnecessarily constrained.
content_sql = (root/'sql/content/content.sql').read_text()
marker = '-- name: VerifyContentRevision :one'
if marker not in content_sql:
    errs.append('content VerifyContentRevision query missing')
else:
    verify_sql = content_sql.split(marker, 1)[1]
    lines = verify_sql.splitlines()
    for i, line in enumerate(lines):
        needle = 'FROM jsonb_to_recordset'
        if needle not in line:
            continue

        # The SELECT may be on the same line (``SELECT * FROM ...``) or the
        # immediately preceding non-blank line (``SELECT *`` / ``FROM ...``).
        # Deliberately do not use a cross-CTE regex: it can bind an earlier
        # SELECT to a later recordset and create false positives.
        prefix = line.split(needle, 1)[0].strip()
        if prefix.startswith('SELECT '):
            projection = prefix[len('SELECT '):].strip()
        else:
            j = i - 1
            while j >= 0 and not lines[j].strip():
                j -= 1
            prev = lines[j].strip() if j >= 0 else ''
            projection = prev[len('SELECT '):].strip() if prev.startswith('SELECT ') else ''

        if projection != '*':
            lineno = i + 1
            errs.append(
                'jsonb_to_recordset verification projection must be SELECT * '
                f'for sqlc v1.31.1 compatibility (VerifyContentRevision relative line {lineno}); '
                f'got: {projection[:120] or "<unrecognized projection>"}'
            )
if errs:
    print('SQLC GENERATION POLICY: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('SQLC GENERATION POLICY: PASS')
