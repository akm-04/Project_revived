"""Source-derived generic Backpack sale metadata for Pass69.1.

The current Lua SellDetailWindow displays ``item:mana(id)`` as the generic sale
price, falling back to ``item:crystal(id)`` only when Mana is zero.  Inscription
and Dorm-key families visibly route to specialized resolve/exchange flows, and
Horcruxes are generated instances rather than ordinary Backpack stacks.
"""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from types import MappingProxyType
from typing import Any, Mapping


class ItemSaleCatalogError(ValueError):
    pass


class UnknownSaleItem(ItemSaleCatalogError):
    pass


class SpecializedSaleItem(ItemSaleCatalogError):
    pass


@dataclass(frozen=True)
class ItemSaleDescriptor:
    item_id: int
    name: str
    type_id: int
    subtype_id: int
    mana_sell: int
    crystal_sell: int
    storage_plane: str
    action_flags: tuple[str, ...]
    generic_sell_allowed: bool
    override_reason: str | None

    @property
    def resource_key(self) -> str:
        if self.mana_sell > 0:
            return "mana"
        if self.crystal_sell > 0:
            return "crystal"
        raise UnknownSaleItem(f"item {self.item_id} has no positive generic sale price")

    @property
    def unit_price(self) -> int:
        if self.mana_sell > 0:
            return self.mana_sell
        if self.crystal_sell > 0:
            return self.crystal_sell
        return 0


class ItemSaleCatalog:
    SCHEMA_VERSION = 1

    def __init__(self, payload: Mapping[str, Any], *, source_path: Path | None = None) -> None:
        meta = payload.get("_meta") if isinstance(payload, Mapping) else None
        if not isinstance(meta, Mapping) or int(meta.get("schema_version", 0) or 0) != self.SCHEMA_VERSION:
            raise ItemSaleCatalogError("invalid item sale catalog metadata")
        raw_rows = payload.get("rows")
        if not isinstance(raw_rows, Mapping):
            raise ItemSaleCatalogError("item sale catalog rows missing")
        rows: dict[int, ItemSaleDescriptor] = {}
        for raw_id, raw in raw_rows.items():
            if not isinstance(raw, Mapping):
                continue
            item_id = int(raw.get("item_id", raw_id) or 0)
            if item_id <= 0:
                continue
            flags = raw.get("action_flags") if isinstance(raw.get("action_flags"), list) else []
            desc = ItemSaleDescriptor(
                item_id=item_id,
                name=str(raw.get("name") or ""),
                type_id=int(raw.get("type_id", 0) or 0),
                subtype_id=int(raw.get("subtype_id", 0) or 0),
                mana_sell=max(0, int(raw.get("mana_sell", 0) or 0)),
                crystal_sell=max(0, int(raw.get("crystal_sell", 0) or 0)),
                storage_plane=str(raw.get("storage_plane") or ""),
                action_flags=tuple(str(value) for value in flags),
                generic_sell_allowed=bool(raw.get("generic_sell_allowed", False)),
                override_reason=(str(raw.get("override_reason")) if raw.get("override_reason") else None),
            )
            if desc.mana_sell <= 0 and desc.crystal_sell <= 0:
                continue
            rows[item_id] = desc
        self._rows = MappingProxyType(rows)
        self._meta = MappingProxyType(dict(meta))
        self.source_path = Path(source_path) if source_path is not None else None

    @classmethod
    def load(cls, path: Path) -> "ItemSaleCatalog":
        path = Path(path)
        payload = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(payload, dict):
            raise ItemSaleCatalogError("item sale catalog root must be object")
        return cls(payload, source_path=path)

    @property
    def metadata(self) -> Mapping[str, Any]:
        return self._meta

    def get(self, item_id: Any) -> ItemSaleDescriptor:
        try:
            target = int(item_id)
        except (TypeError, ValueError) as exc:
            raise UnknownSaleItem(f"invalid sale item id {item_id!r}") from exc
        row = self._rows.get(target)
        if row is None:
            raise UnknownSaleItem(f"item {target} has no recovered generic sale metadata")
        return row

    def require_generic(self, item_id: Any) -> ItemSaleDescriptor:
        row = self.get(item_id)
        if not row.generic_sell_allowed:
            raise SpecializedSaleItem(
                f"item {row.item_id} uses specialized sale/resolve flow: {row.override_reason or 'UNKNOWN'}"
            )
        return row

    def __len__(self) -> int:
        return len(self._rows)
