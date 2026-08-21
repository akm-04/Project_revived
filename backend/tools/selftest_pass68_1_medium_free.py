#!/usr/bin/env python3
"""Pass68.1 regression: post-tutorial Medium/CrystalFree MID50 type3/index1."""
from __future__ import annotations

import json
import time
from pathlib import Path

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.persistence_state import ensure_persistence_state
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.profiles import apply_established_profile
from gxb_backend.state.request_services import RequestServices

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"


def make_services(*, ready: bool) -> tuple[PlayerState, RequestServices, list[str]]:
    player = apply_established_profile(PlayerState())
    player.account_uid = "13371337"
    player.player_id = "12525385"
    player.guide_id = 101001

    # Existing runtime player has already completed the deterministic Pandaria
    # CrystalFree tutorial. Use a normal runtime entity id, not the tutorial's
    # fresh-player partner_id=3, to exercise established-state adoption.
    player.heroes["10002"] = {
        "player_id": player.player_id,
        "partner_id": 10002,
        "table_id": 10001003,
        "star": 1,
        "lev": 1,
        "exp": 0,
        "color": 1,
        "skills": [1, 1, 1, 1, 1, 1],
        "equips": [0, 0, 0, 0, 0, 0],
        "fumos": [0, 0, 0, 0, 0, 0],
    }
    now = int(time.time())
    player.summon = {
        "tutorial_crystal_done": 1,
        "crystal_free_time": now - (165601 if ready else 60),
        "mana_free_time": now,
        "mana_free_num": 0,
    }
    commits: list[str] = []
    catalog = GameDataCatalog.load(DATA / "game_data_catalog.json")
    services = RequestServices(player, DATA, lambda: commits.append("commit"), catalog=catalog)
    return player, services, commits


def main() -> int:
    # Ready established player: normalization must adopt Pandaria as free slot 1,
    # and the next accepted pull must advance to source milestone 2.
    player, services, commits = make_services(ready=True)
    payload = services.summon.payload()
    counter_key = "private_medium_free_result_counter_v1"
    assert player.summon[counter_key] == 1
    # Ignore the one-time normalization save; the accepted pull itself must
    # produce exactly one durable command commit.
    commits.clear()
    old_time = int(player.summon["crystal_free_time"])

    response = services.summon.summon_hero({"summon_type": 3, "summon_index": 1})
    assert response.get("error_code", 0) == 0, response
    assert isinstance(response.get("result"), list) and len(response["result"]) == 1, response
    assert player.summon[counter_key] == 2
    assert int(player.summon["crystal_free_time"]) > old_time
    assert response["summon_info"]["crystal_free_time"] == player.summon["crystal_free_time"]
    assert commits == ["commit"], commits
    assert ensure_persistence_state(player)["state_version"] == 1

    # Immediate transport retry must replay the committed result without another
    # counter/timestamp/state-version change or another durable commit.
    saved_result = json.loads(json.dumps(response["result"]))
    saved_time = int(player.summon["crystal_free_time"])
    retry = services.summon.summon_hero({"summon_type": 3, "summon_index": 1})
    assert retry.get("error_code", 0) == 0, retry
    assert retry["result"] == saved_result
    assert player.summon[counter_key] == 2
    assert int(player.summon["crystal_free_time"]) == saved_time
    assert ensure_persistence_state(player)["state_version"] == 1
    assert commits == ["commit"], commits

    # A separate established player whose source-backed 46h cooldown is not ready
    # must still fail closed without mutation.
    blocked_player, blocked_services, blocked_commits = make_services(ready=False)
    blocked_services.summon.payload()
    assert blocked_player.summon[counter_key] == 1
    blocked_commits.clear()
    before = json.loads(json.dumps(blocked_player.summon))
    blocked = blocked_services.summon.summon_hero({"summon_type": 3, "summon_index": 1})
    assert blocked.get("error_code") == 1, blocked
    assert blocked_player.summon == before
    assert blocked_commits == []
    assert ensure_persistence_state(blocked_player)["state_version"] == 0

    report = {
        "pass": "68.1",
        "status": "PASS",
        "protocol": {"mid": 50, "summon_type": 3, "summon_index": 1},
        "cooldown_seconds": 165600,
        "existing_tutorial_counter_adoption": 1,
        "accepted_counter_after": 2,
        "accepted_state_version": 1,
        "retry_replayed_without_second_commit": True,
        "not_ready_fail_closed": True,
    }
    out = ROOT / "docs" / "PASS68_1_MEDIUM_FREE_SELFTEST.json"
    out.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
