#!/usr/bin/env python3
"""Build the source-backed Campaign special-story partner-drop metadata.

Inputs are the authoritative client tables:
  data/tables/campaign.lua
  data/tables/partner.lua

The generated runtime metadata contains only:
- Campaign IDs whose ``story_drop_partner`` source field is non-zero;
- the source-listed selectable partner table IDs;
- each selectable partner's source ``ini_star``.

The script parses table literals as data. It never executes Lua.
"""
from __future__ import annotations

import argparse
import base64
import json
import re
from pathlib import Path
from typing import Iterable


def _top_level_tables(text: str) -> list[str]:
    out: list[str] = []
    depth = 0
    start: int | None = None
    quote: str | None = None
    long_end: str | None = None
    i = 0
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
        char = text[i]
        if char in ('"', "'"):
            quote = char
        elif char == "{":
            if depth == 0:
                start = i
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0 and start is not None:
                out.append(text[start : i + 1])
                start = None
        i += 1
    return out


def _string_values(table_text: str) -> list[str]:
    """Parse the string/scalar fields in one flat Lua row table."""
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
        if inner[i] == '"':
            i += 1
            buffer: list[str] = []
            while i < len(inner):
                char = inner[i]
                if char == "\\" and i + 1 < len(inner):
                    # Table fields needed by this generator are numeric strings;
                    # preserving the escaped character is sufficient here.
                    buffer.append(inner[i + 1])
                    i += 2
                    continue
                if char == '"':
                    i += 1
                    break
                buffer.append(char)
                i += 1
            values.append("".join(buffer))
            continue
        end = i
        while end < len(inner) and inner[end] not in ",\n\r}":
            end += 1
        values.append(inner[i:end].strip())
        i = end
    return values


def _campaign_story_options(path: Path) -> dict[int, list[int]]:
    text = path.read_text(encoding="utf-8-sig")
    keys_match = re.search(r"keys\s*=\s*\{(.*?)\}\s*,\s*rows\s*=", text, re.S)
    rows_match = re.search(r"rows\s*=\s*\{(.*)\}\s*\}\s*$", text, re.S)
    if not keys_match or not rows_match:
        raise ValueError(f"unrecognized campaign table shape: {path}")
    keys = re.findall(r'"([^"\\]*(?:\\.[^"\\]*)*)"', keys_match.group(1))
    try:
        story_index = keys.index("story_drop_partner")
        campaign_index = keys.index("campaign_id")
    except ValueError as exc:
        raise ValueError("campaign.lua is missing required keys") from exc

    result: dict[int, list[int]] = {}
    for row_text in _top_level_tables(rows_match.group(1)):
        values = _string_values(row_text)
        if len(values) != len(keys):
            raise ValueError(
                f"campaign row field count mismatch: expected {len(keys)}, got {len(values)}"
            )
        raw = values[story_index].strip()
        if not raw or raw == "0":
            continue
        campaign_id = int(values[campaign_index])
        options = [int(value) for value in raw.split("|") if value and value != "0"]
        if options:
            result[campaign_id] = options
    return result


def _extract_indexed_row(text: str, table_id: int) -> str:
    marker = f"[{table_id}]"
    marker_pos = text.find(marker)
    if marker_pos < 0:
        raise ValueError(f"partner table ID {table_id} not found")
    row_start = text.find("{", marker_pos)
    if row_start < 0:
        raise ValueError(f"partner row {table_id} has no table")
    rows = _top_level_tables(text[row_start:])
    if not rows:
        raise ValueError(f"could not parse partner row {table_id}")
    return rows[0]


def _partner_initial_stars(path: Path, table_ids: Iterable[int]) -> dict[int, int]:
    wrapped = path.read_text(encoding="utf-8-sig")
    payload_match = re.search(r'return\s+"([A-Za-z0-9+/=]+)"', wrapped, re.S)
    if not payload_match:
        raise ValueError(f"unrecognized encoded partner table shape: {path}")
    decoded = base64.b64decode(payload_match.group(1)).decode("utf-8")
    ini_match = re.search(r"\bini_star\s*=\s*(\d+)", decoded)
    if not ini_match:
        raise ValueError("partner.lua decoded key map has no ini_star")
    ini_index = int(ini_match.group(1)) - 1

    result: dict[int, int] = {}
    for table_id in sorted(set(table_ids)):
        values = _string_values(_extract_indexed_row(decoded, table_id))
        if ini_index >= len(values):
            raise ValueError(f"partner row {table_id} lacks ini_star field")
        star = int(values[ini_index])
        if star <= 0:
            raise ValueError(f"partner row {table_id} has invalid ini_star={star}")
        result[table_id] = star
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source_root", type=Path, help="authoritative src_64 root")
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("data/campaign_story_drop_meta.json"),
    )
    args = parser.parse_args()

    campaign_path = args.source_root / "data/tables/campaign.lua"
    partner_path = args.source_root / "data/tables/partner.lua"
    options = _campaign_story_options(campaign_path)
    partner_ids = {table_id for values in options.values() for table_id in values}
    initial_stars = _partner_initial_stars(partner_path, partner_ids)

    payload = {
        "source": {
            "campaign": "src_64/data/tables/campaign.lua: story_drop_partner",
            "partner": "src_64/data/tables/partner.lua: ini_star",
        },
        "campaigns": {
            str(campaign_id): {"story_drop_partner": partner_ids}
            for campaign_id, partner_ids in sorted(options.items())
        },
        "partners": {
            str(table_id): {"ini_star": star}
            for table_id, star in sorted(initial_stars.items())
        },
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(
        f"wrote {args.output}: campaigns={len(options)} selectable_partners={len(initial_stars)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
