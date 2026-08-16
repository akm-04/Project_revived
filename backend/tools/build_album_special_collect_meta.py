#!/usr/bin/env python3
"""Regenerate album-special fresh-account shape from collect_special.lua."""
from __future__ import annotations
import argparse, json, re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "data/album_special_collect_meta.json"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("collect_special_lua", type=Path)
    args = ap.parse_args()
    text = args.collect_special_lua.read_text(encoding="utf-8-sig")
    ids = [int(x) for x in re.findall(r'\{\s*\n\s*"(\d+)",', text)]
    if not ids or ids != list(range(1, max(ids) + 1)):
        raise SystemExit(f"Expected contiguous 1..N IDs, got {ids[:10]}... count={len(ids)}")
    data = {
        "ids": ids,
        "fresh_is_award": [0] * len(ids),
        "source": str(args.collect_special_lua),
        "note": "is_award is consumed as a Lua array by SelfPlayer.",
    }
    OUT.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {OUT}: slots={len(ids)}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
