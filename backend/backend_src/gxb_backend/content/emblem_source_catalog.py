"""Immutable effective-src_64 authority for the Emblem/Inscription subsystem."""
from __future__ import annotations

import copy
import json
from pathlib import Path
from types import MappingProxyType
from typing import Any, Mapping


class EmblemSourceCatalog:
    SCHEMA_VERSION = 1
    EXPECTED_COUNTS = {
        "forge_rows": 23,
        "ordinary_forge_rows": 21,
        "special_family_rows": 2,
        "concrete_items": 254,
        "ordinary_candidates": 210,
        "scholarship_items": 30,
        "non_forge_orphans": 14,
        "sets": 12,
        "dynamic_scholarship_positions": 30,
    }
    STAR_ITEMS = (50001343, 50001344, 50001345)
    HEART_ITEM = 50001346
    HEART_FRAGMENT = 50001347
    SCHOLARSHIP_FAMILIES = (40001, 50001)

    def __init__(self, data_dir: Path) -> None:
        self.path = Path(data_dir) / "emblem_source_catalog.json"
        raw = json.loads(self.path.read_text(encoding="utf-8"))
        if not isinstance(raw, dict) or int(raw.get("schema_version", 0) or 0) != self.SCHEMA_VERSION:
            raise ValueError("invalid Emblem source catalog schema")
        meta = raw.get("_meta")
        if not isinstance(meta, dict) or meta.get("epistemic_class") != "SOURCE_FACT_ONLY":
            raise ValueError("Emblem source catalog must remain source-fact-only")
        counts = meta.get("counts")
        if counts != self.EXPECTED_COUNTS:
            raise ValueError(f"Emblem source catalog census drift: {counts}")

        identity = raw.get("identity") or {}
        if int(identity.get("function_id", 0) or 0) != 45 or int(identity.get("function_level", 0) or 0) != 100:
            raise ValueError("Emblem Function45 source identity drift")
        rules = raw.get("rules") or {}
        if tuple(int(v) for v in rules.get("star_items") or ()) != self.STAR_ITEMS:
            raise ValueError("Emblem Star item source drift")
        if int(rules.get("heart_item", 0) or 0) != self.HEART_ITEM or int(rules.get("heart_fragment", 0) or 0) != self.HEART_FRAGMENT:
            raise ValueError("Emblem Heart source identity drift")
        if tuple(int(v) for v in rules.get("scholarship_family_ids") or ()) != self.SCHOLARSHIP_FAMILIES:
            raise ValueError("Emblem Scholarship family source drift")
        if tuple(int(v) for v in rules.get("scholarship_family_weights") or ()) != (70, 30):
            raise ValueError("Emblem Scholarship family weight drift")
        if str(rules.get("outer_scholarship_probability")) != "SERVER_UNKNOWN":
            raise ValueError("Emblem source catalog must not invent outer Scholarship probability")

        inscriptions_raw = raw.get("inscriptions")
        items_raw = raw.get("concrete_items")
        sets_raw = raw.get("sets")
        if not isinstance(inscriptions_raw, dict) or not isinstance(items_raw, dict) or not isinstance(sets_raw, dict):
            raise ValueError("Emblem source catalog tables missing")
        self._raw = copy.deepcopy(raw)
        self._metadata = MappingProxyType(copy.deepcopy(meta))
        self._identity = MappingProxyType(copy.deepcopy(identity))
        self._rules = MappingProxyType(copy.deepcopy(rules))
        self._inscriptions = {
            int(key): MappingProxyType(copy.deepcopy(value))
            for key, value in inscriptions_raw.items()
        }
        self._items = {
            int(key): MappingProxyType(copy.deepcopy(value))
            for key, value in items_raw.items()
        }
        self._sets = {
            int(key): MappingProxyType(copy.deepcopy(value))
            for key, value in sets_raw.items()
        }
        self._rate_rows = tuple(MappingProxyType(copy.deepcopy(row)) for row in raw.get("rate_rows_uninterpreted") or ())
        self._exchange = tuple(MappingProxyType(copy.deepcopy(row)) for row in raw.get("exchange_materials") or ())
        self._heart_recipe = MappingProxyType(copy.deepcopy(raw.get("heart_recipe") or {}))
        self._validate_relations()

    def _validate_relations(self) -> None:
        if len(self._inscriptions) != 23 or len(self._items) != 254 or len(self._sets) != 12:
            raise ValueError("Emblem source table count drift")
        ordinary = [row for row in self._inscriptions.values() if int(row.get("special", 0) or 0) == 0]
        special = [row for row in self._inscriptions.values() if int(row.get("special", 0) or 0) == 1]
        if len(ordinary) != 21 or {int(row["id"]) for row in special} != set(self.SCHOLARSHIP_FAMILIES):
            raise ValueError("Emblem ordinary/special row topology drift")
        for inscription_id, row in self._inscriptions.items():
            candidates = tuple(int(v) for v in row.get("candidate_item_ids") or ())
            weights = tuple(int(v) for v in row.get("candidate_weights") or ())
            if not candidates or len(candidates) != len(weights) or sum(weights) <= 0:
                raise ValueError(f"Emblem candidate topology invalid for {inscription_id}")
            for item_id in candidates:
                item = self._items.get(item_id)
                if item is None or int(item.get("inscription_id", 0) or 0) != inscription_id:
                    raise ValueError(f"Emblem candidate mapping drift for {item_id}")
        scholarship = [row for row in self._items.values() if row.get("classification") == "SCHOLARSHIP_SET_CANDIDATE"]
        if len(scholarship) != 30 or {int(row.get("physical_position", 0) or 0) for row in scholarship} != {1, 2, 3}:
            raise ValueError("Emblem Scholarship concrete position drift")
        orphans = [row for row in self._items.values() if row.get("classification") == "SOURCE_PRESENT_NON_FORGE_ORPHAN"]
        if len(orphans) != 14 or any(int(row.get("physical_position", 0) or 0) != 2 for row in orphans):
            raise ValueError("Emblem Honor-orphan source topology drift")
        for suit_id, suit in self._sets.items():
            pieces = tuple(int(v) for v in suit.get("item_ids") or ())
            if len(pieces) not in {2, 3}:
                raise ValueError(f"Emblem set {suit_id} size drift")
            if any(int(self._items[p].get("set_id", 0) or 0) != suit_id for p in pieces):
                raise ValueError(f"Emblem set {suit_id} linkage drift")
        if len(self._exchange) != 3:
            raise ValueError("Emblem Star exchange mapping drift")
        if int(self._heart_recipe.get("item_id", 0) or 0) != self.HEART_ITEM:
            raise ValueError("Emblem Heart recipe drift")

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    @property
    def metadata(self) -> Mapping[str, Any]:
        return self._metadata

    @property
    def identity(self) -> Mapping[str, Any]:
        return self._identity

    @property
    def rules(self) -> Mapping[str, Any]:
        return self._rules

    @property
    def remove_replace_crystal(self) -> int:
        return int(self._rules["remove_replace_crystal"])

    @property
    def heart_recipe(self) -> Mapping[str, Any]:
        return self._heart_recipe

    @property
    def uninterpreted_rate_rows(self) -> tuple[Mapping[str, Any], ...]:
        return self._rate_rows

    @property
    def exchange_materials(self) -> tuple[Mapping[str, Any], ...]:
        return self._exchange

    def inscription(self, inscription_id: Any) -> Mapping[str, Any] | None:
        return self._inscriptions.get(self._int(inscription_id))

    def require_inscription(self, inscription_id: Any) -> Mapping[str, Any]:
        row = self.inscription(inscription_id)
        if row is None:
            raise ValueError(f"unknown Emblem inscription_id {inscription_id!r}")
        return row

    def concrete_item(self, item_id: Any) -> Mapping[str, Any] | None:
        return self._items.get(self._int(item_id))

    def require_concrete_item(self, item_id: Any) -> Mapping[str, Any]:
        row = self.concrete_item(item_id)
        if row is None:
            raise ValueError(f"unknown Emblem item_id {item_id!r}")
        return row

    def inscription_for_item(self, item_id: Any) -> Mapping[str, Any] | None:
        item = self.concrete_item(item_id)
        return self.inscription(item.get("inscription_id")) if item else None

    def physical_position(self, item_id: Any) -> int:
        item = self.concrete_item(item_id)
        return int(item.get("physical_position", 0) or 0) if item else 0

    def is_generation_candidate(self, item_id: Any) -> bool:
        item = self.concrete_item(item_id)
        return bool(item and item.get("classification") != "SOURCE_PRESENT_NON_FORGE_ORPHAN")

    def is_scholarship_item(self, item_id: Any) -> bool:
        item = self.concrete_item(item_id)
        return bool(item and item.get("classification") == "SCHOLARSHIP_SET_CANDIDATE")

    def ordinary_candidate_pool(self, inscription_id: Any, *, exclude_item_id: Any = 0) -> tuple[tuple[int, ...], tuple[int, ...]]:
        row = self.require_inscription(inscription_id)
        if int(row.get("special", 0) or 0) != 0:
            raise ValueError("ordinary candidate pool requires a non-special inscription row")
        exclude = self._int(exclude_item_id)
        candidates: list[int] = []
        weights: list[int] = []
        for item_id, weight in zip(row.get("candidate_item_ids") or (), row.get("candidate_weights") or ()):
            item_id = int(item_id)
            if exclude > 0 and item_id == exclude:
                continue
            candidates.append(item_id)
            weights.append(int(weight))
        if not candidates or sum(weights) <= 0:
            raise ValueError("ordinary Emblem candidate pool became empty")
        return tuple(candidates), tuple(weights)

    def scholarship_family_pool(self) -> tuple[tuple[int, ...], tuple[int, ...]]:
        return (
            tuple(int(v) for v in self._rules["scholarship_family_ids"]),
            tuple(int(v) for v in self._rules["scholarship_family_weights"]),
        )

    def scholarship_candidate_pool(self, family_id: Any) -> tuple[tuple[int, ...], tuple[int, ...]]:
        row = self.require_inscription(family_id)
        if int(row.get("special", 0) or 0) != 1:
            raise ValueError("Scholarship candidate pool requires a special family row")
        return (
            tuple(int(v) for v in row.get("candidate_item_ids") or ()),
            tuple(int(v) for v in row.get("candidate_weights") or ()),
        )

    def set_row(self, set_id: Any) -> Mapping[str, Any] | None:
        return self._sets.get(self._int(set_id))

    def inscription_ids(self) -> tuple[int, ...]:
        return tuple(sorted(self._inscriptions))

    def concrete_item_ids(self) -> tuple[int, ...]:
        return tuple(sorted(self._items))

    def set_ids(self) -> tuple[int, ...]:
        return tuple(sorted(self._sets))
