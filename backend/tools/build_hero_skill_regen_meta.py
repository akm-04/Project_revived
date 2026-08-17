#!/usr/bin/env python3
"""Build skill-point timer/cap/purchase metadata from effective src_64.

Each source path is resolved independently using writable hot-update precedence
before the APK baseline.  The generated file is consumed by SkillPointPolicy;
it intentionally contains source constants only, not server policy guesses.
"""
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


def resolve_effective(apk_root: Path, writable_root: Path | None, relative: str) -> tuple[Path, str]:
    if writable_root is not None:
        candidate = writable_root / relative
        if candidate.is_file():
            return candidate, "writable_hot_update"
    candidate = apk_root / relative
    if candidate.is_file():
        return candidate, "apk_baseline"
    raise FileNotFoundError(f"effective source file not found: {relative}")


def translation_skill_grant(path: Path) -> int:
    text = path.read_text(encoding="utf-8-sig", errors="strict")
    match = re.search(
        r'"SKILL_POINT_BUY"\s*,\s*"([^"]+)"',
        text,
        re.S,
    )
    if not match:
        raise SystemExit(f"SKILL_POINT_BUY translation not found: {path}")
    amount = re.search(r"buy\s+(\d+)\s+skill\s+points", match.group(1), re.I)
    if not amount:
        raise SystemExit(f"skill-point purchase grant not found in translation: {path}")
    return int(amount.group(1))


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Build skill-point metadata from the effective writable-over-APK src_64 view."
    )
    ap.add_argument(
        "--apk-root",
        required=True,
        type=Path,
        help="APK baseline src_64 root (app-assets/output/assets/src_64)",
    )
    ap.add_argument(
        "--writable-root",
        type=Path,
        default=None,
        help="optional recovered writable src_64 root (downloaded-assets/output/src_64)",
    )
    ap.add_argument("--output", type=Path, default=Path("data/hero_skill_regen_meta.json"))
    args = ap.parse_args()

    relative_paths = {
        "misc": "data/tables/misc.lua",
        "vip": "data/tables/vip.lua",
        "monthly": "data/tables/monthly_privilege.lua",
        "refresh_cost": "data/tables/refresh_cost.lua",
        "translation": "data/tables/translation.lua",
    }
    actual: dict[str, Path] = {}
    resolved: dict[str, dict[str, str]] = {}
    for key, relative in relative_paths.items():
        path, layer = resolve_effective(args.apk_root, args.writable_root, relative)
        actual[key] = path
        resolved[relative] = {"layer": layer, "relative_path": relative}

    misc = rows_as_dicts(actual["misc"])
    vip = rows_as_dicts(actual["vip"])
    monthly = rows_as_dicts(actual["monthly"])
    refresh = rows_as_dicts(actual["refresh_cost"])

    duration_row = next((r for r in misc if r.get("key") == "skill_point_incr_time"), None)
    monthly_row = next((r for r in monthly if r.get("id") == "1"), None)
    if not duration_row or not monthly_row:
        raise SystemExit("Required source rows missing")

    vip_max = {
        str(int(r["id"])): int(r["skill_max"])
        for r in vip
        if r.get("id") not in (None, "") and r.get("skill_max") not in (None, "")
    }
    vip_buy = {
        str(int(r["id"])): int(r["skill_buy"])
        for r in vip
        if r.get("id") not in (None, "") and r.get("skill_buy") not in (None, "")
    }
    buy_cost = {
        str(int(r["id"])): int(r["buy_skill_cost"])
        for r in refresh
        if r.get("id") not in (None, "") and r.get("buy_skill_cost") not in (None, "")
    }
    max_times = max((int(key) for key in buy_cost), default=0)

    out = {
        "_meta": {
            "format": "GXB Pass30.1 effective-source skill-point metadata",
            "source_resolution": "effective_merged",
            "source_precedence": "writable_hot_update_over_apk_baseline",
            "resolved_inputs": resolved,
            "client_consumers": [
                "src_64/app/model/SelfPlayer.lua:getSkillPoint/recoverByTime/buySkillPoint",
                "src_64/app/windows/HeroMainWindow.lua:addSkillLevel",
                "src_64/app/common/tables/RefreshCostTable.lua:buySkillCost",
                "src_64/app/common/tables/VipTable.lua:skillBuy/skillPoint",
            ],
            "provenance": "source-confirmed constants; fresh-account full-pool initialization is a separate runtime-informed compatibility policy",
        },
        "skill_point_incr_time": int(duration_row["value"]),
        "vip_skill_max": vip_max,
        "vip_skill_buy": vip_buy,
        "monthly_privilege_skill_max": int(monthly_row["skill_max"]),
        "buy_skill_cost": buy_cost,
        "buy_skill_cost_max_times": max_times,
        "skill_point_purchase_grant": translation_skill_grant(actual["translation"]),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(out, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(
        f"[SKILL-META] duration={out['skill_point_incr_time']} vip_rows={len(vip_max)} "
        f"cost_rows={len(buy_cost)} grant={out['skill_point_purchase_grant']} source=effective_merged"
    )
    print(f"[SKILL-META] output={args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
