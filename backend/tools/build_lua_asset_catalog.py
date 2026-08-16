#!/usr/bin/env python3
"""Build a compact provenance catalog from the recovered GXB asset archive.

Expected archive layers:
  app-assets/output/assets/src_32|src_64/       APK baseline
  downloaded-assets/output/src_32|src_64/      recovered writable overrides

The supplied recovery snapshot has byte-identical 32/64 trees, so the catalog
stores one record per relative path while still validating that both arches agree.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import zipfile
from pathlib import Path


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("archive", type=Path)
    ap.add_argument("--output", type=Path, default=Path("data/lua_asset_catalog.json"))
    args = ap.parse_args()

    app32 = "app-assets/output/assets/src_32/"
    app64 = "app-assets/output/assets/src_64/"
    down32 = "downloaded-assets/output/src_32/"
    down64 = "downloaded-assets/output/src_64/"

    with zipfile.ZipFile(args.archive) as zf:
        names = set(zf.namelist())
        rels = sorted(n[len(app64):] for n in names if n.startswith(app64) and not n.endswith("/"))
        entries = []
        arch_mismatches = []
        override_arch_mismatches = []
        override_count = 0
        override_changed = 0
        for rel in rels:
            a64 = zf.read(app64 + rel)
            a32_name = app32 + rel
            if a32_name not in names:
                arch_mismatches.append({"path": rel, "reason": "missing src_32 baseline"})
                a32 = None
            else:
                a32 = zf.read(a32_name)
                if a32 != a64:
                    arch_mismatches.append({"path": rel, "reason": "src_32/src_64 baseline bytes differ"})

            row = {
                "path": rel,
                "app_size": len(a64),
                "app_sha256": sha256(a64),
            }
            d64_name = down64 + rel
            d32_name = down32 + rel
            if d64_name in names or d32_name in names:
                override_count += 1
                d64 = zf.read(d64_name) if d64_name in names else None
                d32 = zf.read(d32_name) if d32_name in names else None
                chosen = d64 if d64 is not None else d32
                if d64 is None or d32 is None or d64 != d32:
                    override_arch_mismatches.append(rel)
                row["downloaded_override"] = {
                    "size": len(chosen),
                    "sha256": sha256(chosen),
                    "changed_from_app": chosen != a64,
                }
                if chosen != a64:
                    override_changed += 1
            entries.append(row)

    out = {
        "_meta": {
            "source_archive": args.archive.name,
            "apk_baseline_entries": len(entries),
            "downloaded_override_entries": override_count,
            "downloaded_overrides_changed_from_app": override_changed,
            "baseline_arch_mismatches": len(arch_mismatches),
            "override_arch_mismatches": len(override_arch_mismatches),
            "note": "One record per relative path; source snapshot 32/64 equality is validated during generation."
        },
        "entries": entries,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(out, separators=(",", ":"), ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"[LUA-CATALOG] baseline={len(entries)} overrides={override_count} changed={override_changed}")
    print(f"[LUA-CATALOG] baseline_arch_mismatches={len(arch_mismatches)} override_arch_mismatches={len(override_arch_mismatches)}")
    print(f"[LUA-CATALOG] output={args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
