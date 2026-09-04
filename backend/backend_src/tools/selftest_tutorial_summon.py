#!/usr/bin/env python3
"""Offline state test for the v0.8.1 mapped tutorial summon slice."""

from __future__ import annotations

import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from gxb_backend.state.profiles import apply_established_profile, make_fresh_player
from gxb_backend.state.summon_repository import SummonRepository
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.multiuser_database import MultiUserDatabase


def require(cond: bool, message: str) -> None:
    if not cond:
        raise AssertionError(message)


def main() -> None:
    player = make_fresh_player(
        account_uid="20009999",
        player_id="19709999",
        region=197,
        region_name="Local-197",
    )
    saved = 0

    def save() -> None:
        nonlocal saved
        saved += 1

    repo = SummonRepository(player, ROOT / "data", save)
    payload = repo.payload()
    require(player.heroes["1"]["table_id"] == 10001001, "Aquaris must be partner_id 1")
    require(player.heroes["1"]["star"] == 1, "fresh Aquaris must use source ini_star=1")
    require(player.heroes["1"]["lev"] == 1 and player.heroes["1"]["color"] == 1, "fresh Aquaris shape")
    require(payload["mana_free_time"] == 0, "Mana tutorial pull must begin free")
    require(payload["crystal_free_time"] == 0, "Crystal tutorial pull must begin free")
    require(payload["mana_free_num"] == 5, "source Mana initial free count")
    require(len(payload["main_ids"]) >= 2 and all(payload["main_ids"][:2]), "main banner IDs")
    require(len(payload["second_ids"]) >= 3 and all(payload["second_ids"][:3]), "daily banner IDs")
    require(payload["mana_id"] > 0 and payload["partner_id"] > 0 and payload["pet_id"] > 0, "display IDs")

    first = repo.summon_hero({"summon_type": 1, "summon_index": 1})
    require(first.get("error_code", 0) == 0, "first Mana pull should succeed")
    require(first["result"][0]["partner_id"] == 2, "Lavia partner id")
    require(first["result"][0]["table_id"] == 10001002, "Lavia table id")
    require(first["result"][0]["is_partner"] is True, "Lavia result Hero flag")
    require(player.summon["mana_free_num"] == 4, "Mana count decremented once")
    first_time = player.summon["mana_free_time"]
    require(first_time > 0, "Mana cooldown timestamp stored")
    require(len(player.heroes) == 2, "Aquaris + Lavia")

    retry = repo.summon_hero({"summon_type": 1, "summon_index": 1})
    require(retry.get("error_code", 0) == 0, "interrupted Mana retry should be idempotent")
    require(len(player.heroes) == 2, "Mana retry must not duplicate")
    require(player.summon["mana_free_num"] == 4, "Mana retry must not decrement again")
    require(player.summon["mana_free_time"] == first_time, "Mana retry must preserve timestamp")

    player.guide_id = 100105
    blocked = repo.summon_hero({"summon_type": 1, "summon_index": 1})
    require(blocked.get("error_code") == 1, "post-guide Mana general gacha must remain unsupported")

    crystal = repo.summon_hero({"summon_type": 3, "summon_index": 1})
    require(crystal.get("error_code", 0) == 0, "first CrystalFree pull should succeed")
    require(crystal["result"][0]["partner_id"] == 3, "Pandaria partner id")
    require(crystal["result"][0]["table_id"] == 10001003, "Pandaria table id")
    require(player.summon["crystal_free_time"] > 0, "Crystal cooldown stored")
    require(len(player.heroes) == 3, "Aquaris + Lavia + Pandaria")

    crystal_retry = repo.summon_hero({"summon_type": 3, "summon_index": 1})
    require(crystal_retry.get("error_code", 0) == 0, "interrupted Crystal retry should be idempotent")
    require(len(player.heroes) == 3, "Crystal retry must not duplicate")

    player.guide_id = 100108
    blocked_crystal = repo.summon_hero({"summon_type": 3, "summon_index": 1})
    require(blocked_crystal.get("error_code") == 1, "post-guide Crystal general gacha must remain unsupported")

    before = dict(player.heroes)
    unsupported = repo.summon_hero({"summon_type": 2, "summon_index": 1})
    require(unsupported.get("error_code") == 1, "ordinary Crystal RNG is intentionally unsupported")
    require(player.heroes == before, "unsupported pull must not mutate roster")

    sandbox = apply_established_profile(PlayerState())
    sandbox.account_uid = "13371337"
    sandbox_before = dict(sandbox.heroes)
    sandbox_repo = SummonRepository(sandbox, ROOT / "data")
    sandbox_payload = sandbox_repo.payload()
    require("1" not in sandbox.heroes, "sandbox must not receive tutorial partner_id 1")
    require(sandbox.heroes == sandbox_before, "sandbox roster must remain established")
    require(sandbox_payload["mana_id"] > 0, "sandbox MID56 still needs render-safe display IDs")

    # Exercise the real multi-user creation/load normalization path used by MID1
    # and by existing v0.8.0 credential-player migration.
    with tempfile.TemporaryDirectory(prefix="gxb-v081-summon-") as tmp:
        db = MultiUserDatabase(Path(tmp) / "server_state", ROOT / "data")
        created = db.create_fresh_player(uid="20008888", region=197, region_name="Local-197")
        require(created.heroes["1"]["table_id"] == 10001001, "MID1 creation path must seed Aquaris")
        reloaded = db.load_player(str(created.player_id))
        require(reloaded is not None and reloaded.heroes["1"]["partner_id"] == 1, "tutorial seed must persist/reload")
        require(reloaded.summon.get("mana_free_num") == 5, "tutorial free state must persist/reload")

    print("PASS: v0.8.1 tutorial summon offline state test")
    print(f"save callbacks observed: {saved}")


if __name__ == "__main__":
    main()
