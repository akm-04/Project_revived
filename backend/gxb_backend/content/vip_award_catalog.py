"""Source-derived VIP one-time reward catalog (Pass91).

Runtime policy is generated from effective ``src_64``.  The backend never
executes Lua and never treats the UI's displayed gift as an authority for
settlement.
"""
from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path
from types import MappingProxyType
from typing import Any, Mapping


class VipAwardCatalogError(ValueError):
    pass


@dataclass(frozen=True)
class VipAwardTier:
    vip_level: int
    gift_id: int
    items: tuple[tuple[int, int], ...]
    crystal: int

    def response_awards(self) -> list[dict[str, int]]:
        awards = [
            {"table_id": int(item_id), "item_num": int(item_num)}
            for item_id, item_num in self.items
            if int(item_id) > 0 and int(item_num) > 0
        ]
        # Effective src_64 asset.lua uses -1 as the Crystal pseudo-item in
        # reward-display arrays.  Canonical currency persistence still belongs
        # to EconomyLedger; this row exists only for handleRewards/showRewards.
        if self.crystal > 0:
            awards.append({"table_id": -1, "item_num": int(self.crystal)})
        return awards


class VipAwardSourceCatalog:
    META_FILE = "vip_award_meta.json"
    MIN_LEVEL = 1
    MAX_LEVEL = 15

    def __init__(self, data_dir: Path) -> None:
        path = Path(data_dir) / self.META_FILE
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise RuntimeError(f"[VIP_AWARD] invalid source metadata {path}: {exc}") from exc
        if not isinstance(payload, dict):
            raise RuntimeError("[VIP_AWARD] metadata root must be an object")
        meta = payload.get("_meta")
        if not isinstance(meta, dict) or meta.get("source_resolution") != "effective_merged":
            raise RuntimeError("[VIP_AWARD] metadata is not effective_merged")
        raw_rows = payload.get("tiers")
        if not isinstance(raw_rows, dict):
            raise RuntimeError("[VIP_AWARD] tiers must be a mapping")

        tiers: dict[int, VipAwardTier] = {}
        for level in range(self.MIN_LEVEL, self.MAX_LEVEL + 1):
            raw = raw_rows.get(str(level))
            if not isinstance(raw, dict):
                raise RuntimeError(f"[VIP_AWARD] missing VIP{level} tier")
            try:
                gift_id = int(raw.get("gift_id") or 0)
                crystal = max(0, int(raw.get("crystal") or 0))
            except (TypeError, ValueError) as exc:
                raise RuntimeError(f"[VIP_AWARD] invalid VIP{level} scalar: {exc}") from exc
            if gift_id <= 0:
                raise RuntimeError(f"[VIP_AWARD] VIP{level} has no gift_id")
            raw_items = raw.get("items")
            if not isinstance(raw_items, list):
                raise RuntimeError(f"[VIP_AWARD] VIP{level} items must be a list")
            items: list[tuple[int, int]] = []
            for entry in raw_items:
                if not isinstance(entry, dict):
                    raise RuntimeError(f"[VIP_AWARD] VIP{level} invalid item row")
                try:
                    item_id = int(entry.get("item_id") or 0)
                    item_num = int(entry.get("item_num") or 0)
                except (TypeError, ValueError) as exc:
                    raise RuntimeError(f"[VIP_AWARD] VIP{level} invalid item: {exc}") from exc
                if item_id <= 0 or item_num <= 0:
                    raise RuntimeError(f"[VIP_AWARD] VIP{level} non-positive item grant")
                items.append((item_id, item_num))
            if not items and crystal <= 0:
                raise RuntimeError(f"[VIP_AWARD] VIP{level} gift is empty")
            tiers[level] = VipAwardTier(level, gift_id, tuple(items), crystal)
        self._tiers: Mapping[int, VipAwardTier] = MappingProxyType(tiers)
        self.meta: Mapping[str, Any] = MappingProxyType(dict(meta))

    def tier(self, vip_level: Any) -> VipAwardTier:
        try:
            level = int(vip_level)
        except (TypeError, ValueError) as exc:
            raise VipAwardCatalogError("VIP award level must be an integer") from exc
        row = self._tiers.get(level)
        if row is None:
            raise VipAwardCatalogError(f"unsupported VIP award level {level}")
        return row

    def levels(self) -> tuple[int, ...]:
        return tuple(sorted(self._tiers))
