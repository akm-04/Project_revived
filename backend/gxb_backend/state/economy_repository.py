"""Canonical cumulative player economy mutations.

Pass 30 extends the Pass-29 Phase-1 transaction spine with source-driven level FunctionID side effects and Campaign Crystal rewards.
The repository owns safe atomic mutations for Mana, Crystal, Energy and
cumulative player EXP/level. Source-derived player level/Energy constants are
loaded only from metadata stamped as generated through the effective merged
writable-over-APK source resolver.

All response values are cumulative current totals. Endpoint handlers should
mutate canonical state here and let the request ResponseProjector attach the
changed ``economy_`` block.
"""
from __future__ import annotations

import json
from collections.abc import Callable
from pathlib import Path
from typing import Any

from .function_unlock_repository import FunctionUnlockRepository
from .player_state import PlayerState


class EconomyMutationError(ValueError):
    """Local transaction validation failure; no mutation is committed."""


class EconomyRepository:
    PHASE1_FIELDS = ("mana", "crystal", "energy", "exp", "lev")

    def __init__(
        self,
        player: PlayerState,
        data_dir: Path,
        save_callback: Callable[[], None] | None = None,
        *,
        function_unlocks: FunctionUnlockRepository | None = None,
    ) -> None:
        self.player = player
        self.data_dir = Path(data_dir)
        self._save_callback = save_callback
        self.function_unlocks = function_unlocks
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

    def player_level_meta(self, level: Any) -> dict[str, int]:
        row = self.player_levels.get(str(max(1, self._int(level, 1)))) if isinstance(self.player_levels, dict) else None
        if not isinstance(row, dict):
            return {}
        return {str(key): self._int(value) for key, value in row.items()}

    def _highest_source_level(self) -> int:
        if not isinstance(self.player_levels, dict):
            return 1
        values = [self._int(key, 0) for key in self.player_levels.keys()]
        return max((value for value in values if value > 0), default=1)

    def _level_after_exp(self, total_exp: int) -> int:
        """Mirror SelfPlayer's cumulative EXP threshold loop without demotion."""
        level = max(1, self._int(self.player.lev, 1))
        ceiling = min(max(level, self._int(self.player.max_lev, level)), self._highest_source_level())
        while level < ceiling:
            row = self.player_level_meta(level)
            threshold = self._int(row.get("total_exp"), 0)
            if threshold <= 0 or total_exp < threshold:
                break
            level += 1
        return level

    def _snapshot(self) -> dict[str, Any]:
        return {
            "mana": self._int(self.player.mana, 0),
            "crystal": self._int(self.player.crystal, 0),
            "energy": self._int(self.player.energy, 0),
            "exp": self._int(self.player.exp, 0),
            "lev": self._int(self.player.lev, 1),
            "max_energy": self._int(self.player.max_energy, 0),
            "func_ids": list(self.player.func_ids) if isinstance(self.player.func_ids, list) else [],
        }

    def _restore(self, snapshot: dict[str, Any]) -> None:
        for field, value in snapshot.items():
            setattr(self.player, field, value)

    def _apply_player_exp_gain(self, gain: int, changed: dict[str, int]) -> None:
        if gain <= 0:
            return
        self.player.exp = max(0, self._int(self.player.exp, 0)) + gain
        before_level = max(1, self._int(self.player.lev, 1))
        after_level = self._level_after_exp(self.player.exp)

        energy_award = 0
        if after_level > before_level:
            for level in range(before_level, after_level):
                row = self.player_level_meta(level)
                energy_award += max(0, self._int(row.get("award_energy"), 0))

        self.player.lev = after_level
        if after_level > before_level and self.function_unlocks is not None:
            self.function_unlocks.unlock_crossed_levels(
                before_level, after_level, persist=False
            )
        level_meta = self.player_level_meta(after_level)
        source_max_energy = self._int(level_meta.get("energy"), 0)
        if source_max_energy > 0:
            self.player.max_energy = source_max_energy

        changed["exp"] = self._int(self.player.exp, 0)
        if after_level != before_level:
            changed["lev"] = after_level
        if energy_award > 0:
            # Source client level-up flow allows current Energy above the normal
            # regeneration cap, so do not clamp this award to max_energy.
            self.player.energy = max(0, self._int(self.player.energy, 0)) + energy_award
            changed["energy"] = self._int(self.player.energy, 0)

    def apply_deltas(
        self,
        *,
        mana_delta: Any = 0,
        crystal_delta: Any = 0,
        energy_delta: Any = 0,
        player_exp_gain: Any = 0,
        persist: bool = False,
    ) -> dict[str, int]:
        """Validate and atomically apply a Phase-1 economy transaction.

        Mana/Crystal/Energy use signed deltas. Player EXP is cumulative progress
        and therefore accepts grants only. All insufficient-balance checks occur
        before any field is changed. Any unexpected failure restores the local
        snapshot before propagating the error.
        """
        mana_delta = self._int(mana_delta, 0)
        crystal_delta = self._int(crystal_delta, 0)
        energy_delta = self._int(energy_delta, 0)
        player_exp_gain = self._int(player_exp_gain, 0)
        if player_exp_gain < 0:
            raise EconomyMutationError("player EXP cannot be spent through the Phase-1 economy API")

        before = self._snapshot()
        proposed = {
            "mana": before["mana"] + mana_delta,
            "crystal": before["crystal"] + crystal_delta,
            "energy": before["energy"] + energy_delta,
        }
        for field, value in proposed.items():
            if value < 0:
                raise EconomyMutationError(f"insufficient {field}: would become {value}")

        changed: dict[str, int] = {}
        try:
            if mana_delta:
                self.player.mana = proposed["mana"]
                changed["mana"] = proposed["mana"]
            if crystal_delta:
                self.player.crystal = proposed["crystal"]
                changed["crystal"] = proposed["crystal"]
            if energy_delta:
                self.player.energy = proposed["energy"]
                changed["energy"] = proposed["energy"]

            self._apply_player_exp_gain(player_exp_gain, changed)

            if persist and changed:
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
        return self.apply_deltas(player_exp_gain=gain, persist=persist) if gain else {}

    def apply_campaign_win(
        self,
        *,
        mana_gain: Any,
        crystal_gain: Any = 0,
        player_exp_gain: Any,
        persist: bool = False,
    ) -> dict[str, int]:
        """Commit source-confirmed normal-Campaign scalar rewards atomically."""
        return self.apply_deltas(
            mana_delta=max(0, self._int(mana_gain, 0)),
            crystal_delta=max(0, self._int(crystal_gain, 0)),
            player_exp_gain=max(0, self._int(player_exp_gain, 0)),
            persist=persist,
        )

    def _save(self) -> None:
        if self._save_callback:
            self._save_callback()
