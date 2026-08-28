"""Immutable effective-source facts for ordinary equipment Fumo restoration.

P0 Girls/Gear keeps the recovered source facts separate from the private-server
compatibility conversion policy.  The source exposes restoration material IDs,
their enchantment values, and per-quality return coefficients; the recovered
client does not expose the original server's rounding/decomposition algorithm.
"""
from __future__ import annotations

from dataclasses import dataclass
from fractions import Fraction
import json
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class FumoRestorationMaterial:
    item_id: int
    enchant_value: int
    ordinal: int


class FumoRestorationSourceCatalog:
    DATA_FILE = "fumo_restoration_source_catalog.json"

    def __init__(self, data_dir: Path | str) -> None:
        path = Path(data_dir) / self.DATA_FILE
        raw = json.loads(path.read_text(encoding="utf-8"))
        meta = raw.get("_meta") if isinstance(raw, dict) else None
        if not isinstance(meta, dict) or meta.get("source_resolution") != "effective_src64":
            raise RuntimeError("Fumo restoration catalog is not effective_src64")
        self.meta = dict(meta)
        self.materials = tuple(
            FumoRestorationMaterial(
                item_id=int(row["item_id"]),
                enchant_value=int(row["enchant_value"]),
                ordinal=int(row["ordinal"]),
            )
            for row in raw.get("materials", [])
        )
        if not self.materials or any(row.item_id <= 0 or row.enchant_value <= 0 for row in self.materials):
            raise RuntimeError("invalid Fumo restoration material catalog")
        qualities = raw.get("quality_restore_fraction") or {}
        self.quality_restore_fraction = {
            int(key): Fraction(int(value[0]), int(value[1]))
            for key, value in qualities.items()
        }
        if set(self.quality_restore_fraction) != {2, 3, 4, 5, 6}:
            raise RuntimeError("Fumo restoration quality coefficients drifted")

    def fraction_for_quality(self, quality: Any) -> Fraction | None:
        try:
            return self.quality_restore_fraction.get(int(quality))
        except (TypeError, ValueError):
            return None
