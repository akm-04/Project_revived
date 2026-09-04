from __future__ import annotations

import copy
import json
import tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

from gxb_backend.state.daily_reset import (
    DailyResetCoordinator,
    DailyResetParticipantRegistry,
    QuickEnchantDailyResetParticipant,
    PurchaseCounterDailyResetParticipant,
    CampaignDailyResetParticipant,
    TaskDailyCacheInvalidationParticipant,
    merge_daily_reset_projection,
)
from gxb_backend.state.hero_advanced_progression_repository import HeroAdvancedProgressionRepository
from gxb_backend.state.player_database import JsonPlayerDatabase
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.server_clock import ServerClock, ServerDayClock
from gxb_backend.state.unit_of_work import UnitOfWork
from gxb_backend.state.account import AccountIdentity
from gxb_backend.state.repository import StateRepository

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"


def require(cond: bool, message: str) -> None:
    if not cond:
        raise AssertionError(message)


def epoch_local(year: int, month: int, day: int, hour: int, minute: int, second: int) -> int:
    tz = timezone(timedelta(hours=8))
    return int(datetime(year, month, day, hour, minute, second, tzinfo=tz).timestamp())


def make_registry() -> DailyResetParticipantRegistry:
    return DailyResetParticipantRegistry((
        QuickEnchantDailyResetParticipant(),
        PurchaseCounterDailyResetParticipant(),
        CampaignDailyResetParticipant(DATA),
        TaskDailyCacheInvalidationParticipant(),
    ))


def coordinator(player: PlayerState, now: int, commits: list[dict]) -> DailyResetCoordinator:
    clock = ServerDayClock(ServerClock(lambda: now))
    uow = UnitOfWork(player, lambda: commits.append(copy.deepcopy(vars(player))))
    return DailyResetCoordinator(player, uow, clock, make_registry())


