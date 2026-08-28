#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

EXPECTED_SOURCE_ARCHIVE_SHA256 = "89f0f830508b92e5fff6ad53c6a9dae961a14042dbfdf5649008efb8353f5608"

ORDINARY_EVENT_OUTLIER_MISSIONS = {
    1041001, 1122001, 1144001, 1157001, 1158001, 1200001,
    1232001, 1242001, 1258001, 1260001, 1262001,
}
BLOOD_EVENT_OUTLIER_MISSIONS = {
    2122001, 2157001, 2158001, 2190001, 2200001, 2232001, 2258001,
}

EXPECTED_SOURCE_HASHES = {
    "data/tables/awaken_mission.lua": "fdbcaf96386a7aa775c23b071bfe9952ef6acfc57982d17300b8308417fdb123",
    "data/tables/bloodline_mission.lua": "b773cd8ebb0936c76c7ad0727a5d9efa67e87b748f508c3cd66147f075b81299",
    "data/tables/campaign.lua": "7a58e878a7171839342a856cd74b512037528438259d036009a7249472504683",
    "data/tables/campaign_dropbox.lua": "374b6b13bae56e2f5ac8d6b884821d2fb448d239871d1992b84bcf365e90404e",
    "data/tables/creats_chapter_select.lua": "c4134b5ee3a9861d75f76f6c704e16345c0cb61d6b49adefcdf1f90549d26e3d",
}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def _scan_balanced(text: str, start: int) -> tuple[str, int]:
    depth = 0
    in_string = False
    escaped = False
    for idx in range(start, len(text)):
        ch = text[idx]
        if in_string:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                in_string = False
            continue
        if ch == '"':
            in_string = True
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return text[start : idx + 1], idx + 1
    raise ValueError("unterminated Lua table block")


def _quoted_values(block: str) -> list[str]:
    values: list[str] = []
    i = 0
    while i < len(block):
        if block[i] != '"':
            i += 1
            continue
        j = i + 1
        escaped = False
        while j < len(block):
            ch = block[j]
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                token = block[i : j + 1]
                # The generated table strings are compatible with JSON escapes.
                values.append(json.loads(token))
                i = j + 1
                break
            j += 1
        else:
            raise ValueError("unterminated Lua string")
    return values


def parse_table(path: Path) -> list[dict[str, str]]:
    text = path.read_text(encoding="utf-8-sig")
    key_pos = text.find("keys =")
    row_pos = text.find("rows =")
    if key_pos < 0 or row_pos < 0:
        raise ValueError(f"{path.name}: expected keys/rows table")
    key_start = text.find("{", key_pos)
    row_start = text.find("{", row_pos)
    key_block, _ = _scan_balanced(text, key_start)
    row_block, _ = _scan_balanced(text, row_start)
    keys = _quoted_values(key_block)
    rows: list[dict[str, str]] = []
    i = 1
    while i < len(row_block) - 1:
        if row_block[i] != "{":
            i += 1
            continue
        block, end = _scan_balanced(row_block, i)
        vals = _quoted_values(block)
        if vals:
            if len(vals) != len(keys):
                raise ValueError(f"{path.name}: row has {len(vals)} values for {len(keys)} keys")
            rows.append(dict(zip(keys, vals)))
        i = end
    return rows


