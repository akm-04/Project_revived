#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path

LOCK_REL = Path("docs/architecture/CUMULATIVE_CONTENT_GENERATION_LOCK.json")

def load_lock(root: Path) -> dict:
    return json.loads((root / LOCK_REL).read_text())

def _rows(root: Path) -> list[dict]:
    rows = list(load_lock(root).get("generations") or [])
    ords=[r.get("ordinal") for r in rows]
    if ords != list(range(1,len(rows)+1)):
        raise ValueError("content generation ordinals are not contiguous from 1")
    comps=[r.get("compiler_version") for r in rows]
    if len(comps) != len(set(comps)):
        raise ValueError("duplicate compiler_version in cumulative content generation lock")
    pairs=[(r.get("compiler_version"),r.get("parser_version")) for r in rows if r.get("parser_version") is not None]
    if len(pairs) != len(set(pairs)):
        raise ValueError("duplicate compiler/parser pair in cumulative content generation lock")
    return rows

def registered_compiler_successor(root: Path, compiler: str | None, floor_compiler: str) -> bool:
    rows=_rows(root); idx={r["compiler_version"]:r["ordinal"] for r in rows}
    return compiler in idx and floor_compiler in idx and idx[compiler] >= idx[floor_compiler]

def registered_pair_successor(root: Path, compiler: str | None, parser: str | None, floor_compiler: str) -> bool:
    rows=_rows(root); idx={r["compiler_version"]:r for r in rows}
    cur=idx.get(compiler); floor=idx.get(floor_compiler)
    return bool(cur and floor and cur.get("parser_version")==parser and cur["ordinal"] >= floor["ordinal"])

def current_identity_is_latest(root: Path, compiler: str | None, parser: str | None) -> bool:
    data=load_lock(root); rows=_rows(root)
    if not rows: return False
    latest=rows[-1]
    declared=data.get("current") or {}
    return (compiler,parser)==(latest.get("compiler_version"),latest.get("parser_version")) == (declared.get("compiler_version"),declared.get("parser_version"))
