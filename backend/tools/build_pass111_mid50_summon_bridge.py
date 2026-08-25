#!/usr/bin/env python3
"""Build Pass111 source-native MID50 operation-id OTA override from canonical Lua."""
from __future__ import annotations
import argparse, hashlib, json
from pathlib import Path

MARKER = "-- PASS111 PRESERVATION OTA MID50 OPERATION ID BRIDGE"
OLD = '''function var_0_0.summonHero(arg_137_0, arg_137_1, arg_137_2)\n\txyd.Backend.get():request(xyd.mid.SUMMON_HERO, arg_137_1, function(arg_138_0, arg_138_1, arg_138_2)'''
NEW = '''-- PASS111 PRESERVATION OTA MID50 OPERATION ID BRIDGE
function var_0_0.summonHero(arg_137_0, arg_137_1, arg_137_2)
\targ_137_1 = arg_137_1 or {}

\tif not arg_137_1.summon_op_id or arg_137_1.summon_op_id == "" then
\t\targ_137_1.summon_op_id = "mid50-" .. tostring(xyd.generateUUID())
\tend

\txyd.Backend.get():request(xyd.mid.SUMMON_HERO, arg_137_1, function(arg_138_0, arg_138_1, arg_138_2)'''

def sha(data: bytes) -> str: return hashlib.sha256(data).hexdigest()

def patch(raw: bytes) -> bytes:
    bom=raw.startswith(b"\xef\xbb\xbf")
    text=raw.decode('utf-8-sig')
    newline='\r\n' if '\r\n' in text else '\n'
    norm=text.replace('\r\n','\n')
    if MARKER in norm: raise RuntimeError('canonical SelfPlayer.lua already contains Pass111 marker')
    count=norm.count(OLD)
    if count != 1: raise RuntimeError(f'MID50 choke point exact match count={count} sha={sha(raw)}')
    out=norm.replace(OLD,NEW,1)
    if newline=='\r\n': out=out.replace('\n','\r\n')
    data=out.encode('utf-8')
    return (b"\xef\xbb\xbf"+data) if bom else data

def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument('asset_root',type=Path)
    ap.add_argument('--local-assets',type=Path,default=Path('local_assets'))
    ap.add_argument('--report',type=Path,default=Path('docs/PASS111_OTA_BRIDGE_BUILD.json'))
    args=ap.parse_args()
    prior={}
    for p in sorted(args.local_assets.rglob('*')):
        if p.is_file() and ('/src_32/' in '/' + p.as_posix() or '/src_64/' in '/' + p.as_posix()):
            prior[p.relative_to(args.local_assets).as_posix()] = sha(p.read_bytes())
    rows=[]; patched=[]
    for arch in ('src_32','src_64'):
        src=args.asset_root/arch/'app/model/SelfPlayer.lua'
        raw=src.read_bytes(); out=patch(raw)
        dst=args.local_assets/arch/'app/model/SelfPlayer.lua'
        dst.parent.mkdir(parents=True,exist_ok=True); dst.write_bytes(out)
        rows.append({'arch':arch,'source':f'{arch}/app/model/SelfPlayer.lua','source_sha256':sha(raw),'override':f'{arch}/app/model/SelfPlayer.lua','override_sha256':sha(out),'source_size':len(raw),'override_size':len(out)})
        patched.append(out)
    if patched[0] != patched[1]: raise RuntimeError('src_32/src_64 Pass111 overrides drifted')
    # Every pre-Pass111 sparse override must remain byte-identical.
    for rel, digest in prior.items():
        cur=args.local_assets/rel
        if not cur.is_file() or sha(cur.read_bytes()) != digest:
            raise RuntimeError(f'Pass111 altered prior OTA override: {rel}')
    report={
      'schema_version':1,'pass':'111.0','status':'GENERATED_FROM_CANONICAL_SOURCE',
      'bridge':'MID50 source-native per-click UUID operation identity',
      'operation_id_formula':'mid50-{xyd.generateUUID()}',
      'injection_rule':'create only when params.summon_op_id is nil/empty; never overwrite an existing identity',
      'retry_invariant':'Backend.lua pendingRequests stores the same params table and reuses it on retry.',
      'source_choke_point':'app/model/SelfPlayer.lua::summonHero()',
      'prior_override_count':len(prior),'prior_override_hashes':prior,'files':rows,
    }
    args.report.parent.mkdir(parents=True,exist_ok=True)
    args.report.write_text(json.dumps(report,indent=2,sort_keys=True)+'\n',encoding='utf-8')
    print(json.dumps(report,indent=2))
    return 0
if __name__=='__main__': raise SystemExit(main())
