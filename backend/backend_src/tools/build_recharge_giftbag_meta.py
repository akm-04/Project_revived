#!/usr/bin/env python3
"""Build source-bounded Recharge giftbag metadata from effective src_64.

Pass149/B1-B2: source facts only. EOL visibility/capability decisions are stored
as explicit classifications and interpreted by the runtime catalog/policy.
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


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def as_int(value, default=0):
    try:
        return int(str(value).strip() or default)
    except (TypeError, ValueError):
        return default


def parse_encoded_tsv(path: Path) -> list[dict[str, str]]:
    source = path.read_text(encoding="utf-8-sig")
    match = re.search(r'return\s+"([A-Za-z0-9+/=]+)"', source, re.S)
    if not match:
        raise RuntimeError(f"no base64 payload in {path}")
    decoded = base64.b64decode(match.group(1)).decode("utf-8")
    lines = decoded.splitlines()
    if len(lines) >= 2 and lines[1].split("\t", 1)[0] == "id":
        decoded = "\n".join(lines[1:])
    return list(csv.DictReader(io.StringIO(decoded), delimiter="\t"))


def parse_lua_rows(path: Path) -> list[dict[str, str]]:
    source = path.read_text(encoding="utf-8-sig")
    key_pos = source.find("keys")
    row_pos = source.find("rows", key_pos)
    if key_pos < 0 or row_pos < 0:
        raise RuntimeError(f"unrecognized Lua table shape: {path}")
    keys = re.findall(r'"((?:\\.|[^"\\])*)"', source[key_pos:row_pos])
    text = source[source.find("{", row_pos):]
    rows: list[dict[str, str]] = []
    depth = 0
    in_quote = False
    escaped = False
    start = None
    for idx, char in enumerate(text):
        if in_quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_quote = False
            continue
        if char == '"':
            in_quote = True
            continue
        if char == "{":
            depth += 1
            if depth == 2:
                start = idx
        elif char == "}":
            if depth == 2 and start is not None:
                values = re.findall(r'"((?:\\.|[^"\\])*)"', text[start:idx + 1])
                if len(values) == len(keys):
                    rows.append(dict(zip(keys, values)))
                start = None
            depth -= 1
            if depth == 0:
                break
    return rows


def split_ints(value: str) -> list[int]:
    return [as_int(part) for part in str(value or "").split("|") if part and part != "0"]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--src64", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    src = args.src64
    giftbag_path = src / "data/tables/giftbag.lua"
    gift_path = src / "data/tables/gift.lua"
    item_path = src / "data/tables/item.lua"
    dropbox_path = src / "data/tables/dropbox.lua"
    giftbags = parse_lua_rows(giftbag_path)
    gifts = {as_int(row.get("id")): row for row in parse_lua_rows(gift_path)}
    items = {as_int(row.get("id")): row for row in parse_encoded_tsv(item_path)}
    dropbox_rows = parse_lua_rows(dropbox_path)
    dropboxes: dict[int, list[dict[str, str]]] = {}
    for drop_row in dropbox_rows:
        dropboxes.setdefault(as_int(drop_row.get("dropbox_id")), []).append(drop_row)

    scalar_fields = (
        "crystal", "mana", "energy", "vip_exp", "arena_coin", "march_coin",
        "lucky_coin", "friendship_coin", "skin_fragment", "exp", "badge",
        "soul", "vip", "ex_badge", "tutor_coin", "skin_coin", "spirit_energy",
    )
    products = []
    counts = {"page2": 0, "source_complete": 0, "missing_gift": 0,
              "fixed_nonhero": 0, "direct_hero": 0, "random": 0}
    for row in giftbags:
        if as_int(row.get("page")) != 2:
            continue
        counts["page2"] += 1
        charge_id = as_int(row.get("charge_id"))
        gift_id = as_int(row.get("gift_id"))
        gift = gifts.get(gift_id)
        item_rewards: list[dict[str, int]] = []
        scalars: dict[str, int] = {}
        drops: list[int] = []
        drop_occurrences: list[dict[str, object]] = []
        classification = "SOURCE_INCOMPLETE_MISSING_GIFT"
        capability = "FAIL_CLOSED_MISSING_GIFT"
        if gift is None:
            counts["missing_gift"] += 1
        else:
            counts["source_complete"] += 1
            item_ids = split_ints(gift.get("items", ""))
            item_nums = split_ints(gift.get("item_nums", ""))
            if len(item_ids) != len(item_nums):
                raise RuntimeError(f"gift {gift_id} item/item_nums length mismatch")
            item_types = []
            for item_id, item_num in zip(item_ids, item_nums):
                item_row = items.get(item_id)
                if item_row is None:
                    raise RuntimeError(f"gift {gift_id} references unknown item {item_id}")
                item_type = as_int(item_row.get("type"))
                item_types.append(item_type)
                item_rewards.append({"item_id": item_id, "item_num": item_num, "item_type": item_type})
            for field in scalar_fields:
                amount = as_int(gift.get(field))
                if amount:
                    scalars[field] = amount
            drops = split_ints(gift.get("drops", ""))
            for occurrence_index, dropbox_id in enumerate(drops):
                candidates = []
                source_rows = dropboxes.get(dropbox_id, [])
                for source_index, drop_row in enumerate(source_rows):
                    candidate_item_id = as_int(drop_row.get("item_id"))
                    candidate_item = items.get(candidate_item_id)
                    if candidate_item is None:
                        raise RuntimeError(f"dropbox {dropbox_id} references unknown item {candidate_item_id}")
                    candidates.append({
                        "source_index": source_index,
                        "row_id": as_int(drop_row.get("id")),
                        "item_id": candidate_item_id,
                        "item_num": as_int(drop_row.get("item_num")),
                        "item_type": as_int(candidate_item.get("type")),
                        "drop_rate": as_int(drop_row.get("drop_rate")),
                        "roll_type": as_int(drop_row.get("roll_type")),
                    })
                drop_occurrences.append({
                    "occurrence_index": occurrence_index,
                    "dropbox_id": dropbox_id,
                    "candidates": candidates,
                })
            if any(item_type == -1 for item_type in item_types):
                classification = "DIRECT_HERO_ENTITY"
                capability = "DEFER_GENERATED_UNIQUE"
                counts["direct_hero"] += 1
            elif drops:
                classification = "RANDOM_DROP_GIFT"
                capability = "B3_RANDOM_NONHERO"
                counts["random"] += 1
            else:
                classification = "FIXED_ITEM_SCALAR"
                capability = "B2_FIXED_NONHERO"
                counts["fixed_nonhero"] += 1

        products.append({
            "charge_id": charge_id,
            "gift_id": gift_id,
            "name": str(row.get("name") or ""),
            "name_new": str(row.get("name_new") or ""),
            "page": 2,
            "type": as_int(row.get("type")),
            "charge": float(row.get("charge") or 0),
            "original_charge": float(row.get("original_charge") or 0),
            "diamond": as_int(row.get("diamond")),
            "condition": str(row.get("condition") or ""),
            "start": as_int(row.get("start")),
            "time": as_int(row.get("time")),
            "is_buy_remove": as_int(row.get("is_buy_remove")),
            "require_charge": as_int(row.get("require_charge")),
            "next_charge": as_int(row.get("next_charge")),
            "total_value": as_int(row.get("total_value")),
            "is_open": as_int(row.get("is_open")),
            "seque": as_int(row.get("seque")),
            "display_time": as_int(row.get("display_time")),
            "time_limited": str(row.get("time_limited") or ""),
            "classification": classification,
            "capability": capability,
            "items": item_rewards,
            "scalars": scalars,
            "drops": drops,
            "drop_occurrences": drop_occurrences,
        })

    expected = {"page2": 284, "source_complete": 269, "missing_gift": 15,
                "fixed_nonhero": 265, "direct_hero": 3, "random": 1}
    if counts != expected:
        raise RuntimeError(f"Recharge page2 census drift: {counts} != {expected}")

    payload = {
        "schema_version": 1,
        "_meta": {
            "pass": "150.0",
            "source_resolution": "effective_src64",
            "giftbag_source": "data/tables/giftbag.lua",
            "gift_source": "data/tables/gift.lua",
            "item_source": "data/tables/item.lua",
            "dropbox_source": "data/tables/dropbox.lua",
            "source_hashes": {
                "data/tables/giftbag.lua": sha256(giftbag_path),
                "data/tables/gift.lua": sha256(gift_path),
                "data/tables/item.lua": sha256(item_path),
                "data/tables/dropbox.lua": sha256(dropbox_path),
            },
            "epistemic_note": "Rows/rewards are SOURCE_FACT. capability and EOL visibility are explicit compatibility gates.",
            "eol_visibility_policy": "ignore historical condition/start/time; reactivate source-complete is_open=1; preserve one-shot/repeatable and require_charge chains",
        },
        "summary": counts,
        "products": products,
    }
    args.output.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(args.output), "summary": counts}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
