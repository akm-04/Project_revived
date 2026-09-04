"""Immutable current-src64 BattlePass facts needed only for redmark projection."""
from __future__ import annotations

import json
from pathlib import Path
from types import MappingProxyType
from typing import Any


class BattlePassRedmarkSourceCatalog:
    def __init__(self, data_dir: Path) -> None:
        path = Path(data_dir) / "battle_pass_redmark_source_catalog.json"
        raw = json.loads(path.read_text(encoding="utf-8"))
        constants = raw.get("constants") if isinstance(raw.get("constants"), dict) else {}
        self.point_per_level = self._positive(constants.get("point_per_level"), "point_per_level")
        self.award_max_level = self._positive(constants.get("award_max_level"), "award_max_level")
        self.award_loop_range = self._positive(constants.get("award_loop_range"), "award_loop_range")
        missions = raw.get("mission_required_counts") if isinstance(raw.get("mission_required_counts"), dict) else {}
        rewards = raw.get("rewards") if isinstance(raw.get("rewards"), dict) else {}
        self._mission_counts = MappingProxyType({int(k): max(0, int(v)) for k, v in missions.items()})
        self._rewards = MappingProxyType({
            int(k): MappingProxyType({
                "common_gift": max(0, self._int(v.get("common_gift"))) if isinstance(v, dict) else 0,
                "special_gift": max(0, self._int(v.get("special_gift"))) if isinstance(v, dict) else 0,
            })
            for k, v in rewards.items()
        })
        if tuple(sorted(self._mission_counts)) != tuple(range(1, 44)):
            raise ValueError("BattlePass mission redmark source census drift")
        if tuple(sorted(self._rewards)) != tuple(range(1, 101)):
            raise ValueError("BattlePass reward redmark source census drift")
        self.source_metadata = raw.get("source_metadata") if isinstance(raw.get("source_metadata"), dict) else {}

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    @classmethod
    def _positive(cls, value: Any, name: str) -> int:
        result = cls._int(value)
        if result <= 0:
            raise ValueError(f"BattlePass source constant {name} must be positive")
        return result

    def mission_required_count(self, mission_id: Any) -> int:
        return int(self._mission_counts.get(self._int(mission_id), 0))

    def reward_gift(self, level: Any, *, advanced: bool = False) -> int:
        lev = self._int(level)
        lookup = lev
        if lev > self.award_max_level and (lev - self.award_max_level) % self.award_loop_range == 0:
            lookup = self.award_max_level
        row = self._rewards.get(lookup)
        if row is None:
            return 0
        return int(row["special_gift" if advanced else "common_gift"])
