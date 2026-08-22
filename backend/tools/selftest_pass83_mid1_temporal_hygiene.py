from __future__ import annotations

import contextlib
import io
import json
import tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

from gxb_backend.config import Settings
from gxb_backend.handlers.bootstrap import BootstrapHandlers
from gxb_backend.handlers.context import HandlerContext
from gxb_backend.state.daily_reset import DailyResetCoordinator, build_default_daily_reset_registry
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.repository import StateRepository
from gxb_backend.state.server_clock import ServerClock, ServerDayClock
from gxb_backend.state.temporal_policy_service import TemporalPolicyService
from gxb_backend.state.unit_of_work import UnitOfWork

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"


def require(cond: bool, message: str) -> None:
    if not cond:
        raise AssertionError(message)


def epoch_local(year: int, month: int, day: int, hour: int, minute: int, second: int) -> int:
    tz = timezone(timedelta(hours=8))
    return int(datetime(year, month, day, hour, minute, second, tzinfo=tz).timestamp())


def bootstrap_settings(temp: Path) -> Settings:
    return Settings(
        player_db_path=DATA / "player_db.json",
        multiuser_root=temp / "server_state",
        state_path=ROOT / "state" / "gxb_state.json",
        runtime_log_dir=temp / "runtime_logs",
        static_asset_root=ROOT / "local_assets",
        bootstrap_detail_mode="stage3",
    )


def test_mid1_ordering_and_migration() -> dict:
    now = epoch_local(2026, 8, 24, 6, 0, 0)
    day_clock = ServerDayClock(ServerClock(lambda: now))
    previous_day = day_clock.day_id(now) - 1
    prior_commit = day_clock.day_start_epoch(previous_day) + 3600

    with tempfile.TemporaryDirectory(prefix="gxb-pass83-mid1-") as td:
        temp = Path(td)
        state = StateRepository(
            DATA / "player_db.json",
            profile="established",
            legacy_path=ROOT / "state" / "gxb_state.json",
            multiuser_root=temp / "server_state",
            server_clock=ServerClock(lambda: now),
        )
        sandbox = state.store.sandbox_player()
        sandbox.daily_reset_state = {}
        sandbox.daily_consume_state = {"schema_version": 1, "day": previous_day, "counts": {"2": 1}}
        sandbox.buy_mana_times = 4
        sandbox.buy_energy_times = 5
        sandbox.buy_skill_times = 6
        sandbox.world_map = {
            "normal": list((sandbox.world_map or {}).get("normal") or []),
            "super": [{"campaign_id": 100019, "star": 1, "daily_limit": 0, "reset_count": 2, "is_partner_drop": 0}],
        }
        sandbox.persistence_state = {
            "contract_version": 1,
            "state_version": 7,
            "slice_revisions": {},
            "slice_schema_versions": {},
            "receipts": {},
            "claims": {},
            "migration": {},
            "last_commit": {
                "schema_version": 1,
                "committed_at": prior_commit,
                "state_version_before": 6,
                "state_version_after": 7,
                "domain": "test",
                "operation": "prior_day",
                "protocol_mid": 99,
            },
        }
        # A future temporal anchor proves daily-reset evaluation must run before
        # materialize_all() and also exercises the Pass83 rebase on the same MID1.
        sandbox.skill_point = 20
        sandbox.skill_time = now + 7200
        state.store.save_player(sandbox)

        settings = bootstrap_settings(temp)
        req = {"mid": 1, "token": "local_token", "region": 125, "sid": "local_sid"}
        with state.request_scope(req):
            response = BootstrapHandlers(HandlerContext(state, settings)).retrieve_token(req)
            bound = state.get_player()
            require(int(response.get("error_code", 0) or 0) == 0, "MID1 unexpectedly failed")
            require(bound.daily_reset_state.get("current_day_id") == day_clock.day_id(now), "MID1 did not materialize current source day")
            require(bound.daily_reset_state.get("initialization_mode") == "RESET_LAST_UOW_COMMIT_BEHIND_SOURCE_DAY", "stale migration evidence was lost before reset")
            require(bound.daily_consume_state.get("counts") == {}, "MID1 did not clear Quick Enchant before hydration")
            require(bound.buy_mana_times == bound.buy_energy_times == bound.buy_skill_times == 0, "MID1 did not reset purchase counters")
            super_rows = list((bound.world_map or {}).get("super") or [])
            require(super_rows and int(super_rows[0].get("daily_limit", -1)) == 3, "MID1 did not restore Super Campaign attempts")
            require(int(super_rows[0].get("reset_count", -1)) == 0, "MID1 did not reset Super reset_count")
            require(bound.skill_point == 20 and bound.skill_time == now, "future Skill Point anchor was not neutrally rebased")
            detail = response.get("detail") or {}
            require(int((detail.get("17") or {}).get("buy_skill_times", -1)) == 0, "MID1 detail[17] captured stale buy_skill_times")
            require(int((detail.get("17") or {}).get("skill_time", -1)) == now, "MID1 detail[17] projected a future skill_time")
            world = detail.get("112") or {}
            projected_super = list(world.get("super") or [])
            require(projected_super and int(projected_super[0].get("daily_limit", -1)) == 3, "MID1 detail[112] captured stale Super attempts")
            require(int(response.get("server_time", -1)) == now, "MID1 did not project authoritative repository ServerClock")
            require("economy_" not in response, "MID1 fabricated a daily_updates economy pulse")
            # Reset must commit before temporal hygiene; temporal then becomes the
            # later last_commit, proving ordering rather than suppressing persistence.
            last_commit = (bound.persistence_state or {}).get("last_commit") or {}
            require(last_commit.get("domain") == "temporal", "temporal commit did not occur after daily reset")
            require(int(last_commit.get("committed_at", -1)) == now, "temporal commit did not use authoritative server clock")

        persisted = state.store.sandbox_player()
        require(persisted.daily_consume_state.get("counts") == {}, "MID1 Quick Enchant reset did not persist")
        require(int(((persisted.world_map or {}).get("super") or [{}])[0].get("daily_limit", -1)) == 3, "MID1 Super reset did not persist")
        require(persisted.skill_time == now, "future temporal anchor rebase did not persist")

    return {
        "migration_reset_before_temporal": True,
        "detail17_current": True,
        "detail112_current": True,
        "mid1_daily_updates_suppressed": True,
        "authoritative_server_clock_projection": True,
    }



