#!/usr/bin/env python3
"""Build Pass96 source-derived Backpack stack-limit metadata from item.lua."""
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


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


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


def as_int(value: object, default: int = 0) -> int:
    try:
        return int(str(value).strip() or default)
    except (TypeError, ValueError):
        return default


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    headers, rows = decode_item_table(args.source)
    index = {name: i for i, name in enumerate(headers) if name}
    required = ("id", "stack", "stack_exceed_mail")
    missing = [key for key in required if key not in index]
    if missing:
        raise ValueError(f"item.lua missing columns: {missing}")

    items: dict[str, dict[str, int]] = {}
    distribution: Counter[int] = Counter()
    for values in rows:
        if len(values) < len(headers):
            values += [""] * (len(headers) - len(values))
        item_id = as_int(values[index["id"]])
        if item_id <= 0:
            continue
        stack = max(0, as_int(values[index["stack"]]))
        mail = max(0, as_int(values[index["stack_exceed_mail"]]))
        items[str(item_id)] = {"stack": stack, "stack_exceed_mail": mail}
        distribution[stack] += 1

    payload = {
        "_meta": {
            "schema_version": 1,
            "pass": "96.0",
            "source_resolution": "effective_merged",
            "source": "data/tables/item.lua",
            "source_sha256": sha256(args.source),
            "row_count": len(items),
            "positive_stack_rows": sum(count for stack, count in distribution.items() if stack > 0),
            "stack_distribution": {str(k): distribution[k] for k in sorted(distribution)},
            "runtime_rule": "Positive item.stack values are hard Backpack ceilings for new positive StackInventory settlements; reductions of legacy-overfull stacks remain allowed. stack=0 is not interpreted as a Backpack zero-cap.",
        },
        "items": items,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"wrote {args.output}: {len(items)} rows")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
