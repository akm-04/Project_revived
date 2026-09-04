"""Private operator balance overlay for classic Small/Medium Vending.

Pass42.12 adds explicit category and native-star tuning without mutating the
recovered pool catalog.  The overlay is opt-in per family.  When disabled, the
pre-Pass42.12 two-stage class/pool selection remains byte-semantically intact.
"""
from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path
from typing import Iterable

from gxb_backend.content import CatalogNamespace, ContentRef, GameDataCatalog
from gxb_backend.content.summon_pool_catalog import SummonPool, SummonPoolRow

from .summon_private_policy import SummonRandomSource, SystemSummonRandomSource


CATEGORIES = ("item", "scroll", "girl")
NATIVE_STARS = (1, 2, 3)


@dataclass(frozen=True)
class ClassicVendingFamilyBalance:
    family: str
    category_enabled: bool
    category_weights: dict[str, int]
    girl_star_enabled: bool
    girl_star_weights: dict[int, int]
    scroll_candidate_mode: str
    item_candidate_mode: str
    girl_candidate_mode: str


class ClassicVendingBalancePolicy:
    DATA_FILE = "classic_vending_balance_policy.json"

    def __init__(self, data_dir: Path | str) -> None:
        path = Path(data_dir) / self.DATA_FILE
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise RuntimeError(f"cannot load classic Vending balance policy {path}: {exc}") from exc
        if not isinstance(raw, dict) or not isinstance(raw.get("_meta"), dict):
            raise RuntimeError(f"invalid classic Vending balance policy: {path}")
        if int(raw["_meta"].get("schema_version") or 0) != 1:
            raise RuntimeError("unsupported classic Vending balance policy schema")
        self.meta = dict(raw["_meta"])
        families = raw.get("families")
        if not isinstance(families, dict):
            raise RuntimeError("classic Vending balance policy families missing")
        self._families: dict[str, ClassicVendingFamilyBalance] = {}
        for family in ("small", "medium"):
            row = families.get(family)
            if not isinstance(row, dict):
                raise RuntimeError(f"classic Vending balance policy missing {family}")
            category = row.get("category_override")
            star = row.get("girl_star_override")
            if not isinstance(category, dict) or not isinstance(star, dict):
                raise RuntimeError(f"classic Vending balance policy malformed for {family}")
            category_weights = {
                name: int(dict(category.get("weights_per_10000") or {}).get(name, 0))
                for name in CATEGORIES
            }
            star_weights = {
                value: int(dict(star.get("weights_per_10000") or {}).get(str(value), 0))
                for value in NATIVE_STARS
            }
            if any(v < 0 for v in category_weights.values()) or sum(category_weights.values()) != 10000:
                raise RuntimeError(f"{family} category weights must be nonnegative and sum to 10000")
            if any(v < 0 for v in star_weights.values()) or sum(star_weights.values()) != 10000:
                raise RuntimeError(f"{family} Girl-star weights must be nonnegative and sum to 10000")
            scroll_mode = str(row.get("scroll_candidate_mode") or "")
            item_mode = str(row.get("item_candidate_mode") or "")
            girl_mode = str(row.get("girl_candidate_mode") or "")
            if scroll_mode != "flat_equal":
                raise RuntimeError(f"unsupported {family} scroll candidate mode: {scroll_mode}")
            if item_mode != "source_weighted":
                raise RuntimeError(f"unsupported {family} item candidate mode: {item_mode}")
            if girl_mode != "source_weighted_within_native_star":
                raise RuntimeError(f"unsupported {family} Girl candidate mode: {girl_mode}")
            self._families[family] = ClassicVendingFamilyBalance(
                family=family,
                category_enabled=bool(category.get("enabled", False)),
                category_weights=category_weights,
                girl_star_enabled=bool(star.get("enabled", False)),
                girl_star_weights=star_weights,
                scroll_candidate_mode=scroll_mode,
                item_candidate_mode=item_mode,
                girl_candidate_mode=girl_mode,
            )

    def family(self, family: str) -> ClassicVendingFamilyBalance:
        try:
            return self._families[str(family)]
        except KeyError as exc:
            raise RuntimeError(f"classic Vending balance family not configured: {family}") from exc