def test_mid1_existing_marker_rollover() -> dict:
    now = epoch_local(2026, 8, 25, 6, 0, 0)
    day_clock = ServerDayClock(ServerClock(lambda: now))
    current_day = day_clock.day_id(now)
    previous_day = current_day - 1
    with tempfile.TemporaryDirectory(prefix="gxb-pass83-cold-marker-") as td:
        temp = Path(td)
        state = StateRepository(
            DATA / "player_db.json", profile="established",
            legacy_path=ROOT / "state" / "gxb_state.json",
            multiuser_root=temp / "server_state", server_clock=ServerClock(lambda: now),
        )
        sandbox = state.store.sandbox_player()
        sandbox.daily_reset_state = {
            "schema_version": 1, "current_day_id": previous_day,
            "initialized_at": day_clock.day_start_epoch(previous_day),
        }
        sandbox.daily_consume_state = {"schema_version": 2, "source_day_id": previous_day, "day": previous_day, "counts": {"2": 1}}
        sandbox.buy_mana_times = 2
        sandbox.buy_energy_times = 3
        sandbox.buy_skill_times = 4
        sandbox.world_map = {
            "normal": list((sandbox.world_map or {}).get("normal") or []),
            "super": [{"campaign_id": 100019, "star": 1, "daily_limit": 0, "reset_count": 1, "is_partner_drop": 0}],
        }
        state.store.save_player(sandbox)
        req = {"mid": 1, "token": "local_token", "region": 125, "sid": "local_sid"}
        with state.request_scope(req):
            response = BootstrapHandlers(HandlerContext(state, bootstrap_settings(temp))).retrieve_token(req)
            player = state.get_player()
            require(player.daily_reset_state.get("current_day_id") == current_day, "cold MID1 did not advance existing day marker")
            require(player.daily_consume_state.get("counts") == {}, "cold MID1 did not clear Quick Enchant")
            require(player.buy_mana_times == player.buy_energy_times == player.buy_skill_times == 0, "cold MID1 did not reset purchase counters")
            require(int((((response.get("detail") or {}).get("112") or {}).get("super") or [{}])[0].get("daily_limit", -1)) == 3, "cold MID1 detail[112] did not carry restored Super attempts")
            require(int(((response.get("detail") or {}).get("17") or {}).get("buy_skill_times", -1)) == 0, "cold MID1 detail[17] did not carry reset purchase counter")
            later = state.evaluate_daily_reset(229)
            require(later is not None and not later.rolled_over and later.projection is None, "post-MID1 request repeated rollover or emitted stale daily_updates")
    return {
        "existing_marker_previous_to_current": True,
        "bootstrap_detail_current": True,
        "post_login_no_duplicate_or_stale_pulse": True,
    }


