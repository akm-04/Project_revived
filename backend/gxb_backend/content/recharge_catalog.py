"""Source-bounded direct Crystal recharge catalog (Pass87 Phase 1).

Runtime code consumes generated JSON rather than executing Lua. The catalog
contains only source facts plus one explicitly classified private-server VIP
progression policy for direct charge.lua Crystal packs.
"""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from types import MappingProxyType
from typing import Any, Mapping


@dataclass(frozen=True)
class RechargeProduct:
    charge_id: int
    display_price: float
    base_crystal: int
    first_extra_crystal: int
    repeat_extra_crystal: int
    ios_product_id: str
    buy_limit: int
    vip_progression_delta: int
    vip_progression_classification: str


class RechargeSourceCatalog:
    META_FILE = "commerce_source_meta.json"

    def __init__(self, data_dir: Path) -> None:
        self.data_dir = Path(data_dir)
        path = self.data_dir / self.META_FILE
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise RuntimeError(f"[COMMERCE] invalid recharge metadata {path}: {exc}") from exc
        if not isinstance(payload, dict):
            raise RuntimeError(f"[COMMERCE] recharge metadata root is not an object: {path}")
        meta = payload.get("_meta")
        if not isinstance(meta, dict) or meta.get("source_resolution") != "effective_merged":
            raise RuntimeError("[COMMERCE] recharge metadata is not effective_merged")
        rows = payload.get("direct_crystal_products")
        if not isinstance(rows, list):
            raise RuntimeError("[COMMERCE] direct_crystal_products is not a list")
        parsed: dict[int, RechargeProduct] = {}
        order: list[int] = []
        for row in rows:
            if not isinstance(row, dict):
                continue
            try:
                charge_id = int(row.get("charge_id") or 0)
                product = RechargeProduct(
                    charge_id=charge_id,
                    display_price=float(row.get("display_price") or 0.0),
                    base_crystal=max(0, int(row.get("base_crystal") or 0)),
                    first_extra_crystal=max(0, int(row.get("first_extra_crystal") or 0)),
                    repeat_extra_crystal=max(0, int(row.get("repeat_extra_crystal") or 0)),
                    ios_product_id=str(row.get("ios_product_id") or ""),
                    buy_limit=int(row.get("buy_limit") if row.get("buy_limit") is not None else -1),
                    vip_progression_delta=max(0, int(row.get("vip_progression_delta") or 0)),
                    vip_progression_classification=str(row.get("vip_progression_classification") or ""),
                )
            except (TypeError, ValueError) as exc:
                raise RuntimeError(f"[COMMERCE] invalid recharge row {row!r}: {exc}") from exc
            if charge_id <= 0 or product.base_crystal <= 0:
                raise RuntimeError(f"[COMMERCE] invalid direct Crystal product {charge_id}")
            if charge_id in parsed:
                raise RuntimeError(f"[COMMERCE] duplicate charge_id {charge_id}")
            if product.vip_progression_classification != "PRIVATE_SERVER_POLICY_SOURCE_BOUNDED":
                raise RuntimeError(f"[COMMERCE] unclassified VIP progression for charge_id={charge_id}")
            parsed[charge_id] = product
            order.append(charge_id)
        if not parsed:
            raise RuntimeError("[COMMERCE] no direct Crystal products loaded")
        self._products: Mapping[int, RechargeProduct] = MappingProxyType(parsed)
        self._order = tuple(order)
        self.meta = MappingProxyType(dict(meta))

    def get(self, charge_id: Any) -> RechargeProduct | None:
        try:
            key = int(charge_id)
        except (TypeError, ValueError):
            return None
        return self._products.get(key)

    def require(self, charge_id: Any) -> RechargeProduct:
        product = self.get(charge_id)
        if product is None:
            raise KeyError(f"unsupported charge_id {charge_id!r}")
        return product

    def direct_products(self) -> tuple[RechargeProduct, ...]:
        return tuple(self._products[charge_id] for charge_id in self._order)

    def advertised_ids(self) -> tuple[int, ...]:
        return self._order
