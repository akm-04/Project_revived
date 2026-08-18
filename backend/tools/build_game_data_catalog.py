#!/usr/bin/env python3
"""Build Pass-32.6 typed GameDataCatalog from the effective src_64 view.

The generator parses Lua table data without executing Lua. Every input is
resolved through the shared writable-over-APK EffectiveSourceResolver and is
stamped with layer + SHA-256 provenance.
"""
from __future__ import annotations

import argparse
import base64
import csv
import io
import json
import re
import sys
from pathlib import Path
from typing import Any, Iterable

PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from gxb_backend.content.source_resolver import EffectiveSourceResolver, ResolvedSource


def _int(value: Any, default: int = 0) -> int:
    try:
        return int(str(value).strip() or default)
    except (TypeError, ValueError):
        return default


def _split_ints(value: Any) -> list[int]:
    return [_int(part) for part in str(value or "").split("|") if str(part).strip()]


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
        char = text[i]
        if char in ('"', "'"):
            quote = char
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[start : i + 1]
        i += 1
    raise ValueError("unterminated Lua table")


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
        raise ValueError(f"unrecognized flat table shape: {path}")
    keys = re.findall(r'"([^"\\]*(?:\\.[^"\\]*)*)"', keys_match.group(1))
    body = rows_match.group(1)
    rows: list[list[str]] = []
    cursor = 0
    while True:
        start = body.find("{", cursor)
        if start < 0:
            break
        table_text = _extract_table(body, start)
        values = _string_values(table_text)
        if len(values) != len(keys):
            raise ValueError(f"{path.name}: expected {len(keys)} fields, got {len(values)}")
        rows.append(values)
        cursor = start + len(table_text)
    return keys, rows


def _decode_wrapped(path: Path) -> str:
    wrapped = path.read_text(encoding="utf-8-sig")
    match = re.search(r'return\s+"([A-Za-z0-9+/=]+)"', wrapped, re.S)
    if not match:
        raise ValueError(f"unrecognized encoded table: {path}")
    return base64.b64decode(match.group(1)).decode("utf-8")


def _wrapped_lua_rows(path: Path, fields: Iterable[str]) -> dict[str, dict[str, Any]]:
    decoded = _decode_wrapped(path)
    keys_match = re.search(r"table\.keys\s*=\s*\{(.*?)\}\s*table\.rows", decoded, re.S)
    if not keys_match:
        raise ValueError(f"encoded Lua key map missing: {path}")
    key_map = {name: int(index) - 1 for name, index in re.findall(r"(\w+)\s*=\s*(\d+)", keys_match.group(1))}
    requested = list(fields)
    if "id" not in key_map:
        raise ValueError(f"encoded Lua table has no id key: {path}")
    result: dict[str, dict[str, Any]] = {}
    for marker in re.finditer(r"\[(\d+)\]\s*=\s*\{", decoded):
        values = _string_values(_extract_table(decoded, marker.start()))
        table_id = _int(values[key_map["id"]] if key_map["id"] < len(values) else marker.group(1))
        if table_id <= 0:
            continue
        row: dict[str, Any] = {"table_id": table_id}
        for field in requested:
            idx = key_map.get(field)
            if idx is None or idx >= len(values):
                continue
            raw = values[idx]
            if field in {"name", "name2", "class_name"}:
                row[field] = raw
            elif field in {"modelids"}:
                row[field] = _split_ints(raw)
            else:
                row[field] = _int(raw)
        result[str(table_id)] = row
    return result


def _item_rows(path: Path) -> dict[str, dict[str, Any]]:
    decoded = _decode_wrapped(path)
    rows = list(csv.reader(io.StringIO(decoded), delimiter="\t"))
    if len(rows) < 3:
        raise ValueError("item.lua decoded TSV is empty")
    headers = rows[1]
    index = {name: i for i, name in enumerate(headers) if name}
    fields = [
        "id", "name", "type", "sub_type", "partner_id", "pet_id", "skin_model",
        "skin_partner", "exp", "energy", "mana", "crystal", "item_num",
        "compose_item", "compose_num", "compose", "compose_mana", "skill_point",
    ]
    missing = [field for field in fields if field not in index]
    if missing:
        raise ValueError(f"item.lua missing columns: {missing}")
    out: dict[str, dict[str, Any]] = {}
    list_fields = {"compose_item", "compose_num", "compose"}
    text_fields = {"name"}
    for values in rows[2:]:
        if not values:
            continue
        if len(values) < len(headers):
            values += [""] * (len(headers) - len(values))
        table_id = _int(values[index["id"]])
        if table_id <= 0:
            continue
        row: dict[str, Any] = {"id": table_id}
        for field in fields[1:]:
            raw = values[index[field]]
            if field in list_fields:
                row[field] = _split_ints(raw)
            elif field in text_fields:
                row[field] = raw
            else:
                row[field] = _int(raw)
        out[str(table_id)] = row
    return out


