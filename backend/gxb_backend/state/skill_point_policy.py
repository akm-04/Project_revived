"""Source-derived skill-point regeneration policy.

The 1.631.0 client does not treat ``skill_point`` as a static field. Every
``SelfPlayer:getSkillPoint()`` calls ``recoverByTime('skillPoint',
'lastSkillPoint', ...)``. The authoritative shipped tables establish:

* ``misc.skill_point_incr_time`` = 300 seconds
* ``vip.skill_max`` varies by VIP level
* monthly privilege row 1 adds 10 to the maximum while active
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
            return raw if isinstance(raw, dict) else {}
        except Exception as exc:
            print(f"[SKILL] could not load {path}: {exc}")
            return {}

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

    def recover(self, *, persist: bool = False) -> bool:
        """Mirror ``SelfPlayer:recoverByTime`` for skill points."""
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
        """Mirror HeroMainWindow's timer start when spending from a full pool."""
        maximum = self.max_points()
        if maximum is None:
            return
        if before_points >= maximum and before_time == 0 and self.player.skill_point < maximum:
            self.player.skill_time = self.player.now()
