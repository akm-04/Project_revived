"""Source-derived deterministic MID97 purchase constants (Pass100)."""
from __future__ import annotations

import json
from pathlib import Path


class EnergyPurchaseCatalogError(ValueError):
    pass


class EnergyPurchaseSourceCatalog:
    META_FILE = "energy_purchase_source_meta.json"

    def __init__(self, data_dir: Path) -> None:
        path = Path(data_dir) / self.META_FILE
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise RuntimeError(f"[MID97] invalid source metadata {path}: {exc}") from exc
        meta = payload.get("_meta") if isinstance(payload, dict) else None
        if not isinstance(meta, dict) or meta.get("source_resolution") != "effective_merged":
            raise RuntimeError("[MID97] metadata is not effective_merged")
        costs = payload.get("buy_energy_cost_by_ordinal")
        if not isinstance(costs, dict):
            raise RuntimeError("[MID97] missing buy_energy_cost_by_ordinal")
        self.meta = dict(meta)
        self.energy_grant = max(0, int(payload.get("energy_grant") or 0))
        self.energy_purchase_threshold = max(0, int(payload.get("energy_purchase_threshold") or 0))
        self.monthly_privilege_num_energy = max(0, int(payload.get("monthly_privilege_num_energy") or 0))
        self._costs = {int(k): max(0, int(v)) for k, v in costs.items()}
        if self.energy_grant <= 0 or self.energy_purchase_threshold <= 0:
            raise RuntimeError("[MID97] invalid grant/threshold metadata")

    def cost(self, ordinal: int) -> int:
        value = self._costs.get(int(ordinal), 0)
        if value <= 0:
            raise EnergyPurchaseCatalogError(f"missing source Energy purchase cost ordinal {ordinal}")
        return value
