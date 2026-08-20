"""Explicit Custom Private Server Policy for unrecoverable classic Vending math.

Recovered client/source facts remain inputs. Probability, retry and ordinary-pool
substitution choices in this module are private-server behavior. Duplicate conversion
quantities moved to the evidence-backed global policy in Pass41.7.
not claims about the historical official service.
"""
from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path
import random
from typing import Protocol

from gxb_backend.content.summon_pool_catalog import SummonPool, SummonPoolCatalog, SummonPoolRow


class SummonRandomSource(Protocol):
    def randbelow(self, upper: int) -> int:
        ...


class SystemSummonRandomSource:
    def __init__(self) -> None:
        self._rng = random.SystemRandom()

    def randbelow(self, upper: int) -> int:
        if int(upper) <= 0:
            raise ValueError("upper must be positive")
        return self._rng.randrange(int(upper))


@dataclass(frozen=True)
class ClassicFamilyPolicy:
    family: str
    base_pool_id: int
    super_pool_id: int
    super_chance_per_10000: int
    ten_pull_guarantee: str


class SummonPrivateServerPolicy:
    DATA_FILE = "summon_private_server_policy.json"

    def __init__(self, data_dir: Path | str) -> None:
        path = Path(data_dir) / self.DATA_FILE
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise RuntimeError(f"cannot load private summon policy {path}: {exc}") from exc
        if not isinstance(raw, dict):
            raise RuntimeError(f"invalid private summon policy: {path}")
        self.meta = dict(raw.get("_meta") or {})
        self.retry = dict(raw.get("retry_policy") or {})
        self._active = frozenset(str(v) for v in self.meta.get("active_semantics") or [])
        self._families: dict[str, ClassicFamilyPolicy] = {}
        for family in ("small", "medium"):
            row = raw.get(family)
            if not isinstance(row, dict):
                raise RuntimeError(f"private summon policy missing family {family}")
            ordinary = row.get("ordinary_policy")
            guarantee = row.get("ten_pull_guarantee")
            if not isinstance(ordinary, dict) or not isinstance(guarantee, dict):
                raise RuntimeError(f"private summon policy malformed for {family}")
            base_pool_id = int(ordinary.get("custom_base_pool_id") or ordinary.get("base_pool_id") or 0)
            super_pool_id = int(ordinary.get("super_pool_id") or 0)
            chance = int(ordinary.get("super_chance_per_10000") or 0)
            if base_pool_id <= 0 or super_pool_id <= 0 or chance < 0 or chance > 10000:
                raise RuntimeError(f"invalid ordinary private summon policy for {family}")
            mode = str(guarantee.get("mode") or "")
            if mode not in {"at_least_one_item", "at_least_one_hero"}:
                raise RuntimeError(f"unsupported ten-pull guarantee for {family}: {mode}")
            self._families[family] = ClassicFamilyPolicy(
                family=family,
                base_pool_id=base_pool_id,
                super_pool_id=super_pool_id,
                super_chance_per_10000=chance,
                ten_pull_guarantee=mode,
            )

    def active(self, semantic: str) -> bool:
        return str(semantic) in self._active

    @property
    def retry_window_ms(self) -> int:
        return max(0, int(self.retry.get("window_ms") or 0))

    def family(self, family: str) -> ClassicFamilyPolicy:
        try:
            return self._families[str(family)]
        except KeyError as exc:
            raise RuntimeError(f"private summon family not configured: {family}") from exc


class ClassicVendingPrivatePlanner:
    """Pure weighted pool selection for the explicit private policy."""

    def __init__(
        self,
        pools: SummonPoolCatalog,
        policy: SummonPrivateServerPolicy,
        random_source: SummonRandomSource | None = None,
        balance_planner=None,
    ) -> None:
        self.pools = pools
        self.policy = policy
        self.random = random_source or SystemSummonRandomSource()
        self.balance = balance_planner

    def ordinary_pool(self, family: str) -> SummonPool:
        config = self.policy.family(family)
        if self.random.randbelow(10000) < config.super_chance_per_10000:
            return self.pools.require(config.super_pool_id)
        return self.pools.require(config.base_pool_id)

    def pick_row(self, pool: SummonPool) -> SummonPoolRow:
        total = sum(max(0, int(row.drop_rate)) for row in pool.rows)
        if total <= 0:
            raise RuntimeError(f"summon pool {pool.dropbox_id} has no positive weight")
        roll = self.random.randbelow(total)
        cursor = 0
        for row in pool.rows:
            cursor += max(0, int(row.drop_rate))
            if roll < cursor:
                return row
        raise RuntimeError(f"weighted selection overflow for summon pool {pool.dropbox_id}")

    def category_override_enabled(self, family: str) -> bool:
        return bool(self.balance is not None and self.balance.category_enabled(family))

    def pick_ordinary_category(self, family: str) -> str:
        if self.balance is None:
            raise RuntimeError("classic Vending balance planner unavailable")
        return self.balance.pick_category(family)

    def pick_item_class_category(self, family: str) -> str:
        if self.balance is None:
            raise RuntimeError("classic Vending balance planner unavailable")
        return self.balance.pick_item_class_category(family)

    def partition_item_pool(self, pool: SummonPool, category: str) -> SummonPool:
        if self.balance is None:
            raise RuntimeError("classic Vending balance planner unavailable")
        return self.balance.partition_item_pool(pool, category)

    def partition_hero_pool_by_star(self, family: str, pool: SummonPool) -> SummonPool:
        if self.balance is None:
            return pool
        return self.balance.partition_hero_pool_by_star(family, pool)
