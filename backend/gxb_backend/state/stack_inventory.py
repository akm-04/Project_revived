"""Typed Backpack stack owner introduced by Pass69.

The storage representation intentionally remains the legacy PlayerState
``backpack_items`` list.  This class centralizes signed stack arithmetic and
lets the existing InventoryRepository survive as a compatibility facade.
"""
from __future__ import annotations

import copy
from dataclasses import dataclass
from typing import Any, Callable, Iterable, Mapping

from .player_state import PlayerState
from .unit_of_work import PlayerUnitOfWork


class StackInventoryError(ValueError):
    pass


class InsufficientStackQuantity(StackInventoryError):
    pass


@dataclass(frozen=True)
class StackMutationRecord:
    item_id: int
    before: int
    after: int
    delta: int


class StackInventory:
    SLICE_ID = "backpack_stacks"

    def __init__(
        self,
        player: PlayerState,
        save_callback: Callable[[], None] | None = None,
        *,
        uow: PlayerUnitOfWork | None = None,
    ) -> None:
        self.player = player
        self._save_callback = save_callback
        self.uow = uow

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def normalize(self) -> bool:
        """Normalize ordinary stacks without inventing expiration metadata."""
        changed = False
        raw = self.player.backpack_items
        if not isinstance(raw, list):
            raw = []
            changed = True

        merged: dict[int, dict[str, int]] = {}
        order: list[int] = []
        for row in raw:
            if not isinstance(row, dict):
                changed = True
                continue
            item_id = self._int(row.get("table_id"), 0)
            item_num = self._int(row.get("item_num"), 0)
            if item_id <= 0 or item_num <= 0:
                changed = True
                continue
            if item_id not in merged:
                merged[item_id] = {
                    "table_id": item_id,
                    "item_num": 0,
                    "time": max(0, self._int(row.get("time"), 0)),
                }
                order.append(item_id)
            else:
                changed = True
            merged[item_id]["item_num"] += item_num
            if merged[item_id]["time"] == 0:
                merged[item_id]["time"] = max(0, self._int(row.get("time"), 0))

        normalized = [merged[item_id] for item_id in order]
        if normalized != self.player.backpack_items:
            self.player.backpack_items = normalized
            changed = True
        return changed

    def payload(self) -> dict[str, Any]:
        self.normalize()
        return {
            "sort_type": 0,
            "list": list(self.player.backpack_items),
            "spirit_list": list(self.player.spirit_list),
        }

    def quantity(self, item_id: Any) -> int:
        self.normalize()
        target = self._int(item_id, 0)
        for row in self.player.backpack_items:
            if self._int(row.get("table_id"), 0) == target:
                return max(0, self._int(row.get("item_num"), 0))
        return 0

    def validate_deltas(self, deltas: Mapping[Any, Any]) -> dict[int, int]:
        normalized: dict[int, int] = {}
        for raw_id, raw_delta in deltas.items():
            item_id = self._int(raw_id, 0)
            delta = self._int(raw_delta, 0)
            if item_id <= 0:
                raise StackInventoryError(f"invalid item_id {raw_id!r}")
            if delta:
                normalized[item_id] = normalized.get(item_id, 0) + delta
        for item_id, delta in normalized.items():
            current = self.quantity(item_id)
            if current + delta < 0:
                raise InsufficientStackQuantity(
                    f"insufficient item {item_id}: current={current} delta={delta}"
                )
        return normalized

    def apply_deltas(
        self,
        deltas: Mapping[Any, Any],
        *,
        persist: bool = False,
    ) -> tuple[StackMutationRecord, ...]:
        self.normalize()
        normalized = self.validate_deltas(deltas)
        if not normalized:
            return ()

        snapshot = copy.deepcopy(self.player.backpack_items)
        before = {item_id: self.quantity(item_id) for item_id in normalized}
        try:
            by_id = {
                self._int(row.get("table_id"), 0): row
                for row in self.player.backpack_items
                if isinstance(row, dict)
            }
            records: list[StackMutationRecord] = []
            for item_id in sorted(normalized):
                delta = normalized[item_id]
                after = before[item_id] + delta
                row = by_id.get(item_id)
                if after > 0:
                    if row is None:
                        row = {"table_id": item_id, "item_num": after, "time": 0}
                        self.player.backpack_items.append(row)
                        by_id[item_id] = row
                    else:
                        row["item_num"] = after
                elif row is not None:
                    self.player.backpack_items.remove(row)
                    by_id.pop(item_id, None)
                records.append(StackMutationRecord(item_id, before[item_id], after, delta))

            if self.uow is not None and self.uow.active:
                self.uow.mark_changed(self.SLICE_ID)
            elif persist:
                self._save()
            return tuple(records)
        except Exception:
            self.player.backpack_items = snapshot
            raise

    def add_items(self, awards: Iterable[dict[str, Any]], *, persist: bool = True) -> list[dict[str, int]]:
        deltas: dict[int, int] = {}
        response: list[dict[str, int]] = []
        for award in awards:
            if not isinstance(award, dict):
                continue
            item_id = self._int(award.get("item_id"), 0)
            item_num = self._int(award.get("item_num"), 0)
            if item_id <= 0 or item_num <= 0:
                continue
            deltas[item_id] = deltas.get(item_id, 0) + item_num
            response.append({"item_id": item_id, "item_num": item_num})
        if deltas:
            self.apply_deltas(deltas, persist=persist)
        return response

    def consume_item(self, item_id: Any, item_num: Any, *, persist: bool = True) -> int | None:
        target = self._int(item_id, 0)
        count = self._int(item_num, 0)
        if target <= 0 or count <= 0:
            return self.quantity(target)
        try:
            rows = self.apply_deltas({target: -count}, persist=persist)
        except InsufficientStackQuantity:
            return None
        return rows[0].after if rows else self.quantity(target)

    def consume_items(self, items: Iterable[dict[str, Any]], *, persist: bool = True) -> bool:
        deltas: dict[int, int] = {}
        for item in items:
            if not isinstance(item, dict):
                continue
            item_id = self._int(item.get("item_id"), 0)
            item_num = self._int(item.get("item_num"), 0)
            if item_id > 0 and item_num > 0:
                deltas[item_id] = deltas.get(item_id, 0) - item_num
        if not deltas:
            return True
        try:
            self.apply_deltas(deltas, persist=persist)
            return True
        except InsufficientStackQuantity:
            return False

    def get_item_num(self, item_id: Any) -> int:
        return self.quantity(item_id)

    def _save(self) -> None:
        if self._save_callback:
            self._save_callback()
