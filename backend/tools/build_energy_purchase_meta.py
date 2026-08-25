#!/usr/bin/env python3
"""Build source-backed MID97 Energy-purchase metadata for Pass100."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path
from typing import Any


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def extract_table(text: str, start: int) -> str:
    depth = 0
    quote = None
    escape = False
    for i in range(start, len(text)):
        ch = text[i]
        if quote:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == quote:
                quote = None
            continue
        if ch in ('"', "'"):
            quote = ch
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return text[start:i + 1]
    raise ValueError("unterminated Lua row")


def string_values(table_text: str) -> list[str]:
    values: list[str] = []
    i = 0
    while i < len(table_text):
        if table_text[i] != '"':
            i += 1
            continue
        i += 1
        out: list[str] = []
        escape = False
        while i < len(table_text):
            ch = table_text[i]
            i += 1
            if escape:
                out.append(ch)
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                break
            else:
                out.append(ch)
        values.append("".join(out))
    return values


def rows_as_dicts(path: Path) -> list[dict[str, Any]]:
    text = path.read_text(encoding="utf-8-sig")
    km = re.search(r"keys\s*=\s*\{(.*?)\}\s*,\s*rows\s*=", text, re.S)
    rm = re.search(r"rows\s*=\s*\{(.*)\}\s*\}\s*$", text, re.S)
    if not km or not rm:
        raise ValueError(f"unrecognized flat Lua table: {path}")
    keys = re.findall(r'"([^"\\]*(?:\\.[^"\\]*)*)"', km.group(1))
    body = rm.group(1)
    rows: list[list[str]] = []
    cursor = 0
    while True:
        start = body.find("{", cursor)
        if start < 0:
            break
        table = extract_table(body, start)
        rows.append(string_values(table))
        cursor = start + len(table)
    out: list[dict[str, Any]] = []
    for row in rows:
        padded = row + [""] * max(0, len(keys) - len(row))
        values: dict[str, Any] = {}
        for idx, key in enumerate(keys):
            raw = padded[idx].strip()
            if re.fullmatch(r"-?\d+", raw):
                values[key] = int(raw)
            elif re.fullmatch(r"-?\d+\.\d+", raw):
                values[key] = float(raw)
            else:
                values[key] = padded[idx]
        out.append(values)
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("source_root", type=Path, help="effective src_64 root")
    ap.add_argument("--output", type=Path, default=Path("data/energy_purchase_source_meta.json"))
    args = ap.parse_args()

    refresh_path = args.source_root / "data/tables/refresh_cost.lua"
    privilege_path = args.source_root / "data/tables/monthly_privilege.lua"
    misc_path = args.source_root / "data/tables/misc.lua"
    sidebar_path = args.source_root / "app/common/ui/EcoSidebar.lua"
    display_sidebar_path = args.source_root / "app/common/ui/EcoDisplaySidebar.lua"

    refresh_rows = rows_as_dicts(refresh_path)
    privilege_rows = rows_as_dicts(privilege_path)
    misc_rows = rows_as_dicts(misc_path)

    costs = {
        int(row.get("id") or 0): max(0, int(row.get("buy_energy_cost") or 0))
        for row in refresh_rows
        if int(row.get("id") or 0) > 0
    }
    required = tuple(range(1, 21))  # VIP15=16 plus Monthly Privilege +4.
    missing = [i for i in required if i not in costs or costs[i] <= 0]
    if missing:
        raise RuntimeError(f"buy_energy_cost missing required ordinals: {missing}")

    privilege_row = next((r for r in privilege_rows if int(r.get("id") or 0) == 1), None)
    if privilege_row is None:
        raise RuntimeError("monthly_privilege.lua row id=1 missing")
    monthly_bonus = max(0, int(privilege_row.get("num_energy") or 0))

    misc_row = next((r for r in misc_rows if str(r.get("key") or "") == "energy_max_limit"), None)
    if misc_row is None:
        raise RuntimeError("misc.lua energy_max_limit missing")
    energy_max_limit = max(0, int(misc_row.get("value") or 0))

    grant_re = re.compile(r"local\s+var_0_3\s*=\s*(\d+)")
    grants = []
    for path in (sidebar_path, display_sidebar_path):
        match = grant_re.search(path.read_text(encoding="utf-8-sig"))
        if not match:
            raise RuntimeError(f"Energy purchase grant constant missing: {path}")
        grants.append(int(match.group(1)))
    if len(set(grants)) != 1 or grants[0] <= 0:
        raise RuntimeError(f"Energy purchase grant drift: {grants}")

    payload = {
        "_meta": {
            "schema_version": 1,
            "pass": "100.0",
            "source_resolution": "effective_merged",
            "refresh_cost_source": "data/tables/refresh_cost.lua",
            "refresh_cost_source_sha256": sha256(refresh_path),
            "monthly_privilege_source": "data/tables/monthly_privilege.lua",
            "monthly_privilege_source_sha256": sha256(privilege_path),
            "misc_source": "data/tables/misc.lua",
            "misc_source_sha256": sha256(misc_path),
            "energy_ui_sources": [
                "app/common/ui/EcoSidebar.lua",
                "app/common/ui/EcoDisplaySidebar.lua",
            ],
            "energy_ui_source_sha256": {
                "EcoSidebar.lua": sha256(sidebar_path),
                "EcoDisplaySidebar.lua": sha256(display_sidebar_path),
            },
            "runtime_rule": "MID97: nth Crystal cost from buyEnergyCost(counter+1), +120 Energy, reject new purchase at materialized Energy >= energy_max_limit, allowance VIP num_energy plus active Monthly Privilege row1 num_energy.",
        },
        "energy_grant": grants[0],
        "energy_purchase_threshold": energy_max_limit,
        "monthly_privilege_num_energy": monthly_bonus,
        "buy_energy_cost_by_ordinal": {str(i): costs[i] for i in required},
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"wrote {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
