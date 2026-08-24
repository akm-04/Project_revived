#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DATA = ROOT / "data"

from gxb_backend.content import GameDataCatalog
from gxb_backend.content.challenge_campaign_catalog import ChallengeCampaignCatalog
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.testing.scripted_entropy import ScriptedEntropyProvider

CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")


def require(value: bool, message: str) -> None:
    if not value:
        raise AssertionError(message)


def player(*, challenge_star: int = 0, energy: int = 100) -> PlayerState:
    p = PlayerState(player_id="991220", account_uid="991220", player_name="Pass122", vip=15)
    p.lev = 100
    p.max_lev = 100
    p.energy = energy
    p.max_energy = 160
    p.world_map = {
        "normal": [{"campaign_id": 1600016, "star": 3, "daily_limit": 0, "reset_count": 0, "is_partner_drop": 0}],
        "super": [],
        "challenge": [{"campaign_id": 24111, "star": challenge_star, "daily_limit": 0, "reset_count": 0}],
        "chapter_events": {},
        "chapter_info": {
            "normal_chapter_id": 16, "normal_campaign_id": 1600016,
            "normal_stars": 3, "normal_bonus_id": 0,
            "super_chapter_id": 0, "super_campaign_id": 0,
            "super_stars": 0, "super_bonus_id": 0,
        },
    }
    return p


def service(p: PlayerState, commits: list[int]):
    entropy = ScriptedEntropyProvider([])
    svc = RequestServices(p, DATA, lambda: commits.append(1), catalog=CATALOG, entropy_provider=entropy)
    return svc, entropy


def qty(p: PlayerState, item_id: int) -> int:
    return sum(int(r.get("item_num", 0) or 0) for r in p.backpack_items if int(r.get("table_id", 0) or 0) == item_id)


