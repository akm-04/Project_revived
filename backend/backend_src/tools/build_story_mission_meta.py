#!/usr/bin/env python3
"""Build the narrow Pass-30 Story Mission 80001 contract from effective source.

The active reward columns are selected exactly as MissionTable.lua does: when
FunctionID 84 (ID_REWARD_CHANGE) has open_control=1, the *_new columns are used.
Asset pseudo-item IDs for currency display are resolved from effective asset.lua.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from build_campaign_economy_meta import _flat_table, _int, _resolve_effective

TARGET_MISSION_ID = 80001
REWARD_CHANGE_FUNCTION_ID = 84


def _rows_by_id(path: Path, id_key: str = "id") -> tuple[list[str], dict[int, list[str]]]:
    keys, rows = _flat_table(path)
    idx = keys.index(id_key)
    return keys, {_int(row[idx]): row for row in rows if _int(row[idx]) != 0}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk-root", required=True, type=Path)
    parser.add_argument("--writable-root", type=Path, default=None)
    parser.add_argument("--output", type=Path, default=Path("data/story_mission_meta.json"))
    args = parser.parse_args()

    relatives = {
        "mission": "data/tables/mission.lua",
        "function": "data/tables/function.lua",
        "asset": "data/tables/asset.lua",
    }
    actual: dict[str, Path] = {}
    resolved: dict[str, dict[str, str]] = {}
    for key, relative in relatives.items():
        path, layer = _resolve_effective(args.apk_root, args.writable_root, relative)
        actual[key] = path
        resolved[relative] = {"layer": layer, "relative_path": relative}

    mission_keys, mission_rows = _rows_by_id(actual["mission"])
    function_keys, function_rows = _rows_by_id(actual["function"])
    asset_keys, asset_rows = _rows_by_id(actual["asset"])
    mi = {key: mission_keys.index(key) for key in mission_keys}
    fi = {key: function_keys.index(key) for key in function_keys}
    ai = {key: asset_keys.index(key) for key in asset_keys}

    reward_control = function_rows.get(REWARD_CHANGE_FUNCTION_ID)
    if reward_control is None:
        raise ValueError("FunctionID 84 row missing from function.lua")
    use_new = _int(reward_control[fi["open_control"]]) == 1

    asset_by_backend_name: dict[str, int] = {}
    for asset_id, row in asset_rows.items():
        name = str(row[ai["backend_name"]] or "")
        if name:
            asset_by_backend_name[name] = asset_id

    row = mission_rows.get(TARGET_MISSION_ID)
    if row is None:
        raise ValueError("Story Mission 80001 missing from mission.lua")

    money_key = "money_new" if use_new else "money"
    crystal_key = "diamond_new" if use_new else "diamond"
    exp_key = "exp_new" if use_new else "exp"
    award_id_key = "award_id_new" if use_new else "award_id"
    award_num_key = "num_new" if use_new else "num"

    task_num_raw = str(row[mi["task_num"]] or "0")
    task_parts = [_int(part) for part in task_num_raw.split("|") if str(part).strip()]
    task_target = task_parts[-1] if task_parts else 0

    reward = {
        "mana": max(0, _int(row[mi[money_key]])),
        "crystal": max(0, _int(row[mi[crystal_key]])),
        "player_exp": max(0, _int(row[mi[exp_key]])),
        "item_id": max(0, _int(row[mi[award_id_key]])),
        "item_num": max(0, _int(row[mi[award_num_key]])),
    }
    display_awards: list[dict[str, int]] = []
    if reward["mana"] > 0:
        display_awards.append({"item_id": asset_by_backend_name["mana"], "item_num": reward["mana"]})
    if reward["crystal"] > 0:
        display_awards.append({"item_id": asset_by_backend_name["crystal"], "item_num": reward["crystal"]})
    if reward["player_exp"] > 0:
        display_awards.append({"item_id": asset_by_backend_name["exp"], "item_num": reward["player_exp"]})
    if reward["item_id"] > 0 and reward["item_num"] > 0:
        display_awards.append({"item_id": reward["item_id"], "item_num": reward["item_num"]})

    payload = {
        "_meta": {
            "format": "GXB Pass30 source-derived Story Mission metadata",
            "source_resolution": "effective_merged",
            "source_precedence": "writable_hot_update_over_apk_baseline",
            "resolved_inputs": resolved,
            "reward_change_function_id": REWARD_CHANGE_FUNCTION_ID,
            "reward_change_open_control": 1 if use_new else 0,
            "policy": [
                "Pass30 implements only Story Mission 80001 semantics",
                "reward columns follow MissionTable.lua ID_REWARD_CHANGE open_control selection",
                "currency awards are persisted by EconomyRepository and represented in response.awards with effective asset pseudo IDs for client display",
            ],
        },
        "story_missions": {
            str(TARGET_MISSION_ID): {
                "table_id": TARGET_MISSION_ID,
                "new_type": _int(row[mi["new_type"]]),
                "task_req": _int(row[mi["task_req"]]),
                "task_num_raw": task_num_raw,
                "task_target": task_target,
                "previous_task_id": _int(row[mi["task_id"]]),
                "next_task_id": _int(row[mi["next_task_id"]]),
                "display": _int(row[mi["display"]]),
                "goto": str(row[mi["go_id"]] or ""),
                "reward": reward,
                "response_awards": display_awards,
            }
        },
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"wrote {args.output}: mission={TARGET_MISSION_ID} reward_new={use_new} source=effective_merged")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
