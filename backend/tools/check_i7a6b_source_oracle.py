#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,zipfile,sys
r=Path(__file__).resolve().parents[1];v=json.loads((r/'docs/i7a6b/SOURCE_IDENTITY.json').read_text());root=Path(sys.argv[1]);archives=[p for p in root.glob('all-assest-rechecked-1*.zip')if hashlib.file_digest(p.open('rb'),'sha256').hexdigest()==v['source_archive_sha256']];assert len(archives)==1
with zipfile.ZipFile(archives[0])as z:
 for e in v['excerpts']:
  b=z.read(v['source_prefix']+e['path']);assert hashlib.sha256(b).hexdigest()==e['sha256'];lines=b.decode('utf-8-sig').splitlines();assert '\n'.join(lines[e['line_start']-1:e['line_end']])==e['excerpt']
print('I7A6B SRC64: PASS',len(v['excerpts']),'exact source excerpts. Physical stock/Team callback gap remains W2; no original private server truth claimed.')
