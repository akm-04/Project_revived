#!/usr/bin/env python3
"""Build compact read-only protocol label metadata from the canonical Pass34 MID atlas.

This tool is observability-only. It must never be used to decide compatibility,
mutation safety, payload shape, reward ownership, or gameplay semantics.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path


def canonical_label(row: dict) -> str:
    symbols = [str(v) for v in row.get("symbols") or [] if str(v)]
    if symbols:
        return "/".join(symbols)
    backend_symbols = [str(v) for v in row.get("backend_symbols") or [] if str(v)]
    if backend_symbols:
        return "/".join(backend_symbols)
    gm = row.get("gm_operation") if isinstance(row.get("gm_operation"), dict) else None
    aliases = [str(v) for v in (gm or {}).get("aliases") or [] if str(v)]
    if aliases:
        return "GM:" + "/".join(aliases)
    return f"UNKNOWN_{int(row.get('mid', 0))}"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--atlas", required=True, type=Path, help="Pass34/Pass35 00_PASSMAP/MID_LOOKUP_INDEX.json")
    ap.add_argument("--out", required=True, type=Path)
    args = ap.parse_args()

    atlas = json.loads(args.atlas.read_text(encoding="utf-8"))
    if not isinstance(atlas, dict):
        raise SystemExit("atlas root must be an object keyed by numeric MID")

    records: dict[str, dict] = {}
    for key in sorted(atlas, key=lambda value: int(value)):
        row = atlas[key]
        if not isinstance(row, dict):
            continue
        mid = int(row.get("mid", key))
        gm = row.get("gm_operation") if isinstance(row.get("gm_operation"), dict) else {}
        records[str(mid)] = {
            "mid": mid,
            "label": canonical_label(row),
            "plane": str(row.get("plane") or "unknown"),
            "symbols": [str(v) for v in row.get("symbols") or []],
            "backend_symbols": [str(v) for v in row.get("backend_symbols") or []],
            "gm_aliases": [str(v) for v in gm.get("aliases") or []],
            "source_declared": bool(row.get("source_declared", False)),
            "source_assignment_status": str(row.get("source_assignment_status") or "unknown"),
        }

    payload = {
        "_meta": {
            "schema": 1,
            "purpose": "read_only_protocol_labels_and_planes",
            "source": "canonical Pass34 MID_LOOKUP_INDEX.json retained through Pass35",
            "record_count": len(records),
            "numeric_mid_is_canonical_key": True,
            "safety_rule": "metadata only; never decide compatibility, mutation safety, response shape, reward ownership, or gameplay semantics from labels/ranges",
        },
        "records": records,
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"[PROTOCOL-REGISTRY] records={len(records)} out={args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
