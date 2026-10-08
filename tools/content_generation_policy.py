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

def qualified_social_gift_scalar_delta(root: Path, payload: dict) -> bool:
    """Narrow successor proof: all5556 historical rows remain byte identical."""
    import hashlib
    qualification=json.loads((root/"docs/i7a7a/CONTENT_SCALAR_DELTA_QUALIFICATION.json").read_text())
    manifest=json.loads((root/"internal/content/builtin/generated/manifest.json").read_text())
    if manifest.get("compiler_version")!="i7a7a-social-gift" or manifest.get("parser_version")!="lua-generated-v16-social-gift":return False
    if not current_identity_is_latest(root,manifest["compiler_version"],manifest["parser_version"]):return False
    expected={"catalog_status":"QUALIFIED","class":"SCALAR_CURRENCY","definition_key":"scalar_currency:friendship_coin","resource_key":"friendship_coin","settlement_activation":"ENABLED_R4"}
    rows=payload.get("resources",[])
    extra=[r for r in rows if r.get("definition_key")==expected["definition_key"]]
    if extra!=[expected] or qualification.get("exact_new_row")!=expected or len(rows)!=5557:return False
    reduced=dict(payload);reduced["resources"]=[r for r in rows if r.get("definition_key")!=expected["definition_key"]]
    data=(json.dumps(reduced,ensure_ascii=False,sort_keys=True,separators=(",",":"))+"\n").encode()
    if len(reduced["resources"])!=5556 or hashlib.sha256(data).hexdigest()!=qualification.get("old_catalog_sha256"):return False
    raw=(root/"internal/content/builtin/generated/resource_catalog.json").read_bytes()
    gift=(root/"internal/content/builtin/generated/social_gift_catalog.json").read_bytes()
    if hashlib.sha256(raw).hexdigest()!=qualification.get("new_catalog_sha256") or hashlib.sha256(gift).hexdigest()!=qualification.get("gift_catalog_sha256"):return False
    return "SOCIAL_GIFT_I7A7A" in manifest.get("enabled_capabilities",[]) and qualification.get("old_count")==5556 and qualification.get("new_count")==5557