class ClassicVendingBalancePlanner:
    """Pure category/tier picker layered over recovered classic pools."""

    def __init__(
        self,
        policy: ClassicVendingBalancePolicy,
        catalog: GameDataCatalog,
        random_source: SummonRandomSource | None = None,
    ) -> None:
        self.policy = policy
        self.catalog = catalog
        self.random = random_source or SystemSummonRandomSource()
        partner_refs = self.catalog.iter_namespace(CatalogNamespace.PARTNER)
        self._partner_stars: dict[int, int] = {}
        self._scroll_item_ids: set[int] = set()
        for ref in partner_refs:
            row = self.catalog.get(ref)
            star = int(row.get("ini_star") or 0)
            stone = int(row.get("stone_id") or 0)
            if star in NATIVE_STARS:
                self._partner_stars[int(ref.table_id)] = star
            if stone > 0:
                self._scroll_item_ids.add(stone)

    def category_enabled(self, family: str) -> bool:
        return self.policy.family(family).category_enabled

    def star_enabled(self, family: str) -> bool:
        return self.policy.family(family).girl_star_enabled

    def is_scroll_item_id(self, item_id: int) -> bool:
        return int(item_id) in self._scroll_item_ids

    def native_star(self, hero_id: int) -> int:
        return int(self._partner_stars.get(int(hero_id), 0))

    def _weighted_name(self, weights: dict, *, error: str):
        rows = tuple((key, max(0, int(value))) for key, value in weights.items())
        total = sum(weight for _key, weight in rows)
        if total <= 0:
            raise RuntimeError(error)
        roll = self.random.randbelow(total)
        cursor = 0
        for key, weight in rows:
            cursor += weight
            if roll < cursor:
                return key
        raise RuntimeError(f"{error}: weighted selection overflow")

    def pick_category(self, family: str) -> str:
        config = self.policy.family(family)
        if not config.category_enabled:
            raise RuntimeError(f"{family} explicit category override is disabled")
        return str(self._weighted_name(config.category_weights, error=f"{family} category weights empty"))

    def pick_item_class_category(self, family: str) -> str:
        """Choose item vs scroll for an item-class guarantee under explicit tuning."""
        config = self.policy.family(family)
        if not config.category_enabled:
            raise RuntimeError(f"{family} explicit category override is disabled")
        weights = {name: config.category_weights[name] for name in ("item", "scroll")}
        if sum(max(0, int(v)) for v in weights.values()) <= 0:
            return "base"
        return str(self._weighted_name(weights, error=f"{family} item-class category weights empty"))

    def pick_native_star(self, family: str, rows: Iterable[SummonPoolRow]) -> int | None:
        config = self.policy.family(family)
        if not config.girl_star_enabled:
            return None
        materialized = tuple(rows)
        available = {self.native_star(row.item_id) for row in materialized}
        available.discard(0)
        effective = {
            star: weight if star in available else 0
            for star, weight in config.girl_star_weights.items()
        }
        invalid = [star for star, weight in config.girl_star_weights.items() if weight > 0 and star not in available]
        if invalid:
            raise RuntimeError(
                f"{family} Girl-star override assigns positive weight to unavailable native star(s): {invalid}"
            )
        return int(self._weighted_name(effective, error=f"{family} Girl-star weights have no available mass"))

    def partition_item_pool(self, pool: SummonPool, category: str) -> SummonPool:
        if pool.result_kind != "item" or category not in {"item", "scroll"}:
            raise RuntimeError("classic item partition requires item pool and item/scroll category")
        if category == "scroll":
            source_rows = tuple(row for row in pool.rows if self.is_scroll_item_id(row.item_id))
            # Pass42.12 user contract: scroll probability is split flat across
            # every eligible Girl-scroll row, irrespective of recovered row weight.
            rows = tuple(
                SummonPoolRow(
                    row_id=row.row_id,
                    item_id=row.item_id,
                    item_num=row.item_num,
                    drop_rate=1,
                    roll_type=row.roll_type,
                )
                for row in source_rows
            )
        else:
            rows = tuple(row for row in pool.rows if not self.is_scroll_item_id(row.item_id))
        if not rows:
            raise RuntimeError(f"classic base pool {pool.dropbox_id} has no {category} rows")
        return SummonPool(
            dropbox_id=pool.dropbox_id,
            result_kind=pool.result_kind,
            source_name=pool.source_name + f"+private:{category}",
            rate_sum=sum(max(0, int(row.drop_rate)) for row in rows),
            rows=rows,
        )

    def partition_hero_pool_by_star(self, family: str, pool: SummonPool) -> SummonPool:
        if pool.result_kind != "hero":
            raise RuntimeError("classic Girl-star partition requires Hero pool")
        star = self.pick_native_star(family, pool.rows)
        if star is None:
            return pool
        rows = tuple(row for row in pool.rows if self.native_star(row.item_id) == star)
        if not rows:
            raise RuntimeError(f"{family} Hero pool {pool.dropbox_id} has no native-{star}-star rows")
        return SummonPool(
            dropbox_id=pool.dropbox_id,
            result_kind=pool.result_kind,
            source_name=pool.source_name + f"+private:native_star_{star}",
            rate_sum=sum(max(0, int(row.drop_rate)) for row in rows),
            rows=rows,
        )

    def category_weights(self, family: str) -> dict[str, int]:
        return dict(self.policy.family(family).category_weights)
