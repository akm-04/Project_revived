#!/usr/bin/env python3
"""Build current-src64 BattlePass redmark source facts deterministically."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

MISSION_REL = Path("data/tables/battlepass_mission.lua")
REWARD_REL = Path("data/tables/battlepass_reward.lua")
MISC_REL = Path("data/tables/misc.lua")
MODEL_REL = Path("app/model/BattlePass.lua")
MISSION_WRAPPER_REL = Path("app/common/tables/BattlePassMissionTable.lua")
REWARD_WRAPPER_REL = Path("app/common/tables/BattlePassRewardTable.lua")


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def quoted_rows(text: str, width: int) -> list[list[str]]:
    rows_block = text.split("rows = {", 1)[1]
    rows = []
    for body in re.findall(r"\{\s*((?:\"(?:[^\"\\]|\\.)*\"\s*,?\s*){%d})\}" % width, rows_block, re.S):
        values = re.findall(r'\"((?:[^\"\\]|\\.)*)\"', body)
        if len(values) == width:
            rows.append(values)
    return rows


def misc_value(text: str, key: str) -> int:
    pat = re.compile(r'\{\s*\"' + re.escape(key) + r'\"\s*,\s*\"(-?\d+)\"', re.S)
    match = pat.search(text)
    if not match:
        raise ValueError(f"missing misc key {key}")
    return int(match.group(1))


def build(src64_root: Path) -> dict:
    src64_root = Path(src64_root)
    paths = {name: src64_root / rel for name, rel in {
        "mission_table": MISSION_REL,
        "reward_table": REWARD_REL,
        "misc_table": MISC_REL,
        "model": MODEL_REL,
        "mission_wrapper": MISSION_WRAPPER_REL,
        "reward_wrapper": REWARD_WRAPPER_REL,
    }.items()}
    blobs = {name: path.read_bytes() for name, path in paths.items()}
    mission_rows = quoted_rows(blobs["mission_table"].decode("utf-8-sig"), 9)
    reward_rows = quoted_rows(blobs["reward_table"].decode("utf-8-sig"), 4)
    misc_text = blobs["misc_table"].decode("utf-8-sig")

    missions = {int(row[0]): int(row[3]) for row in mission_rows}
    rewards = {
        int(row[0]): {"common_gift": int(row[1] or 0), "special_gift": int(row[2] or 0)}
        for row in reward_rows
    }
    if sorted(missions) != list(range(1, 44)):
        raise ValueError(f"BattlePass mission census drift: {sorted(missions)}")
    if sorted(rewards) != list(range(1, 101)):
        raise ValueError(f"BattlePass reward census drift: {sorted(rewards)[:3]}..{sorted(rewards)[-3:]}")

    constants = {
        "point_per_level": misc_value(misc_text, "battle_pass_point_per_level"),
        "award_max_level": misc_value(misc_text, "battle_pass_award_max_level"),
        "award_loop_range": misc_value(misc_text, "battle_pass_award_loop_range"),
    }
    if constants != {"point_per_level": 100, "award_max_level": 100, "award_loop_range": 10}:
        raise ValueError(f"BattlePass current-source constants drift: {constants}")

    return {
        "schema_version": 1,
        "classification": "CURRENT_SRC64_GENERATED_SOURCE_CATALOG",
        "source_metadata": {
            name: {"path": str(path.relative_to(src64_root)).replace("\\", "/"), "sha256": sha256(blobs[name])}
            for name, path in paths.items()
        },
        "consumer_fact": (
            "BattlePass.isRedMarkShow derives level-up readiness from point/awarded levels and reward gift availability; "
            "BattlePass.getTaskDatas derives mission readiness from positional mission_list/mission_counts/is_award and battlepass_mission.count."
        ),
        "constants": constants,
        "mission_required_counts": {str(key): missions[key] for key in sorted(missions)},
        "rewards": {str(key): rewards[key] for key in sorted(rewards)},
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--src64-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("data/battle_pass_redmark_source_catalog.json"))
    args = parser.parse_args()
    payload = build(args.src64_root)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"status":"PASS","missions":len(payload["mission_required_counts"]),"rewards":len(payload["rewards"]),"constants":payload["constants"]}, indent=2))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
