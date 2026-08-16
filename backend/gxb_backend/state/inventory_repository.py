"""Canonical Backpack/inventory mutation owner.

Stage 4A.5 promotes ordinary Backpack item stacks to a repository so Campaign
rewards and MID81 bootstrap/reload data share one persisted state graph.
"""

from __future__ import annotations

from collections.abc import Callable, Iterable
from typing import Any

from .player_state import PlayerState


class InventoryRepository:
    def __init__(self, player: PlayerState, save_callback: Callable[[], None] | None = None) -> None:
        self.player = player
        self._save_callback = save_callback

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def normalize(self) -> bool:
        """Normalize ordinary item stacks into Backpack.populate's source shape."""
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
            table_id = self._int(row.get("table_id"), 0)
            item_num = self._int(row.get("item_num"), 0)
            if table_id <= 0 or item_num <= 0:
                changed = True
                continue
            if table_id not in merged:
                merged[table_id] = {
                    "table_id": table_id,
                    "item_num": 0,
                    # Backpack.lua consumes time/startTime but ordinary static
                    # item rows do not require a fabricated expiry timestamp.
                    "time": max(0, self._int(row.get("time"), 0)),
                }
                order.append(table_id)
            else:
                changed = True
            merged[table_id]["item_num"] += item_num
            # Preserve a non-zero persisted time if one exists.
            if merged[table_id]["time"] == 0:
                merged[table_id]["time"] = max(0, self._int(row.get("time"), 0))

        normalized = [merged[table_id] for table_id in order]
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

    def add_items(self, awards: Iterable[dict[str, Any]], *, persist: bool = True) -> list[dict[str, int]]:
        """Add source-ID item awards and return the MID response award shape.

        Input/return rows use ``item_id`` + ``item_num`` as consumed by
        BattleCreate's MID114 callback. Canonical Backpack rows remain
        ``table_id`` + ``item_num`` + ``time`` as consumed by Backpack.lua.
        """
        self.normalize()
        by_id = {self._int(row.get("table_id"), 0): row for row in self.player.backpack_items}
        response: list[dict[str, int]] = []

        for award in awards:
            if not isinstance(award, dict):
                continue
            item_id = self._int(award.get("item_id"), 0)
            item_num = self._int(award.get("item_num"), 0)
            if item_id <= 0 or item_num <= 0:
                continue
            row = by_id.get(item_id)
            if row is None:
                row = {"table_id": item_id, "item_num": 0, "time": 0}
                self.player.backpack_items.append(row)
                by_id[item_id] = row
            row["item_num"] = self._int(row.get("item_num"), 0) + item_num
            response.append({"item_id": item_id, "item_num": item_num})

        if response and persist:
            self._save()
        return response


    def get_item_num(self, item_id: Any) -> int:
        """Return the canonical quantity for one ordinary Backpack item."""
        self.normalize()
        target = self._int(item_id, 0)
        for row in self.player.backpack_items:
            if self._int(row.get("table_id"), 0) == target:
                return max(0, self._int(row.get("item_num"), 0))
        return 0

    def consume_item(self, item_id: Any, item_num: Any, *, persist: bool = True) -> int | None:
        """Consume an exact positive quantity and return the remaining stack.

        ``None`` means the canonical Backpack did not contain enough items. The
        normal client only submits quantities already present in Backpack, so
        callers can keep an invalid handcrafted request mutation-free without
        inventing an unverified numeric error code.
        """
        self.normalize()
        target = self._int(item_id, 0)
        count = self._int(item_num, 0)
        if target <= 0 or count <= 0:
            return self.get_item_num(target)

        for index, row in enumerate(self.player.backpack_items):
            if self._int(row.get("table_id"), 0) != target:
                continue
            current = max(0, self._int(row.get("item_num"), 0))
            if current < count:
                return None
            remaining = current - count
            if remaining > 0:
                row["item_num"] = remaining
            else:
                self.player.backpack_items.pop(index)
            if persist:
                self._save()
            return remaining
        return None

    def consume_items(self, items: Iterable[dict[str, Any]], *, persist: bool = True) -> bool:
        """Atomically consume a list of ``item_id``/``item_num`` rows."""
        self.normalize()
        requested: dict[int, int] = {}
        for item in items:
            if not isinstance(item, dict):
                continue
            item_id = self._int(item.get("item_id"), 0)
            item_num = self._int(item.get("item_num"), 0)
            if item_id > 0 and item_num > 0:
                requested[item_id] = requested.get(item_id, 0) + item_num
        if not requested:
            return True
        if any(self.get_item_num(item_id) < item_num for item_id, item_num in requested.items()):
            return False
        for item_id, item_num in requested.items():
            self.consume_item(item_id, item_num, persist=False)
        if persist:
            self._save()
        return True

    def _save(self) -> None:
        if self._save_callback:
            self._save_callback()
