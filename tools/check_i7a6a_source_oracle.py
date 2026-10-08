#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,zipfile,sys
b=Path(__file__).resolve().parents[1];d=json.loads((b/'docs/i7a6a/SOURCE_IDENTITY.json').read_text());root=Path(sys.argv[1]);matches=[p for p in root.glob('all-assest-rechecked-1*.zip') if hashlib.file_digest(p.open('rb'),'sha256').hexdigest()==d['source_archive_sha256']];assert matches,'exact source archive missing'
with zipfile.ZipFile(matches[0])as z:
 for row in d['source_files']:
  raw=z.read(d['source_prefix']+row['path']);assert hashlib.sha256(raw).hexdigest()==row['sha256'],row['path'];lines=raw.decode('utf-8-sig').splitlines()
  for anchor in row['anchors']:assert anchor['anchor'] in lines[anchor['line']-1],(row['path'],anchor)
print('I7A6A SOURCE ORACLE: PASS',len(d['source_files']),'selected src_64 files and exact anchors; static source fact, physical W2 deferred')
