"""Legacy five-field economy compatibility facade over canonical owners.

Pass94 completes the Player EXP/level strangler step.  ``EconomyRepository`` no
longer owns progression behavior: EXP/level delegates to
``PlayerProgressionService``; Mana/Crystal delegate to ``EconomyLedger``; and
Energy delegates to ``TemporalPolicyService``.  The old direct-write paths are
retained only for explicitly legacy/incomplete construction and are fenced off
in live RequestServices and maintenance composition.

Campaign reward *facts* remain available here for compatibility while callers
migrate toward narrower source catalogs.
"""
from __future__ import annotations

import copy
import json
from collections.abc import Callable
from pathlib import Path
from typing import Any

from .economy_ledger import EconomyLedger, EconomyLedgerError
from .function_state_repository import FunctionStateRepository
from .player_progression_service import PlayerProgressionError, PlayerProgressionService
from .player_state import PlayerState
from .resource_registry import ResourceRegistry
from .temporal_policy_service import TemporalPolicyError, TemporalPolicyService
from .unit_of_work import PlayerUnitOfWork


class EconomyMutationError(ValueError):
    """Local transaction validation failure; no mutation is committed."""


class EconomyRepository:
    """Compatibility API that routes the historical five fields to typed owners."""

    PHASE1_FIELDS = ("mana", "crystal", "energy", "exp", "lev")

    def __init__(
        self,
        player: PlayerState,
        data_dir: Path,
        save_callback: Callable[[], None] | None = None,
        *,
        function_unlocks: FunctionStateRepository | None = None,
        resource_registry: ResourceRegistry | None = None,
        ledger: EconomyLedger | None = None,
        uow: PlayerUnitOfWork | None = None,
        temporal: TemporalPolicyService | None = None,
        progression: PlayerProgressionService | None = None,
        allow_legacy_direct_mutation: bool = True,
    ) -> None:
        self.player = player
        self.data_dir = Path(data_dir)
        self._save_callback = save_callback
        self.function_unlocks = function_unlocks
        self.resource_registry = resource_registry
        self.ledger = ledger
        self.uow = uow
        self.temporal = temporal
        self.allow_legacy_direct_mutation = bool(allow_legacy_direct_mutation)
        if self.resource_registry is not None:
            for field in self.PHASE1_FIELDS:
                self.resource_registry.assert_legacy_economy_field(field)
        if self.ledger is not None:
            for field in ("mana", "crystal"):
                if self.ledger.descriptor(field).owner_service != "EconomyLedger":
                    raise RuntimeError(f"legacy scalar facade owner drift: {field}")
        self.progression = progression or PlayerProgressionService(
            player,
            self.data_dir,
            save_callback,
            function_unlocks=function_unlocks,
            resource_registry=resource_registry,
            uow=uow,
            temporal=temporal,
            allow_legacy_direct_energy_mutation=self.allow_legacy_direct_mutation,
        )
        self.meta = self._load_meta()

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _load_meta(self) -> dict[str, Any]:
        path = self.data_dir / "campaign_economy_meta.json"
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            if not isinstance(data, dict):
                raise ValueError("metadata root must be an object")
            meta = data.get("_meta") or {}
            if not isinstance(meta, dict) or meta.get("source_resolution") != "effective_merged":
                raise ValueError(
                    "economy metadata is not stamped effective_merged; regenerate with "
                    "tools/build_campaign_economy_meta.py --apk-root ... --writable-root ..."
                )
            return data
        except Exception as exc:
            raise RuntimeError(f"[ECONOMY] invalid source metadata {path}: {exc}") from exc

    def campaign_meta(self, campaign_id: Any) -> dict[str, int]:
        campaigns = self.meta.get("campaigns") or {}
        row = campaigns.get(str(self._int(campaign_id, -1))) if isinstance(campaigns, dict) else None
        if not isinstance(row, dict):
            return {}
        return {str(key): self._int(value) for key, value in row.items()}

    def player_exp_multiplier(self) -> int:
        return max(0, self._int(self.meta.get("player_exp_multiplier"), 0))

    # Compatibility readers now delegate to the canonical progression owner.
    def player_level_meta(self, level: Any) -> dict[str, int]:
        return self.progression.player_level_meta(level)

    def _snapshot(self) -> dict[str, Any]:
        return {
            "mana": self._int(self.player.mana, 0),
            "crystal": self._int(self.player.crystal, 0),
            "energy": self._int(self.player.energy, 0),
            "energy_time": self._int(self.player.energy_time, 0),
            "exp": self._int(self.player.exp, 0),
            "lev": self._int(self.player.lev, 1),
            "max_energy": self._int(self.player.max_energy, 0),
            "func_ids": list(self.player.func_ids) if isinstance(self.player.func_ids, list) else [],
            "function_state": copy.deepcopy(self.player.function_state) if isinstance(self.player.function_state, dict) else {},
        }

    def _restore(self, snapshot: dict[str, Any]) -> None:
        for field, value in snapshot.items():
            setattr(self.player, field, value)

    def _require_scalar_owner(self, field: str) -> None:
        if self.ledger is None and not self.allow_legacy_direct_mutation:
            raise EconomyMutationError(f"{field} mutation requires canonical EconomyLedger")

    def _require_energy_owner(self) -> None:
        if self.temporal is None and not self.allow_legacy_direct_mutation:
            raise EconomyMutationError("energy mutation requires canonical TemporalPolicyService")

    def apply_deltas(
        self,
        *,
        mana_delta: Any = 0,
        crystal_delta: Any = 0,
        energy_delta: Any = 0,
        player_exp_gain: Any = 0,
        persist: bool = False,
    ) -> dict[str, int]:
        """Route a historical mixed transaction through canonical typed owners.

        The compatibility facade remains for old repositories/callers, but live
        composition supplies every canonical owner and disables direct fallback.
        Player EXP is now delegated to PlayerProgressionService rather than
        mutated here.
        """
        mana_delta = self._int(mana_delta, 0)
        crystal_delta = self._int(crystal_delta, 0)
        energy_delta = self._int(energy_delta, 0)
        player_exp_gain = self._int(player_exp_gain, 0)
        if player_exp_gain < 0:
            raise EconomyMutationError("player EXP cannot be spent through the compatibility economy API")
        if mana_delta:
            self._require_scalar_owner("mana")
        if crystal_delta:
            self._require_scalar_owner("crystal")
        if energy_delta:
            self._require_energy_owner()

        before = self._snapshot()
        if energy_delta:
            if self.temporal is not None:
                try:
                    self.temporal.preview(
                        "energy", "CREDIT" if energy_delta > 0 else "DEBIT", abs(energy_delta)
                    )
                except TemporalPolicyError as exc:
                    raise EconomyMutationError(str(exc)) from exc
            else:
                proposed_energy = before["energy"] + energy_delta
                if proposed_energy < 0:
                    raise EconomyMutationError(f"insufficient energy: would become {proposed_energy}")

        scalar_deltas = {"mana": mana_delta, "crystal": crystal_delta}
        if self.ledger is not None:
            try:
                self.ledger.validate_deltas(scalar_deltas)
            except EconomyLedgerError as exc:
                raise EconomyMutationError(str(exc)) from exc
        else:
            for field, delta in scalar_deltas.items():
                if before[field] + delta < 0:
                    raise EconomyMutationError(f"insufficient {field}: would become {before[field] + delta}")

        changed: dict[str, int] = {}
        try:
            if self.ledger is not None:
                for record in self.ledger.apply_deltas(scalar_deltas, persist=False):
                    changed[record.key] = record.after
            else:
                if mana_delta:
                    self.player.mana = before["mana"] + mana_delta
                    changed["mana"] = self._int(self.player.mana, 0)
                if crystal_delta:
                    self.player.crystal = before["crystal"] + crystal_delta
                    changed["crystal"] = self._int(self.player.crystal, 0)

            if energy_delta:
                if self.temporal is not None:
                    change = self.temporal.apply_transition(
                        "energy", "CREDIT" if energy_delta > 0 else "DEBIT", abs(energy_delta),
                        persist=False, publish=True,
                        origin_ref="EconomyRepository:compatibility_energy",
                    )
                    changed["energy"] = change.after.balance
                else:
                    proposed_energy = before["energy"] + energy_delta
                    self.player.energy = proposed_energy
                    changed["energy"] = proposed_energy
                    if self.uow is not None and self.uow.active:
                        self.uow.mark_changed("temporal_resources")

            if player_exp_gain:
                try:
                    changed.update(self.progression.grant_exp(player_exp_gain, persist=False))
                except PlayerProgressionError as exc:
                    raise EconomyMutationError(str(exc)) from exc

            if persist and changed and not (self.uow is not None and self.uow.active):
                self._save()
            return changed
        except Exception:
            self._restore(before)
            raise

    def try_apply_deltas(self, **kwargs: Any) -> dict[str, int] | None:
        try:
            return self.apply_deltas(**kwargs)
        except EconomyMutationError:
            return None

    def grant_mana(self, amount: Any, *, persist: bool = False) -> dict[str, int]:
        delta = max(0, self._int(amount, 0))
        return self.apply_deltas(mana_delta=delta, persist=persist) if delta else {}

    def spend_mana(self, amount: Any, *, persist: bool = False) -> bool:
        cost = max(0, self._int(amount, 0))
        if cost == 0:
            return True
        return self.try_apply_deltas(mana_delta=-cost, persist=persist) is not None

    def grant_crystal(self, amount: Any, *, persist: bool = False) -> dict[str, int]:
        delta = max(0, self._int(amount, 0))
        return self.apply_deltas(crystal_delta=delta, persist=persist) if delta else {}

    def spend_crystal(self, amount: Any, *, persist: bool = False) -> bool:
        cost = max(0, self._int(amount, 0))
        if cost == 0:
            return True
        return self.try_apply_deltas(crystal_delta=-cost, persist=persist) is not None

    def grant_energy(self, amount: Any, *, persist: bool = False) -> dict[str, int]:
        delta = max(0, self._int(amount, 0))
        return self.apply_deltas(energy_delta=delta, persist=persist) if delta else {}

    def spend_energy(self, amount: Any, *, persist: bool = False) -> bool:
        cost = max(0, self._int(amount, 0))
        if cost == 0:
            return True
        return self.try_apply_deltas(energy_delta=-cost, persist=persist) is not None

    def grant_player_exp(self, amount: Any, *, persist: bool = False) -> dict[str, int]:
        gain = max(0, self._int(amount, 0))
        return self.progression.grant_exp(gain, persist=persist) if gain else {}

    def apply_campaign_win(
        self,
        *,
        mana_gain: Any,
        crystal_gain: Any = 0,
        player_exp_gain: Any,
        persist: bool = False,
    ) -> dict[str, int]:
        """Compatibility wrapper for source-confirmed normal-Campaign rewards."""
        return self.apply_deltas(
            mana_delta=max(0, self._int(mana_gain, 0)),
            crystal_delta=max(0, self._int(crystal_gain, 0)),
            player_exp_gain=max(0, self._int(player_exp_gain, 0)),
            persist=persist,
        )

    def _save(self) -> None:
        if self._save_callback:
            self._save_callback()