def test_mid1_reset_failure_fail_closed() -> dict:
    now = epoch_local(2026, 8, 26, 6, 0, 0)
    day_clock = ServerDayClock(ServerClock(lambda: now))
    prior_commit = day_clock.day_start_epoch(day_clock.day_id(now) - 1) + 1800
    with tempfile.TemporaryDirectory(prefix="gxb-pass83-reset-fail-") as td:
        temp = Path(td)
        state = StateRepository(
            DATA / "player_db.json", profile="established",
            legacy_path=ROOT / "state" / "gxb_state.json",
            multiuser_root=temp / "server_state", server_clock=ServerClock(lambda: now),
        )
        sandbox = state.store.sandbox_player()
        sandbox.daily_reset_state = {}
        sandbox.persistence_state = {
            "contract_version": 1, "state_version": 11, "slice_revisions": {},
            "slice_schema_versions": {}, "receipts": {}, "claims": {}, "migration": {},
            "last_commit": {
                "schema_version": 1, "committed_at": prior_commit,
                "state_version_before": 10, "state_version_after": 11,
                "domain": "preexisting", "operation": "stale_evidence", "protocol_mid": 99,
            },
        }
        sandbox.skill_point = 5
        sandbox.skill_time = now + 7200
        state.store.save_player(sandbox)
        before = json.loads(json.dumps(sandbox.persistence_state))
        state.evaluate_daily_reset = lambda trigger_mid=None: None  # type: ignore[method-assign]
        req = {"mid": 1, "token": "local_token", "region": 125, "sid": "local_sid"}
        with state.request_scope(req):
            response = BootstrapHandlers(HandlerContext(state, bootstrap_settings(temp))).retrieve_token(req)
            bound = state.get_player()
            require(int(response.get("error_code", 0) or 0) == 1, "MID1 did not fail closed when bound reset evaluation failed")
            require((bound.persistence_state or {}).get("last_commit") == before.get("last_commit"), "temporal persistence overwrote migration evidence after reset failure")
            require(int((bound.persistence_state or {}).get("state_version", -1)) == 11, "state_version advanced after reset failure")
            require(bound.skill_time == now + 7200, "temporal hygiene ran even though reset decision failed")
    return {
        "login_fail_closed": True,
        "last_commit_preserved": True,
        "temporal_not_run": True,
    }

