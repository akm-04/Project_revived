"""Pass71 specialized ownership for the four global regenerating resources.

The client projects elapsed whole intervals locally, but authoritative amount and
anchor live on the server.  Natural caps stop regeneration; they are not generic
inventory ceilings, so grants/purchases may remain above cap.  Arena Invitation
is modeled but deliberately disabled because effective src_64 still contains a
player-table accessor mismatch.
"""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Mapping

from .server_clock import ServerClock
from .unit_of_work import OperationContext, PlayerUnitOfWork
from .vip_policy import VipPrivilegeResolver, VipProgressionPolicy


class TemporalPolicyError(ValueError):
    pass


class TemporalPolicyUnavailable(TemporalPolicyError):
    pass


class TemporalInsufficientBalance(TemporalPolicyError):
    pass


@dataclass(frozen=True)
class TemporalState:
    resource_key: str
    balance: int
    anchor: int
    natural_cap: int | None
    interval_seconds: int

    def summary(self) -> dict[str, int | str | None]:
        return {
            "resource_key": self.resource_key,
            "balance": self.balance,
            "anchor": self.anchor,
            "natural_cap": self.natural_cap,
            "interval_seconds": self.interval_seconds,
        }


@dataclass(frozen=True)
class TemporalChange:
    resource_key: str
    action: str
    before: TemporalState
    materialized: TemporalState
    after: TemporalState

    @property
    def delta(self) -> int:
        return int(self.after.balance) - int(self.before.balance)

    @property
    def changed(self) -> bool:
        return self.before != self.after


