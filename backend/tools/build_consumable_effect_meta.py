#!/usr/bin/env python3
"""Build Pass98 source-derived deterministic consumable metadata from item.lua.

The catalog preserves raw client-visible item effect columns but runtime consumers
must still select effects by the source operation/sub-type contract.  This avoids
interpreting every non-zero numeric column as a generic reward.
"""
from __future__ import annotations

import argparse
import base64
import csv
import hashlib
import io
import json
import re
from collections import Counter
from pathlib import Path
from typing import Any


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def as_int(value: Any, default: int = 0) -> int:
    try:
        return int(str(value).strip() or default)
    except (TypeError, ValueError):
        return default


def split_ints(value: Any) -> list[int]:
    text = str(value or "").strip()
    if not text:
        return []
    out: list[int] = []
    for part in text.split("|"):
        try:
            number = int(part.strip())
        except (TypeError, ValueError):
            continue
        if number > 0:
            out.append(number)
    return out


def decode_item_table(path: Path) -> tuple[list[str], list[list[str]]]:
    wrapped = path.read_text(encoding="utf-8-sig")
    match = re.search(r'return\s+"([A-Za-z0-9+/=]+)"', wrapped, re.S)
    if not match:
        raise ValueError(f"unrecognized encoded item table: {path}")
    decoded = base64.b64decode(match.group(1)).decode("utf-8")
    rows = list(csv.reader(io.StringIO(decoded), delimiter="\t"))
    if len(rows) < 3:
        raise ValueError("decoded item.lua TSV is empty")
    return rows[1], rows[2:]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    headers, rows = decode_item_table(args.source)
    index = {name: i for i, name in enumerate(headers) if name}
    required = (
        "id", "name", "type", "sub_type", "energy", "exp", "mana", "crystal",
        "skill_point", "magic_energy", "magic_dust", "magic_liquid", "spirit_energy",
        "giftbag_id", "gifts", "one_in_more",
    )
    missing = [key for key in required if key not in index]
    if missing:
        raise ValueError(f"item.lua missing columns: {missing}")

    items: dict[str, dict[str, Any]] = {}
    subtype_counts: Counter[int] = Counter()
    total_rows = 0
    for values in rows:
        if len(values) < len(headers):
            values += [""] * (len(headers) - len(values))
        item_id = as_int(values[index["id"]])
        if item_id <= 0:
            continue
        total_rows += 1
        item_type = as_int(values[index["type"]])
        if item_type != 4:  # xyd.ItemType.CONSUMABLES
            continue
        sub_type = as_int(values[index["sub_type"]])
        subtype_counts[sub_type] += 1
        items[str(item_id)] = {
            "item_id": item_id,
            "name": values[index["name"]],
            "type": item_type,
            "sub_type": sub_type,
            "energy": max(0, as_int(values[index["energy"]])),
            "exp": max(0, as_int(values[index["exp"]])),
            "mana": max(0, as_int(values[index["mana"]])),
            "crystal": max(0, as_int(values[index["crystal"]])),
            "skill_point": max(0, as_int(values[index["skill_point"]])),
            "magic_energy": max(0, as_int(values[index["magic_energy"]])),
            "magic_dust": max(0, as_int(values[index["magic_dust"]])),
            "magic_liquid": max(0, as_int(values[index["magic_liquid"]])),
            "spirit_energy": max(0, as_int(values[index["spirit_energy"]])),
            "giftbag_id": max(0, as_int(values[index["giftbag_id"]])),
            "gifts": split_ints(values[index["gifts"]]),
            "one_in_more": max(0, as_int(values[index["one_in_more"]])),
        }

    energy_rows = [row for row in items.values() if row["sub_type"] == 5 and row["energy"] > 0]
    magic_rows = [
        row for row in items.values()
        if row["sub_type"] == 12
        and (row["magic_energy"] > 0 or row["magic_dust"] > 0 or row["magic_liquid"] > 0)
    ]
    payload = {
        "_meta": {
            "schema_version": 1,
            "pass": "98.0",
            "source_resolution": "effective_merged",
            "source": "data/tables/item.lua",
            "source_sha256": sha256(args.source),
            "source_item_rows": total_rows,
            "consumable_rows": len(items),
            "subtype_counts": {str(k): subtype_counts[k] for k in sorted(subtype_counts)},
            "energy_item_count": len(energy_rows),
            "magic_item_count": len(magic_rows),
            "runtime_rule": (
                "Effects are operation-scoped: MID27 accepts only CONSUMABLES/sub_type=5 and uses energy; "
                "MID87 accepts only CONSUMABLES/sub_type=12 and uses the client priority magic_energy, magic_dust, magic_liquid. "
                "Gift/random fields are catalogued for provenance only and are not settled by Pass98."
            ),
        },
        "items": items,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2, sort_keys=True, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({
        "output": str(args.output),
        "source_item_rows": total_rows,
        "consumable_rows": len(items),
        "energy_items": len(energy_rows),
        "magic_items": len(magic_rows),
    }, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
