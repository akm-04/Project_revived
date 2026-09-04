#!/usr/bin/env python3
"""Build Pass241 immutable Emblem/Inscription source catalog from effective src_64.

Only current-client facts belong here. Unrecovered original-server policy lives in
``emblem_policy_v1.json`` and must never be written into this catalog.
"""
from __future__ import annotations

import argparse
import base64
import csv
import hashlib
import io
import json
import re
from pathlib import Path
from typing import Any

SCHEMA_VERSION = 1
SOURCE_ARCHIVE_SHA256 = "c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf"
EXPECTED_FORGE_ROWS = 23
EXPECTED_ORDINARY_ROWS = 21
EXPECTED_CONCRETE_ITEMS = 254
EXPECTED_ORDINARY_CANDIDATES = 210
EXPECTED_SCHOLARSHIP_ITEMS = 30
EXPECTED_ORPHANS = 14
EXPECTED_SETS = 12
EXPECTED_DYNAMIC_SET_POSITIONS = 30


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _decode_lua_string(raw: str) -> str:
    return bytes(raw, "utf-8").decode("unicode_escape") if "\\" in raw else raw


def _parse_lua_table(path: Path) -> list[dict[str, str]]:
    text = path.read_text(encoding="utf-8-sig")
    keys_match = re.search(r"keys\s*=\s*\{(.*?)\}\s*,?\s*rows\s*=", text, re.S)
    rows_match = re.search(r"rows\s*=\s*\{(.*)\}\s*\}\s*$", text, re.S)
    if not keys_match or not rows_match:
        raise ValueError(f"unsupported Lua table shape: {path}")
    keys = [_decode_lua_string(v) for v in re.findall(r'"((?:\\.|[^"\\])*)"', keys_match.group(1))]
    body = rows_match.group(1)
    rows: list[dict[str, str]] = []
    depth = 0
    start: int | None = None
    quoted = False
    escaped = False
    for index, char in enumerate(body):
        if quoted:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                quoted = False
            continue
        if char == '"':
            quoted = True
        elif char == "{":
            if depth == 0:
                start = index + 1
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0 and start is not None:
                values = [_decode_lua_string(v) for v in re.findall(r'"((?:\\.|[^"\\])*)"', body[start:index])]
                if len(values) != len(keys):
                    raise ValueError(f"row width drift in {path}: {len(values)} != {len(keys)}")
                rows.append(dict(zip(keys, values)))
                start = None
    return rows


def _parse_item_table(path: Path) -> dict[int, dict[str, str]]:
    text = path.read_text(encoding="utf-8-sig")
    match = re.search(r'return\s+"([A-Za-z0-9+/=]+)"', text, re.S)
    if not match:
        raise ValueError(f"encoded item table payload missing: {path}")
    decoded = base64.b64decode(match.group(1)).decode("utf-8")
    rows = list(csv.reader(io.StringIO(decoded), delimiter="\t"))
    if len(rows) < 3:
        raise ValueError("item.lua decoded table is incomplete")
    keys = rows[1]
    out: dict[int, dict[str, str]] = {}
    for values in rows[2:]:
        if not values or not values[0]:
            continue
        if len(values) < len(keys):
            values = values + [""] * (len(keys) - len(values))
        try:
            item_id = int(values[0])
        except ValueError:
            continue
        out[item_id] = dict(zip(keys, values))
    return out


def _int(value: Any, default: int = 0) -> int:
    try:
        return int(float(str(value or "0")))
    except (TypeError, ValueError):
        return default


def _number(value: Any) -> int | float:
    try:
        number = float(str(value or "0"))
    except (TypeError, ValueError):
        return 0
    return int(number) if number.is_integer() else number


def _pipe_ints(value: Any) -> list[int]:
    return [_int(part) for part in str(value or "").split("|") if str(part).strip()]


def _pipe_numbers(value: Any) -> list[int | float]:
    return [_number(part) for part in str(value or "").split("|") if str(part).strip()]


