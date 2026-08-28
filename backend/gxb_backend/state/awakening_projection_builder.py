"""Pure source-shaped Awakening response projection helpers (Pass205 Stage A)."""
from __future__ import annotations

import copy
from typing import Any, Iterable


class AwakeningProjectionBuilder:
    HERO = 1
    HERO_TWICE = 2
    PET = 3
    CHANNELS = {HERO: "awake_mission_", HERO_TWICE: "twice_awake_mission_", PET: "pet_awake_mission_"}

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def task_row(self, record: dict[str, Any], *, is_going: int = 1) -> dict[str, int]:
        going = 1 if self._int(is_going, 0) else 0
        return {
            "table_id": self._int(record.get("mission_id")),
            "awake_type": self._int(record.get("awake_type")),
            "is_going": going,
            "is_complete": 1 if record.get("complete") and going else 0,
            "is_open": 1,
            "is_reward": 0,
            "count": self._int(record.get("count")) if going else 0,
        }

    def mission_list(self, records: Iterable[dict[str, Any]]) -> dict[str, list[dict[str, int]]]:
        return {"mission_list": [self.task_row(rec) for rec in records if isinstance(rec, dict)]}

    def mission_delta(self, awake_type: Any, rows: Iterable[dict[str, Any]], *, is_going: int = 1) -> dict[str, Any]:
        atype = self._int(awake_type)
        channel = self.CHANNELS.get(atype)
        if channel is None:
            raise ValueError(f"unsupported Awake projection type {awake_type}")
        return {channel: [self.task_row(rec, is_going=is_going) for rec in rows if isinstance(rec, dict)]}

    @staticmethod
    def twice_awake_stage(*, table_id: Any, stage: Any) -> dict[str, dict[str, int]]:
        return {"twice_awake_stage_": {"table_id": int(table_id), "stage": int(stage)}}

    @staticmethod
    def extra_drops(rows: Iterable[dict[str, Any]]) -> dict[str, Any]:
        # Backend.lua processes extra_drops_ before request callback. This is a
        # delivery projection only; callers must settle canonical Inventory first.
        return {"extra_drops_": [copy.deepcopy(dict(row)) for row in rows if isinstance(row, dict)]}