class TemporalPolicyService:
    SUPPORTED_KEYS = ("energy", "spirit_energy", "skill_point", "invitation")

    def __init__(
        self,
        player,
        data_dir: Path,
        save_callback: Callable[[], None] | None = None,
        *,
        clock: ServerClock | None = None,
        uow: PlayerUnitOfWork | None = None,
        vip_privileges: VipPrivilegeResolver | None = None,
    ) -> None:
        self.player = player
        self.data_dir = Path(data_dir)
        self._save_callback = save_callback
        self.clock = clock or ServerClock()
        self.uow = uow
        self.vip_privileges = vip_privileges or VipPrivilegeResolver(
            player, VipProgressionPolicy(self.data_dir)
        )
        self._meta = self._load_json("temporal_resource_meta.json")
        self._economy_meta = self._load_json("campaign_economy_meta.json")
        self._skill_meta = self._load_json("hero_skill_regen_meta.json")
        if self._meta.get("source_resolution") != "effective_merged":
            raise RuntimeError("temporal_resource_meta is not effective_merged")

    def _load_json(self, name: str) -> dict[str, Any]:
        path = self.data_dir / name
        raw = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(raw, dict):
            raise RuntimeError(f"invalid temporal metadata root: {path}")
        return raw

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _policy(self, key: str) -> Mapping[str, Any]:
        key = str(key)
        policies = self._meta.get("policies")
        row = policies.get(key) if isinstance(policies, dict) else None
        if not isinstance(row, dict):
            raise TemporalPolicyError(f"unknown temporal resource {key!r}")
        return row

    def enabled(self, key: str) -> bool:
        return bool(self._policy(key).get("enabled", False))

    def projection_allowed(self, key: str) -> bool:
        row = self._policy(key)
        return self.enabled(key) and str(row.get("projection") or "").startswith("economy_.")

    def interval(self, key: str) -> int:
        return max(1, self._int(self._policy(key).get("interval_seconds"), 1))

    def natural_cap(self, key: str) -> int | None:
        key = str(key)
        row = self._policy(key)
        if not bool(row.get("enabled", False)):
            return None
        if key == "energy":
            levels = self._economy_meta.get("player_levels")
            level_row = levels.get(str(max(1, self._int(getattr(self.player, "lev", 1), 1)))) if isinstance(levels, dict) else None
            if not isinstance(level_row, dict):
                return None
            cap = self._int(level_row.get("energy"), 0)
            return cap if cap > 0 else None
        if key == "spirit_energy":
            cap = self._int(row.get("natural_cap"), 0)
            return cap if cap > 0 else None
        if key == "skill_point":
            # Pass87 centralizes VIP semantics through VipPrivilegeResolver.
            # Monthly Privilege remains an orthogonal entitlement composition.
            cap = self.vip_privileges.skill_point_natural_cap()
            if self._int(getattr(self.player, "privilege_left_card_day", 0), 0) > 0:
                cap += max(0, self._int(self._skill_meta.get("monthly_privilege_skill_max"), 0))
            return cap
        return None

    def state(self, key: str) -> TemporalState:
        row = self._policy(key)
        amount_field = str(row.get("amount_field"))
        anchor_field = str(row.get("anchor_field"))
        raw_balance = getattr(self.player, amount_field, 0)
        if raw_balance is None:
            balance = 0
        else:
            balance = max(0, self._int(raw_balance, 0))
        return TemporalState(
            resource_key=str(key),
            balance=balance,
            anchor=max(0, self._int(getattr(self.player, anchor_field, 0), 0)),
            natural_cap=self.natural_cap(key),
            interval_seconds=self.interval(key),
        )

    def _materialize_state(self, current: TemporalState, now: int) -> TemporalState:
        cap = current.natural_cap
        if cap is None:
            return current
        balance = current.balance
        anchor = current.anchor
        if balance >= cap:
            # Client recoverByTime uses zero as the full/naturally-paused sentinel.
            return TemporalState(current.resource_key, balance, 0, cap, current.interval_seconds)
        if anchor <= 0:
            # Legacy/migrated state below cap with no trustworthy historical anchor:
            # rearm now, but never invent offline catch-up before the known anchor.
            return TemporalState(current.resource_key, balance, now, cap, current.interval_seconds)
        if anchor > now:
            # Pass83 src_64 hygiene: SelfPlayer:recoverByTime() does not clamp a
            # negative (serverTime-anchor) delta and can subtract Energy/Spirit
            # Energy/Skill Points after a host-clock rollback. Rebase only the
            # timer anchor; the authoritative balance is deliberately unchanged,
            # so this grants no catch-up and removes no resource.
            return TemporalState(current.resource_key, balance, now, cap, current.interval_seconds)
        elapsed = now - anchor
        recovered = elapsed // current.interval_seconds
        if recovered <= 0:
            return current
        gain = min(max(0, cap - balance), recovered)
        after_balance = balance + gain
        after_anchor = anchor + gain * current.interval_seconds
        if after_balance >= cap:
            after_anchor = 0
        return TemporalState(current.resource_key, after_balance, after_anchor, cap, current.interval_seconds)

    def preview(self, key: str, action: str = "MATERIALIZE", amount: Any = 0, *, now: int | None = None) -> TemporalChange:
        key = str(key)
        if not self.enabled(key):
            raise TemporalPolicyUnavailable(f"temporal policy {key} is disabled/source-drifted")
        action = str(action).upper()
        if action not in {"MATERIALIZE", "CREDIT", "DEBIT"}:
            raise TemporalPolicyError(f"unsupported temporal action {action!r}")
        value = self._int(amount, 0)
        if action in {"CREDIT", "DEBIT"} and value <= 0:
            raise TemporalPolicyError("temporal credit/debit amount must be positive")
        at = self.clock.now() if now is None else int(now)
        before = self.state(key)
        materialized = self._materialize_state(before, at)
        balance = materialized.balance
        anchor = materialized.anchor
        cap = materialized.natural_cap
        if action == "CREDIT":
            balance += value
            # Natural cap is not a hard inventory ceiling.  Stop timer at/above cap.
            if cap is not None and balance >= cap:
                anchor = 0
            elif cap is not None and anchor <= 0:
                anchor = at
        elif action == "DEBIT":
            if balance < value:
                raise TemporalInsufficientBalance(f"insufficient {key}: {balance} < {value}")
            balance -= value
            if cap is not None and balance < cap and anchor <= 0:
                anchor = at
            elif cap is not None and balance >= cap:
                anchor = 0
        after = TemporalState(key, max(0, balance), max(0, anchor), cap, materialized.interval_seconds)
        return TemporalChange(key, action, before, materialized, after)

    def _write(self, change: TemporalChange) -> None:
        row = self._policy(change.resource_key)
        setattr(self.player, str(row.get("amount_field")), change.after.balance)
        setattr(self.player, str(row.get("anchor_field")), change.after.anchor)

    def _stage_change(self, change: TemporalChange, *, publish: bool, origin_ref: str | None = None) -> None:
        if not change.changed or self.uow is None or not self.uow.active:
            return
        tags: tuple[str, ...] = ("economy_",) if publish and self.projection_allowed(change.resource_key) else ()
        self.uow.stage_journal({
            "seq": 0,
            "owner": "TemporalPolicyService",
            "category": "TEMPORAL",
            "subject": {
                "resource_key": change.resource_key,
                "anchor_field": str(self._policy(change.resource_key).get("anchor_field")),
            },
            "action": change.action,
            "before": change.before.summary(),
            "after": change.after.summary(),
            "delta": change.delta,
            "projection_tags": list(tags),
            "origin_ref": origin_ref,
        })

    def apply_transition(
        self,
        key: str,
        action: str = "MATERIALIZE",
        amount: Any = 0,
        *,
        persist: bool = False,
        publish: bool = True,
        origin_ref: str | None = None,
        stage_journal: bool = True,
    ) -> TemporalChange:
        change = self.preview(key, action, amount)
        if change.changed:
            self._write(change)
            if self.uow is not None and self.uow.active:
                self.uow.mark_changed("temporal_resources")
            if stage_journal:
                self._stage_change(change, publish=publish, origin_ref=origin_ref)
            if persist and self.uow is None and self._save_callback:
                self._save_callback()
            elif persist and self.uow is not None and not self.uow.active and self._save_callback:
                self._save_callback()
        return change

    def materialize(self, key: str, *, persist: bool = False, publish: bool = True) -> TemporalChange:
        return self.apply_transition(key, "MATERIALIZE", 0, persist=persist, publish=publish)

    def credit(self, key: str, amount: Any, *, persist: bool = False, publish: bool = True) -> TemporalChange:
        return self.apply_transition(key, "CREDIT", amount, persist=persist, publish=publish)

    def debit(self, key: str, amount: Any, *, persist: bool = False, publish: bool = True) -> TemporalChange:
        return self.apply_transition(key, "DEBIT", amount, persist=persist, publish=publish)

    def materialize_all(self, *, persist: bool = False, publish: bool = False) -> dict[str, TemporalChange]:
        """Materialize active global pools; Invitation remains explicitly skipped."""
        changes: dict[str, TemporalChange] = {}

        def run() -> None:
            for key in self.SUPPORTED_KEYS:
                if not self.enabled(key):
                    continue
                change = self.materialize(key, persist=False, publish=publish)
                changes[key] = change
            if any(c.changed for c in changes.values()) and self._save_callback:
                self._save_callback()

        if self.uow is not None and not self.uow.active:
            context = OperationContext(
                actor_player_id=str(self.player.player_id),
                domain="temporal",
                operation_name="materialize_all",
                server_time=self.clock.now(),
            )
            with self.uow.transaction(context):
                run()
        else:
            run()
        return changes
