"""Source-derived deterministic consumable effect catalog (Pass98)."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any


class ConsumableEffectCatalog:
    META_FILE = "consumable_effect_meta.json"
    ITEM_TYPE_CONSUMABLE = 4
    ENERGY_SUBTYPE = 5
    MAGIC_SUBTYPE = 12

    def __init__(self, data_dir: Path) -> None:
        path = Path(data_dir) / self.META_FILE
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise RuntimeError(f"[CONSUMABLE] invalid source metadata {path}: {exc}") from exc
        if not isinstance(payload, dict):
            raise RuntimeError("[CONSUMABLE] metadata root must be an object")
        meta = payload.get("_meta")
        rows = payload.get("items")
        if not isinstance(meta, dict) or meta.get("source_resolution") != "effective_merged":
            raise RuntimeError("[CONSUMABLE] metadata is not effective_merged")
        if int(meta.get("schema_version", 0) or 0) != 1:
            raise RuntimeError("[CONSUMABLE] unsupported metadata schema")
        if not isinstance(rows, dict):
            raise RuntimeError("[CONSUMABLE] items must be a mapping")
        self.meta = dict(meta)
        self._rows: dict[int, dict[str, Any]] = {}
        for raw_id, raw in rows.items():
            if not isinstance(raw, dict):
                continue
            try:
                item_id = int(raw_id)
            except (TypeError, ValueError):
                continue
            if item_id <= 0:
                continue
            self._rows[item_id] = dict(raw)

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def row(self, item_id: Any) -> dict[str, Any] | None:
        try:
            target = int(item_id)
        except (TypeError, ValueError):
            return None
        row = self._rows.get(target)
        return dict(row) if row is not None else None

    def energy_effect(self, item_id: Any) -> int | None:
        row = self.row(item_id)
        if row is None:
            return None
        if self._int(row.get("type")) != self.ITEM_TYPE_CONSUMABLE:
            return None
        if self._int(row.get("sub_type")) != self.ENERGY_SUBTYPE:
            return None
        amount = self._int(row.get("energy"))
        return amount if amount > 0 else None

    def magic_effect(self, item_id: Any) -> tuple[str, int] | None:
        """Return MID87's one source effect using the same client precedence."""
        row = self.row(item_id)
        if row is None:
            return None
        if self._int(row.get("type")) != self.ITEM_TYPE_CONSUMABLE:
            return None
        if self._int(row.get("sub_type")) != self.MAGIC_SUBTYPE:
            return None
        for key in ("magic_energy", "magic_dust", "magic_liquid"):
            amount = self._int(row.get(key))
            if amount > 0:
                return key, amount
        return None

    def gift_ids(self, item_id: Any) -> tuple[int, ...]:
        row = self.row(item_id)
        if row is None:
            return ()
        raw = row.get("gifts")
        if not isinstance(raw, list):
            return ()
        values: list[int] = []
        for value in raw:
            number = self._int(value)
            if number > 0:
                values.append(number)
        return tuple(values)

    def __len__(self) -> int:
        return len(self._rows)
