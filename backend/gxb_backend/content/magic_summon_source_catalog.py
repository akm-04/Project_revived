"""Recovered Magic/Gachapon MID70/MID71 source contract.

This catalog contains only effective-source/client facts.  It deliberately owns
no private-server probability, multiplicity, retry, or response-placement policy.
"""
from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class MagicSummonTarget:
    hero_table_id: int
    namespace: str
    name: str
    fragment_item_id: int
    initial_star: int
    awaken_table_id: int


@dataclass(frozen=True)
class MagicFragmentRate:
    quantity: int
    weight: int


class MagicSummonSourceCatalog:
    DATA_FILE = "magic_summon_source_catalog.json"

    def __init__(self, data_dir: Path | str) -> None:
        path = Path(data_dir) / self.DATA_FILE
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise RuntimeError(f"cannot load Magic summon source catalog {path}: {exc}") from exc
        if not isinstance(raw, dict):
            raise RuntimeError(f"invalid Magic summon source catalog: {path}")
        meta = raw.get("_meta")
        if not isinstance(meta, dict) or meta.get("source_resolution") != "effective_merged":
            raise RuntimeError("Magic summon source catalog is not effective_merged")
        self.meta = dict(meta)
        self.protocol = dict(raw.get("protocol") or {})
        self.costs = dict(raw.get("costs") or {})
        self.client_channels = dict(raw.get("client_channels") or {})
        self.byproduct_dropbox_id = int(raw.get("byproduct_dropbox_id") or 0)
        self.byproduct_rate_sum = int(raw.get("byproduct_rate_sum") or 0)
        self.byproduct_row_count = int(raw.get("byproduct_row_count") or 0)
        if self.byproduct_dropbox_id <= 0 or self.byproduct_rate_sum <= 0 or self.byproduct_row_count <= 0:
            raise RuntimeError("Magic summon source catalog has invalid byproduct metadata")

        self._targets: dict[int, MagicSummonTarget] = {}
        for row in raw.get("targets") or []:
            if not isinstance(row, dict):
                raise RuntimeError("Magic summon target row must be an object")
            target = MagicSummonTarget(
                hero_table_id=int(row.get("hero_table_id") or 0),
                namespace=str(row.get("namespace") or ""),
                name=str(row.get("name") or ""),
                fragment_item_id=int(row.get("fragment_item_id") or 0),
                initial_star=int(row.get("initial_star") or 0),
                awaken_table_id=int(row.get("awaken_table_id") or 0),
            )
            if (
                target.hero_table_id <= 0
                or target.fragment_item_id <= 0
                or target.initial_star <= 0
                or target.hero_table_id in self._targets
                or target.namespace not in {"partner", "super_partner"}
            ):
                raise RuntimeError(f"invalid/duplicate Magic summon target {target.hero_table_id}")
            self._targets[target.hero_table_id] = target
        if not self._targets:
            raise RuntimeError("Magic summon target allow-list is empty")

        rates: list[MagicFragmentRate] = []
        for row in raw.get("selected_fragment_rate_table") or []:
            if not isinstance(row, dict):
                raise RuntimeError("Magic fragment rate row must be an object")
            parsed = MagicFragmentRate(
                quantity=int(row.get("num") or 0),
                weight=int(row.get("rate") or 0),
            )
            if parsed.quantity <= 0 or parsed.weight <= 0:
                raise RuntimeError("Magic fragment rate table contains invalid values")
            rates.append(parsed)
        if not rates or sum(row.weight for row in rates) <= 0:
            raise RuntimeError("Magic fragment rate table is empty")
        self._fragment_rates = tuple(rates)

        single = int(self.costs.get("single") or 0)
        ten = int(self.costs.get("ten") or 0)
        if single <= 0 or ten <= 0 or str(self.costs.get("currency") or "") != "crystal":
            raise RuntimeError("Magic summon source costs are invalid")

    def target(self, hero_table_id: Any) -> MagicSummonTarget | None:
        try:
            key = int(hero_table_id)
        except (TypeError, ValueError):
            return None
        return self._targets.get(key)

    def allowed_target_ids(self) -> tuple[int, ...]:
        return tuple(self._targets.keys())

    def fragment_rates(self) -> tuple[MagicFragmentRate, ...]:
        return self._fragment_rates

    def crystal_cost(self, pull_count: Any) -> int | None:
        try:
            count = int(pull_count)
        except (TypeError, ValueError):
            return None
        if count == 1:
            return int(self.costs["single"])
        if count == 10:
            return int(self.costs["ten"])
        return None
