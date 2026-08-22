"""Pass79 canonical 05:00 GMT+8 daily-reset ownership.

The recovered client defines its server day as::

    day_id = floor((unix_timestamp + 3 hours) / 86400)

The +3 hour shift is equivalent to a 05:00 boundary in GMT+8.  This module
keeps that time math stateless and centralizes durable one-player rollover in a
registry-driven coordinator.  Participants own only already-proven state;
future domains can register without changing the clock/coordinator core.
"""
from __future__ import annotations

import copy
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Protocol

from .player_state import PlayerState
from .server_clock import ServerClock, ServerDayClock
from .unit_of_work import OperationContext, UnitOfWork


@dataclass(frozen=True)
class DailyResetParticipantResult:
    name: str
    changed: bool
    slices: tuple[str, ...] = ()
    details: dict[str, Any] | None = None


@dataclass(frozen=True)
class DailyResetContext:
    previous_day_id: int | None
    current_day_id: int
    current_day_start: int
    now: int
    trigger_mid: int | None


@dataclass(frozen=True)
class DailyResetOutcome:
    initialized: bool = False
    rolled_over: bool = False
    previous_day_id: int | None = None
    current_day_id: int | None = None
    projection: dict[str, Any] | None = None
    participant_results: tuple[DailyResetParticipantResult, ...] = ()
    initialization_mode: str | None = None


class DailyResetParticipant(Protocol):
    name: str

    def reset(self, player: PlayerState, context: DailyResetContext) -> DailyResetParticipantResult:
        ...


class DailyResetParticipantRegistry:
    """Ordered, duplicate-safe registry for source-proven daily reset owners."""

    def __init__(self, participants: Iterable[DailyResetParticipant] | None = None) -> None:
        self._participants: list[DailyResetParticipant] = []
        self._names: set[str] = set()
        for participant in participants or ():
            self.register(participant)

    def register(self, participant: DailyResetParticipant) -> None:
        name = str(getattr(participant, "name", "")).strip()
        if not name:
            raise ValueError("daily reset participant requires a stable name")
        if name in self._names:
            raise ValueError(f"duplicate daily reset participant: {name}")
        self._names.add(name)
        self._participants.append(participant)

    @property
    def participants(self) -> tuple[DailyResetParticipant, ...]:
        return tuple(self._participants)

    @property
    def names(self) -> tuple[str, ...]:
        return tuple(str(participant.name) for participant in self._participants)


class QuickEnchantDailyResetParticipant:
    name = "quick_enchant_daily_consume"

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def reset(self, player: PlayerState, context: DailyResetContext) -> DailyResetParticipantResult:
        root = player.daily_consume_state if isinstance(player.daily_consume_state, dict) else {}
        before = copy.deepcopy(root)
        player.daily_consume_state = root
        root["schema_version"] = 2
        # Keep ``day`` as a compatibility alias, but its semantics are now the
        # canonical source-day id rather than the removed UTC-midnight day.
        root["day"] = int(context.current_day_id)
        root["source_day_id"] = int(context.current_day_id)
        root["counts"] = {}
        changed = before != root
        return DailyResetParticipantResult(
            self.name,
            changed,
            ("daily_consume",) if changed else (),
            {
                "consume_2_before": self._int((before.get("counts") or {}).get("2"), 0)
                if isinstance(before.get("counts"), dict)
                else 0,
                "source_day_id": int(context.current_day_id),
            },
        )


class PurchaseCounterDailyResetParticipant:
    name = "global_purchase_counters"
    RESET_FIELDS = ("buy_mana_times", "buy_energy_times", "buy_skill_times")

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def reset(self, player: PlayerState, context: DailyResetContext) -> DailyResetParticipantResult:
        before = {field: max(0, self._int(getattr(player, field, 0))) for field in self.RESET_FIELDS}
        for field in self.RESET_FIELDS:
            setattr(player, field, 0)
        after = {field: max(0, self._int(getattr(player, field, 0))) for field in self.RESET_FIELDS}
        changed = before != after
        return DailyResetParticipantResult(
            self.name,
            changed,
            ("economy_daily_counters",) if changed else (),
            {
                "before": before,
                "after": after,
                "buy_spirit_energy_times_preserved": max(
                    0, self._int(getattr(player, "buy_spirit_energy_times", 0))
                ),
            },
        )


