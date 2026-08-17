#!/usr/bin/env python3
"""Build source-backed normal-Hero equipment/promotion metadata.

Inputs are authoritative supplied ``src_64`` tables:
- ``data/tables/partner.lua`` (base64-wrapped Lua rows)
- ``data/tables/item.lua`` (base64-wrapped TSV)
- ``data/tables/random_name.lua`` (source random-name fragments)
- ``data/tables/misc.lua`` (normal-Hero table-ID boundary)

The output contains only fields directly consumed by the early normal-Hero
SET_HERO_EQUIP / ONE_CLICK_EQUIP / ONE_CLICK_JINJIE client calculations.
The script decodes/parses source data; it never executes Lua.
"""
from __future__ import annotations

import argparse
import base64
import csv
import io
import json
import re
from pathlib import Path
from typing import Any

COLORS = [
    "white", "green", "green1", "blue", "blue1", "blue2", "purple",
    "purple1", "purple2", "purple3", "purple4", "orange", "orange1",
    "orange2", "red", "red1",
]


def _int(value: Any, default: int = 0) -> int:
    try:
        return int(str(value).strip() or default)
    except (TypeError, ValueError):
        return default


def _split_ints(value: Any) -> list[int]:
    text = str(value or "").strip()
    if not text:
        return []
    result: list[int] = []
    for part in text.split("|"):
        part = part.strip()
        if not part:
            continue
        result.append(_int(part, 0))
    return result


def _decode_wrapped(path: Path) -> str:
    wrapped = path.read_text(encoding="utf-8-sig")
    match = re.search(r'return\s+"([A-Za-z0-9+/=]+)"', wrapped, re.S)
    if not match:
        raise ValueError(f"unrecognized encoded table: {path}")
    return base64.b64decode(match.group(1)).decode("utf-8")


def _extract_table(text: str, start: int) -> str:
    start = text.find("{", start)
    if start < 0:
        raise ValueError("row table start not found")
    depth = 0
    quote: str | None = None
    long_end: str | None = None
    i = start
    while i < len(text):
        if long_end is not None:
            end = text.find(long_end, i)
            if end < 0:
                raise ValueError("unterminated Lua long string")
            i = end + len(long_end)
            long_end = None
            continue
        if quote is not None:
            if text[i] == "\\":
                i += 2
                continue
            if text[i] == quote:
                quote = None
            i += 1
            continue
        if text.startswith("[==[", i):
            long_end = "]==]"
            i += 4
            continue
        ch = text[i]
        if ch in ('"', "'"):
            quote = ch
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return text[start : i + 1]
        i += 1
    raise ValueError("unterminated Lua row table")


def _string_values(table_text: str) -> list[str]:
    inner = table_text.strip()[1:-1]
    values: list[str] = []
    i = 0
    while i < len(inner):
        while i < len(inner) and (inner[i].isspace() or inner[i] == ","):
            i += 1
        if i >= len(inner):
            break
        if inner.startswith("[==[", i):
            end = inner.find("]==]", i + 4)
            if end < 0:
                raise ValueError("unterminated Lua long string in row")
            values.append(inner[i + 4 : end])
            i = end + 4
            continue
        if inner[i] in ('"', "'"):
            quote = inner[i]
            i += 1
            buf: list[str] = []
            while i < len(inner):
                ch = inner[i]
                if ch == "\\" and i + 1 < len(inner):
                    buf.append(inner[i + 1])
                    i += 2
                    continue
                if ch == quote:
                    i += 1
                    break
                buf.append(ch)
                i += 1
            values.append("".join(buf))
            continue
        end = i
        while end < len(inner) and inner[end] not in ",\n\r}":
            end += 1
        values.append(inner[i:end].strip())
        i = end
    return values


def _partner_rows(path: Path) -> dict[str, dict[str, Any]]:
    decoded = _decode_wrapped(path)
    keys_match = re.search(r"table\.keys\s*=\s*\{(.*?)\}\s*table\.rows", decoded, re.S)
    if not keys_match:
        raise ValueError("partner.lua decoded key map not found")
    key_map = {name: int(index) - 1 for name, index in re.findall(r"(\w+)\s*=\s*(\d+)", keys_match.group(1))}
    required = ["id", *COLORS]
    for key in required:
        if key not in key_map:
            raise ValueError(f"partner.lua missing key {key}")

    result: dict[str, dict[str, Any]] = {}
    for marker in re.finditer(r"\[(\d+)\]\s*=\s*\{", decoded):
        table_id = int(marker.group(1))
        values = _string_values(_extract_table(decoded, marker.start()))
        if key_map["id"] >= len(values):
            continue
        row_id = _int(values[key_map["id"]], table_id)
        if row_id <= 0:
            continue
        color_lists: dict[str, list[int]] = {}
        for color_index, color_key in enumerate(COLORS, start=1):
            idx = key_map[color_key]
            color_lists[str(color_index)] = _split_ints(values[idx] if idx < len(values) else "")
        result[str(row_id)] = {"equip_lists": color_lists}
    return result


