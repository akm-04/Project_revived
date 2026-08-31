"""Stock-client lazy resource state helpers for bulk writable bootstraps.

Pass298 scope
=============
The current v1.631.0 client initializes ``lazyFile.json`` before MID2. A later
loud BULK_RESOURCE_BOOTSTRAP can therefore place exact files into the writable
``res/...`` tree while stale ``__lazy__...`` keys continue to tell
``AssetDownload`` that those resources are absent. Current v1.631.0 no longer
performs the historical v1.164 local-alias MD5 reconciliation in
``AssetDownload.insertToStack``.

For a bulk baseline only, rebuild the stock-owned ``lazyFile.json`` from the
same authoritative version catalog used by the asset collector:
- force=1 rows are never lazy markers;
- exact-current rows supplied by the bulk ZIP have no marker;
- force=0 rows not supplied exactly retain the normal stock marker/value shape.

This is intentionally distinct from CATALOG_MIGRATION. Catalog overlays still
rely on UpdateScene's stock changed-MD5 merge semantics and must not use this
helper as a generic replacement for client state.
"""
from __future__ import annotations

import json
from typing import Any, Iterable

LAZY_PREFIX = "__lazy__"


def lazy_key(path: str) -> str:
    normalized = str(path or "").replace("\\", "/").strip("/")
    if not normalized:
        raise ValueError("lazy path is empty")
    return LAZY_PREFIX + "___".join(normalized.split("/"))


def lazy_value(row: dict[str, Any]) -> str:
    """Encode the same JSON-string value shape written by UpdateScene.lua."""
    path = str(row.get("path") or "").replace("\\", "/")
    md5 = str(row.get("md5") or "").lower()
    payload: dict[str, Any] = {
        "size": int(row.get("size") or 0),
        "md5": md5,
        "path": path,
    }
    # Lua omits nil table members before cjson.encode; preserve that behavior.
    if row.get("version") is not None:
        payload["version"] = row.get("version")
    return json.dumps(payload, ensure_ascii=False, separators=(",", ":"))


def build_lazy_map(
    rows: Iterable[dict[str, Any]],
    supplied_catalog_paths: Iterable[str],
) -> tuple[dict[str, str], dict[str, Any]]:
    supplied = {str(p).replace("\\", "/") for p in supplied_catalog_paths}
    out: dict[str, str] = {}
    considered = 0
    supplied_lazy = 0
    retained = 0
    for row in rows:
        if not isinstance(row, dict) or int(row.get("force") or 0) == 1:
            continue
        path = str(row.get("path") or "").replace("\\", "/")
        if not path:
            continue
        considered += 1
        if path in supplied:
            supplied_lazy += 1
            continue
        out[lazy_key(path)] = lazy_value(row)
        retained += 1
    summary = {
        "catalog_lazy_considered": considered,
        "supplied_exact_lazy_paths": supplied_lazy,
        "retained_lazy_markers": retained,
        "marker_prefix": LAZY_PREFIX,
        "state_file": "lazyFile.json",
        "state_semantics": "post-bulk writable baseline; omit exact supplied force=0 rows, retain unsupplied force=0 rows",
    }
    if supplied_lazy + retained != considered:
        raise ValueError("lazy-state accounting mismatch")
    return out, summary


def validate_lazy_map(
    lazy_map: dict[str, Any],
    rows: Iterable[dict[str, Any]],
    supplied_catalog_paths: Iterable[str],
) -> dict[str, Any]:
    expected, summary = build_lazy_map(rows, supplied_catalog_paths)
    if lazy_map != expected:
        missing = sorted(set(expected) - set(lazy_map))[:20]
        extra = sorted(set(lazy_map) - set(expected))[:20]
        changed = sorted(k for k in set(expected) & set(lazy_map) if expected[k] != lazy_map[k])[:20]
        raise ValueError(
            "lazyFile.json differs from stock-compatible bulk projection "
            f"missing={missing} extra={extra} changed={changed}"
        )
    return summary
