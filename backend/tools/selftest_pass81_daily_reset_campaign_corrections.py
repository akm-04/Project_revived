#!/usr/bin/env python3
"""Pass81 persistence replacement + Super Campaign daily-attempt corrections."""
from __future__ import annotations

import json
import tempfile
from pathlib import Path

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.account import AccountIdentity
from gxb_backend.state.daily_reset import CampaignDailyResetParticipant, DailyResetContext
from gxb_backend.state.player_database import JsonPlayerDatabase
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")


def require(cond: bool, message: str) -> None:
    if not cond:
        raise AssertionError(message)


def persistence_replacement_test() -> dict[str, object]:
    account = AccountIdentity(uid="810001", sid="sid", token="token", username="Pass81")
    original = PlayerState(player_id="810001", account_uid="810001")
    original.daily_consume_state = {
        "schema_version": 2,
        "day": 123,
        "source_day_id": 123,
        "counts": {"2": 1, "7": 4},
    }
    original.mission_state = {
        "daily_cache": {"stale": {"nested": 1}},
        "daily_cache_day_id": 122,
        "story": {"missions": {"80001": {"count": 1}}},
    }

    with tempfile.TemporaryDirectory(prefix="gxb-pass81-persist-") as td:
        path = Path(td) / "player.json"
        db = JsonPlayerDatabase(path)
        db.save(account, original)

        # Simulate future/unknown extension payloads that the compatibility
        # merge must preserve while the two domain-owned clear containers are
        # treated as authoritative replacements.
        raw = json.loads(path.read_text(encoding="utf-8"))
        raw["player"]["domains"]["daily_consume_state"]["future_extension"] = {"keep": 7}
        raw["player"]["lobby"]["mission_state"]["future_extension"] = {"keep": 9}
        raw["player"]["domains"]["future_domain"] = {"unknown": {"keep": 11}}
        path.write_text(json.dumps(raw, indent=2) + "\n", encoding="utf-8")

        _account, loaded = db.load(account, PlayerState(player_id="810001", account_uid="810001"))
        loaded.daily_consume_state["counts"] = {}
        loaded.mission_state["daily_cache"] = {}
        db.save(account, loaded)

        persisted = json.loads(path.read_text(encoding="utf-8"))
        daily = persisted["player"]["domains"]["daily_consume_state"]
        mission = persisted["player"]["lobby"]["mission_state"]
        require(daily.get("counts") == {}, f"daily consume clear resurrected: {daily.get('counts')!r}")
        require(mission.get("daily_cache") == {}, f"mission daily cache clear resurrected: {mission.get('daily_cache')!r}")
        require(daily.get("future_extension") == {"keep": 7}, "daily consume sibling extension lost")
        require(mission.get("future_extension") == {"keep": 9}, "mission sibling extension lost")
        require(persisted["player"]["domains"].get("future_domain") == {"unknown": {"keep": 11}}, "unrelated future domain lost")

        _account2, reloaded = db.load(account, PlayerState(player_id="810001", account_uid="810001"))
        require(reloaded.daily_consume_state.get("counts") == {}, "cleared DailyConsume did not survive reload")
        require(reloaded.mission_state.get("daily_cache") == {}, "cleared Task cache did not survive reload")

    return {
        "daily_consume_counts_clear_persists": True,
        "mission_daily_cache_clear_persists": True,
        "unknown_extension_siblings_preserved": True,
    }


def services(*, uid: str = "810010", energy: int = 100) -> tuple[PlayerState, RequestServices, list[int]]:
    p = PlayerState(player_id=uid, account_uid=uid, player_name="Pass81")
    p.lev = 100
    p.max_lev = 100
    p.energy = int(energy)
    p.max_energy = 100
    p.energy_time = 0
    commits: list[int] = []
    s = RequestServices(
        p,
        DATA,
        lambda: commits.append(int(p.persistence_state.get("state_version", 0))),
        catalog=CATALOG,
    )
    s.world.normalize()
    return p, s, commits


def response_campaign(response: dict, campaign_id: int) -> dict:
    for row in response.get("campaigns") or []:
        if isinstance(row, dict) and int(row.get("campaign_id", 0) or 0) == campaign_id:
            return row
    raise AssertionError(f"campaign {campaign_id} missing from response {response!r}")


