#!/usr/bin/env python3
"""Copy a legacy server_state and repair only the known sandbox ID/region anomaly.

The historical JSON runtime could move SANDBOX_UID 13371337 between regions
without reallocating player_id 12525385.  The PostgreSQL identity schema
correctly requires player_id to live inside the selected region namespace.

The *multi-user server_state* is the later authority for the sandbox's active
region, while the singleton player_db.json corroborates why the old player_id
still encodes region 125.  This helper never edits the source.  It copies the
source, keeps the server_state region, remaps the sandbox player_id into that
region while preserving its serial suffix, rewrites bounded own-player
references, lifts the target-region allocator, and writes an audit report.
"""
from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path
from typing import Any

UID = "13371337"
PID = "12525385"
OWN_PLAYER_ID_KEYS = frozenset({"player_id", "actor_player_id"})


def load(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def dump(path: Path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def rewrite_own_player_ids(value: Any, *, old_pid: str, new_pid: str) -> int:
    """Rewrite only typed own-player-id fields equal to the known old PID."""
    changed = 0
    if isinstance(value, dict):
        for key, item in list(value.items()):
            if key in OWN_PLAYER_ID_KEYS and str(item) == old_pid:
                value[key] = int(new_pid) if isinstance(item, int) else new_pid
                changed += 1
            else:
                changed += rewrite_own_player_ids(item, old_pid=old_pid, new_pid=new_pid)
    elif isinstance(value, list):
        for item in value:
            changed += rewrite_own_player_ids(item, old_pid=old_pid, new_pid=new_pid)
    return changed


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--source-root", required=True)
    ap.add_argument("--destination", required=True)
    ap.add_argument("--singleton", required=True)
    ap.add_argument("--report", required=True)
    args = ap.parse_args()
    src, dst = Path(args.source_root).resolve(), Path(args.destination).resolve()
    if not src.is_dir():
        raise SystemExit(f"source is not a server_state directory: {src}")
    if dst.exists():
        raise SystemExit(f"destination already exists: {dst}")

    singleton = load(Path(args.singleton))
    sident = singleton.get("player", {}).get("identity", {})
    if str(sident.get("account_uid")) != UID or str(sident.get("player_id")) != PID:
        raise SystemExit("singleton does not corroborate the known sandbox identity")
    singleton_region = int(sident.get("region"))
    encoded_region = int(PID) // 100000
    if singleton_region != encoded_region:
        raise SystemExit("singleton region does not corroborate the old player-id namespace")

    player_path = src / "players" / PID / "player.json"
    index_path = src / "indexes" / "player_by_account_region.json"
    serial_path = src / "indexes" / "region_player_serial.json"
    player, index = load(player_path), load(index_path)
    ident, meta = player.get("player", {}).get("identity", {}), player.get("_meta", {})
    if str(ident.get("account_uid")) != UID or str(meta.get("account_uid")) != UID:
        raise SystemExit("source is not the known sandbox account anomaly")
    if str(ident.get("player_id")) != PID or str(meta.get("player_id")) != PID:
        raise SystemExit("source player identity does not match known sandbox")
    source_region = int(ident.get("region"))
    if int(meta.get("region")) != source_region:
        raise SystemExit("source player metadata and payload region already disagree")
    if source_region == encoded_region:
        raise SystemExit("source sandbox player_id already matches its active region; no normalization needed")

    bucket = index.get(UID)
    if not isinstance(bucket, dict) or str(bucket.get(str(source_region))) != PID:
        raise SystemExit("ownership index does not contain the exact known sandbox mapping")
    for other_uid, regions in index.items():
        if not isinstance(regions, dict):
            continue
        for region, player_id in regions.items():
            if str(player_id) == PID and (str(other_uid), str(region)) != (UID, str(source_region)):
                raise SystemExit("player has a competing ownership reference; refusing automatic normalization")

    serial = int(PID) % 100000
    if serial <= 0:
        raise SystemExit("known sandbox player_id has invalid zero serial")
    target_pid = str(source_region * 100000 + serial)
    if target_pid == PID:
        raise SystemExit("derived target player_id unexpectedly equals source")
    if (src / "players" / target_pid).exists():
        raise SystemExit(f"target sandbox player path already exists: {target_pid}")
    for other_uid, regions in index.items():
        if not isinstance(regions, dict):
            continue
        for region, player_id in regions.items():
            if str(player_id) == target_pid:
                raise SystemExit(f"target sandbox player_id already owned by {other_uid}/{region}")

    shutil.copytree(src, dst, symlinks=False)
    old_dir = dst / "players" / PID
    new_dir = dst / "players" / target_pid
    old_dir.rename(new_dir)
    ppath = new_dir / "player.json"
    ipath = dst / "indexes" / "player_by_account_region.json"
    spath = dst / "indexes" / "region_player_serial.json"
    player, index = load(ppath), load(ipath)

    rewritten = rewrite_own_player_ids(player, old_pid=PID, new_pid=target_pid)
    # Region stays exactly as the later multi-user source recorded it.
    player["player"]["identity"]["region"] = source_region
    player["_meta"]["region"] = source_region
    index[UID][str(source_region)] = target_pid

    serials = load(spath) if spath.exists() else {}
    if not isinstance(serials, dict):
        raise SystemExit("region_player_serial.json is not an object")
    old_cursor = int(serials.get(str(source_region), 1) or 1)
    target_cursor = max(old_cursor, serial + 1)
    serials[str(source_region)] = target_cursor

    dump(ppath, player)
    dump(ipath, index)
    dump(spath, serials)
    report = {
        "status": "NORMALIZED_COPY",
        "adjustment": "LEGACY_SANDBOX_REGION_PLAYER_ID_REMAP",
        "source_root": str(src),
        "destination": str(dst),
        "account_uid": UID,
        "source_player_id": PID,
        "target_player_id": target_pid,
        "active_region_preserved": source_region,
        "singleton_region": singleton_region,
        "serial_suffix_preserved": serial,
        "own_player_references_rewritten": rewritten,
        "region_allocator_source_cursor": old_cursor,
        "region_allocator_target_cursor": target_cursor,
        "source_untouched": True,
    }
    out = Path(args.report)
    out.parent.mkdir(parents=True, exist_ok=True)
    dump(out, report)
    print(json.dumps(report, sort_keys=True))


if __name__ == "__main__":
    main()