def as_int(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def pipe_ints(value: Any) -> list[int]:
    out: list[int] = []
    for token in str(value or "").split("|"):
        token = token.strip()
        if not token or token == "0":
            continue
        try:
            out.append(int(token))
        except ValueError:
            pass
    return out


def normalize_mission(row: dict[str, str], awake_type: int) -> dict[str, Any]:
    return {
        "id": as_int(row.get("id")),
        "awake_type": awake_type,
        "stage": as_int(row.get("stage")),
        "table_id": as_int(row.get("table_id")),
        "awaken_table_id": as_int(row.get("awaken_table_id")),
        "task_id": as_int(row.get("task_id")),
        "next_task_id": as_int(row.get("next_task_id")),
        "task_num": as_int(row.get("task_num")),
        "go_ids": pipe_ints(row.get("go_id")),
        "awaken_dropbox": as_int(row.get("awaken_dropbox")),
        "awaken_material": as_int(row.get("awaken_material")),
        "awaken_item_piece": as_int(row.get("awaken_item_piece")),
        "item": as_int(row.get("item")),
        "trial_challenge": pipe_ints(row.get("trial_challenge")),
        "copy_challenge": as_int(row.get("copy_challenge")),
        "challenge_num": as_int(row.get("challenge_num")),
        "mission_type": str(row.get("mission_type") or ""),
        "display": as_int(row.get("display")),
        "delete_items": pipe_ints(row.get("delete_item")),
    }


def build(src_root: Path) -> dict[str, Any]:
    source_hashes: dict[str, str] = {}
    for rel, expected in EXPECTED_SOURCE_HASHES.items():
        path = src_root / rel
        actual = sha256(path)
        if actual != expected:
            raise ValueError(f"effective src_64 drift for {rel}: {actual} != {expected}")
        source_hashes[rel] = actual

    awaken_rows = parse_table(src_root / "data/tables/awaken_mission.lua")
    bloodline_rows = parse_table(src_root / "data/tables/bloodline_mission.lua")
    campaign_rows = parse_table(src_root / "data/tables/campaign.lua")
    drop_rows = parse_table(src_root / "data/tables/campaign_dropbox.lua")
    occult_rows = parse_table(src_root / "data/tables/creats_chapter_select.lua")

    ordinary: dict[int, dict[str, Any]] = {}
    blood: dict[int, dict[str, Any]] = {}
    for row in awaken_rows:
        mission_id = as_int(row.get("id"))
        ordinary[mission_id] = normalize_mission(row, 1)
    for row in bloodline_rows:
        mission_id = as_int(row.get("id"))
        blood[mission_id] = normalize_mission(row, 2)

    dropbox_rows: dict[int, list[dict[str, int]]] = {}
    for ordinal, row in enumerate(drop_rows, 1):
        dropbox_id = as_int(row.get("dropbox_id"))
        if dropbox_id <= 0:
            continue
        dropbox_rows.setdefault(dropbox_id, []).append({
            "row_id": as_int(row.get("id")),
            "item_id": as_int(row.get("item_id")),
            "increase_rate": as_int(row.get("increase_rate")),
            "source_ordinal": ordinal,
        })

    ordinary_campaigns: dict[int, list[dict[str, Any]]] = {}
    blood_campaigns: dict[int, list[dict[str, Any]]] = {}
    for ordinal, row in enumerate(campaign_rows, 1):
        campaign_id = as_int(row.get("campaign_id"))
        for mission_key, drop_key, target in (
            ("awaken_mission_id", "awaken_dropbox", ordinary_campaigns),
            ("bloodline_mission_id", "bloodline_dropbox", blood_campaigns),
        ):
            mission_ids = pipe_ints(row.get(mission_key))
            dropbox_ids = pipe_ints(row.get(drop_key))
            if not mission_ids:
                continue
            if len(dropbox_ids) == 1 and len(mission_ids) > 1:
                dropbox_ids = dropbox_ids * len(mission_ids)
            if len(dropbox_ids) != len(mission_ids):
                raise ValueError(f"Campaign {campaign_id} {mission_key}/{drop_key} vector mismatch")
            for mission_id, dropbox_id in zip(mission_ids, dropbox_ids):
                target.setdefault(mission_id, []).append({
                    "campaign_id": campaign_id,
                    "chapter": as_int(row.get("chapter")),
                    "campaign_type": as_int(row.get("campaign_type")),
                    "dropbox_id": dropbox_id,
                    "source_ordinal": ordinal,
                })

    occult_by_mission: dict[int, dict[str, Any]] = {}
    for row in occult_rows:
        mids = pipe_ints(row.get("awaken_mission_ids"))
        items = pipe_ints(row.get("awaken_items"))
        nums = pipe_ints(row.get("awaken_nums"))
        if len(items) != len(mids) or len(nums) != len(mids):
            raise ValueError(f"Occult chapter {row.get('chapter_id')} awakening vector mismatch")
        for idx, mission_id in enumerate(mids):
            occult_by_mission[mission_id] = {
                "chapter_id": as_int(row.get("chapter_id")),
                "chapter_table_id": as_int(row.get("table_id")),
                "chapter_name": str(row.get("chapter_name") or ""),
                "fragment_item": items[idx],
                "awaken_num_raw": nums[idx],
            }

    def classify(
        missions: dict[int, dict[str, Any]],
        campaigns: dict[int, list[dict[str, Any]]],
        *,
        allow_occult: bool,
        event_outliers: set[int],
    ) -> dict[int, dict[str, Any]]:
        stage1: dict[int, dict[str, Any]] = {}
        for mid, mission in missions.items():
            if mission["stage"] != 1:
                continue
            if mid in event_outliers:
                route = "EVENT_OUTLIER"
            elif allow_occult and mid in occult_by_mission:
                route = "OCCULT"
            elif mid in campaigns:
                route = "CAMPAIGN"
            else:
                raise ValueError(f"unclassified Awakening stage-one mission {mid}")
            stage1[mid] = {
                "mission_id": mid,
                "awake_type": mission["awake_type"],
                "origin_table_id": mission["table_id"],
                "awaken_table_id": mission["awaken_table_id"],
                "next_task_id": mission["next_task_id"],
                "material_item": mission["awaken_material"],
                "fragment_item": mission["awaken_item_piece"],
                "exclusive_gear_item": mission["item"],
                "delete_items": mission["delete_items"],
                "route_class": route,
                "campaigns": campaigns.get(mid, []),
                "occult": occult_by_mission.get(mid) if route == "OCCULT" else None,
            }
        return stage1

    ordinary_stage1 = classify(ordinary, ordinary_campaigns, allow_occult=True, event_outliers=ORDINARY_EVENT_OUTLIER_MISSIONS)
    blood_stage1 = classify(blood, blood_campaigns, allow_occult=False, event_outliers=BLOOD_EVENT_OUTLIER_MISSIONS)

    counts = {
        "ordinary_rows": len(ordinary),
        "ordinary_stage1": sum(1 for row in ordinary.values() if row["stage"] == 1),
        "ordinary_stage2": sum(1 for row in ordinary.values() if row["stage"] == 2),
        "ordinary_aux_stage_minus1": sum(1 for row in ordinary.values() if row["stage"] == -1),
        "ordinary_route_campaign": sum(1 for row in ordinary_stage1.values() if row["route_class"] == "CAMPAIGN"),
        "ordinary_route_occult": sum(1 for row in ordinary_stage1.values() if row["route_class"] == "OCCULT"),
        "ordinary_route_event_outlier": sum(1 for row in ordinary_stage1.values() if row["route_class"] == "EVENT_OUTLIER"),
        "blood_rows": len(blood),
        "blood_stage1": sum(1 for row in blood.values() if row["stage"] == 1),
        "blood_stage2": sum(1 for row in blood.values() if row["stage"] == 2),
        "blood_route_campaign": sum(1 for row in blood_stage1.values() if row["route_class"] == "CAMPAIGN"),
        "blood_route_event_outlier": sum(1 for row in blood_stage1.values() if row["route_class"] == "EVENT_OUTLIER"),
    }
    expected_counts = {
        "ordinary_rows": 465,
        "ordinary_stage1": 164,
        "ordinary_stage2": 164,
        "ordinary_aux_stage_minus1": 137,
        "ordinary_route_campaign": 131,
        "ordinary_route_occult": 22,
        "ordinary_route_event_outlier": 11,
        "blood_rows": 162,
        "blood_stage1": 81,
        "blood_stage2": 81,
        "blood_route_campaign": 74,
        "blood_route_event_outlier": 7,
    }
    if counts != expected_counts:
        raise ValueError(f"Awakening source census drift: {counts!r}")

    referenced_dropboxes = sorted({
        int(entry["dropbox_id"])
        for bucket in (ordinary_campaigns, blood_campaigns)
        for entries in bucket.values()
        for entry in entries
        if int(entry.get("dropbox_id", 0) or 0) > 0
    })

    return {
        "schema_version": 1,
        "_meta": {
            "schema_version": 1,
            "source_resolution": "effective_src64",
            "epistemic_class": "SOURCE_FACT_ONLY",
            "source_archive_sha256": EXPECTED_SOURCE_ARCHIVE_SHA256,
            "effective_src64_file_count": 4370,
            "source_hashes": source_hashes,
            "classification_note": "Stage-one route partition is derived exhaustively from source campaign/Occult references; unmatched stage-one rows are EVENT_OUTLIER. No compatibility policy or runtime mutation state is stored here.",
        },
        "counts": counts,
        "special_dropboxes": {str(k): dropbox_rows.get(k, []) for k in referenced_dropboxes},
        "ordinary": {str(k): v for k, v in sorted(ordinary.items())},
        "blood": {str(k): v for k, v in sorted(blood.items())},
        "ordinary_stage1_routes": {str(k): v for k, v in sorted(ordinary_stage1.items())},
        "blood_stage1_routes": {str(k): v for k, v in sorted(blood_stage1.items())},
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--src-root", required=True, type=Path)
    parser.add_argument("--output", type=Path, default=None)
    args = parser.parse_args()
    out = args.output or (Path(__file__).resolve().parents[1] / "data" / "awakening_source_catalog.json")
    payload = build(args.src_root)
    out.write_text(json.dumps(payload, indent=2, sort_keys=True, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(out), "counts": payload["counts"]}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
