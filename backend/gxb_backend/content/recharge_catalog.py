"""Source-bounded Recharge catalog.

Direct Crystal products remain the Pass87/88 preservation surface. Pass149 adds
an immutable typed view of source-native page-2 giftbag products without moving
availability, settlement, VIP or RNG policy into the content catalog.
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


@dataclass(frozen=True)
class RechargeGiftbagItem:
    item_id: int
    item_num: int
    item_type: int


@dataclass(frozen=True)
class RechargeGiftbagDropCandidate:
    source_index: int
    row_id: int
    item_id: int
    item_num: int
    item_type: int
    drop_rate: int
    roll_type: int


@dataclass(frozen=True)
class RechargeGiftbagDropOccurrence:
    occurrence_index: int
    dropbox_id: int
    candidates: tuple[RechargeGiftbagDropCandidate, ...]


@dataclass(frozen=True)
class RechargeGiftbagProduct:
    charge_id: int
    gift_id: int
    name: str
    name_new: str
    page: int
    source_type: int
    display_price: float
    original_price: float
    diamond_display: int
    condition: str
    start: int
    time: int
    is_buy_remove: int
    require_charge: int
    next_charge: int
    total_value: int
    is_open: int
    seque: int
    display_time: int
    time_limited: str
    classification: str
    capability: str
    items: tuple[RechargeGiftbagItem, ...]
    scalars: tuple[tuple[str, int], ...]
    drops: tuple[int, ...]
    drop_occurrences: tuple[RechargeGiftbagDropOccurrence, ...]

    def scalar(self, field: str) -> int:
        key = str(field)
        for source_field, amount in self.scalars:
            if source_field == key:
                return int(amount)
        return 0

    @property
    def one_shot(self) -> bool:
        return int(self.is_buy_remove) == 1

    @property
    def fixed_b2_supported(self) -> bool:
        return self.capability == "B2_FIXED_NONHERO"

    @property
    def random_b3_supported(self) -> bool:
        return self.capability == "B3_RANDOM_NONHERO"

    @property
    def source_native_supported(self) -> bool:
        return self.fixed_b2_supported or self.random_b3_supported


@dataclass(frozen=True)
class RechargeEolProduct:
    product_kind: str
    charge_id: int
    gift_id: int
    page: int
    source_item_id: int
    metadata: Mapping[str, Any]

    @property
    def ota_required(self) -> bool:
        return True


class RechargeSourceCatalog:
    META_FILE = "commerce_source_meta.json"
    GIFTBAG_META_FILE = "recharge_giftbag_source_meta.json"
    EOL_META_FILE = "recharge_eol_product_meta.json"

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

        giftbag_path = self.data_dir / self.GIFTBAG_META_FILE
        try:
            giftbag_payload = json.loads(giftbag_path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise RuntimeError(f"[COMMERCE] invalid giftbag metadata {giftbag_path}: {exc}") from exc
        giftbag_meta = giftbag_payload.get("_meta") if isinstance(giftbag_payload, dict) else None
        if not isinstance(giftbag_meta, dict) or giftbag_meta.get("source_resolution") != "effective_src64":
            raise RuntimeError("[COMMERCE] giftbag metadata is not effective_src64")
        giftbag_rows = giftbag_payload.get("products")
        if not isinstance(giftbag_rows, list):
            raise RuntimeError("[COMMERCE] giftbag products is not a list")
        giftbags: dict[int, RechargeGiftbagProduct] = {}
        giftbag_order: list[int] = []
        for row in giftbag_rows:
            if not isinstance(row, dict):
                continue
            try:
                charge_id = int(row.get("charge_id") or 0)
                raw_items = row.get("items") if isinstance(row.get("items"), list) else []
                items = tuple(
                    RechargeGiftbagItem(
                        item_id=int(item.get("item_id") or 0),
                        item_num=int(item.get("item_num") or 0),
                        item_type=int(item.get("item_type") or 0),
                    )
                    for item in raw_items
                    if isinstance(item, dict)
                )
                raw_scalars = row.get("scalars") if isinstance(row.get("scalars"), dict) else {}
                scalars = tuple(
                    (str(field), int(amount))
                    for field, amount in raw_scalars.items()
                    if int(amount or 0) != 0
                )
                raw_drops = row.get("drops") if isinstance(row.get("drops"), list) else []
                raw_occurrences = row.get("drop_occurrences") if isinstance(row.get("drop_occurrences"), list) else []
                drop_occurrences = tuple(
                    RechargeGiftbagDropOccurrence(
                        occurrence_index=int(occ.get("occurrence_index") or 0),
                        dropbox_id=int(occ.get("dropbox_id") or 0),
                        candidates=tuple(
                            RechargeGiftbagDropCandidate(
                                source_index=int(candidate.get("source_index") or 0),
                                row_id=int(candidate.get("row_id") or 0),
                                item_id=int(candidate.get("item_id") or 0),
                                item_num=int(candidate.get("item_num") or 0),
                                item_type=int(candidate.get("item_type") or 0),
                                drop_rate=int(candidate.get("drop_rate") or 0),
                                roll_type=int(candidate.get("roll_type") or 0),
                            )
                            for candidate in (occ.get("candidates") if isinstance(occ.get("candidates"), list) else [])
                            if isinstance(candidate, dict)
                        ),
                    )
                    for occ in raw_occurrences
                    if isinstance(occ, dict)
                )
                product = RechargeGiftbagProduct(
                    charge_id=charge_id,
                    gift_id=int(row.get("gift_id") or 0),
                    name=str(row.get("name") or ""),
                    name_new=str(row.get("name_new") or ""),
                    page=int(row.get("page") or 0),
                    source_type=int(row.get("type") or 0),
                    display_price=float(row.get("charge") or 0.0),
                    original_price=float(row.get("original_charge") or 0.0),
                    diamond_display=max(0, int(row.get("diamond") or 0)),
                    condition=str(row.get("condition") or ""),
                    start=int(row.get("start") or 0),
                    time=int(row.get("time") or 0),
                    is_buy_remove=int(row.get("is_buy_remove") or 0),
                    require_charge=int(row.get("require_charge") or 0),
                    next_charge=int(row.get("next_charge") or 0),
                    total_value=int(row.get("total_value") or 0),
                    is_open=int(row.get("is_open") or 0),
                    seque=int(row.get("seque") or 0),
                    display_time=int(row.get("display_time") or 0),
                    time_limited=str(row.get("time_limited") or ""),
                    classification=str(row.get("classification") or ""),
                    capability=str(row.get("capability") or ""),
                    items=items,
                    scalars=scalars,
                    drops=tuple(int(value) for value in raw_drops),
                    drop_occurrences=drop_occurrences,
                )
            except (TypeError, ValueError) as exc:
                raise RuntimeError(f"[COMMERCE] invalid giftbag row {row!r}: {exc}") from exc
            if charge_id <= 0 or product.page != 2:
                raise RuntimeError(f"[COMMERCE] invalid page2 giftbag product {charge_id}")
            if charge_id in parsed or charge_id in giftbags:
                raise RuntimeError(f"[COMMERCE] duplicate charge_id across Recharge catalogs {charge_id}")
            if product.capability == "B2_FIXED_NONHERO":
                if product.gift_id <= 0 or product.drops or product.drop_occurrences:
                    raise RuntimeError(f"[COMMERCE] malformed B2 fixed giftbag {charge_id}")
                if any(item.item_id <= 0 or item.item_num <= 0 or item.item_type == -1 for item in product.items):
                    raise RuntimeError(f"[COMMERCE] unsupported B2 fixed item reward {charge_id}")
            elif product.capability == "B3_RANDOM_NONHERO":
                if product.gift_id <= 0 or not product.drops or len(product.drop_occurrences) != len(product.drops):
                    raise RuntimeError(f"[COMMERCE] malformed B3 random giftbag {charge_id}")
                for occurrence in product.drop_occurrences:
                    if occurrence.dropbox_id <= 0 or not occurrence.candidates:
                        raise RuntimeError(f"[COMMERCE] missing B3 dropbox candidates {charge_id}")
                    if not any(candidate.drop_rate > 0 for candidate in occurrence.candidates):
                        raise RuntimeError(f"[COMMERCE] all-zero B3 dropbox {charge_id}")
                    for candidate in occurrence.candidates:
                        if candidate.item_id <= 0 or candidate.item_num <= 0 or candidate.item_type in {-1, 24}:
                            raise RuntimeError(f"[COMMERCE] unsupported B3 candidate reward {charge_id}")
                        if candidate.drop_rate < 0 or candidate.roll_type != 1:
                            raise RuntimeError(f"[COMMERCE] unsupported B3 dropbox policy {charge_id}")
            giftbags[charge_id] = product
            giftbag_order.append(charge_id)
        summary = giftbag_payload.get("summary") if isinstance(giftbag_payload.get("summary"), dict) else {}
        if len(giftbags) != 284 or int(summary.get("fixed_nonhero") or 0) != 265:
            raise RuntimeError("[COMMERCE] giftbag source census drift")
        self._giftbags: Mapping[int, RechargeGiftbagProduct] = MappingProxyType(giftbags)
        self._giftbag_order = tuple(giftbag_order)
        self.giftbag_meta = MappingProxyType(dict(giftbag_meta))

        eol_path = self.data_dir / self.EOL_META_FILE
        try:
            eol_payload = json.loads(eol_path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise RuntimeError(f"[COMMERCE] invalid EOL Recharge metadata {eol_path}: {exc}") from exc
        eol_meta = eol_payload.get("_meta") if isinstance(eol_payload, dict) else None
        summary = eol_payload.get("summary") if isinstance(eol_payload, dict) else None
        if not isinstance(eol_meta, dict) or not isinstance(summary, dict):
            raise RuntimeError("[COMMERCE] malformed EOL Recharge metadata")
        eol_rows = []
        for key in ("skin_products", "elemental_products"):
            rows = eol_payload.get(key)
            if not isinstance(rows, list):
                raise RuntimeError(f"[COMMERCE] EOL Recharge {key} is not a list")
            eol_rows.extend(rows)
        eol_products: dict[int, RechargeEolProduct] = {}
        eol_order: list[int] = []
        for row in eol_rows:
            if not isinstance(row, dict):
                continue
            product = RechargeEolProduct(
                product_kind=str(row.get("product_kind") or ""),
                charge_id=int(row.get("charge_id") or 0),
                gift_id=int(row.get("gift_id") or 0),
                page=int(row.get("page") or 0),
                source_item_id=int(row.get("source_item_id") or 0),
                metadata=MappingProxyType(dict(row)),
            )
            if product.product_kind not in {"SYNTHETIC_EOL_SKIN", "SYNTHETIC_EOL_ELEMENTAL"}:
                raise RuntimeError(f"[COMMERCE] unsupported EOL product kind {product.product_kind!r}")
            if product.charge_id <= 0 or product.gift_id <= 0 or product.source_item_id <= 0:
                raise RuntimeError("[COMMERCE] invalid synthetic EOL Recharge product")
            if product.charge_id in parsed or product.charge_id in giftbags or product.charge_id in eol_products:
                raise RuntimeError(f"[COMMERCE] synthetic charge_id collision {product.charge_id}")
            eol_products[product.charge_id] = product
            eol_order.append(product.charge_id)
        if len(eol_products) != 272 or int(summary.get("skin_products") or 0) != 262 or int(summary.get("elemental_products") or 0) != 10:
            raise RuntimeError("[COMMERCE] synthetic EOL Recharge census drift")
        self._eol_products: Mapping[int, RechargeEolProduct] = MappingProxyType(eol_products)
        self._eol_order = tuple(eol_order)
        self.eol_meta = MappingProxyType(dict(eol_meta))

    def get(self, charge_id: Any) -> RechargeProduct | None:
        """Backward-compatible direct-Crystal lookup."""
        try:
            key = int(charge_id)
        except (TypeError, ValueError):
            return None
        return self._products.get(key)

    def get_giftbag(self, charge_id: Any) -> RechargeGiftbagProduct | None:
        try:
            key = int(charge_id)
        except (TypeError, ValueError):
            return None
        return self._giftbags.get(key)

    def get_eol_product(self, charge_id: Any) -> RechargeEolProduct | None:
        try:
            key = int(charge_id)
        except (TypeError, ValueError):
            return None
        return self._eol_products.get(key)

    def get_any(self, charge_id: Any) -> RechargeProduct | RechargeGiftbagProduct | RechargeEolProduct | None:
        return self.get(charge_id) or self.get_giftbag(charge_id) or self.get_eol_product(charge_id)

    def require(self, charge_id: Any) -> RechargeProduct:
        product = self.get(charge_id)
        if product is None:
            raise KeyError(f"unsupported direct charge_id {charge_id!r}")
        return product

    def direct_products(self) -> tuple[RechargeProduct, ...]:
        return tuple(self._products[charge_id] for charge_id in self._order)

    def giftbag_products(self) -> tuple[RechargeGiftbagProduct, ...]:
        return tuple(self._giftbags[charge_id] for charge_id in self._giftbag_order)

    def fixed_b2_giftbags(self) -> tuple[RechargeGiftbagProduct, ...]:
        return tuple(product for product in self.giftbag_products() if product.fixed_b2_supported)

    def random_b3_giftbags(self) -> tuple[RechargeGiftbagProduct, ...]:
        return tuple(product for product in self.giftbag_products() if product.random_b3_supported)

    def source_native_supported_giftbags(self) -> tuple[RechargeGiftbagProduct, ...]:
        return tuple(product for product in self.giftbag_products() if product.source_native_supported)

    def eol_products(self) -> tuple[RechargeEolProduct, ...]:
        return tuple(self._eol_products[charge_id] for charge_id in self._eol_order)

    def eol_skin_products(self) -> tuple[RechargeEolProduct, ...]:
        return tuple(product for product in self.eol_products() if product.product_kind == "SYNTHETIC_EOL_SKIN")

    def eol_elemental_products(self) -> tuple[RechargeEolProduct, ...]:
        return tuple(product for product in self.eol_products() if product.product_kind == "SYNTHETIC_EOL_ELEMENTAL")

    def advertised_ids(self) -> tuple[int, ...]:
        """Backward-compatible direct-Crystal advertised IDs."""
        return self._order
