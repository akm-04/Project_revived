#!/usr/bin/env python3
"""Build Pass72 source-backed ordinary Hero star progression metadata."""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


def _extract_rows(path: Path) -> dict[str, dict[str, int]]:
    text = path.read_text(encoding="utf-8-sig")
    keys_match = re.search(r"keys\s*=\s*\{(.*?)\}\s*,\s*rows\s*=", text, re.S)
    if not keys_match:
        raise ValueError("star.lua keys not found")
    keys = re.findall(r'"([^"\\]+)"', keys_match.group(1))
    wanted = {"star", "evolve_num", "evolve_price", "summon_num", "summon_price"}
    if not wanted.issubset(set(keys)):
        raise ValueError(f"star.lua missing expected keys: {sorted(wanted-set(keys))}")
    rows: dict[str, dict[str, int]] = {}
    for block in re.findall(r"\{\s*((?:\"[^\"]*\"\s*,?\s*)+)\}", text[text.find("rows"):], re.S):
        vals = re.findall(r'"([^"\\]*)"', block)
        if len(vals) < len(keys):
            continue
        row = {key: int(vals[i] or 0) for i, key in enumerate(keys)}
        star = row.get("star", 0)
        if star > 0:
            rows[str(star)] = row
    return rows


def _enum_fragments(path: Path) -> list[int]:
    text = path.read_text(encoding="utf-8-sig")
    m = re.search(r"xyd\.StarLevelSuipian\s*=\s*\{(.*?)\}", text, re.S)
    if not m:
        raise ValueError("StarLevelSuipian not found")
    return [int(v) for v in re.findall(r"\b\d+\b", m.group(1))]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("source_root", type=Path)
    ap.add_argument("--output", type=Path, default=Path("data/hero_progression_meta.json"))
    args = ap.parse_args()
    rows = _extract_rows(args.source_root / "data/tables/star.lua")
    fragments = _enum_fragments(args.source_root / "app/common/enums.lua")
    for star in range(1, 6):
        if str(star) not in rows:
            raise ValueError(f"star.lua row {star} missing")
        if len(fragments) < star or int(rows[str(star)]["evolve_num"]) != int(fragments[star-1]):
            raise ValueError(f"star {star} evolve_num disagrees with StarLevelSuipian")
    payload = {
        "_meta": {
            "format": "GXB v0.9.4 Pass72 source-derived Hero progression metadata",
            "source": [
                "effective src_64/data/tables/star.lua",
                "effective src_64/app/common/enums.lua: StarLevelSuipian",
                "effective src_64/app/windows/HeroMainWindow.lua: evolvePrice(next_star)",
            ],
            "policy": [
                "rows are source facts, not private-server balance policy",
                "ordinary 1->5 evolution is activated; post-5 SuperHero evolution remains separate/source-bounded",
            ],
        },
        "normal_max_star": 5,
        "stars": rows,
        "star_level_fragments": fragments,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"wrote {args.output}: stars={len(rows)} enum_fragments={len(fragments)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
