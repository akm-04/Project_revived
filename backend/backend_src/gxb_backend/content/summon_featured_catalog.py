"""Release-owned candidate cohorts for deterministic featured Vending policy.

The JSON is generated from the canonical GirlsGuide catalogue.  Runtime code
never infers SX/Legacy membership from numeric prefixes or display names.
"""
from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path
from typing import Iterable


@dataclass(frozen=True)
class FeaturedGirl:
    hero_id: int
    name: str
    native_star: int
    stone_id: int
    is_sx: bool


class SummonFeaturedCatalog:
    DATA_FILE = "summon_featured_catalog.json"

    def __init__(self, data_dir: Path | str) -> None:
        path = Path(data_dir) / self.DATA_FILE
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise RuntimeError(f"cannot load featured summon catalog {path}: {exc}") from exc
        if not isinstance(raw, dict):
            raise RuntimeError(f"invalid featured summon catalog: {path}")
        self.meta = dict(raw.get("_meta") or {})
        self._sx = self._parse(raw.get("sx_eligible"), "sx_eligible")
        self._medium_extension = self._parse(
            raw.get("medium_legacy_ordinary_extension"), "medium_legacy_ordinary_extension"
        )
        self._medium_featured = self._parse(
            raw.get("medium_legacy_featured_only"), "medium_legacy_featured_only"
        )
        if len(self._sx) != 73 or len(self._medium_extension) != 58 or len(self._medium_featured) != 56:
            raise RuntimeError(
                "featured summon catalogue cohort drift: "
                f"sx={len(self._sx)} medium_extension={len(self._medium_extension)} "
                f"medium_featured={len(self._medium_featured)}"
            )
        if any(not row.is_sx for row in self._sx):
            raise RuntimeError("SX featured cohort contains non-SX Girl")
        if any(row.is_sx for row in (*self._medium_extension, *self._medium_featured)):
            raise RuntimeError("Medium Legacy cohort contains SX Girl")
        all_groups = [
            {r.hero_id for r in self._sx},
            {r.hero_id for r in self._medium_extension},
            {r.hero_id for r in self._medium_featured},
        ]
        if any(all_groups[i] & all_groups[j] for i in range(3) for j in range(i + 1, 3)):
            raise RuntimeError("featured summon cohorts overlap")

    @staticmethod
    def _parse(value: object, label: str) -> tuple[FeaturedGirl, ...]:
        if not isinstance(value, list):
            raise RuntimeError(f"featured summon catalog {label} must be an array")
        out: list[FeaturedGirl] = []
        seen: set[int] = set()
        for item in value:
            if not isinstance(item, dict):
                raise RuntimeError(f"invalid {label} row")
            row = FeaturedGirl(
                hero_id=int(item.get("hero_id") or 0),
                name=str(item.get("name") or ""),
                native_star=int(item.get("native_star") or 0),
                stone_id=int(item.get("stone_id") or 0),
                is_sx=bool(item.get("is_sx")),
            )
            if row.hero_id <= 0 or row.native_star <= 0 or row.stone_id <= 0 or row.hero_id in seen:
                raise RuntimeError(f"invalid/duplicate {label} Girl {row.hero_id}")
            seen.add(row.hero_id)
            out.append(row)
        return tuple(out)

    def sx(self) -> tuple[FeaturedGirl, ...]:
        return self._sx

    def medium_extension(self) -> tuple[FeaturedGirl, ...]:
        return self._medium_extension

    def medium_featured(self) -> tuple[FeaturedGirl, ...]:
        return self._medium_featured

    def sx_ids(self) -> frozenset[int]:
        return frozenset(row.hero_id for row in self._sx)

    def medium_extension_ids(self) -> frozenset[int]:
        return frozenset(row.hero_id for row in self._medium_extension)

    def medium_featured_ids(self) -> frozenset[int]:
        return frozenset(row.hero_id for row in self._medium_featured)

    @staticmethod
    def by_id(rows: Iterable[FeaturedGirl], hero_id: int) -> FeaturedGirl | None:
        target = int(hero_id)
        return next((row for row in rows if row.hero_id == target), None)
