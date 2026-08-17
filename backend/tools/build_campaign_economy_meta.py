#!/usr/bin/env python3
"""Build source-derived Campaign/player economy metadata for v0.8.2.

Inputs are resolved through the Pass-28 effective source policy:
recovered writable ``src_64`` overrides the APK baseline per relative path.
The generator parses Lua table literals as data; it never executes Lua.
``SelfPlayer:getExpMulti()`` is additionally read to preserve the ordinary
normal-Campaign player EXP multiplier used by the result UI.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


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
            buffer: list[str] = []
            while i < len(inner):
                char = inner[i]
                if char == "\\" and i + 1 < len(inner):
                    buffer.append(inner[i + 1])
                    i += 2
                    continue
                if char == quote:
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


def _flat_table(path: Path) -> tuple[list[str], list[list[str]]]:
    text = path.read_text(encoding="utf-8-sig")
    keys_match = re.search(r"keys\s*=\s*\{(.*?)\}\s*,\s*rows\s*=", text, re.S)
    rows_match = re.search(r"rows\s*=\s*\{(.*)\}\s*\}\s*$", text, re.S)
    if not keys_match or not rows_match:
        raise ValueError(f"unrecognized table shape: {path}")
    keys = re.findall(r'"([^"\\]*(?:\\.[^"\\]*)*)"', keys_match.group(1))
    rows: list[list[str]] = []
    for row_text in _top_level_tables(rows_match.group(1)):
        values = _string_values(row_text)
        if len(values) != len(keys):
            raise ValueError(
                f"{path.name}: expected {len(keys)} row fields, got {len(values)}"
            )
        rows.append(values)
    return keys, rows


def _int(value: Any, default: int = 0) -> int:
    try:
        return int(str(value).strip() or default)
    except (TypeError, ValueError):
        return default


def _campaign_rows(path: Path) -> dict[str, dict[str, int]]:
    keys, rows = _flat_table(path)
    required = [
        "campaign_id",
        "campaign_type",
        "chapter",
        "energy_cost",
        "defeat_cost",
        "partner_exp",
        "init_dropbox",
        "dropbox",
        "mana_gain",
        "star_gift",
        "next_campaign_id",
    ]
    indexes = {key: keys.index(key) for key in required}
    result: dict[str, dict[str, int]] = {}
    for row in rows:
        cid = _int(row[indexes["campaign_id"]])
        if cid <= 0:
            continue
        result[str(cid)] = {
            key: _int(row[indexes[key]])
            for key in required
            if key != "campaign_id"
        }
    return result


def _player_rows(path: Path) -> dict[str, dict[str, int]]:
    keys, rows = _flat_table(path)
    required = [
        "lev",
        "energy",
        "exp",
        "award_energy",
        "total_exp",
        "hero_lev",
        "power",
        "expedition_mana",
    ]
    indexes = {key: keys.index(key) for key in required}
    result: dict[str, dict[str, int]] = {}
    for row in rows:
        lev = _int(row[indexes["lev"]])
        if lev <= 0:
            continue
        result[str(lev)] = {
            key: _int(row[indexes[key]])
            for key in required
            if key != "lev"
        }
    return result


def _exp_multiplier(path: Path) -> int:
    text = path.read_text(encoding="utf-8-sig")
    # Decompiler-local symbol names vary, so anchor on the known method name.
    match = re.search(
        r"function\s+[^\n]*\.getExpMulti\([^)]*\)(.*?)\bend\b",
        text,
        re.S,
    )
    if not match:
        raise ValueError(f"getExpMulti() not found in {path}")
    value = re.search(r"\breturn\s+(\d+)\b", match.group(1))
    if not value:
        raise ValueError(f"numeric getExpMulti() return not found in {path}")
    return int(value.group(1))


def _resolve_effective(apk_root: Path, writable_root: Path | None, relative: str) -> tuple[Path, str]:
    if writable_root is not None:
        candidate = writable_root / relative
        if candidate.is_file():
            return candidate, "writable_hot_update"
    candidate = apk_root / relative
    if candidate.is_file():
        return candidate, "apk_baseline"
    raise FileNotFoundError(f"effective source file not found: {relative}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Build Campaign/economy metadata from the effective writable-over-APK src_64 view."
    )
    parser.add_argument(
        "--apk-root",
        required=True,
        type=Path,
        help="APK baseline src_64 root (app-assets/output/assets/src_64)",
    )
    parser.add_argument(
        "--writable-root",
        type=Path,
        default=None,
        help="optional recovered writable src_64 root (downloaded-assets/output/src_64)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("data/campaign_economy_meta.json"),
    )
    args = parser.parse_args()

    relative_paths = {
        "campaign": "data/tables/campaign.lua",
        "player": "data/tables/player.lua",
        "self_player": "app/model/SelfPlayer.lua",
    }
    resolved: dict[str, dict[str, str]] = {}
    actual: dict[str, Path] = {}
    for key, relative in relative_paths.items():
        path, layer = _resolve_effective(args.apk_root, args.writable_root, relative)
        actual[key] = path
        resolved[relative] = {"layer": layer, "relative_path": relative}

    campaigns = _campaign_rows(actual["campaign"])
    levels = _player_rows(actual["player"])
    multiplier = _exp_multiplier(actual["self_player"])

    payload = {
        "_meta": {
            "format": "GXB Pass30 source-derived Campaign/Phase-1 economy metadata",
            "source_resolution": "effective_merged",
            "source_precedence": "writable_hot_update_over_apk_baseline",
            "resolved_inputs": resolved,
            "source": [
                "src_64/data/tables/campaign.lua",
                "src_64/data/tables/player.lua",
                "src_64/app/model/SelfPlayer.lua:getExpMulti",
            ],
            "policy": [
                "each input path is resolved writable-over-APK before parsing",
                "campaign rows are source data only; this file does not define drop RNG",
                "ordinary normal-Campaign player EXP uses energy_cost * player_exp_multiplier",
                "mentor/student modifiers remain outside this metadata contract",
            ],
        },
        "player_exp_multiplier": multiplier,
        "campaigns": campaigns,
        "player_levels": levels,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        f"wrote {args.output}: campaigns={len(campaigns)} "
        f"player_levels={len(levels)} multiplier={multiplier} source=effective_merged"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
