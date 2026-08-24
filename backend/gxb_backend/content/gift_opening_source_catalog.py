"""Immutable effective-source facts for MID241 Gift Opening.

Pass138 loads a generated catalog whose raw drop metadata deliberately carries
no probability semantics.  Runtime capability gates are explicit compatibility
classifications and must not be mistaken for recovered original-server logic.
"""
from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class GiftOpeningFixedItem:
    item_id: int
    item_num: int
    ordinal: int


@dataclass(frozen=True)
class GiftOpeningDropCandidate:
    source_ordinal: int
    row_id: int
    item_id: int
    item_num: int
    drop_rate: int
    roll_type: int
    item_type: int | None


@dataclass(frozen=True)
class GiftOpeningDropOccurrence:
    ordinal: int
    dropbox_id: int
    missing_source: bool
    candidates: tuple[GiftOpeningDropCandidate, ...]


@dataclass(frozen=True)
class GiftOpeningOperation:
    item_id: int
    gift_id: int
    route: str
    supports_num: bool
    status: str
    capability: str
    raw_items: tuple[int, ...]
    raw_item_nums: tuple[int, ...]
    fixed_items: tuple[GiftOpeningFixedItem, ...]
    fixed_scalars: tuple[tuple[str, int], ...]
    raw_equip: str
    drop_occurrences: tuple[GiftOpeningDropOccurrence, ...]


class GiftOpeningSourceCatalog:
    DATA_FILE = "gift_opening_source_catalog.json"
    PHASE2_CAPABILITY = "ORDINARY_CURRENT_OWNERS"
    PHASE3_CAPABILITY = "ORDINARY_RANDOM_CURRENT_OWNERS"

    def __init__(self, data_dir: Path | str) -> None:
        path = Path(data_dir) / self.DATA_FILE
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise RuntimeError(f"cannot load Gift Opening source catalog {path}: {exc}") from exc
        if not isinstance(raw, dict):
            raise RuntimeError(f"invalid Gift Opening source catalog {path}")
        meta = raw.get("_meta")
        if not isinstance(meta, dict) or meta.get("source_resolution") != "effective_src64":
            raise RuntimeError("Gift Opening source catalog is not effective_src64")
        if meta.get("probability_semantics") != "NONE_RAW_METADATA_ONLY":
            raise RuntimeError("Gift Opening source catalog illegally assigns probability semantics")
        self.meta = dict(meta)
        self.summary = dict(raw.get("summary") or {})
        scalar_map = meta.get("phase2_scalar_map")
        if not isinstance(scalar_map, dict):
            raise RuntimeError("Gift Opening source catalog lacks Phase2 scalar map")
        self.phase2_scalar_map = {
            str(key): str(value)
            for key, value in scalar_map.items()
            if str(key) and str(value)
        }

        self._operations: dict[tuple[int, int], GiftOpeningOperation] = {}
        raw_operations = raw.get("operations")
        if not isinstance(raw_operations, list):
            raise RuntimeError("Gift Opening source catalog operations must be a list")
        for value in raw_operations:
            if not isinstance(value, dict):
                raise RuntimeError("Gift Opening operation row must be an object")
            operation = self._parse_operation(value)
            key = (operation.item_id, operation.gift_id)
            if operation.item_id <= 0 or operation.gift_id <= 0 or key in self._operations:
                raise RuntimeError(f"invalid/duplicate Gift Opening operation {key}")
            self._operations[key] = operation
        if not self._operations:
            raise RuntimeError("Gift Opening source catalog is empty")

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _parse_operation(self, value: dict[str, Any]) -> GiftOpeningOperation:
        fixed_items: list[GiftOpeningFixedItem] = []
        for raw in value.get("fixed_items") or []:
            if not isinstance(raw, dict):
                continue
            fixed_items.append(GiftOpeningFixedItem(
                item_id=self._int(raw.get("item_id")),
                item_num=self._int(raw.get("item_num")),
                ordinal=self._int(raw.get("ordinal"), len(fixed_items)),
            ))

        scalars = value.get("fixed_scalars") or {}
        if not isinstance(scalars, dict):
            raise RuntimeError("Gift Opening fixed_scalars must be an object")
        fixed_scalars = tuple(
            (str(key), self._int(amount))
            for key, amount in scalars.items()
            if self._int(amount) != 0
        )

        drop_occurrences: list[GiftOpeningDropOccurrence] = []
        for raw_occurrence in value.get("drop_occurrences") or []:
            if not isinstance(raw_occurrence, dict):
                continue
            candidates: list[GiftOpeningDropCandidate] = []
            for raw_candidate in raw_occurrence.get("candidates") or []:
                if not isinstance(raw_candidate, dict):
                    continue
                raw_type = raw_candidate.get("item_type")
                candidates.append(GiftOpeningDropCandidate(
                    source_ordinal=self._int(raw_candidate.get("source_ordinal"), len(candidates)),
                    row_id=self._int(raw_candidate.get("row_id")),
                    item_id=self._int(raw_candidate.get("item_id")),
                    item_num=self._int(raw_candidate.get("item_num")),
                    drop_rate=self._int(raw_candidate.get("drop_rate")),
                    roll_type=self._int(raw_candidate.get("roll_type")),
                    item_type=None if raw_type is None else self._int(raw_type),
                ))
            drop_occurrences.append(GiftOpeningDropOccurrence(
                ordinal=self._int(raw_occurrence.get("ordinal"), len(drop_occurrences)),
                dropbox_id=self._int(raw_occurrence.get("dropbox_id")),
                missing_source=bool(raw_occurrence.get("missing_source")),
                candidates=tuple(candidates),
            ))

        raw_items = tuple(self._int(v) for v in (value.get("raw_items") or []))
        raw_item_nums = tuple(self._int(v) for v in (value.get("raw_item_nums") or []))
        return GiftOpeningOperation(
            item_id=self._int(value.get("item_id")),
            gift_id=self._int(value.get("gift_id")),
            route=str(value.get("route") or ""),
            supports_num=bool(value.get("supports_num")),
            status=str(value.get("status") or ""),
            capability=str(value.get("capability") or ""),
            raw_items=raw_items,
            raw_item_nums=raw_item_nums,
            fixed_items=tuple(fixed_items),
            fixed_scalars=fixed_scalars,
            raw_equip=str(value.get("raw_equip") or ""),
            drop_occurrences=tuple(drop_occurrences),
        )

    def operation(self, item_id: Any, gift_id: Any) -> GiftOpeningOperation | None:
        return self._operations.get((self._int(item_id, -1), self._int(gift_id, -1)))

    def operations(self) -> tuple[GiftOpeningOperation, ...]:
        return tuple(self._operations.values())

    def count_capability(self, capability: str) -> int:
        target = str(capability)
        return sum(operation.capability == target for operation in self._operations.values())
