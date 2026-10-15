#!/usr/bin/env python3
"""Check the exact current src_64 boundaries used for Spirit reconstruction."""
from pathlib import Path
import hashlib,json,sys,zipfile
B=Path(__file__).resolve().parents[1];root=Path(sys.argv[1]);manifest=json.loads((B/'docs/i7c2h/SOURCE_MANIFEST.json').read_text());archive=root/'all-assest-rechecked-1.zip';expected='c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'
assert hashlib.file_digest(archive.open('rb'),'sha256').hexdigest()==expected,'current source archive identity'
with zipfile.ZipFile(archive)as z:
 for row in manifest:
  names=[n for n in z.namelist()if n=='app-assets/output/assets/src_64/'+row['path']];assert len(names)==1,(row['path'],names)
  raw=z.read(names[0]);assert len(raw)==row['bytes']and hashlib.sha256(raw).hexdigest()==row['sha256'],row['path']
print('I7C2H EXACT SOURCE ORACLE: PASS',len(manifest),'current src_64 boundaries; reconstruction policy remains explicit')