def test_future_anchor_hygiene() -> dict:
    now = epoch_local(2026, 8, 24, 6, 30, 0)
    player = PlayerState(player_id="830002", account_uid="830002")
    player.lev = 1
    player.vip = 0
    player.privilege_left_card_day = 0
    player.energy = 50
    player.energy_time = now + 900
    player.spirit_energy = 100
    player.spirit_energy_time = now + 900
    player.skill_point = 5
    player.skill_time = now + 900
    commits: list[int] = []
    service = TemporalPolicyService(
        player,
        DATA,
        lambda: commits.append(1),
        clock=ServerClock(lambda: now),
    )
    before = {
        "energy": player.energy,
        "spirit_energy": player.spirit_energy,
        "skill_point": player.skill_point,
    }
    changes = service.materialize_all(persist=True, publish=False)
    require(player.energy == before["energy"], "future Energy anchor rebase changed balance")
    require(player.spirit_energy == before["spirit_energy"], "future Spirit Energy anchor rebase changed balance")
    require(player.skill_point == before["skill_point"], "future Skill Point anchor rebase changed balance")
    require(player.energy_time == player.spirit_energy_time == player.skill_time == now, "future anchors were not rebased to now")
    require(all((now - getattr(player, field)) >= 0 for field in ("energy_time", "spirit_energy_time", "skill_time")), "src_64 recoverByTime could still see a negative elapsed delta")
    require(all(changes[key].delta == 0 for key in ("energy", "spirit_energy", "skill_point")), "future-anchor hygiene fabricated resource delta")
    require(len(commits) == 1, "future-anchor hygiene should persist one grouped materialization")

    # Source full-pool sentinel still wins over rebasing.
    player.energy = 60
    player.energy_time = now + 900
    full = service.materialize("energy")
    require(full.after.balance == 60 and player.energy_time == 0, "full Energy did not preserve source zero sentinel")
    return {
        "resources": ["energy", "spirit_energy", "skill_point"],
        "balance_neutral": True,
        "rebase_to_now": True,
        "full_pool_zero_sentinel": True,
    }


def test_high_water_observability() -> dict:
    now = epoch_local(2026, 8, 24, 4, 0, 0)
    day_clock = ServerDayClock(ServerClock(lambda: now))
    observed = day_clock.day_id(now)
    stored = observed + 1
    player = PlayerState(player_id="830003", account_uid="830003", buy_skill_times=5)
    player.daily_reset_state = {"schema_version": 1, "current_day_id": stored, "initialized_at": now - 86400}
    commits: list[int] = []
    c = DailyResetCoordinator(
        player,
        UnitOfWork(player, lambda: commits.append(1)),
        day_clock,
        build_default_daily_reset_registry(DATA),
    )
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        rollback = c.evaluate(1)
    log = buf.getvalue()
    require(rollback.initialization_mode == "CLOCK_REGRESSION_IGNORED", "clock rollback protection weakened")
    require(player.buy_skill_times == 5 and commits == [], "clock rollback reopened daily entitlement")
    require("clock_regression_ignored" in log and f"stored_day_id={stored}" in log and f"observed_day_id={observed}" in log, "clock regression diagnostics incomplete")

    # Catching up to the high-water day is still same-day/inert.
    catchup_now = day_clock.day_start_epoch(stored) + 3600
    c.day_clock = ServerDayClock(ServerClock(lambda: catchup_now))
    catchup = c.evaluate(1)
    require(not catchup.rolled_over and player.buy_skill_times == 5 and commits == [], "catch-up to high-water day incorrectly reset")

    # Crossing high-water+1 performs exactly one reset.
    next_now = day_clock.day_start_epoch(stored + 1)
    c.day_clock = ServerDayClock(ServerClock(lambda: next_now))
    crossed = c.evaluate(1)
    require(crossed.rolled_over and player.buy_skill_times == 0 and len(commits) == 1, "high-water+1 did not reset exactly once")
    again = c.evaluate(1)
    require(not again.rolled_over and len(commits) == 1, "high-water+1 reset repeated")
    return {
        "rollback_ignored": True,
        "diagnostic_fields": ["stored_day_id", "observed_day_id", "resume_at_or_after"],
        "catchup_same_day_inert": True,
        "high_water_plus_one_exactly_once": True,
    }


def main() -> None:
    report = {
        "pass": "83.0",
        "status": "PASS",
        "scope": "MID1 ordering + temporal future-anchor hygiene + high-water observability only",
        "mid1": test_mid1_ordering_and_migration(),
        "cold_mid1_existing_marker": test_mid1_existing_marker_rollover(),
        "mid1_reset_failure": test_mid1_reset_failure_fail_closed(),
        "temporal": test_future_anchor_hygiene(),
        "high_water": test_high_water_observability(),
        "hard_boundary": "MID116/117/118 and new domains not implemented",
    }
    print(json.dumps(report, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