def _flat_rows(path: Path, id_field: str, fields: Iterable[str], *, key_name: str | None = None) -> dict[str, dict[str, Any]]:
    keys, rows = _flat_table(path)
    idx = {name: i for i, name in enumerate(keys)}
    if id_field not in idx:
        raise ValueError(f"{path.name} missing id field {id_field}")
    fields = list(fields)
    out: dict[str, dict[str, Any]] = {}
    list_fields = {
        "first_display", "first_number", "story_drop_partner", "sweep_reward", "sweep_reward_num",
    }
    text_fields = {"name", "level", "task_num", "go_id", "award_id", "award_id_new", "num", "num_new"}
    for values in rows:
        table_id = _int(values[idx[id_field]])
        if table_id <= 0:
            continue
        row: dict[str, Any] = {(key_name or id_field): table_id}
        for field in fields:
            if field not in idx:
                continue
            raw = values[idx[field]]
            if field in list_fields:
                row[field] = _split_ints(raw)
            elif field in text_fields:
                row[field] = raw
            else:
                row[field] = _int(raw)
        out[str(table_id)] = row
    return out


def _function_rows(path: Path) -> dict[str, dict[str, Any]]:
    rows = _flat_rows(
        path,
        "id",
        ["name", "level", "condition", "is_on_levelup_wnd", "is_function_show", "open_control"],
        key_name="function_id",
    )
    for row in rows.values():
        parts = _split_ints(row.get("level", ""))
        kind = parts[0] if len(parts) >= 1 else 0
        value = parts[1] if len(parts) >= 2 else 0
        row["eligibility_kind"] = kind
        row["eligibility_value"] = value
        row["player_level"] = value if kind in (1, 6, 7) else 0
        row["stage"] = value if kind == 2 else 0
        row["vip"] = value if kind == 3 else 0
        row["energy"] = value if kind == 5 else 0
    return rows


def _dropbox_rows(path: Path) -> dict[str, dict[str, Any]]:
    keys, rows = _flat_table(path)
    idx = {name: i for i, name in enumerate(keys)}
    required = ["id", "dropbox_id", "item_id", "item_num", "drop_rate", "roll_type"]
    for field in required:
        if field not in idx:
            raise ValueError(f"dropbox.lua missing {field}")
    out: dict[str, dict[str, Any]] = {}
    for values in rows:
        dropbox_id = _int(values[idx["dropbox_id"]])
        if dropbox_id <= 0:
            continue
        row = out.setdefault(str(dropbox_id), {"dropbox_id": dropbox_id, "entries": []})
        row["entries"].append({
            "row_id": _int(values[idx["id"]]),
            "item_id": _int(values[idx["item_id"]]),
            "item_num": _int(values[idx["item_num"]]),
            "drop_rate": _int(values[idx["drop_rate"]]),
            "roll_type": _int(values[idx["roll_type"]]),
        })
    return out


def _skill_price_rows(path: Path) -> dict[str, dict[str, int]]:
    rows = _flat_rows(path, "lev", ["mana"], key_name="lev")
    return {key: {"lev": _int(value.get("lev")), "mana": _int(value.get("mana"))} for key, value in rows.items()}


def _current_reward_item_ids(metadata_dir: Path) -> set[int]:
    """Return only item rows reachable by already-implemented reward paths."""
    path = metadata_dir / "campaign_reward_meta.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    campaigns = data.get("campaigns") if isinstance(data, dict) else None
    if not isinstance(campaigns, dict):
        raise ValueError(f"invalid campaign reward metadata: {path}")
    item_ids: set[int] = {40001004}  # Mission80001 source-confirmed Lightin contracts.
    for row in campaigns.values():
        if not isinstance(row, dict):
            continue
        for award in row.get("init_dropbox_rows") or []:
            if not isinstance(award, dict):
                continue
            if _int(award.get("increase_rate")) == 10000 and _int(award.get("item_id")) > 0:
                item_ids.add(_int(award.get("item_id")))
        for award in row.get("sweep_rewards") or []:
            if isinstance(award, dict) and _int(award.get("item_id")) > 0:
                item_ids.add(_int(award.get("item_id")))
    return item_ids


