"""Source-derived Backpack stack ceilings.

Pass96 promotes ``item.lua.stack`` from client-only validation metadata into a
backend settlement invariant. Runtime handlers still never parse Lua: the
packaged JSON catalog is generated from the effective ``src_64`` source.
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any


class ItemStackLimitCatalogError(ValueError):
    pass


class ItemStackLimitCatalog:
    META_FILE = "item_stack_limit_meta.json"

    def __init__(self, data_dir: Path) -> None:
        self.data_dir = Path(data_dir)
        path = self.data_dir / self.META_FILE
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise RuntimeError(f"[ITEM_STACK] invalid source metadata {path}: {exc}") from exc
        if not isinstance(payload, dict):
            raise RuntimeError("[ITEM_STACK] metadata root must be an object")
        meta = payload.get("_meta")
        if not isinstance(meta, dict) or meta.get("source_resolution") != "effective_merged":
            raise RuntimeError("[ITEM_STACK] metadata is not effective_merged")
        rows = payload.get("items")
        if not isinstance(rows, dict):
            raise RuntimeError("[ITEM_STACK] items must be a mapping")
        self.meta = dict(meta)
        self._rows: dict[int, dict[str, int]] = {}
        for raw_id, raw in rows.items():
            if not isinstance(raw, dict):
                continue
            try:
                item_id = int(raw_id)
                stack = int(raw.get("stack") or 0)
                stack_exceed_mail = int(raw.get("stack_exceed_mail") or 0)
            except (TypeError, ValueError):
                continue
            if item_id <= 0:
                continue
            self._rows[item_id] = {
                "stack": max(0, stack),
                "stack_exceed_mail": max(0, stack_exceed_mail),
            }

    def row(self, item_id: Any) -> dict[str, int] | None:
        try:
            target = int(item_id)
        except (TypeError, ValueError):
            return None
        row = self._rows.get(target)
        return dict(row) if row is not None else None

    def limit(self, item_id: Any) -> int | None:
        row = self.row(item_id)
        if row is None:
            return None
        value = int(row.get("stack") or 0)
        # item.lua contains stack=0 rows for content that does not use ordinary
        # Backpack stacking. StackInventory only owns positive Backpack stacks,
        # so 0 is treated as "no StackInventory ceiling" rather than inventing
        # a zero-cap rejection for another storage domain.
        return value if value > 0 else None

    def stack_exceed_mail(self, item_id: Any) -> bool:
        row = self.row(item_id)
        return bool(row and int(row.get("stack_exceed_mail") or 0) == 1)

    def __len__(self) -> int:
        return len(self._rows)