def main() -> None:
    # 1) Exact recovered boundary: 04:59:59 -> old day; 05:00:00 -> next day.
    before = epoch_local(2026, 8, 22, 4, 59, 59)
    boundary = epoch_local(2026, 8, 22, 5, 0, 0)
    day_clock = ServerDayClock(ServerClock(lambda: boundary))
    require(day_clock.day_id(before) + 1 == day_clock.day_id(boundary), "05:00 GMT+8 day boundary drift")
    require(day_clock.day_start_epoch(day_clock.day_id(boundary)) == boundary, "day start epoch mismatch")

    current_day = day_clock.day_id(boundary)
    previous_day = current_day - 1

    # 2) Full source-owned rollover on ACTIVITIES: all proven participants reset,
    # spirit counter is explicitly preserved, and daily_updates is one-shot.
    player = PlayerState(player_id="790001", account_uid="790001")
    player.daily_reset_state = {"schema_version": 1, "current_day_id": previous_day, "initialized_at": before}
    player.daily_consume_state = {"schema_version": 1, "day": previous_day, "counts": {"2": 1, "7": 4}}
    player.buy_mana_times = 5
    player.buy_energy_times = 6
    player.buy_skill_times = 7
    player.buy_spirit_energy_times = 8
    player.world_map = {
        "normal": [],
        "super": [{"campaign_id": 100019, "star": 1, "daily_limit": 0, "reset_count": 2, "is_partner_drop": 0}],
    }
    player.mission_state = {"story": {"missions": {"80001": {"count": 1}}}, "daily_cache": {"stale": 1}}
    commits: list[dict] = []
    c = coordinator(player, boundary, commits)
    outcome = c.evaluate(229)
    require(outcome.rolled_over, "ACTIVITIES did not materialize rollover")
    require(len(commits) == 1, "rollover should commit exactly once")
    require(player.daily_consume_state.get("counts") == {}, "Quick Enchant daily counts not reset")
    require(player.buy_mana_times == player.buy_energy_times == player.buy_skill_times == 0, "global buy counters not reset")
    require(player.buy_spirit_energy_times == 8, "buy_spirit_energy_times must not reset")
    super_row = player.world_map["super"][0]
    require(super_row["daily_limit"] == 3 and super_row["reset_count"] == 0, "Super Campaign daily state not restored")
    require(player.mission_state.get("daily_cache") == {}, "Task daily cache not invalidated")
    require(player.mission_state["story"]["missions"]["80001"]["count"] == 1, "Story Mission state was incorrectly reset")
    require(outcome.projection == {
        "economy_": {
            "daily_updates": 1,
            "updates": {"buy_mana_times": 0, "buy_energy_times": 0, "buy_skill_times": 0},
        }
    }, "daily_updates wire shape drift")
    require("buy_spirit_energy_times" not in outcome.projection["economy_"]["updates"], "spirit counter leaked into source updates")

    # 3) Same-day reevaluation is inert: no second reset, no second notification.
    second = c.evaluate(229)
    require(not second.rolled_over and second.projection is None, "daily_updates repeated in the same source day")
    require(len(commits) == 1, "same-day coordinator unexpectedly persisted")

    # 4) Non-source trigger materializes reset but suppresses later stale pulse.
    player2 = PlayerState(player_id="790002", account_uid="790002", buy_skill_times=4)
    player2.daily_reset_state = {"schema_version": 1, "current_day_id": previous_day, "initialized_at": before}
    commits2: list[dict] = []
    nontrigger = coordinator(player2, boundary, commits2)
    first = nontrigger.evaluate(99)
    require(first.rolled_over and first.projection is None, "non-trigger rollover should not emit daily_updates")
    later = nontrigger.evaluate(229)
    require(later.projection is None, "stale daily_updates was emitted after non-trigger materialization")
    require(player2.daily_reset_state["notification"]["last_suppressed_day_id"] == current_day, "suppressed notification audit missing")

    # 5) TASK_LOAD_BY_TYPE is the bounded source-compatible fallback trigger.
    player3 = PlayerState(player_id="790003", account_uid="790003")
    player3.daily_reset_state = {"schema_version": 1, "current_day_id": previous_day, "initialized_at": before}
    out3 = coordinator(player3, boundary, []).evaluate(2736)
    require(out3.projection and out3.projection["economy_"]["daily_updates"] == 1, "TASK fallback trigger missing")

    # 6) Upgrade migration: a same-source-day legacy Quick Enchant marker seeds
    # the coordinator without destructive reset or an extra free purchase/use.
    player4 = PlayerState(player_id="790004", account_uid="790004", buy_skill_times=5)
    player4.daily_consume_state = {"schema_version": 1, "day": current_day, "counts": {"2": 1}}
    seed_commits: list[dict] = []
    seeded = coordinator(player4, boundary + 3600, seed_commits).evaluate(229)
    require(seeded.initialized and not seeded.rolled_over, "same-day migration should seed, not reset")
    require(player4.buy_skill_times == 5 and player4.daily_consume_state["counts"].get("2") == 1, "migration granted unintended extra daily use")
    require(seeded.projection is None, "migration seed fabricated daily_updates")

    # 7) A stale legacy UTC day without durable commit evidence is *not* enough
    # to reset every owner; this avoids an upgrade-time extra use in the
    # 05:00-08:00 GMT+8 ambiguity window. Durable prior-day UoW evidence does
    # authorize the full reset.
    player5 = PlayerState(player_id="790005", account_uid="790005", buy_skill_times=5)
    player5.daily_consume_state = {"schema_version": 1, "day": previous_day, "counts": {"2": 1}}
    conservative = coordinator(player5, boundary, []).evaluate(229)
    require(conservative.initialized and not conservative.rolled_over and player5.buy_skill_times == 5, "legacy UTC marker caused destructive upgrade reset")

    player5b = PlayerState(player_id="790005b", account_uid="790005b", buy_skill_times=5)
    player5b.daily_consume_state = {"schema_version": 1, "day": previous_day, "counts": {"2": 1}}
    player5b.persistence_state = {
        "contract_version": 1,
        "state_version": 3,
        "slice_revisions": {},
        "slice_schema_versions": {},
        "receipts": {},
        "claims": {},
        "migration": {},
        "last_commit": {"committed_at": before - 3600},
    }
    migrated = coordinator(player5b, boundary, []).evaluate(229)
    require(migrated.rolled_over and player5b.buy_skill_times == 0, "durably stale prior-day state was not migrated through reset")

    # 8) Quick Enchant repository no longer owns a UTC-midnight clock. Once the
    # coordinator materializes a day, changing PlayerState.now cannot clear it.
    player6 = PlayerState(player_id="790006", account_uid="790006")
    player6.daily_consume_state = {"schema_version": 2, "source_day_id": current_day, "day": current_day, "counts": {"2": 1}}
    repo = object.__new__(HeroAdvancedProgressionRepository)
    repo.player = player6
    player6.now = lambda: boundary + 3 * 86_400  # type: ignore[method-assign]
    repo.daily_consume_load()
    require(player6.daily_consume_state["counts"].get("2") == 1, "Quick Enchant still performs local day rollover")

    # 9) Persistence round-trip keeps the new server-only daily_reset_state.
    player7 = PlayerState(player_id="790007", account_uid="790007")
    player7.daily_reset_state = copy.deepcopy(player.daily_reset_state)
    account = AccountIdentity(uid="790007", token="token", sid="sid", username="pass79")
    with tempfile.TemporaryDirectory() as td:
        path = Path(td) / "player.json"
        db = JsonPlayerDatabase(path)
        db.save(account, player7)
        _account, loaded = db.load(account, PlayerState(player_id="790007", account_uid="790007"))
        require(loaded.daily_reset_state == player7.daily_reset_state, "daily_reset_state persistence round-trip failed")

    # 10) Projection merge keeps daily_updates/updates as siblings inside economy_.
    merged = merge_daily_reset_projection({"economy_": {"mana": 123}}, outcome.projection)
    require(merged["economy_"]["mana"] == 123, "daily projection clobbered handler economy")
    require(merged["economy_"]["daily_updates"] == 1, "daily_updates missing after merge")
    require(merged["economy_"]["updates"]["buy_skill_times"] == 0, "updates sibling merge failed")

    # 11) StateRepository request-bound integration: the lightweight evaluator
    # uses the shared authoritative clock and persists the source-day rollover
    # before a handler would execute, without constructing the full service graph.
    shared_clock = ServerClock(lambda: boundary)
    with tempfile.TemporaryDirectory() as td:
        temp = Path(td)
        state = StateRepository(
            DATA / "player_db.json",
            profile="established",
            legacy_path=ROOT / "state" / "gxb_state.json",
            multiuser_root=temp / "server_state",
            server_clock=shared_clock,
        )
        sandbox = state.store.sandbox_player()
        sandbox.daily_reset_state = {
            "schema_version": 1,
            "current_day_id": previous_day,
            "initialized_at": before,
        }
        sandbox.buy_skill_times = 3
        state.store.save_player(sandbox)
        req = {"mid": 229, "token": "local_token", "region": 125}
        with state.request_scope(req):
            response1 = state.evaluate_daily_reset(229)
        with state.request_scope(req):
            response2 = state.evaluate_daily_reset(229)
        require(response1 is not None and response1.projection is not None, "request-bound evaluator failed to emit daily projection")
        require(response1.projection["economy_"]["updates"]["buy_skill_times"] == 0, "request-bound evaluator emitted stale buy_skill_times")
        require(response2 is not None and response2.projection is None, "request-bound evaluator repeated daily projection")

    report = {
        "pass": "79.0",
        "status": "PASS",
        "checks": 11,
        "boundary": "05:00 GMT+8",
        "source_day_formula": "floor((unix_timestamp + 10800) / 86400)",
        "notification_mids": [229, 2736],
        "participants": list(make_registry().names),
    }
    print(json.dumps(report, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