class CampaignDailyResetParticipant:
    name = "campaign_super_daily_limits"

    def __init__(self, data_dir: Path) -> None:
        path = Path(data_dir) / "pass75_campaign_ownership_meta.json"
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise RuntimeError(f"[DAILY_RESET] invalid campaign ownership metadata {path}: {exc}") from exc
        campaigns = data.get("campaigns") if isinstance(data, dict) else None
        super_ids = data.get("super_campaign_ids") if isinstance(data, dict) else None
        if not isinstance(campaigns, dict) or not isinstance(super_ids, list):
            raise RuntimeError(f"[DAILY_RESET] malformed campaign ownership metadata {path}")
        self._daily_limits: dict[int, int] = {}
        for raw_id in super_ids:
            try:
                cid = int(raw_id)
            except (TypeError, ValueError):
                continue
            row = campaigns.get(str(cid))
            if not isinstance(row, dict):
                continue
            try:
                daily_limit = int(row.get("daily_limit", 0) or 0)
            except (TypeError, ValueError):
                daily_limit = 0
            if cid > 0 and daily_limit >= 0:
                self._daily_limits[cid] = daily_limit

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def reset(self, player: PlayerState, context: DailyResetContext) -> DailyResetParticipantResult:
        world = player.world_map if isinstance(player.world_map, dict) else {}
        rows = world.get("super") if isinstance(world.get("super"), list) else []
        changed_rows: list[dict[str, int]] = []
        for row in rows:
            if not isinstance(row, dict):
                continue
            cid = self._int(row.get("campaign_id"), 0)
            if cid not in self._daily_limits:
                continue
            source_limit = max(0, self._daily_limits[cid])
            old_limit = self._int(row.get("daily_limit"), 0)
            old_reset = self._int(row.get("reset_count"), 0)
            if old_limit != source_limit or old_reset != 0:
                row["daily_limit"] = source_limit
                row["reset_count"] = 0
                changed_rows.append(
                    {
                        "campaign_id": cid,
                        "daily_limit_before": old_limit,
                        "daily_limit_after": source_limit,
                        "reset_count_before": old_reset,
                    }
                )
        return DailyResetParticipantResult(
            self.name,
            bool(changed_rows),
            ("campaign",) if changed_rows else (),
            {"rows_reset": changed_rows},
        )


class TaskDailyCacheInvalidationParticipant:
    """Invalidate only server-owned Task cache metadata; never generate missions."""

    name = "task_daily_cache_invalidation"

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def reset(self, player: PlayerState, context: DailyResetContext) -> DailyResetParticipantResult:
        root = player.mission_state if isinstance(player.mission_state, dict) else {}
        player.mission_state = root
        before_cache = copy.deepcopy(root.get("daily_cache"))
        before_day = self._int(root.get("daily_cache_day_id"), -1)
        before_generation = max(0, self._int(root.get("daily_cache_generation"), 0))

        # This is deliberately cache-only. ``player.missions`` and canonical
        # Story/Awakening rows are untouched until their domain research owns
        # generation/progress semantics.
        if "daily_cache" in root:
            root["daily_cache"] = {}
        root["daily_cache_day_id"] = int(context.current_day_id)
        root["daily_cache_generation"] = before_generation + 1
        root["daily_cache_invalidated_at"] = int(context.now)

        changed = (
            before_cache not in (None, {})
            or before_day != int(context.current_day_id)
            or before_generation + 1 != before_generation
        )
        return DailyResetParticipantResult(
            self.name,
            changed,
            ("mission_daily_cache",) if changed else (),
            {
                "source_day_id": int(context.current_day_id),
                "generation": before_generation + 1,
                "cached_payload_cleared": before_cache not in (None, {}),
            },
        )


def build_default_daily_reset_registry(data_dir: Path) -> DailyResetParticipantRegistry:
    return DailyResetParticipantRegistry(
        (
            QuickEnchantDailyResetParticipant(),
            PurchaseCounterDailyResetParticipant(),
            CampaignDailyResetParticipant(data_dir),
            TaskDailyCacheInvalidationParticipant(),
        )
    )


