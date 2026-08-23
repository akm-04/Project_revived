#!/usr/bin/env python3
"""Build source-backed Super Campaign paid-reset metadata for Pass92.

Runtime never executes raw Lua.  This builder extracts only the static facts
used by MID116: nth reset Crystal costs and Monthly Privilege's additive
``num_elite`` allowance. VIP ``num_elite`` remains owned by vip_source_meta.json
and VipPrivilegeResolver.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path
from typing import Any


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
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
                return text[start : i + 1]
    raise ValueError("unterminated Lua row table")


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
    ap.add_argument("--output", type=Path, default=Path("data/campaign_reset_meta.json"))
    args = ap.parse_args()

    refresh_path = args.source_root / "data/tables/refresh_cost.lua"
    privilege_path = args.source_root / "data/tables/monthly_privilege.lua"
    refresh_rows = rows_as_dicts(refresh_path)
    privilege_rows = rows_as_dicts(privilege_path)

    costs: dict[str, int] = {}
    for row in refresh_rows:
        ordinal = int(row.get("id") or 0)
        if ordinal <= 0:
            continue
        costs[str(ordinal)] = max(0, int(row.get("refresh_elite_cost") or 0))

    privilege_row = next((r for r in privilege_rows if int(r.get("id") or 0) == 1), None)
    if privilege_row is None:
        raise RuntimeError("monthly_privilege.lua row id=1 missing")
    monthly_bonus = max(0, int(privilege_row.get("num_elite") or 0))

    # Effective vip.lua caps at 25 paid resets and active Monthly Privilege adds
    # 3, so source costs must cover at least ordinals 1..28.
    required = tuple(range(1, 29))
    missing = [i for i in required if str(i) not in costs]
    if missing:
        raise RuntimeError(f"refresh_elite_cost missing required ordinals: {missing}")

    payload = {
        "_meta": {
            "schema_version": 1,
            "pass": "92.0",
            "source_resolution": "effective_merged",
            "refresh_cost_source": "data/tables/refresh_cost.lua",
            "refresh_cost_source_sha256": sha256(refresh_path),
            "monthly_privilege_source": "data/tables/monthly_privilege.lua",
            "monthly_privilege_source_sha256": sha256(privilege_path),
            "runtime_rule": "MID116 cost is refreshEliteCost(reset_count+1); active Monthly Privilege contributes row1 num_elite. VIP num_elite remains VipPrivilegeResolver-owned.",
        },
        "monthly_privilege_num_elite": monthly_bonus,
        "refresh_elite_cost_by_ordinal": {str(i): costs[str(i)] for i in required},
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"wrote {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
