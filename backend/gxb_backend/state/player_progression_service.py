"""Canonical cumulative player EXP/level progression owner.

Pass94 extracts Player EXP/level behavior from the legacy EconomyRepository into
the owner already declared by ``data/resource_registry.json``.  The behavioral
contract remains source-driven from effective ``src_64``:

* EXP is cumulative.
* Level advances while cumulative EXP reaches ``player.lua.total_exp`` for the
  current level, without demotion.
* Each crossed level grants ``player.lua.award_energy`` for the level being
  left.
* Current Energy may exceed the ordinary regeneration cap after a level-up.
* The post-level Energy cap is ``player.lua.energy`` for the resulting level.
* Level-gated Function state is observed by FunctionStateRepository.

The service owns progression only.  Energy mutation remains delegated to
TemporalPolicyService in canonical request composition.
"""
from __future__ import annotations

import copy
import json
from collections.abc import Callable
from pathlib import Path
from typing import Any

from .function_state_repository import FunctionStateRepository
from .player_state import PlayerState
from .resource_registry import ResourceRegistry
from .temporal_policy_service import TemporalPolicyService
from .unit_of_work import PlayerUnitOfWork


class PlayerProgressionError(ValueError):
    """Player progression validation or ownership failure."""


class PlayerProgressionService:
    """First-class owner for cumulative Player EXP and level progression."""

    OWNER = "PlayerProgressionService"

    def __init__(
        self,
        player: PlayerState,
        data_dir: Path,
        save_callback: Callable[[], None] | None = None,
        *,
        function_unlocks: FunctionStateRepository | None = None,
        resource_registry: ResourceRegistry | None = None,
        uow: PlayerUnitOfWork | None = None,
        temporal: TemporalPolicyService | None = None,
        allow_legacy_direct_energy_mutation: bool = True,
    ) -> None:
        self.player = player
        self.data_dir = Path(data_dir)
        self._save_callback = save_callback
        self.function_unlocks = function_unlocks
        self.resource_registry = resource_registry
        self.uow = uow
        self.temporal = temporal
        self.allow_legacy_direct_energy_mutation = bool(allow_legacy_direct_energy_mutation)
        if self.resource_registry is not None:
            for field in ("exp", "lev"):
                desc = self.resource_registry.assert_legacy_economy_field(field)
                if desc.owner_service != self.OWNER:
                    raise RuntimeError(f"progression owner drift: {field} -> {desc.owner_service}")
        self.meta = self._load_meta()
        self.player_levels = self.meta.get("player_levels") or {}

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
                raise ValueError("player progression metadata is not stamped effective_merged")
            return data
        except Exception as exc:
            raise RuntimeError(f"[PLAYER_PROGRESSION] invalid source metadata {path}: {exc}") from exc

    def player_level_meta(self, level: Any) -> dict[str, int]:
        row = self.player_levels.get(str(max(1, self._int(level, 1)))) if isinstance(self.player_levels, dict) else None
        if not isinstance(row, dict):
            return {}
        return {str(key): self._int(value) for key, value in row.items()}

    def highest_source_level(self) -> int:
        if not isinstance(self.player_levels, dict):
            return 1
        values = [self._int(key, 0) for key in self.player_levels.keys()]
        return max((value for value in values if value > 0), default=1)

    def max_level_exp_ceiling(self) -> int | None:
        """Highest cumulative EXP value safe for the source client at max level.

        SelfPlayer increments ``lev`` before checking ``maxTeamLev``. Therefore
        sending EXP >= player.lua.total_exp(max_level) while already at the
        maximum would make the client momentarily step to level 101.
        """
        highest = self.highest_source_level()
        threshold = self._int(self.player_level_meta(highest).get("total_exp"), 0)
        return threshold - 1 if threshold > 0 else None

    def normalize_source_authority(self) -> bool:
        """Align persisted Academy authority with the recovered player table."""
        changed = False
        highest = self.highest_source_level()
        if self._int(self.player.max_lev, 0) != highest:
            self.player.max_lev = highest
            changed = True
        if self._int(self.player.lev, 1) > highest:
            self.player.lev = highest
            changed = True
        if self._int(self.player.lev, 1) >= highest:
            ceiling = self.max_level_exp_ceiling()
            if ceiling is not None and self._int(self.player.exp, 0) > ceiling:
                self.player.exp = ceiling
                changed = True
        return changed

    def level_after_exp(self, total_exp: Any) -> int:
        """Mirror ``SelfPlayer:economySyncEvent_`` cumulative threshold loop."""
        total = max(0, self._int(total_exp, 0))
        level = max(1, self._int(self.player.lev, 1))
        ceiling = min(max(level, self._int(self.player.max_lev, level)), self.highest_source_level())
        while level < ceiling:
            threshold = self._int(self.player_level_meta(level).get("total_exp"), 0)
            if threshold <= 0 or total < threshold:
                break
            level += 1
        return level

    def _snapshot(self) -> dict[str, Any]:
        return {
            "exp": self._int(self.player.exp, 0),
            "lev": self._int(self.player.lev, 1),
            "max_energy": self._int(self.player.max_energy, 0),
            "energy": self._int(self.player.energy, 0),
            "energy_time": self._int(self.player.energy_time, 0),
            "func_ids": list(self.player.func_ids) if isinstance(self.player.func_ids, list) else [],
            "function_state": copy.deepcopy(self.player.function_state) if isinstance(self.player.function_state, dict) else {},
        }

    def _restore(self, snapshot: dict[str, Any]) -> None:
        for field, value in snapshot.items():
            setattr(self.player, field, value)

    def grant_exp(self, amount: Any, *, persist: bool = False) -> dict[str, int]:
        gain = self._int(amount, 0)
        if gain < 0:
            raise PlayerProgressionError("player EXP is grant-only")
        if gain == 0:
            return {}

        before = self._snapshot()
        before_level = max(1, self._int(self.player.lev, 1))
        before_exp = max(0, self._int(self.player.exp, 0))
        changed: dict[str, int] = {}
        try:
            self.player.exp = before_exp + gain
            after_level = self.level_after_exp(self.player.exp)
            if after_level >= self.highest_source_level():
                ceiling = self.max_level_exp_ceiling()
                if ceiling is not None and self.player.exp > ceiling:
                    self.player.exp = ceiling

            energy_award = 0
            if after_level > before_level:
                for level in range(before_level, after_level):
                    energy_award += max(0, self._int(self.player_level_meta(level).get("award_energy"), 0))

            self.player.lev = after_level
            if after_level > before_level and self.function_unlocks is not None:
                self.function_unlocks.observe_level_progress(before_level, after_level, persist=False)

            source_max_energy = self._int(self.player_level_meta(after_level).get("energy"), 0)
            if source_max_energy > 0:
                self.player.max_energy = source_max_energy

            actual_exp_gain = self._int(self.player.exp, 0) - before_exp
            if actual_exp_gain != 0:
                changed["exp"] = self._int(self.player.exp, 0)
            if after_level != before_level:
                changed["lev"] = after_level

            if energy_award > 0:
                if self.temporal is not None:
                    change = self.temporal.apply_transition(
                        "energy",
                        "CREDIT",
                        energy_award,
                        persist=False,
                        publish=True,
                        origin_ref="PlayerProgressionService:level_up_award",
                    )
                    changed["energy"] = change.after.balance
                elif self.allow_legacy_direct_energy_mutation:
                    self.player.energy = max(0, self._int(self.player.energy, 0)) + energy_award
                    changed["energy"] = self._int(self.player.energy, 0)
                else:
                    raise PlayerProgressionError(
                        "level-up Energy award requires canonical TemporalPolicyService"
                    )

            if changed and self.uow is not None and self.uow.active:
                self.uow.mark_changed("player_progression")
                self.uow.stage_journal({
                    "seq": 0,
                    "owner": self.OWNER,
                    "category": "PROGRESSION",
                    "subject": {"resource_key": "exp", "level_field": "lev"},
                    "action": "CREDIT_EXP",
                    "before": {
                        "exp": before_exp,
                        "lev": before_level,
                        "max_energy": before["max_energy"],
                    },
                    "after": {
                        "exp": self._int(self.player.exp, 0),
                        "lev": self._int(self.player.lev, 1),
                        "max_energy": self._int(self.player.max_energy, 0),
                    },
                    "delta": actual_exp_gain,
                    "projection_tags": ["economy_"],
                    "origin_ref": "PlayerProgressionService:grant_exp",
                })

            if changed and persist and not (self.uow is not None and self.uow.active) and self._save_callback:
                self._save_callback()
            return changed
        except Exception:
            self._restore(before)
            raise
