#!/usr/bin/env python3
"""Build immutable MID241 Gift Opening source facts from effective src_64.

Pass138 foundation: this generator preserves recovered client/table facts and a
source-bounded capability partition.  It deliberately does not assign random
probability semantics; raw drop_rate/roll_type values are retained for Phase 3.
"""
from __future__ import annotations

import argparse
import base64
import csv
import hashlib
import io
import json
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

FIXED_SCALAR_FIELDS = (
    "crystal", "mana", "energy", "vip_exp", "arena_coin", "march_coin",
    "lucky_coin", "friendship_coin", "skin_fragment", "exp", "badge",
    "soul", "vip", "ex_badge", "tutor_coin", "skin_coin", "spirit_energy",
)
# Phase2's existing canonical owners can settle these source-observed fields.
# This is a capability boundary, not a probability or original-server rule.
PHASE2_SCALAR_MAP = {
    "crystal": "crystal",
    "mana": "mana",
    "skin_fragment": "skin_fragment",
    "skin_coin": "skin_coin",
    "exp": "player_exp",
}


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _int(value: Any, default: int = 0) -> int:
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return default


def _pipe_ints(value: Any) -> list[int]:
    out: list[int] = []
    for part in str(value or "").split("|"):
        part = part.strip()
        if not part:
            continue
        number = _int(part, 0)
        if number != 0:
            out.append(number)
    return out


def _parse_lua_rows(path: Path) -> list[dict[str, str]]:
    text = path.read_text(encoding="utf-8-sig")
    key_match = re.search(r"keys\s*=\s*\{(.*?)\}\s*,\s*rows\s*=", text, re.S)
    row_match = re.search(r"rows\s*=\s*\{(.*)\}\s*\}\s*$", text, re.S)
    if not key_match or not row_match:
        raise RuntimeError(f"cannot parse Lua table {path}")
    keys = re.findall(r'"([^"]*)"', key_match.group(1))
    chunks = re.findall(
        r'\{\s*((?:"(?:[^"\\]|\\.)*"\s*,?\s*)+)\}',
        row_match.group(1), re.S,
    )
    rows: list[dict[str, str]] = []
    for chunk in chunks:
        values = re.findall(r'"((?:[^"\\]|\\.)*)"', chunk)
        if len(values) == len(keys):
            rows.append(dict(zip(keys, values)))
    return rows


def _parse_item(path: Path) -> list[dict[str, str]]:
    raw = path.read_text(encoding="utf-8-sig")
    match = re.match(r'\s*return\s+"(.*)"\s*$', raw, re.S)
    if not match:
        raise RuntimeError(f"cannot decode item table {path}")
    decoded = base64.b64decode(match.group(1)).decode("utf-8")
    lines = decoded.splitlines()
    if len(lines) < 3:
        raise RuntimeError("decoded item table is unexpectedly short")
    # First decoded line is human-readable headings; second is machine columns.
    return [
        row
        for row in csv.DictReader(io.StringIO("\n".join(lines[1:])), delimiter="\t")
        if row.get("id")
    ]


def _special_sx_ids(backpack_window: Path) -> list[int]:
    text = backpack_window.read_text(encoding="utf-8-sig")
    marker = 'openWindow("select_sx"'
    marker_pos = text.find(marker)
    if marker_pos < 0:
        raise RuntimeError("BackpackWindow select_sx route not found")
    prefix = text[max(0, marker_pos - 1200):marker_pos]
    ids = [int(v) for v in re.findall(r"itemID\s*==\s*(500\d+)", prefix)]
    # Keep source occurrence order while deduplicating syntax repeats.
    ordered = list(dict.fromkeys(ids))
    if not ordered:
        raise RuntimeError("BackpackWindow select_sx item ids not recovered")
    return ordered