class DailyResetCoordinator:
    """Durable lazy-evaluation owner for one player's canonical source day."""

    SCHEMA_VERSION = 1
    SOURCE_NOTIFICATION_MIDS = frozenset({229, 2736})  # ACTIVITIES, TASK_LOAD_BY_TYPE

    def __init__(
        self,
        player: PlayerState,
        uow: UnitOfWork,
        day_clock: ServerDayClock,
        registry: DailyResetParticipantRegistry,
    ) -> None:
        self.player = player
        self.uow = uow
        self.day_clock = day_clock
        self.registry = registry

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _raw_state(self) -> dict[str, Any]:
        value = self.player.daily_reset_state if isinstance(self.player.daily_reset_state, dict) else {}
        self.player.daily_reset_state = value
        return value

    def _notification_projection(self) -> dict[str, Any]:
        return {
            "economy_": {
                "daily_updates": 1,
                "updates": {
                    "buy_mana_times": max(0, self._int(self.player.buy_mana_times)),
                    "buy_energy_times": max(0, self._int(self.player.buy_energy_times)),
                    "buy_skill_times": max(0, self._int(self.player.buy_skill_times)),
                },
            }
        }

    def _migration_decision(self, current_day_id: int) -> tuple[bool, str, int | None]:
        """Choose reset-vs-seed without granting an upgrade-time extra daily use.

        Pass75 has no canonical source-day marker. The legacy Quick-Enchant
        ``day`` used UTC midnight, so its value alone is unsafe evidence during
        the 05:00-08:00 GMT+8 window: a consume made after the *source* reset can
        still carry the previous UTC day number. Prefer the durable UoW
        ``last_commit`` because every currently-active daily owner (Quick
        Enchant and Skill Point purchase) commits through that boundary. If no
        durable stale proof exists, seed the current source day conservatively
        and let the next 05:00 boundary perform the first full reset.
        """
        persistence = self.player.persistence_state if isinstance(self.player.persistence_state, dict) else {}
        last_commit = persistence.get("last_commit") if isinstance(persistence.get("last_commit"), dict) else {}
        committed_at = self._int(last_commit.get("committed_at"), 0)
        if committed_at > 0:
            committed_day = self.day_clock.day_id(committed_at)
            if committed_day < current_day_id:
                return True, "RESET_LAST_UOW_COMMIT_BEHIND_SOURCE_DAY", committed_day
            return False, "SEED_CURRENT_SOURCE_DAY_FROM_LAST_UOW_COMMIT", current_day_id

        legacy = self.player.daily_consume_state if isinstance(self.player.daily_consume_state, dict) else {}
        legacy_day = self._int(legacy.get("day"), -1)
        if legacy_day >= 0:
            return False, "SEED_CURRENT_SOURCE_DAY_LEGACY_UTC_DAY_UNSAFE_FOR_GLOBAL_RESET", current_day_id

        return False, "SEED_CURRENT_SOURCE_DAY_NO_STALE_EVIDENCE", current_day_id

    def _write_state(
        self,
        *,
        current_day_id: int,
        now: int,
        initialized_at: int,
        initialization_mode: str,
        previous_day_id: int | None,
        results: tuple[DailyResetParticipantResult, ...],
        trigger_mid: int | None,
        emitted: bool,
    ) -> None:
        state = self._raw_state()
        notification = state.get("notification") if isinstance(state.get("notification"), dict) else {}
        state.clear()
        state.update(
            {
                "schema_version": self.SCHEMA_VERSION,
                "current_day_id": int(current_day_id),
                "current_day_start": int(self.day_clock.day_start_epoch(current_day_id)),
                "initialized_at": int(initialized_at),
                "initialization_mode": str(initialization_mode),
                "last_materialized_at": int(now),
                "participants": list(self.registry.names),
                "last_rollover": None,
                "notification": notification,
            }
        )
        if previous_day_id is not None:
            state["last_rollover"] = {
                "from_day_id": int(previous_day_id),
                "to_day_id": int(current_day_id),
                "materialized_at": int(now),
                "trigger_mid": int(trigger_mid) if trigger_mid is not None else None,
                "participants": [
                    {
                        "name": result.name,
                        "changed": bool(result.changed),
                        "details": copy.deepcopy(result.details) if result.details is not None else {},
                    }
                    for result in results
                ],
            }
        if emitted:
            notification["last_emitted_day_id"] = int(current_day_id)
            notification["last_emitted_mid"] = int(trigger_mid) if trigger_mid is not None else None
            notification["last_emitted_at"] = int(now)
        elif previous_day_id is not None:
            notification["last_suppressed_day_id"] = int(current_day_id)
            notification["last_suppressed_mid"] = int(trigger_mid) if trigger_mid is not None else None
            notification["last_suppressed_at"] = int(now)
            notification["last_suppressed_reason"] = "ROLLOVER_MATERIALIZED_ON_NON_SOURCE_TRIGGER"
        state["notification"] = notification
        self.player.daily_reset_state = state

    def evaluate(self, trigger_mid: int | None = None) -> DailyResetOutcome:
        now = self.day_clock.now()
        current_day_id = self.day_clock.day_id(now)
        raw = self._raw_state()
        stored_day = self._int(raw.get("current_day_id"), -1)

        # Clock rollback must never re-open an older daily window.  Keep the
        # durable higher day marker and resume normally after wall clock catches up.
        if stored_day > current_day_id:
            print(
                "[DAILY_RESET] clock_regression_ignored "
                f"player={self.player.player_id} mid={trigger_mid} now={now} "
                f"stored_day_id={stored_day} observed_day_id={current_day_id} "
                f"resume_at_or_after={self.day_clock.day_start_epoch(stored_day)}"
            )
            return DailyResetOutcome(
                current_day_id=stored_day,
                initialization_mode="CLOCK_REGRESSION_IGNORED",
            )
        if stored_day == current_day_id:
            return DailyResetOutcome(current_day_id=current_day_id)

        initialized_at = self._int(raw.get("initialized_at"), 0) or now
        initialization_mode = str(raw.get("initialization_mode") or "ROLLOVER_FROM_DURABLE_MARKER")
        previous_day_id: int | None = stored_day if stored_day >= 0 else None
        should_reset = stored_day >= 0

        if stored_day < 0:
            should_reset, initialization_mode, inferred_previous = self._migration_decision(current_day_id)
            if should_reset:
                previous_day_id = inferred_previous

        emitted = bool(should_reset and trigger_mid in self.SOURCE_NOTIFICATION_MIDS)
        results: tuple[DailyResetParticipantResult, ...] = ()
        context = OperationContext(
            actor_player_id=str(self.player.player_id),
            domain="daily_reset",
            operation_name="rollover" if should_reset else "initialize_day_marker",
            protocol_mid=int(trigger_mid) if trigger_mid is not None else None,
            server_time=now,
        )
        with self.uow.transaction(context):
            if should_reset:
                reset_context = DailyResetContext(
                    previous_day_id=previous_day_id,
                    current_day_id=current_day_id,
                    current_day_start=self.day_clock.day_start_epoch(current_day_id),
                    now=now,
                    trigger_mid=trigger_mid,
                )
                built: list[DailyResetParticipantResult] = []
                for participant in self.registry.participants:
                    result = participant.reset(self.player, reset_context)
                    built.append(result)
                    for slice_id in result.slices:
                        self.uow.touch_slice(slice_id)
                results = tuple(built)
            self._write_state(
                current_day_id=current_day_id,
                now=now,
                initialized_at=initialized_at,
                initialization_mode=initialization_mode,
                previous_day_id=previous_day_id if should_reset else None,
                results=results,
                trigger_mid=trigger_mid,
                emitted=emitted,
            )
            self.uow.touch_slice("daily_reset")
            self.uow.request_save()

        outcome = DailyResetOutcome(
            initialized=stored_day < 0,
            rolled_over=should_reset,
            previous_day_id=previous_day_id,
            current_day_id=current_day_id,
            projection=self._notification_projection() if emitted else None,
            participant_results=results,
            initialization_mode=initialization_mode,
        )
        print(
            "[DAILY_RESET] materialized "
            f"player={self.player.player_id} mid={trigger_mid} now={now} "
            f"previous_day_id={previous_day_id} current_day_id={current_day_id} "
            f"mode={initialization_mode} reset={int(should_reset)} emitted={int(emitted)} "
            f"participants={','.join(result.name for result in results) if results else '-'}"
        )
        return outcome


def merge_daily_reset_projection(payload: Any, projection: dict[str, Any] | None) -> Any:
    """Merge the source-shaped one-shot daily update envelope into a response."""
    if not projection or not isinstance(payload, dict):
        return payload
    result = dict(payload)
    incoming_economy = projection.get("economy_")
    if not isinstance(incoming_economy, dict):
        return result
    merged_economy = dict(result.get("economy_")) if isinstance(result.get("economy_"), dict) else {}
    for key, value in incoming_economy.items():
        if key == "updates" and isinstance(value, dict):
            existing_updates = merged_economy.get("updates")
            updates = dict(existing_updates) if isinstance(existing_updates, dict) else {}
            updates.update(value)
            merged_economy["updates"] = updates
        else:
            merged_economy[key] = copy.deepcopy(value)
    result["economy_"] = merged_economy
    return result
