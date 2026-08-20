"""Private Medium Vending Legacy-access overlay for Pass42.9."""
from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path

from gxb_backend.content.summon_featured_catalog import SummonFeaturedCatalog
from gxb_backend.content.summon_pool_catalog import SummonPool, SummonPoolRow
from .summon_private_policy import SummonRandomSource, SystemSummonRandomSource


@dataclass(frozen=True)
class FeaturedLegacyDecision:
    selected: bool
    forced: bool
    counter_before: int
    counter_after: int


class MediumLegacyPrivatePolicy:
    DATA_FILE = "medium_legacy_private_policy.json"

    def __init__(self, data_dir: Path | str, catalog: SummonFeaturedCatalog) -> None:
        path = Path(data_dir) / self.DATA_FILE
        raw = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(raw, dict):
            raise RuntimeError(f"invalid Medium Legacy private policy: {path}")
        self.meta = dict(raw.get("_meta") or {})
        if int(self.meta.get("schema_version") or 0) != 1:
            raise RuntimeError("unsupported Medium Legacy private policy schema")
        self.catalog = catalog
        self.active_semantics = frozenset(str(v) for v in self.meta.get("active_semantics") or [])
        featured = dict(raw.get("featured_daily_overlay") or {})
        self.featured_chance_per_10000 = int(featured.get("chance_per_10000") or 0)
        self.featured_pity_slots = int(featured.get("pity_eligible_slots") or 0)
        self.featured_counter_key = str(featured.get("counter_key") or "medium_legacy_featured_pity_count")
        self.featured_target_key = str(featured.get("target_key") or "medium_legacy_featured_pity_target_id")
        if not (0 <= self.featured_chance_per_10000 <= 10000) or self.featured_pity_slots <= 0:
            raise RuntimeError("invalid Medium Legacy featured probability/pity")
        extension = dict(raw.get("ordinary_hero_extension") or {})
        self.extension_enabled = bool(extension.get("enabled", True))
        self.extension_default_weight = int(extension.get("default_candidate_weight") or 0)
        self.extension_weight_overrides = {
            int(k): int(v) for k, v in dict(extension.get("hero_weight_overrides") or {}).items()
        }
        if self.extension_default_weight <= 0 or any(v < 0 for v in self.extension_weight_overrides.values()):
            raise RuntimeError("invalid Medium Legacy ordinary extension weights")

    def active(self, semantic: str) -> bool:
        return str(semantic) in self.active_semantics

    def extension_weight(self, hero_id: int) -> int:
        return max(0, int(self.extension_weight_overrides.get(int(hero_id), self.extension_default_weight)))


class MediumLegacyPrivatePlanner:
    def __init__(
        self,
        catalog: SummonFeaturedCatalog,
        policy: MediumLegacyPrivatePolicy,
        random_source: SummonRandomSource | None = None,
    ) -> None:
        self.catalog = catalog
        self.policy = policy
        self.random = random_source or SystemSummonRandomSource()

    def featured_decision(self, counter_before: int) -> FeaturedLegacyDecision:
        before = max(0, int(counter_before))
        forced = before + 1 >= self.policy.featured_pity_slots
        selected = forced or self.random.randbelow(10000) < self.policy.featured_chance_per_10000
        return FeaturedLegacyDecision(
            selected=selected,
            forced=forced,
            counter_before=before,
            counter_after=0 if selected else before + 1,
        )

    @staticmethod
    def featured_pool(hero_id: int) -> SummonPool:
        hid = int(hero_id)
        return SummonPool(
            dropbox_id=-4209001,
            result_kind="hero",
            source_name="private:medium_legacy_featured_daily",
            rate_sum=10000,
            rows=(SummonPoolRow(row_id=hid, item_id=hid, item_num=1, drop_rate=10000, roll_type=1),),
        )

    def augmented_ordinary_hero_pool(self, source_pool: SummonPool) -> SummonPool:
        if source_pool.result_kind != "hero":
            raise RuntimeError("Medium Legacy extension requires a Hero source pool")
        if not self.policy.extension_enabled:
            return source_pool
        existing = {int(row.item_id) for row in source_pool.rows}
        extra: list[SummonPoolRow] = []
        for girl in self.catalog.medium_extension():
            if girl.hero_id in existing:
                continue
            weight = self.policy.extension_weight(girl.hero_id)
            if weight <= 0:
                continue
            extra.append(
                SummonPoolRow(
                    row_id=429000000 + int(girl.hero_id),
                    item_id=int(girl.hero_id),
                    item_num=1,
                    drop_rate=weight,
                    roll_type=1,
                )
            )
        rows = tuple(source_pool.rows) + tuple(extra)
        return SummonPool(
            dropbox_id=source_pool.dropbox_id,
            result_kind=source_pool.result_kind,
            source_name=source_pool.source_name + "+private:medium_legacy_extension",
            rate_sum=sum(max(0, int(row.drop_rate)) for row in rows),
            rows=rows,
        )

    def pick_row(self, pool: SummonPool) -> SummonPoolRow:
        total = sum(max(0, int(row.drop_rate)) for row in pool.rows)
        if total <= 0:
            raise RuntimeError("Medium Legacy augmented pool has no positive weight")
        roll = self.random.randbelow(total)
        cursor = 0
        for row in pool.rows:
            cursor += max(0, int(row.drop_rate))
            if roll < cursor:
                return row
        raise RuntimeError("Medium Legacy weighted selection overflow")