def _route(item_id: int, item_row: dict[str, str], *, sx: set[int], select: set[int]) -> tuple[str, bool, list[int]]:
    gifts = _pipe_ints(item_row.get("gifts"))
    one_in_more = _pipe_ints(item_row.get("one_in_more"))
    if item_id in sx:
        return "SPECIAL_SX_SELECT", False, gifts
    if one_in_more:
        return "ONE_IN_MORE_SELECT", False, gifts
    if item_id in select:
        return "SELECT_EQUIP", True, gifts
    return "AUTO_FIRST_GIFT", True, gifts[:1]


def build(src64: Path) -> dict[str, Any]:
    tables = src64 / "data/tables"
    item_path = tables / "item.lua"
    gift_path = tables / "gift.lua"
    dropbox_path = tables / "dropbox.lua"
    misc_path = tables / "misc.lua"
    backpack_path = src64 / "app/windows/BackpackWindow.lua"
    route_windows = {
        "GiftbagUseWindow.lua": src64 / "app/windows/GiftbagUseWindow.lua",
        "SelectEquipWindow.lua": src64 / "app/windows/SelectEquipWindow.lua",
        "SelectSXHeroWindow.lua": src64 / "app/windows/SelectSXHeroWindow.lua",
        "ExchangeCodeHeroReward.lua": src64 / "app/windows/ExchangeCodeHeroReward.lua",
    }
    for path in [item_path, gift_path, dropbox_path, misc_path, backpack_path, *route_windows.values()]:
        if not path.is_file():
            raise RuntimeError(f"required effective source missing: {path}")

    item_rows = _parse_item(item_path)
    gift_rows = _parse_lua_rows(gift_path)
    dropbox_rows = _parse_lua_rows(dropbox_path)
    misc_rows = _parse_lua_rows(misc_path)
    item_by_id = {int(row["id"]): row for row in item_rows if str(row.get("id", "")).isdigit()}
    gift_by_id = {_int(row.get("id")): row for row in gift_rows if _int(row.get("id")) > 0}
    pools: dict[int, list[dict[str, str]]] = defaultdict(list)
    for row in dropbox_rows:
        pool_id = _int(row.get("dropbox_id"))
        if pool_id > 0:
            pools[pool_id].append(row)
    misc_by_key = {str(row.get("key") or ""): str(row.get("value") or "") for row in misc_rows}
    select_ids = set(_pipe_ints(misc_by_key.get("select_equip_gift_ids")))
    sx_ids = set(_special_sx_ids(backpack_path))

    operations: list[dict[str, Any]] = []
    capability_counts: Counter[str] = Counter()
    route_counts: Counter[str] = Counter()
    status_counts: Counter[str] = Counter()

    for item_id in sorted(item_by_id):
        item_row = item_by_id[item_id]
        source_gifts = _pipe_ints(item_row.get("gifts"))
        if not source_gifts:
            continue
        route, supports_num, effective_gifts = _route(item_id, item_row, sx=sx_ids, select=select_ids)
        for gift_id in effective_gifts:
            gift_row = gift_by_id.get(gift_id)
            operation: dict[str, Any] = {
                "item_id": item_id,
                "gift_id": gift_id,
                "item_name": str(item_row.get("name") or ""),
                "item_desc": str(item_row.get("desc1") or ""),
                "route": route,
                "supports_num": supports_num,
                "source_item_gifts": source_gifts,
                "source_one_in_more": _pipe_ints(item_row.get("one_in_more")),
            }
            route_counts[route] += 1
            if gift_row is None:
                operation.update({
                    "status": "MISSING_GIFT",
                    "capability": "MISSING_GIFT_SOURCE",
                    "capability_epistemic_class": "SOURCE_FACT",
                    "raw_items": [],
                    "raw_item_nums": [],
                    "fixed_items": [],
                    "fixed_scalars": {},
                    "raw_equip": "",
                    "drop_occurrences": [],
                })
                capability_counts["MISSING_GIFT_SOURCE"] += 1
                status_counts["MISSING_GIFT"] += 1
                operations.append(operation)
                continue

            raw_items = _pipe_ints(gift_row.get("items"))
            raw_item_nums = _pipe_ints(gift_row.get("item_nums"))
            fixed_items = [
                {"item_id": iid, "item_num": num, "ordinal": ordinal}
                for ordinal, (iid, num) in enumerate(zip(raw_items, raw_item_nums))
            ]
            fixed_scalars = {
                field: _int(gift_row.get(field))
                for field in FIXED_SCALAR_FIELDS
                if _int(gift_row.get(field)) != 0
            }
            raw_equip = str(gift_row.get("equip") or "").strip()
            drop_ids = _pipe_ints(gift_row.get("drops"))
            drop_occurrences: list[dict[str, Any]] = []
            candidate_types: set[int] = set()
            missing_candidate_defs: set[int] = set()
            missing_dropboxes: list[int] = []
            for ordinal, pool_id in enumerate(drop_ids):
                source_rows = pools.get(pool_id, [])
                if not source_rows:
                    missing_dropboxes.append(pool_id)
                candidates: list[dict[str, Any]] = []
                for source_ordinal, drop_row in enumerate(source_rows):
                    candidate_item_id = _int(drop_row.get("item_id"))
                    candidate_item = item_by_id.get(candidate_item_id)
                    item_type = _int(candidate_item.get("type")) if candidate_item is not None else None
                    if item_type is None:
                        missing_candidate_defs.add(candidate_item_id)
                    else:
                        candidate_types.add(item_type)
                    candidates.append({
                        "source_ordinal": source_ordinal,
                        "row_id": _int(drop_row.get("id")),
                        "item_id": candidate_item_id,
                        "item_num": _int(drop_row.get("item_num")),
                        "drop_rate": _int(drop_row.get("drop_rate")),
                        "roll_type": _int(drop_row.get("roll_type")),
                        "item_type": item_type,
                        "item_name": str(candidate_item.get("name") or "") if candidate_item else None,
                    })
                drop_occurrences.append({
                    "ordinal": ordinal,
                    "dropbox_id": pool_id,
                    "missing_source": not bool(source_rows),
                    "candidates": candidates,
                })

            fixed_item_types: list[int | None] = []
            missing_fixed_item_defs: list[int] = []
            for fixed_id in raw_items:
                source_item = item_by_id.get(fixed_id)
                if source_item is None:
                    fixed_item_types.append(None)
                    missing_fixed_item_defs.append(fixed_id)
                else:
                    fixed_item_types.append(_int(source_item.get("type")))

            if drop_ids:
                status = "RANDOM"
                if missing_dropboxes:
                    capability = "MISSING_DROPBOX_SOURCE"
                elif 24 in candidate_types and missing_candidate_defs:
                    capability = "HUNQI_WITH_MISSING_ITEM_DEFS"
                elif 24 in candidate_types:
                    capability = "GENERATED_HUNQI_DEPENDENCY"
                elif -1 in candidate_types:
                    capability = "HERO_ENTITY_DEPENDENCY"
                elif missing_candidate_defs:
                    capability = "MISSING_CANDIDATE_ITEM_SOURCE"
                else:
                    capability = "ORDINARY_RANDOM_CURRENT_OWNERS"
            else:
                status = "DETERMINISTIC"
                if raw_equip not in {"", "0"}:
                    capability = "SOURCE_INCOMPLETE_EQUIP_FIELD"
                elif -1 in fixed_item_types:
                    capability = "HERO_ENTITY"
                elif 24 in fixed_item_types:
                    capability = "GENERATED_HUNQI_DEPENDENCY"
                elif missing_fixed_item_defs:
                    capability = "MISSING_FIXED_ITEM_SOURCE"
                elif len(raw_items) != len(raw_item_nums):
                    capability = "SOURCE_INCOMPLETE_ITEM_QUANTITY"
                elif "spirit_energy" in fixed_scalars:
                    capability = "TEMPORAL_SPIRIT_ENERGY_GAP"
                elif any(field not in PHASE2_SCALAR_MAP for field in fixed_scalars):
                    capability = "UNSUPPORTED_SCALAR_OWNER"
                elif fixed_items or fixed_scalars:
                    capability = "ORDINARY_CURRENT_OWNERS"
                else:
                    capability = "SOURCE_INCOMPLETE_EMPTY_GIFT"

            operation.update({
                "status": status,
                "capability": capability,
                "capability_epistemic_class": "IMPLEMENTATION_COMPATIBILITY_DECISION",
                "raw_items": raw_items,
                "raw_item_nums": raw_item_nums,
                "fixed_items": fixed_items,
                "fixed_scalars": fixed_scalars,
                "raw_equip": raw_equip,
                "drop_occurrences": drop_occurrences,
                "missing_dropbox_ids": missing_dropboxes,
                "candidate_item_types": sorted(candidate_types),
                "missing_candidate_item_defs": sorted(missing_candidate_defs),
                "fixed_item_types": fixed_item_types,
                "missing_fixed_item_defs": sorted(set(missing_fixed_item_defs)),
            })
            capability_counts[capability] += 1
            status_counts[status] += 1
            operations.append(operation)

    ordinary = [op for op in operations if op["capability"] == "ORDINARY_CURRENT_OWNERS"]
    ordinary_random = [op for op in operations if op["capability"] == "ORDINARY_RANDOM_CURRENT_OWNERS"]
    generated_hunqi_deterministic = [
        op for op in operations
        if op["status"] == "DETERMINISTIC" and op["capability"] == "GENERATED_HUNQI_DEPENDENCY"
    ]
    equip_gap = [op for op in operations if op["capability"] == "SOURCE_INCOMPLETE_EQUIP_FIELD"]

    source_files = {
        "data/tables/item.lua": item_path,
        "data/tables/gift.lua": gift_path,
        "data/tables/dropbox.lua": dropbox_path,
        "data/tables/misc.lua": misc_path,
        "app/windows/BackpackWindow.lua": backpack_path,
        **{f"app/windows/{name}": path for name, path in route_windows.items()},
    }
    return {
        "schema_version": 1,
        "_meta": {
            "pass": "138.0",
            "purpose": "MID241 Gift Opening immutable source facts and capability partition",
            "source_resolution": "effective_src64",
            "probability_semantics": "NONE_RAW_METADATA_ONLY",
            "epistemic_note": (
                "Table/client fields are SOURCE_FACT. capability values are explicit "
                "IMPLEMENTATION_COMPATIBILITY_DECISION gates; they are not recovered original-server behavior."
            ),
            "source_hashes": {name: _sha256(path) for name, path in source_files.items()},
            "special_sx_item_ids": sorted(sx_ids),
            "select_equip_item_ids": sorted(select_ids),
            "phase2_scalar_map": dict(PHASE2_SCALAR_MAP),
        },
        "summary": {
            "effective_operation_count_including_missing_gift_source": len(operations),
            "status_counts": dict(sorted(status_counts.items())),
            "capability_counts": dict(sorted(capability_counts.items())),
            "route_counts": dict(sorted(route_counts.items())),
            "phase2_deterministic_ordinary_operation_count": len(ordinary),
            "phase2_deterministic_ordinary_source_item_count": len({op["item_id"] for op in ordinary}),
            "phase3_ordinary_random_operation_count": len(ordinary_random),
            "phase3_ordinary_random_source_item_count": len({op["item_id"] for op in ordinary_random}),
            "pass136_supersession": {
                "previous_phase2_ordinary_operation_count": 1637,
                "previous_phase2_ordinary_source_item_count": 583,
                "unmodeled_raw_gift_equip_operations": len(equip_gap),
                "deterministic_generated_hunqi_operations": len(generated_hunqi_deterministic),
                "corrected_phase2_ordinary_operation_count": len(ordinary),
                "corrected_phase2_ordinary_source_item_count": len({op["item_id"] for op in ordinary}),
            },
        },
        "operations": operations,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--src64", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    catalog = build(args.src64)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps(catalog["summary"], indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