def test_catalog_contract() -> None:
    c = ChallengeCampaignCatalog(DATA)
    require(len(c.ordered_ids) == 144, "Challenge catalog row count != 144")
    require(sum(len(c.children(cid)) for cid in c.ordered_ids) == 137, "Challenge graph edge count != 137")
    require(c.roots == (24111, 24211, 24311, 24411, 24511, 24611, 24711), f"roots drifted: {c.roots}")
    require(sum(len(c.children(cid)) > 1 for cid in c.ordered_ids) == 22, "fan-out count != 22")
    require(c.children(24111) == (24112, 24121), f"raw branch collapsed: {c.children(24111)}")
    for cid in c.ordered_ids:
        for award in c.awards(cid):
            require(award["item_num"] == award["increase_rate"] // 10000, f"reward formula drift {cid}: {award}")


def test_fixpoint_projection() -> None:
    p = player(challenge_star=1)
    commits: list[int] = []
    svc, entropy = service(p, commits)
    rows = svc.world.payload()["challenge"]
    ids = [int(r["campaign_id"]) for r in rows]
    require(ids[:3] == [24111, 24112, 24121], f"source order/fanout projection wrong: {ids[:8]}")
    require(set([24112, 24121]).issubset(ids), f"first-level children absent: {ids}")
    require(24113 not in ids and 24122 not in ids, "star=0 child recursively opened grandchildren")
    require(set(svc.world.challenge_catalog.roots).issubset(ids), "seven source roots not materialized")
    require(commits, "LOAD_WORLD_MAP projection self-heal was not persisted")
    before = len(commits)
    svc2, _ = service(p, commits)
    require(svc2.world.payload()["challenge"] == rows, "reloaded projection drifted")
    require(len(commits) == before, "already-canonical Challenge projection caused a ghost save")
    require(entropy.consumed == (), "projection consumed entropy")


def test_deterministic_first_clear_and_duplicate_result() -> None:
    p = player(challenge_star=0, energy=100)
    commits: list[int] = []
    svc, entropy = service(p, commits)
    begin = {"campaign_id": 24111, "campaign_type": 24, "formation": ""}
    staged = svc.world.begin_fight(begin)
    require(staged.get("error_code", 0) == 0, f"Challenge MID113 failed: {staged}")
    expected = [{"item_id": 50001121, "item_num": 1}, {"item_id": 50001125, "item_num": 1}, {"item_id": 50001129, "item_num": 1}]
    require(staged.get("items") == expected, f"deterministic first-clear rows drifted: {staged.get('items')}")
    staged2 = svc.world.begin_fight(begin)
    require(staged2.get("items") == expected, "repeated Challenge MID113 changed deterministic stage")
    require(entropy.consumed == (), "Challenge MID113 consumed RandomOutcomeService entropy")

    result_req = {"campaign_id": 24111, "campaign_type": 24, "formation": "", "star": 1}
    result = svc.world.commit_fight_result(result_req)
    require(result.get("error_code", 0) == 0 and result.get("is_win") == 1, f"Challenge MID114 failed: {result}")
    returned = [int(r.get("campaign_id", 0)) for r in result.get("campaigns", [])]
    require(returned[:3] == [24111, 24112, 24121], f"MID114 did not return current + every raw child: {returned}")
    require(result.get("items") == [], f"MID114 duplicated MID113 first-clear item channel: {result.get('items')}")
    require(p.energy == 76, f"Challenge victory did not settle source energy 24: {p.energy}")
    for award in expected:
        require(qty(p, award["item_id"]) == 1, f"Challenge first-clear item not committed once: {award}")

    replay = svc.world.commit_fight_result(result_req)
    require(replay.get("error_code") == 30005, f"Challenge terminal duplicate did not use source 30005: {replay}")
    require(replay.get("is_win") == result.get("is_win") and replay.get("items") == result.get("items"), "Challenge terminal duplicate static response drift")
    require(p.energy == 76, "Challenge duplicate MID114 double-debited energy")
    for award in expected:
        require(qty(p, award["item_id"]) == 1, f"Challenge duplicate MID114 double-granted: {award}")
    require(entropy.consumed == (), "Challenge result consumed entropy")


def test_loss_discards_items_and_uses_defeat_cost() -> None:
    p = player(challenge_star=0, energy=100)
    svc, entropy = service(p, [])
    begin = {"campaign_id": 24111, "campaign_type": 24, "formation": ""}
    staged = svc.world.begin_fight(begin)
    require(len(staged.get("items") or []) == 3, "loss setup did not stage deterministic first-clear items")
    result_req = {"campaign_id": 24111, "campaign_type": 24, "formation": "", "star": 0}
    result = svc.world.commit_fight_result(result_req)
    require(result.get("is_win") == 0, f"Challenge loss response wrong: {result}")
    require(p.energy == 98, f"Challenge defeat did not settle source defeat_cost=2: {p.energy}")
    require(all(qty(p, iid) == 0 for iid in (50001121, 50001125, 50001129)), "Challenge loss committed first-clear items")
    require(entropy.consumed == (), "Challenge loss consumed entropy")


def test_locked_and_arbitrary_result_fail_closed() -> None:
    p = player(challenge_star=0)
    p.world_map["normal"][0]["star"] = 0
    p.world_map["challenge"] = []
    svc, _ = service(p, [])
    locked = svc.world.begin_fight({"campaign_id": 24111, "campaign_type": 24, "formation": ""})
    require(locked.get("error_code") == 1 and locked.get("msg") == "campaign_locked", f"locked Challenge staged: {locked}")

    p2 = player(challenge_star=0)
    svc2, _ = service(p2, [])
    arbitrary = svc2.world.commit_fight_result({"campaign_id": 24111, "campaign_type": 24, "formation": "", "star": 1})
    require(arbitrary.get("error_code") == 30005, f"arbitrary Challenge MID114 was not source-family drained: {arbitrary}")
    sweep = svc2.world.sweep({"campaign_id": 24111, "campaign_type": 24, "sweep_num": 1})
    require(sweep.get("error_code") == 1 and sweep.get("msg") == "challenge_sweep_not_supported", f"Challenge sweep plane leaked: {sweep}")


def main() -> None:
    tests = [
        test_catalog_contract,
        test_fixpoint_projection,
        test_deterministic_first_clear_and_duplicate_result,
        test_loss_discards_items_and_uses_defeat_cost,
        test_locked_and_arbitrary_result_fail_closed,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
    print(f"PASS Pass122 Challenge mode ({len(tests)} tests)")


if __name__ == "__main__":
    main()
