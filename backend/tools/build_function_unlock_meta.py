#!/usr/bin/env python3
"""Build level-driven function unlock metadata from the effective src_64 view.

Pass 30 mirrors FunctionOpenTable.lua's interpretation of function.lua. Only
level-backed rows (level spec kinds 1, 6 and 7) are used by the current global
level-unlock plane; stage/VIP/energy-gated rows remain recorded but are not
opened by player-level changes.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from build_campaign_economy_meta import _flat_table, _int, _resolve_effective


def _parse_level_spec(value: str) -> tuple[int, int]:
    parts = [part.strip() for part in str(value or "").split("|") if part.strip()]
    if len(parts) < 2:
        return 0, 0
    return _int(parts[0]), _int(parts[1])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk-root", required=True, type=Path)
    parser.add_argument("--writable-root", type=Path, default=None)
    parser.add_argument("--output", type=Path, default=Path("data/function_unlock_meta.json"))
    args = parser.parse_args()

    relative = "data/tables/function.lua"
    path, layer = _resolve_effective(args.apk_root, args.writable_root, relative)
    keys, rows = _flat_table(path)
    idx = {key: keys.index(key) for key in keys}
    functions: dict[str, dict[str, object]] = {}
    for row in rows:
        fid = _int(row[idx["id"]])
        if fid <= 0:
            continue
        kind, value = _parse_level_spec(row[idx["level"]])
        functions[str(fid)] = {
            "name": row[idx["name"]],
            "level_spec_kind": kind,
            "level_spec_value": value,
            "player_level": value if kind in (1, 6, 7) else 0,
            "stage": value if kind == 2 else 0,
            "vip": value if kind == 3 else 0,
            "condition": _int(row[idx["condition"]]),
            "is_on_levelup_wnd": _int(row[idx["is_on_levelup_wnd"]]),
            "open_control": _int(row[idx["open_control"]]),
            "is_function_show": _int(row[idx["is_function_show"]]),
        }

    payload = {
        "_meta": {
            "format": "GXB Pass30 source-derived function unlock metadata",
            "source_resolution": "effective_merged",
            "source_precedence": "writable_hot_update_over_apk_baseline",
            "resolved_inputs": {relative: {"layer": layer, "relative_path": relative}},
            "policy": [
                "mirrors FunctionOpenTable.lua level-spec parsing",
                "current global unlock plane opens only player-level-backed kinds 1, 6 and 7",
                "stage/VIP/energy-gated functions are not inferred from a player-level change",
            ],
        },
        "functions": functions,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"wrote {args.output}: functions={len(functions)} source=effective_merged")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
