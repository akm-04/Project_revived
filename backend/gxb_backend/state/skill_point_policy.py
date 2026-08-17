"""Source-derived skill-point regeneration and purchase policy.

The authoritative client treats ``skill_point`` as a timed pool whose natural
cap depends on VIP/monthly privilege.  MID99 purchases are a separate grant
that can push the stored point count above that natural recovery cap.

All constants are loaded from ``hero_skill_regen_meta.json`` generated from the
effective writable-over-APK src_64 view.
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Callable

from .player_state import PlayerState


class SkillPointPolicy:
    def __init__(self, player: PlayerState, data_dir: Path, save_callback: Callable[[], None] | None = None) -> None:
        self.player = player
        self.data_dir = Path(data_dir)
        self._save_callback = save_callback
        self._meta = self._load_meta()

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _load_meta(self) -> dict[str, Any]:
        path = self.data_dir / "hero_skill_regen_meta.json"
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
            if not isinstance(raw, dict):
                raise ValueError("metadata root must be an object")
            meta = raw.get("_meta") or {}
            if not isinstance(meta, dict) or meta.get("source_resolution") != "effective_merged":
                raise ValueError(
                    "skill-point metadata is not stamped effective_merged; regenerate with "
                    "tools/build_hero_skill_regen_meta.py --apk-root ... --writable-root ..."
                )
            return raw
        except Exception as exc:
            raise RuntimeError(f"[SKILL] invalid source metadata {path}: {exc}") from exc

    def max_points(self) -> int | None:
        mapping = self._meta.get("vip_skill_max")
        if not isinstance(mapping, dict):
            return None
        vip = str(max(0, self._int(self.player.vip)))
        if vip not in mapping:
            print(f"[SKILL] no source skill_max row for vip={vip}; skipping timed recovery")
            return None
        maximum = max(0, self._int(mapping.get(vip)))
        if self._int(self.player.privilege_left_card_day) > 0:
            maximum += max(0, self._int(self._meta.get("monthly_privilege_skill_max")))
        return maximum

    def can_buy(self) -> bool:
        mapping = self._meta.get("vip_skill_buy")
        if not isinstance(mapping, dict):
            return False
        vip = str(max(0, self._int(self.player.vip)))
        return self._int(mapping.get(vip), 0) == 1

    def purchase_cost(self, purchase_number: Any) -> int | None:
        mapping = self._meta.get("buy_skill_cost")
        if not isinstance(mapping, dict) or not mapping:
            return None
        number = max(1, self._int(purchase_number, 1))
        if str(number) in mapping:
            return max(0, self._int(mapping[str(number)]))
        max_times = max(0, self._int(self._meta.get("buy_skill_cost_max_times"), 0))
        if max_times > 0 and str(max_times) in mapping:
            # Mirrors RefreshCostTable:buySkillCost(): requests above the last
            # configured row reuse the maxTimes price.
            return max(0, self._int(mapping[str(max_times)]))
        return None

    def purchase_grant(self) -> int:
        return max(0, self._int(self._meta.get("skill_point_purchase_grant"), 0))

    def initialize_fresh_full_pool(self) -> bool:
        """Runtime-informed compatibility policy for brand-new credential players.

        The early Skill tutorial is written to spend a substantial pool before
        any VIP purchase is available.  Start a new player at the source-derived
        natural cap for its current VIP and keep ``skill_time=0`` (the client's
        full-pool/no-regeneration sentinel).
        """
        maximum = self.max_points()
        if maximum is None:
            return False
        changed = self._int(self.player.skill_point) != maximum or self._int(self.player.skill_time) != 0
        self.player.skill_point = maximum
        self.player.skill_time = 0
        return changed

    def recover(self, *, persist: bool = False) -> bool:
        """Mirror ``SelfPlayer:recoverByTime`` for Skill Points."""
        duration = max(0, self._int(self._meta.get("skill_point_incr_time")))
        maximum = self.max_points()
        if duration <= 0 or maximum is None:
            return False

        points = max(0, self._int(self.player.skill_point))
        last = max(0, self._int(self.player.skill_time))
        if last == 0:
            return False

        now = self.player.now()
        recovered = max(0, (now - last) // duration)
        if maximum < points + recovered and maximum >= points:
            recovered = maximum - points

        new_last = last + recovered * duration
        new_points = points
        if maximum > points and maximum >= points + recovered:
            new_points = points + recovered
        elif maximum > points and maximum < points + recovered:
            new_points = maximum

        if maximum <= new_points:
            new_last = 0

        changed = new_points != points or new_last != last
        if changed:
            self.player.skill_point = new_points
            self.player.skill_time = new_last
            print(f"[SKILL] recovered points {points}->{new_points} skill_time {last}->{new_last} max={maximum} duration={duration}")
            if persist and self._save_callback:
                self._save_callback()
        return changed

    def begin_recovery_if_full_spent(self, before_points: int, before_time: int) -> None:
        """Start the recovery clock when spending from a naturally full pool."""
        maximum = self.max_points()
        if maximum is None:
            return
        if before_points >= maximum and before_time == 0 and self.player.skill_point < maximum:
            self.player.skill_time = self.player.now()

    def normalize_timer_after_gain(self) -> None:
        """Keep the timer consistent after a purchase/item grant.

        The natural cap is a regeneration cap, not an absolute inventory cap.
        Purchased points may exceed it.  At/above the natural cap regeneration
        is stopped (timestamp 0); below the cap an absent timer starts now.
        """
        maximum = self.max_points()
        if maximum is None:
            return
        points = max(0, self._int(self.player.skill_point))
        if points >= maximum:
            self.player.skill_time = 0
        elif self._int(self.player.skill_time) <= 0:
            self.player.skill_time = self.player.now()
