"""Canonical source-derived VIP progression and privilege facade (Pass87)."""
from __future__ import annotations

import json
from pathlib import Path
from types import MappingProxyType
from typing import Any, Mapping

from .player_state import PlayerState


class VipPolicyError(ValueError):
    pass


class VipProgressionPolicy:
    META_FILE = "vip_source_meta.json"
    MIN_LEVEL = 0
    MAX_LEVEL = 15

    def __init__(self, data_dir: Path) -> None:
        self.data_dir = Path(data_dir)
        path = self.data_dir / self.META_FILE
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise RuntimeError(f"[VIP] invalid source metadata {path}: {exc}") from exc
        if not isinstance(payload, dict):
            raise RuntimeError("[VIP] metadata root must be an object")
        meta = payload.get("_meta")
        if not isinstance(meta, dict) or meta.get("source_resolution") != "effective_merged":
            raise RuntimeError("[VIP] metadata is not effective_merged")
        raw_rows = payload.get("rows")
        if not isinstance(raw_rows, dict):
            raise RuntimeError("[VIP] rows must be a mapping")
        rows: dict[int, Mapping[str, Any]] = {}
        thresholds: list[tuple[int, int]] = []
        for level in range(self.MIN_LEVEL, self.MAX_LEVEL + 1):
            raw = raw_rows.get(str(level))
            if not isinstance(raw, dict):
                raise RuntimeError(f"[VIP] missing source row VIP{level}")
            try:
                source_id = int(raw.get("id") if raw.get("id") is not None else -1)
                threshold = max(0, int(raw.get("charge_req") or 0))
            except (TypeError, ValueError) as exc:
                raise RuntimeError(f"[VIP] invalid VIP{level} row: {exc}") from exc
            if source_id != level:
                raise RuntimeError(f"[VIP] row id drift expected={level} actual={source_id}")
            if thresholds and threshold < thresholds[-1][1]:
                raise RuntimeError("[VIP] charge_req thresholds are not monotonic")
            rows[level] = MappingProxyType(dict(raw))
            thresholds.append((level, threshold))
        if thresholds[0][1] != 0:
            raise RuntimeError("[VIP] VIP0 threshold must be zero")
        self._rows = MappingProxyType(rows)
        self._thresholds = tuple(thresholds)
        self.meta = MappingProxyType(dict(meta))

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def derive_vip(self, cumulative_charge: Any) -> int:
        charge = max(0, self._int(cumulative_charge, 0))
        result = self.MIN_LEVEL
        for level, threshold in self._thresholds:
            if charge < threshold:
                break
            result = level
        return min(self.MAX_LEVEL, max(self.MIN_LEVEL, result))

    def threshold(self, level: Any) -> int:
        level_i = min(self.MAX_LEVEL, max(self.MIN_LEVEL, self._int(level, 0)))
        return self._int(self._rows[level_i].get("charge_req"), 0)

    def row(self, level: Any) -> Mapping[str, Any]:
        level_i = min(self.MAX_LEVEL, max(self.MIN_LEVEL, self._int(level, 0)))
        return self._rows[level_i]

    def value(self, level: Any, key: str, default: Any = 0) -> Any:
        return self.row(level).get(str(key), default)

    @property
    def max_threshold(self) -> int:
        return self.threshold(self.MAX_LEVEL)


class VipPrivilegeResolver:
    """The only VIP-policy facade intended for non-Commerce game domains."""

    def __init__(self, player: PlayerState, policy: VipProgressionPolicy) -> None:
        self.player = player
        self.policy = policy

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def level(self) -> int:
        # PlayerState.vip is canonical persisted projection. Commerce owns its
        # coherence with charge; consumers must not derive or mutate it ad hoc.
        return min(self.policy.MAX_LEVEL, max(self.policy.MIN_LEVEL, self._int(self.player.vip, 0)))

    def meets_level(self, minimum: Any) -> bool:
        return self.level() >= max(0, self._int(minimum, 0))

    def value(self, key: str, default: Any = 0) -> Any:
        return self.policy.value(self.level(), key, default)

    def int_value(self, key: str, default: int = 0) -> int:
        return self._int(self.value(key, default), default)

    def enabled(self, key: str) -> bool:
        return self.int_value(key, 0) > 0

    # Stable semantic names for already-known/high-value dependencies.
    def daily_sweep_card_quantity(self) -> int:
        return max(0, self.int_value("sweep_card"))

    def energy_purchase_limit(self) -> int:
        return max(0, self.int_value("num_energy"))

    def mana_purchase_limit(self) -> int:
        return max(0, self.int_value("num_midas"))

    def super_campaign_paid_reset_limit(self) -> int:
        return max(0, self.int_value("num_elite"))

    def skill_point_purchase_enabled(self) -> bool:
        return self.enabled("skill_buy")

    def skill_point_natural_cap(self) -> int:
        return max(0, self.int_value("skill_max"))

    def soul_box_policy_value(self) -> int:
        return max(0, self.int_value("soul_box"))