def build(src64: Path) -> dict[str, Any]:
    source_files = [
        "data/tables/item.lua",
        "data/tables/inscription.lua",
        "data/tables/inscription_pos.lua",
        "data/tables/inscription_rate.lua",
        "data/tables/inscription_suit.lua",
        "data/tables/misc.lua",
        "data/tables/function.lua",
        "app/model/Inscription.lua",
        "app/common/tables/InscriptionTable.lua",
        "app/common/tables/InscriptionSuitTable.lua",
        "app/model/NormalHero.lua",
        "app/model/SuperHero.lua",
        "app/windows/InscriptionWindow.lua",
        "app/windows/InscriptionTenTimesWindow.lua",
    ]
    paths = {name: src64 / name for name in source_files}
    missing = [name for name, path in paths.items() if not path.is_file()]
    if missing:
        raise FileNotFoundError(f"required effective Emblem source missing: {missing}")

    items = _parse_item_table(paths["data/tables/item.lua"])
    inscriptions_raw = _parse_lua_table(paths["data/tables/inscription.lua"])
    positions_raw = _parse_lua_table(paths["data/tables/inscription_pos.lua"])
    rates_raw = _parse_lua_table(paths["data/tables/inscription_rate.lua"])
    suits_raw = _parse_lua_table(paths["data/tables/inscription_suit.lua"])
    misc_raw = _parse_lua_table(paths["data/tables/misc.lua"])
    functions_raw = _parse_lua_table(paths["data/tables/function.lua"])

    misc = {str(row.get("key") or ""): str(row.get("value") or "") for row in misc_raw}
    function45 = next((row for row in functions_raw if row.get("id") == "45"), None)
    if not function45 or function45.get("level") != "7|100":
        raise ValueError("Function45 source gate drift")

    positions: dict[int, int] = {}
    for row in positions_raw:
        slot = _int(row.get("inscript_type"))
        for item_id in _pipe_ints(row.get("suit_items")):
            if item_id in positions:
                raise ValueError(f"duplicate Scholarship position mapping for {item_id}")
            positions[item_id] = slot
    if len(positions) != EXPECTED_DYNAMIC_SET_POSITIONS or set(positions.values()) != {1, 2, 3}:
        raise ValueError("Scholarship position source drift")

    inscriptions: dict[str, dict[str, Any]] = {}
    ordinary_candidate_ids: set[int] = set()
    scholarship_candidate_ids: set[int] = set()
    candidate_ids: set[int] = set()
    for raw in inscriptions_raw:
        row_id = _int(raw.get("id"))
        candidates = _pipe_ints(raw.get("item_id"))
        weights = [int(v) for v in _pipe_numbers(raw.get("rand"))]
        if len(candidates) != len(weights) or not candidates or any(weight < 0 for weight in weights):
            raise ValueError(f"invalid Emblem candidates/weights for {row_id}")
        special = _int(raw.get("special"))
        if special:
            scholarship_candidate_ids.update(candidates)
        else:
            ordinary_candidate_ids.update(candidates)
        candidate_ids.update(candidates)
        inscriptions[str(row_id)] = {
            "id": row_id,
            "name": str(raw.get("name") or ""),
            "level": _int(raw.get("level")),
            "item_type": _int(raw.get("item_type")),
            "item_pos": _int(raw.get("item_pos")),
            "special": special,
            "candidate_item_ids": candidates,
            "candidate_weights": weights,
            "compound_material": _int(raw.get("compound_material")),
            "compound_num": _int(raw.get("compound_num")),
            "compound_item": _int(raw.get("compound_item")),
            "compound_item_num": _int(raw.get("compound_item_num")),
            "resolve_material": _int(raw.get("resolve_material")),
            "resolve_num": _int(raw.get("resolve_num")),
            "change_gold": _int(raw.get("change_gold")),
            "change_crystal": _int(raw.get("change_crystal")),
            "fighting_capacity": _int(raw.get("fighting_capacity")),
        }

    emblem_items = {item_id: row for item_id, row in items.items() if row.get("type") == "16"}
    concrete_items: dict[str, dict[str, Any]] = {}
    for item_id, raw in sorted(emblem_items.items()):
        inscription_id = _int(raw.get("inscript_id"))
        inscription = inscriptions.get(str(inscription_id))
        if inscription is None:
            raise ValueError(f"Emblem item {item_id} references unknown inscription {inscription_id}")
        physical_position = int(inscription["item_pos"]) or positions.get(item_id, 0)
        if physical_position not in {1, 2, 3}:
            raise ValueError(f"Emblem item {item_id} has invalid physical position {physical_position}")
        if item_id in ordinary_candidate_ids:
            classification = "ORDINARY_FORGE_CANDIDATE"
        elif item_id in scholarship_candidate_ids:
            classification = "SCHOLARSHIP_SET_CANDIDATE"
        else:
            classification = "SOURCE_PRESENT_NON_FORGE_ORPHAN"
        concrete_items[str(item_id)] = {
            "item_id": item_id,
            "name": str(raw.get("name") or ""),
            "inscription_id": inscription_id,
            "physical_position": physical_position,
            "set_id": _int(raw.get("inscript_suit_id")),
            "classification": classification,
            "attr_id": _int(raw.get("attr_ids")),
            "attr_value": _number(raw.get("attr_values")),
            "attr_battle": _number(raw.get("attr_battle")),
            "quality": _int(raw.get("quality")),
            "auction_currency_type": _int(raw.get("auction_currency_type")),
            "auction_currency_value": _int(raw.get("auction_currency_value")),
        }

    suits: dict[str, dict[str, Any]] = {}
    for raw in suits_raw:
        suit_id = _int(raw.get("id"))
        piece_ids = _pipe_ints(raw.get("item_id"))
        if len(piece_ids) not in {2, 3}:
            raise ValueError(f"Emblem set {suit_id} size drift")
        if any(_int(concrete_items.get(str(item_id), {}).get("set_id")) != suit_id for item_id in piece_ids):
            raise ValueError(f"Emblem set {suit_id} concrete-item linkage drift")
        suits[str(suit_id)] = {
            "id": suit_id,
            "type": _int(raw.get("type")),
            "name": str(raw.get("name") or ""),
            "name_show": str(raw.get("name_show") or ""),
            "item_ids": piece_ids,
            "attr_ids": _pipe_ints(raw.get("attr")),
            "attr_values": _pipe_numbers(raw.get("attr_num")),
            "fighting_capacity": _int(raw.get("fighting_capacity")),
            "recommended_partner_ids": _pipe_ints(raw.get("recommend")),
        }

    rate_rows = [
        {
            "id": _int(row.get("id")),
            "rate_suit": _number(row.get("rate_suit")),
            "rate_step": _number(row.get("rate_step")),
            "max_num": _int(row.get("max_num")),
        }
        for row in rates_raw
    ]
    if rate_rows != [
        {"id": 1, "rate_suit": 0, "rate_step": 0.1, "max_num": 1000},
        {"id": 2, "rate_suit": 0, "rate_step": 1, "max_num": 100},
    ]:
        raise ValueError("inscription_rate source rows drift")

    star_items = _pipe_ints(misc.get("inscript_cost_items"))
    special_families = _pipe_ints(misc.get("inscript_drop_suit_id"))
    special_family_weights = _pipe_ints(misc.get("inscript_drop_suit_rate"))
    if star_items != [50001343, 50001344, 50001345]:
        raise ValueError("Emblem Star source items drift")
    if special_families != [40001, 50001] or special_family_weights != [70, 30]:
        raise ValueError("Scholarship family source vector drift")
    if _int(misc.get("drop_suit_inscript_lev")) != 7:
        raise ValueError("Scholarship source level drift")
    if _int(misc.get("remove_inscript_cost")) != 20:
        raise ValueError("Emblem remove/replace cost drift")

    heart = items.get(50001346) or {}
    heart_fragment = items.get(50001347) or {}
    heart_components = _pipe_ints(heart.get("compose"))
    heart_counts = _pipe_ints(heart.get("compose_num"))
    if heart_components != [50001347] or heart_counts != [60] or _int(heart.get("compose_mana")) != 0:
        raise ValueError("Heart of Medal composition source drift")

    counts = {
        "forge_rows": len(inscriptions),
        "ordinary_forge_rows": sum(1 for row in inscriptions.values() if not row["special"]),
        "special_family_rows": sum(1 for row in inscriptions.values() if row["special"]),
        "concrete_items": len(concrete_items),
        "ordinary_candidates": len(ordinary_candidate_ids),
        "scholarship_items": len(scholarship_candidate_ids),
        "non_forge_orphans": len(set(concrete_items) - {str(v) for v in candidate_ids}),
        "sets": len(suits),
        "dynamic_scholarship_positions": len(positions),
    }
    expected = {
        "forge_rows": EXPECTED_FORGE_ROWS,
        "ordinary_forge_rows": EXPECTED_ORDINARY_ROWS,
        "special_family_rows": 2,
        "concrete_items": EXPECTED_CONCRETE_ITEMS,
        "ordinary_candidates": EXPECTED_ORDINARY_CANDIDATES,
        "scholarship_items": EXPECTED_SCHOLARSHIP_ITEMS,
        "non_forge_orphans": EXPECTED_ORPHANS,
        "sets": EXPECTED_SETS,
        "dynamic_scholarship_positions": EXPECTED_DYNAMIC_SET_POSITIONS,
    }
    if counts != expected:
        raise ValueError(f"Emblem source census drift: {counts} != {expected}")

    return {
        "schema_version": SCHEMA_VERSION,
        "_meta": {
            "source_resolution": "effective_src64",
            "epistemic_class": "SOURCE_FACT_ONLY",
            "source_archive_sha256": SOURCE_ARCHIVE_SHA256,
            "effective_src64_root": "app-assets/output/assets/src_64",
            "source_files": source_files,
            "source_file_sha256": {name: _sha256(paths[name]) for name in source_files},
            "counts": counts,
        },
        "identity": {
            "frontend_name": "Emblem",
            "internal_name": "Inscription",
            "item_type": 16,
            "function_id": 45,
            "function_level": 100,
            "function_tip": str(function45.get("tip") or ""),
            "eligibility": "hero.isAwakeTwice() AND hero.level >= 100",
        },
        "rules": {
            "remove_replace_crystal": 20,
            "star_items": star_items,
            "star_exchange_per_item": 5,
            "heart_item": 50001346,
            "heart_fragment": 50001347,
            "heart_fragment_count": 60,
            "scholarship_level": 7,
            "scholarship_family_ids": special_families,
            "scholarship_family_weights": special_family_weights,
            "outer_scholarship_probability": "SERVER_UNKNOWN",
        },
        "rate_rows_uninterpreted": rate_rows,
        "inscriptions": inscriptions,
        "concrete_items": concrete_items,
        "sets": suits,
        "dynamic_scholarship_positions": {str(k): v for k, v in sorted(positions.items())},
        "exchange_materials": [
            {"item_id": 50001343, "resource_id": 19, "per_item": 5},
            {"item_id": 50001344, "resource_id": 20, "per_item": 5},
            {"item_id": 50001345, "resource_id": 21, "per_item": 5},
        ],
        "heart_recipe": {
            "item_id": 50001346,
            "components": [{"item_id": 50001347, "count": 60}],
            "mana": 0,
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--src64", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    payload = build(args.src64.resolve())
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(payload["_meta"]["counts"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
