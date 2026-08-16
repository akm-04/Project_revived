#!/usr/bin/env python3
"""Derive skill-point timer/max metadata from authoritative src_64 Lua tables."""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


def parse_table(path: Path) -> tuple[list[str], list[list[str]]]:
    text = path.read_text(encoding="utf-8-sig", errors="strict")
    km = re.search(r"keys\s*=\s*\{(.*?)\}\s*,\s*rows", text, re.S)
    rm = re.search(r"rows\s*=\s*\{(.*)\}\s*\}\s*$", text, re.S)
    if not km or not rm:
        raise SystemExit(f"Could not parse table wrapper: {path}")
    keys = re.findall(r'"([^"]*)"', km.group(1))
    body = rm.group(1)
    rows: list[list[str]] = []
    depth = 0
    start = None
    for idx, ch in enumerate(body):
        if ch == "{":
            if depth == 0:
                start = idx + 1
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0 and start is not None:
                vals = re.findall(r'"([^"]*)"', body[start:idx])
                if vals:
                    rows.append(vals)
                start = None
    return keys, rows


def rows_as_dicts(path: Path) -> list[dict[str, str]]:
    keys, rows = parse_table(path)
    return [dict(zip(keys, row)) for row in rows if len(row) >= len(keys)]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("src64", type=Path, help="authoritative assets/src_64 root")
    ap.add_argument("--output", type=Path, default=Path("data/hero_skill_regen_meta.json"))
    args = ap.parse_args()
    tables = args.src64 / "data" / "tables"
    misc = rows_as_dicts(tables / "misc.lua")
    vip = rows_as_dicts(tables / "vip.lua")
    monthly = rows_as_dicts(tables / "monthly_privilege.lua")

    duration_row = next((r for r in misc if r.get("key") == "skill_point_incr_time"), None)
    monthly_row = next((r for r in monthly if r.get("id") == "1"), None)
    if not duration_row or not monthly_row:
        raise SystemExit("Required source rows missing")
    vip_map = {str(int(r["id"])): int(r["skill_max"]) for r in vip if r.get("id") and r.get("skill_max")}
    out = {
        "_meta": {
            "generated_from": [
                "src_64/data/tables/misc.lua",
                "src_64/data/tables/vip.lua",
                "src_64/data/tables/monthly_privilege.lua",
            ],
            "client_consumer": "src_64/app/model/SelfPlayer.lua:getSkillPoint/recoverByTime",
            "provenance": "source-confirmed",
        },
        "skill_point_incr_time": int(duration_row["value"]),
        "vip_skill_max": vip_map,
        "monthly_privilege_skill_max": int(monthly_row["skill_max"]),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"[SKILL-META] duration={out['skill_point_incr_time']} vip_rows={len(vip_map)} monthly_bonus={out['monthly_privilege_skill_max']}")
    print(f"[SKILL-META] output={args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
