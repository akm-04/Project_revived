#!/usr/bin/env python3
from __future__ import annotations
import json, sys
from pathlib import Path
from content_generation_policy import load_lock, current_identity_is_latest, registered_compiler_successor, registered_pair_successor
ROOT=Path(__file__).resolve().parents[1]
errs=[]
try:
    data=load_lock(ROOT)
    rows=data.get("generations") or []
    if [r.get("ordinal") for r in rows] != list(range(1,len(rows)+1)): errs.append("non-contiguous generation ordinals")
    if len({r.get("compiler_version") for r in rows}) != len(rows): errs.append("duplicate compiler generation")
    man=json.loads((ROOT/"internal/content/builtin/generated/manifest.json").read_text())
    compiler=man.get("compiler_version"); parser=man.get("parser_version")
    if not current_identity_is_latest(ROOT,compiler,parser):
        errs.append(f"current manifest identity {(compiler,parser)!r} is not the latest registered cumulative generation")
    if not registered_compiler_successor(ROOT,compiler,"r5-1"):
        errs.append("latest compiler is not a registered successor of R5")
    if not registered_pair_successor(ROOT,compiler,parser,"ca3-3"):
        errs.append("latest compiler/parser is not a registered successor of CA3-3")
    if registered_compiler_successor(ROOT,"future-unregistered","r5-1"):
        errs.append("unregistered future compiler was accepted")
    if registered_pair_successor(ROOT,compiler,"wrong-parser","ca3-3"):
        errs.append("mismatched parser was accepted")
except Exception as exc:
    errs.append(str(exc))
if errs:
    print("CUMULATIVE CONTENT GENERATION POLICY: FAIL")
    [print(" -",e) for e in errs]
    raise SystemExit(1)
print("CUMULATIVE CONTENT GENERATION POLICY: PASS")
