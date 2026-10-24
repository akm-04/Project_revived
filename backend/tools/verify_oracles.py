#!/usr/bin/env python3
import argparse,hashlib,json,fnmatch
from pathlib import Path
p=argparse.ArgumentParser(); p.add_argument('--root',required=True); a=p.parse_args(); root=Path(a.root)
lock=json.loads((Path(__file__).resolve().parents[1]/'oracles.lock.json').read_text())
errs=[]
for o in lock['oracles']:
    matches=[]
    for pat in o['filename_patterns']: matches += [x for x in root.iterdir() if x.is_file() and fnmatch.fnmatch(x.name,pat)]
    good=[]
    for x in matches:
        h=hashlib.sha256()
        with x.open('rb') as f:
            for b in iter(lambda:f.read(1024*1024),b''): h.update(b)
        if h.hexdigest()==o['sha256']: good.append(x)
    if not good: errs.append(f"{o['id']}: no matching file with expected sha256")
    else: print(f"PASS {o['id']}: {good[0].name}")
if errs:
    print('ORACLE VERIFY: FAIL'); [print(' -',x) for x in errs]; raise SystemExit(1)
print('ORACLE VERIFY: PASS')