def super_campaign_attempt_test() -> dict[str, object]:
    p, s, _ = services(energy=100)
    cid = 100019
    row = {"campaign_id": cid, "star": 0, "daily_limit": 3, "reset_count": 0, "is_partner_drop": 0}
    s.world._mode_rows(2).append(row)
    fight = {"campaign_id": cid, "campaign_type": 2, "formation": ""}

    # First successful canonical settlement consumes one remaining attempt.
    require(s.world.begin_fight(fight).get("error_code") is None, "Super MID113 3/3 rejected")
    first = s.world.commit_fight_result({**fight, "star": 1})
    require(row["daily_limit"] == 2, f"first Super success did not consume 3->2: {row!r}")
    require(response_campaign(first, cid).get("daily_limit") == 2, "MID114 did not return remaining=2")

    # Duplicate result receipt must remain exactly-once: no second debit.
    version_after_first = s.uow.current_state_version
    retry = s.world.commit_fight_result({**fight, "star": 1})
    require(retry == first, "duplicate MID114 did not return committed receipt")
    require(row["daily_limit"] == 2, "duplicate MID114 consumed a second Super attempt")
    require(s.uow.current_state_version == version_after_first, "duplicate MID114 consumed a state version")

    require(s.world.begin_fight(fight).get("error_code") is None, "Super MID113 2/3 rejected")
    second = s.world.commit_fight_result({**fight, "star": 1})
    require(row["daily_limit"] == 1 and response_campaign(second, cid).get("daily_limit") == 1, "second Super success did not consume 2->1")

    require(s.world.begin_fight(fight).get("error_code") is None, "Super MID113 1/3 rejected")
    third = s.world.commit_fight_result({**fight, "star": 1})
    require(row["daily_limit"] == 0 and response_campaign(third, cid).get("daily_limit") == 0, "third Super success did not consume 1->0")

    # The authority boundary mirrors NewMapDetailWindow's zero-times UI gate.
    version_before_reject = s.uow.current_state_version
    rejected = s.world.begin_fight(fight)
    require(rejected.get("error_code") == 1 and rejected.get("msg") == "campaign_daily_limit_exhausted", f"exhausted Super MID113 not rejected: {rejected!r}")
    require(row["daily_limit"] == 0, "rejected MID113 mutated remaining attempts")
    require(s.uow.current_state_version == version_before_reject, "rejected MID113 consumed a state version")

    # DailyResetCoordinator participant restores the source baseline and reset_count.
    row["reset_count"] = 2
    result = CampaignDailyResetParticipant(DATA).reset(
        p,
        DailyResetContext(
            previous_day_id=100,
            current_day_id=101,
            current_day_start=0,
            now=0,
            trigger_mid=229,
        ),
    )
    require(result.changed, "Campaign reset participant did not report depleted Super row change")
    require(row["daily_limit"] == 3 and row["reset_count"] == 0, f"daily rollover did not restore Super baseline: {row!r}")

    return {
        "successful_mid114_sequence": [2, 1, 0],
        "duplicate_mid114_idempotent": True,
        "mid113_zero_guard": True,
        "daily_reset_restores": 3,
        "defeat_consumption": "DEFERRED_UNRESOLVED",
    }


def normal_campaign_regression_test() -> dict[str, object]:
    p, s, _ = services(uid="810020", energy=100)
    fight = {"campaign_id": 100001, "campaign_type": 1, "formation": ""}
    row = s.world._find_row(100001, 1)
    before_daily = int((row or {}).get("daily_limit", 0) or 0)
    require(s.world.begin_fight(fight).get("error_code") is None, "Normal MID113 regression")
    out = s.world.commit_fight_result({**fight, "star": 1})
    row2 = response_campaign(out, 100001)
    require(int(row2.get("daily_limit", 0) or 0) == before_daily, "Normal Campaign daily_limit changed")
    return {"normal_campaign_unchanged": True, "daily_limit": before_daily}


def main() -> None:
    report = {
        "pass": "81.0",
        "status": "PASS",
        "checks": {
            "persistence": persistence_replacement_test(),
            "super_campaign": super_campaign_attempt_test(),
            "normal_campaign": normal_campaign_regression_test(),
        },
        "scope": "Pass79 correction only; MID116/117/118 not implemented",
    }
    print(json.dumps(report, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
