"""Wave C server-side hydration assembly and source-shape validation."""
from __future__ import annotations

import copy
from collections.abc import Callable, Mapping
from typing import Any

from .catalogs import SynchronizationCatalogs

Provider = Callable[[], Any]


class HydrationShapeValidator:
    """Validate only the source-sensitive contracts enabled in Wave C."""

    _PRACTICE_FIELDS = {
        "last_time": int,
        "practice_attr": list,
        "lock": list,
        "times": int,
        "base_crystal": int,
        "base_mana": int,
        "bless_value": int,
    }
    _PET_FIELDS = (
        "now_floor", "max_floor", "begin_sweep_time", "is_can_sweep",
        "mission_sweep_times", "can_sweep_times", "challenge_times",
    )

    @classmethod
    def validate(cls, mid: int, payload: Any) -> None:
        if not isinstance(payload, dict):
            raise ValueError(f"hydration MID {mid} must serialize an object")
        if mid == 124:
            for key, typ in cls._PRACTICE_FIELDS.items():
                if key not in payload or not isinstance(payload[key], typ):
                    raise ValueError(f"MID124 missing/invalid {key}")
        elif mid == 530:
            if not isinstance(payload.get("teams_info"), list):
                raise ValueError("MID530 teams_info must be list")
            sp = payload.get("sp_info")
            if not isinstance(sp, dict) or not isinstance(sp.get("sp"), int) or not isinstance(sp.get("sp_last_refresh_time"), int):
                raise ValueError("MID530 sp_info shape invalid")
        elif mid == 816:
            normal = payload.get("normal")
            if not isinstance(normal, dict):
                raise ValueError("MID816 normal must be object")
            for key in cls._PET_FIELDS:
                if not isinstance(normal.get(key), int):
                    raise ValueError(f"MID816 normal.{key} invalid")
            if not isinstance(payload.get("is_super_open"), int):
                raise ValueError("MID816 is_super_open invalid")
        elif mid == 822:
            for key in cls._PET_FIELDS:
                if not isinstance(payload.get(key), int):
                    raise ValueError(f"MID822 {key} invalid")
        elif mid == 1152:
            if not isinstance(payload.get("is_enroll"), int):
                raise ValueError("MID1152 is_enroll invalid")
            if "step_id" in payload:
                raise ValueError("MID1152 inactive baseline must omit unrecovered step_id")


class HydrationSnapshotAssembler:
    """Build accepted bootstrap snapshots from an exact provider allow-list.

    The assembler owns no state. Providers remain domain-owned serializers.
    """

    def __init__(self, catalogs: SynchronizationCatalogs, providers: Mapping[int, Provider]) -> None:
        self.catalogs = catalogs
        self._providers = dict(providers)
        expected = set(catalogs.stage3_mids())
        actual = set(self._providers)
        if actual != expected:
            raise ValueError(f"Stage3 hydration provider drift missing={sorted(expected-actual)} extra={sorted(actual-expected)}")

    def stage3_snapshot(self) -> dict[str, object]:
        out: dict[str, object] = {}
        for mid in self.catalogs.stage3_mids():
            out[str(mid)] = copy.deepcopy(self._providers[mid]())
        return out
