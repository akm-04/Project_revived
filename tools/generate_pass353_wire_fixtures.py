#!/usr/bin/env python3
import argparse, fnmatch, hashlib, importlib.util, json, tempfile, zipfile, sys
from pathlib import Path

def sha(path):
    h=hashlib.sha256()
    with open(path,'rb') as f:
        for b in iter(lambda:f.read(1<<20),b''):h.update(b)
    return h.hexdigest()

def locate(root, patterns, expected):
    for p in sorted(Path(root).iterdir()):
        if p.is_file() and any(fnmatch.fnmatch(p.name,pat) for pat in patterns) and sha(p)==expected:
            return p
    raise SystemExit('verified Pass353 oracle not found')

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--root',default='/mnt/data'); ap.add_argument('--check',action='store_true'); a=ap.parse_args()
    repo=Path(__file__).resolve().parents[1]; lock=json.loads((repo/'oracles.lock.json').read_text()); o=next(x for x in lock['oracles'] if x['id']=='v1_pass353'); z=locate(a.root,o['filename_patterns'],o['sha256'])
    with zipfile.ZipFile(z) as zz: src=zz.read('gxb_backend/realtime/codec.py')
    with tempfile.TemporaryDirectory() as td:
        p=Path(td)/'codec.py'; p.write_bytes(src); spec=importlib.util.spec_from_file_location('pass353_codec',p); m=importlib.util.module_from_spec(spec); sys.modules[spec.name]=m; spec.loader.exec_module(m)
        enc=m.RealtimeFrameEncoder()
        cases=[
          ('tcp_login',32771,0,{'token':'local_token','region':194.0,'room_id':194.0}),
          ('chat_room_entered',32779,0,{'room_id':194.0}),
          ('heartbeat',32797,0,{}),
          ('string_reference_object',32797,7,{'left':'repeat','right':'repeat'}),
          ('array_payload',32797,9,{'items':[1.0,'x',True,None]}),
        ]
        fixtures=[]
        for name,mid,seq,params in cases:
            frame=enc.encode(mid,params,sequence=seq)
            decoded=m.RealtimeFrameStreamDecoder().feed(frame)
            if len(decoded)!=1: raise SystemExit('Pass353 oracle failed self decode')
            fixtures.append({'name':name,'mid':mid,'sequence':seq,'params':params,'frame_hex':frame.hex()})
    out={'schema_version':1,'pass':'435.0','stage':'I2','oracle':'Pass353 realtime/codec.py','oracle_archive_sha256':o['sha256'],'fixtures':fixtures}
    text=json.dumps(out,indent=2,sort_keys=False)+'\n'; target=repo/'testdata/wire/pass435_pass353_realtime_differential.json'
    if a.check:
        if not target.exists() or target.read_text()!=text: raise SystemExit('Pass353 differential fixture drift')
        print(f'PASS353 WIRE FIXTURES: PASS cases={len(fixtures)}')
    else:
        target.parent.mkdir(parents=True,exist_ok=True);target.write_text(text);print(f'wrote {target}')
if __name__=='__main__': main()