def _item_rows(path: Path) -> dict[str, dict[str, Any]]:
    decoded = _decode_wrapped(path)
    reader = csv.reader(io.StringIO(decoded), delimiter="\t")
    rows = list(reader)
    if len(rows) < 3:
        raise ValueError("item.lua decoded TSV is empty")
    headers = rows[1]
    index = {name: i for i, name in enumerate(headers) if name}
    required = ["id", "level", "compose", "compose_num", "compose_mana", "exp", "is_awaken_item", "is_bloodline_item"]
    for key in required:
        if key not in index:
            raise ValueError(f"item.lua missing column {key}")

    result: dict[str, dict[str, Any]] = {}
    for row in rows[2:]:
        if not row:
            continue
        if len(row) < len(headers):
            row = row + [""] * (len(headers) - len(row))
        item_id = _int(row[index["id"]], 0)
        if item_id <= 0:
            continue
        result[str(item_id)] = {
            "level": max(0, _int(row[index["level"]], 0)),
            "compose": _split_ints(row[index["compose"]]),
            "compose_num": _split_ints(row[index["compose_num"]]),
            "compose_mana": max(0, _int(row[index["compose_mana"]], 0)),
            "exp": max(0, _int(row[index["exp"]], 0)),
            "is_awaken_item": max(0, _int(row[index["is_awaken_item"]], 0)),
            "is_bloodline_item": max(0, _int(row[index["is_bloodline_item"]], 0)),
        }
    return result


def _flat_table_rows(path: Path) -> tuple[list[str], list[list[str]]]:
    text = path.read_text(encoding="utf-8-sig")
    keys_match = re.search(r"keys\s*=\s*\{(.*?)\}\s*,\s*rows\s*=", text, re.S)
    rows_match = re.search(r"rows\s*=\s*\{(.*)\}\s*\}\s*$", text, re.S)
    if not keys_match or not rows_match:
        raise ValueError(f"unrecognized flat Lua table: {path}")
    keys = re.findall(r'"([^"\\]*(?:\\.[^"\\]*)*)"', keys_match.group(1))
    body = rows_match.group(1)
    result: list[list[str]] = []
    cursor = 0
    while True:
        start = body.find("{", cursor)
        if start < 0:
            break
        table_text = _extract_table(body, start)
        result.append(_string_values(table_text))
        cursor = start + len(table_text)
    return keys, result


def _random_names(path: Path) -> list[str]:
    keys, rows = _flat_table_rows(path)
    text_index = keys.index("text")
    result: list[str] = []
    for row in rows:
        if text_index < len(row):
            value = row[text_index].strip()
            if value and value not in result:
                result.append(value)
    return result


def _misc_value(path: Path, target_key: str) -> int:
    keys, rows = _flat_table_rows(path)
    key_index = keys.index("key") if "key" in keys else 0
    value_index = keys.index("value") if "value" in keys else 1
    for row in rows:
        if len(row) > max(key_index, value_index) and row[key_index] == target_key:
            return _int(row[value_index], 0)
    raise ValueError(f"misc.lua has no {target_key}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source_root", type=Path)
    parser.add_argument("--output", type=Path, default=Path("data/hero_equipment_meta.json"))
    args = parser.parse_args()

    table_root = args.source_root / "data/tables"
    partners = _partner_rows(table_root / "partner.lua")
    items = _item_rows(table_root / "item.lua")
    names = _random_names(table_root / "random_name.lua")
    partner_init = _misc_value(table_root / "misc.lua", "partner_table_init_id")

    payload = {
        "_meta": {
            "format": "GXB v0.8.4 source-derived normal-Hero equipment metadata",
            "source": [
                "src_64/data/tables/partner.lua: white..red1 equipment lists",
                "src_64/data/tables/item.lua: level/compose/compose_num/compose_mana/exp/awaken flags",
                "src_64/data/tables/random_name.lua: generated-name source fragments",
                "src_64/data/tables/misc.lua: partner_table_init_id",
            ],
            "policy": [
                "metadata is source data only; server mutation policy is implemented separately",
                "general awakened/bloodline/fumo promotion semantics remain outside v0.8.4",
            ],
        },
        "partner_table_init_id": partner_init,
        "potion_ids": [50001001, 50001002, 50001004, 50001005, 50005182],
        "partners": partners,
        "items": items,
        "random_names": names,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"wrote {args.output}: partners={len(partners)} items={len(items)} names={len(names)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
