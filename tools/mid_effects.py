#!/usr/bin/env python3
"""Derive each registered MID's effect (read, state, unknown) for reply replay.

The source is the system map's per-MID trace class (docs/architecture/system_map/MID_CLASSES.json).
Its `writes` value is `state` when the route trace reaches write SQL other than the receipt store,
`receipt` when it records only an operation receipt, `none` when the walk found no write, and
`UNKNOWN` when a FANOUT, UNRESOLVED or BOUND marker could hide one. `none` is a trace-backed read:
only a complete walk with no marker yields it. Lock clauses do not raise a MID above its write
class here: route traces show only the shared session FOR SHARE or conditional FOR UPDATE clauses
whose caller argument decides, so they are not proof of a change.

An `unknown` MID counts as `state` for undelivered-reply replay, because a wrong `state` only
clears a stored mark early.
"""

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MID_CLASSES = ROOT / "docs" / "architecture" / "system_map" / "MID_CLASSES.json"
OUTPUT = ROOT / "docs" / "protocol" / "MID_EFFECTS.json"

WRITE_EFFECTS = {"state": "state", "receipt": "state", "none": "read"}


def json_text(value):
    return json.dumps(value, indent=1, ensure_ascii=False, sort_keys=True) + "\n"


def load_mid_classes(path=None):
    source = path or MID_CLASSES
    try:
        return json.loads(source.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise SystemExit("missing %s; run tools/system_map.py --write" % source)


def mid_effect(row):
    if row.get("state_writes") or row.get("receipt_writes"):
        return "state"
    return WRITE_EFFECTS.get(row.get("writes"), "unknown")


def effect_document(mid_classes):
    rows = mid_classes.get("mids")
    if not isinstance(rows, list) or not rows:
        raise SystemExit("MID_CLASSES.json has no mids")
    effects = []
    seen = set()
    for row in rows:
        mid = row.get("mid")
        if not isinstance(mid, int) or mid in seen:
            raise SystemExit("MID class has a missing or duplicate mid: %r" % (mid,))
        seen.add(mid)
        effects.append({"mid": mid, "effect": mid_effect(row)})
    effects.sort(key=lambda effect: effect["mid"])
    return {
        "generated_by": "tools/mid_effects.py --write",
        "source": "docs/architecture/system_map/MID_CLASSES.json",
        "note": "read = the route trace reached no write; state = it reached a write (a receipt included); "
                "unknown = the trace could not decide and counts as state for undelivered-reply replay.",
        "mids": effects,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true")
    mode.add_argument("--check", action="store_true")
    arguments = parser.parse_args()
    document = effect_document(load_mid_classes())
    if arguments.write:
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT.write_text(json_text(document), encoding="utf-8")
        print("wrote %s" % OUTPUT)
        return 0
    current = OUTPUT.read_text(encoding="utf-8") if OUTPUT.is_file() else ""
    if current != json_text(document):
        print("stale: %s" % OUTPUT)
        return 1
    print("MID effects are current")
    return 0


if __name__ == "__main__":
    sys.exit(main())
