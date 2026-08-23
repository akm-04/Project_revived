"""Source-backed static policy inputs for Super Campaign paid resets (MID116)."""
from __future__ import annotations

import json
from pathlib import Path
from types import MappingProxyType
from typing import Any, Mapping


class CampaignResetCatalogError(ValueError):
    pass


class CampaignResetSourceCatalog:
    META_FILE = "campaign_reset_meta.json"

    def __init__(self, data_dir: Path) -> None:
        path = Path(data_dir) / self.META_FILE
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise RuntimeError(f"[CAMPAIGN RESET] invalid source metadata {path}: {exc}") from exc
        if not isinstance(payload, dict):
            raise RuntimeError("[CAMPAIGN RESET] metadata root must be an object")
        meta = payload.get("_meta")
        if not isinstance(meta, dict) or meta.get("source_resolution") != "effective_merged":
            raise RuntimeError("[CAMPAIGN RESET] metadata is not effective_merged")
        raw_costs = payload.get("refresh_elite_cost_by_ordinal")
        if not isinstance(raw_costs, dict):
            raise RuntimeError("[CAMPAIGN RESET] reset costs must be a mapping")
        costs: dict[int, int] = {}
        for raw_key, raw_value in raw_costs.items():
            try:
                ordinal = int(raw_key)
                cost = int(raw_value)
            except (TypeError, ValueError) as exc:
                raise RuntimeError(f"[CAMPAIGN RESET] invalid cost row {raw_key!r}: {exc}") from exc
            if ordinal <= 0 or cost < 0:
                raise RuntimeError(f"[CAMPAIGN RESET] invalid cost ordinal={ordinal} cost={cost}")
            costs[ordinal] = cost
        if any(i not in costs for i in range(1, 29)):
            raise RuntimeError("[CAMPAIGN RESET] source costs must cover ordinals 1..28")
        try:
            monthly_bonus = int(payload.get("monthly_privilege_num_elite") or 0)
        except (TypeError, ValueError) as exc:
            raise RuntimeError(f"[CAMPAIGN RESET] invalid Monthly Privilege num_elite: {exc}") from exc
        if monthly_bonus < 0:
            raise RuntimeError("[CAMPAIGN RESET] Monthly Privilege bonus cannot be negative")
        self._costs: Mapping[int, int] = MappingProxyType(costs)
        self._monthly_bonus = monthly_bonus
        self.meta = MappingProxyType(dict(meta))

    @property
    def monthly_privilege_num_elite(self) -> int:
        return self._monthly_bonus

    def cost(self, ordinal: Any) -> int:
        try:
            index = int(ordinal)
        except (TypeError, ValueError) as exc:
            raise CampaignResetCatalogError(f"invalid reset ordinal: {ordinal!r}") from exc
        if index <= 0 or index not in self._costs:
            raise CampaignResetCatalogError(f"source reset cost unavailable for ordinal {index}")
        return int(self._costs[index])

    def costs(self) -> Mapping[int, int]:
        return self._costs
