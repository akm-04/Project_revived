#!/usr/bin/env python3
"""Build the compact backend resource catalog from client metadata.

Usage:
    python3 tools/build_resource_catalog.py /path/to/version.json \
        --lazy /path/to/lazyFile.json \
        --out data/resource_catalog/resource_catalog.json

No asset directory is scanned.  Only metadata is read.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def load_lazy(path: Path | None) -> dict[tuple[str, str], dict]:
    out: dict[tuple[str, str], dict] = {}
    if not path:
        return out
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise SystemExit("lazyFile.json must be a JSON object")
    for raw in payload.values():
        try:
            row = json.loads(raw) if isinstance(raw, str) else raw
        except Exception:
            continue
        if not isinstance(row, dict):
            continue
        p = str(row.get("path") or "").replace("\\", "/")
        md5 = str(row.get("md5") or "").lower()
        if p and len(md5) == 32:
            out[(p, md5)] = row
    return out


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("version", type=Path)
    parser.add_argument("--lazy", type=Path)
    parser.add_argument("--out", type=Path, default=Path("data/resource_catalog/resource_catalog.json"))
    args = parser.parse_args()

    version = json.loads(args.version.read_text(encoding="utf-8"))
    if not isinstance(version, list):
        raise SystemExit("version.json must be a JSON array")
    lazy = load_lazy(args.lazy)

    entries: dict[tuple[str, str], dict] = {}
    for row in version:
        if not isinstance(row, dict):
            continue
        p = str(row.get("path") or "").replace("\\", "/")
        md5 = str(row.get("md5") or "").lower()
        if not p.startswith("res/web/") or len(md5) != 32:
            continue
        key = (p, md5)
        entries[key] = {
            "path": p,
            "md5": md5,
            "size": int(row.get("size") or 0),
            "source": "version.json",
        }
        if key in lazy:
            entries[key]["lazy_missing_snapshot"] = True

    for key, row in lazy.items():
        if key not in entries:
            p, md5 = key
            entries[key] = {
                "path": p,
                "md5": md5,
                "size": int(row.get("size") or 0),
                "source": "lazyFile.json",
                "lazy_missing_snapshot": True,
            }

    payload = {
        "_meta": {
            "generated_from": [str(args.version)] + ([str(args.lazy)] if args.lazy else []),
            "version_entries": len(version),
            "lazy_snapshot_entries": len(lazy),
            "catalog_entries": len(entries),
        },
        "entries": sorted(entries.values(), key=lambda item: (item["path"], item["md5"])),
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    print(f"wrote {len(entries)} entries -> {args.out}")


if __name__ == "__main__":
    main()