def _provenance_row(
    source: ResolvedSource,
    *,
    verified_no_override: bool,
    row_subset_equivalent: bool = False,
    proof: str | None = None,
) -> dict[str, Any]:
    row: dict[str, Any] = {"layer": source.layer, "sha256": source.sha256}
    if source.layer == "apk_baseline" and verified_no_override:
        row["layer"] = "apk_baseline_effective_equivalent_verified"
    if source.layer == "apk_baseline" and row_subset_equivalent:
        row["layer"] = "apk_baseline_effective_equivalent_row_subset"
        row["full_table_complete"] = False
    if proof:
        row["proof"] = proof
    return row


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk-root", required=True, type=Path)
    parser.add_argument("--writable-root", type=Path, default=None)
    parser.add_argument("--output", type=Path, default=Path("data/game_data_catalog.json"))
    parser.add_argument("--metadata-dir", type=Path, default=Path("data"))
    parser.add_argument(
        "--scope",
        choices=("full", "current-implemented"),
        default="full",
        help="Pass32.6 ships current-implemented; full requires a complete effective source tree.",
    )
    parser.add_argument(
        "--verified-no-override",
        action="append",
        default=[],
        metavar="RELATIVE_PATH",
        help="Canonical audit proves this APK file is the effective source because no writable override exists.",
    )
    parser.add_argument(
        "--verified-additive-item-override-ids",
        default="",
        help="Comma-separated item IDs canonically proven to be the only writable additions; used only for filtered current scope.",
    )
    args = parser.parse_args()

    resolver = EffectiveSourceResolver(args.apk_root, args.writable_root)
    relatives = {
        "item": "data/tables/item.lua",
        "partner": "data/tables/partner.lua",
        "super_partner": "data/tables/super_partner.lua",
        "pet": "data/tables/pet.lua",
        "campaign": "data/tables/campaign.lua",
        "mission": "data/tables/mission.lua",
        "function": "data/tables/function.lua",
        "dropbox": "data/tables/dropbox.lua",
        "model": "data/tables/model.lua",
        "skill_price": "data/tables/skill_price.lua",
    }
    current_names = {"item", "partner", "super_partner", "campaign", "mission", "function", "skill_price"}
    names_to_resolve = set(relatives) if args.scope == "full" else current_names
    resolved: dict[str, ResolvedSource] = {
        name: resolver.resolve(relatives[name]) for name in sorted(names_to_resolve)
    }

    verified_no_override = {str(value).replace("\\", "/").lstrip("/") for value in args.verified_no_override}
    additive_item_ids = {
        _int(value)
        for value in str(args.verified_additive_item_override_ids or "").split(",")
        if _int(value) > 0
    }

    if args.writable_root is None:
        unresolved = {
            source.relative_path
            for name, source in resolved.items()
            if name != "item" and source.relative_path not in verified_no_override
        }
        if unresolved:
            raise ValueError(
                "cannot stamp effective_merged from APK-only input without canonical no-override proof: "
                + ", ".join(sorted(unresolved))
            )
        if args.scope == "full" and resolved["item"].relative_path not in verified_no_override:
            raise ValueError("full catalog requires effective item.lua or explicit no-override proof")
        if args.scope == "current-implemented" and not additive_item_ids and resolved["item"].relative_path not in verified_no_override:
            raise ValueError("current catalog requires effective item.lua or a verified additive item override set")

    item_rows = _item_rows(resolved["item"].path)
    partner_rows = _wrapped_lua_rows(
        resolved["partner"].path,
        ["name", "stone_id", "awaken_table_id", "first_table_id", "ini_star", "modelid", "modelids"],
    )
    super_rows = _wrapped_lua_rows(
        resolved["super_partner"].path,
        ["name", "stone_id", "awaken_table_id", "first_table_id", "ini_star", "modelid", "modelids"],
    )
    for rows in (partner_rows, super_rows):
        for row in rows.values():
            row["star"] = _int(row.get("ini_star"))
    campaign_rows = _flat_rows(
        resolved["campaign"].path,
        "campaign_id",
        [
            "campaign_type", "chapter", "energy_cost", "open_lv", "mana_gain",
            "relate_campaign_id", "last_campaign_id", "next_campaign_id", "star_gift",
            "first_display", "first_number", "story_drop_partner", "init_dropbox", "dropbox",
            "partner_exp", "sweep_reward", "sweep_reward_num",
        ],
        key_name="campaign_id",
    )
    function_rows = _function_rows(resolved["function"].path)
    mission_rows = _flat_rows(
        resolved["mission"].path,
        "id",
        [
            "type", "new_type", "task_req", "task_num", "task_id", "next_task_id",
            "money", "money_new", "diamond", "diamond_new", "exp", "exp_new",
            "award_id", "award_id_new", "num", "num_new", "display", "go_id",
        ],
        key_name="id",
    )
    skill_price_rows = _skill_price_rows(resolved["skill_price"].path)

    if args.scope == "current-implemented":
        selected_item_ids = _current_reward_item_ids(args.metadata_dir)
        overlap = selected_item_ids & additive_item_ids
        if overlap and resolved["item"].layer == "apk_baseline":
            raise ValueError(
                "filtered current catalog intersects writable-only item additions: "
                + ", ".join(str(value) for value in sorted(overlap))
            )
        missing = selected_item_ids - {_int(key) for key in item_rows}
        if missing:
            raise ValueError("current reward item IDs missing from resolved item.lua: " + repr(sorted(missing)))
        item_rows = {str(table_id): item_rows[str(table_id)] for table_id in sorted(selected_item_ids)}
        # Mission implementation is deliberately restricted to Story80001.
        mission_rows = {"80001": mission_rows["80001"]} if "80001" in mission_rows else {}
        namespaces = {
            "item": item_rows,
            "partner": partner_rows,
            "super_partner": super_rows,
            "pet": {},
            "campaign": campaign_rows,
            "mission": mission_rows,
            "function": function_rows,
            "dropbox": {},
            "model": {},
            "skill_price": skill_price_rows,
        }
    else:
        namespaces = {
            "item": item_rows,
            "partner": partner_rows,
            "super_partner": super_rows,
            "pet": _wrapped_lua_rows(
                resolved["pet"].path,
                ["name", "stone_id", "awaken_table_id", "first_table_id", "ini_star", "modelid", "modelids"],
            ),
            "campaign": campaign_rows,
            "mission": mission_rows,
            "function": function_rows,
            "dropbox": _dropbox_rows(resolved["dropbox"].path),
            "model": _flat_rows(
                resolved["model"].path,
                "id",
                ["name", "skin_id", "partner_id", "card", "campaign_card", "small_card", "s_card"],
                key_name="id",
            ),
            "skill_price": skill_price_rows,
        }

    source_files: dict[str, dict[str, Any]] = {}
    for name, source in resolved.items():
        if name == "item" and args.scope == "current-implemented" and source.layer == "apk_baseline" and additive_item_ids:
            source_files[source.relative_path] = _provenance_row(
                source,
                verified_no_override=False,
                row_subset_equivalent=True,
                proof=(
                    "Pass28/Pass32 canonical audit: writable item.lua only adds IDs "
                    + ",".join(str(value) for value in sorted(additive_item_ids))
                    + "; the current implemented reward-item subset excludes those additions."
                ),
            )
        else:
            source_files[source.relative_path] = _provenance_row(
                source,
                verified_no_override=source.relative_path in verified_no_override,
            )

    payload = {
        "_meta": {
            "schema_version": 1,
            "format": "GXB Pass32.6 typed game-data catalog",
            "scope": args.scope.replace("-", "_"),
            "source_resolution": resolver.SOURCE_RESOLUTION,
            "source_precedence": resolver.SOURCE_PRECEDENCE,
            "source_files": source_files,
            "coverage": {name: len(rows) for name, rows in namespaces.items()},
            "policy": [
                "runtime handlers do not read raw Lua",
                "numeric IDs are table/context scoped; no global type_of_id exists",
                "asset paths and decimal prefixes are diagnostics only",
                "skill_price is a typed config namespace added for source-backed MID39 pricing",
                "Pass32.6 current scope catalogs only content consumed by implemented domains; deferred namespaces remain empty",
            ],
        },
        "namespaces": namespaces,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print("wrote", args.output)
    for name, rows in namespaces.items():
        print(f"  {name}: {len(rows)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
