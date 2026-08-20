"""Explicit Custom Private Server policy for Magic/Gachapon MID70/MID71.

Recovered source facts come from :mod:`magic_summon_source_catalog`.  This module
owns only the server choices that cannot be recovered from the EOL service.
"""
from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path
from typing import Any

from gxb_backend.content.magic_summon_source_catalog import MagicFragmentRate, MagicSummonSourceCatalog
from gxb_backend.content.summon_pool_catalog import SummonPool, SummonPoolCatalog, SummonPoolRow

from .summon_private_policy import SummonRandomSource, SystemSummonRandomSource


@dataclass(frozen=True)
class MagicOperationPolicy:
    pull_count: int
    crystal_cost: int
    byproduct_rolls: int
    selected_fragment_mode: str
    selected_fragment_bundles: int


class MagicSummonPrivatePolicy:
    DATA_FILE = "magic_summon_private_policy.json"

    def __init__(self, data_dir: Path | str, source: MagicSummonSourceCatalog) -> None:
        path = Path(data_dir) / self.DATA_FILE
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise RuntimeError(f"cannot load private Magic summon policy {path}: {exc}") from exc
        if not isinstance(raw, dict):
            raise RuntimeError(f"invalid private Magic summon policy: {path}")
        meta = raw.get("_meta")
        if not isinstance(meta, dict):
            raise RuntimeError("private Magic summon policy metadata missing")
        self.meta = dict(meta)
        self.active = bool(meta.get("active"))
        self.response_channels = dict(raw.get("response_channels") or {})
        self.retry = dict(raw.get("retry_policy") or {})
        balance = raw.get("balance_overrides")
        if not isinstance(balance, dict):
            raise RuntimeError("private Magic balance_overrides missing")
        self._row_weight_overrides = {
            int(k): int(v) for k, v in dict(balance.get("byproduct_row_weight_overrides") or {}).items()
        }
        self._fragment_rate_overrides = {
            int(k): int(v) for k, v in dict(balance.get("fragment_quantity_rate_overrides") or {}).items()
        }
        if any(row_id <= 0 or weight < 0 for row_id, weight in self._row_weight_overrides.items()):
            raise RuntimeError("invalid Magic byproduct row-weight override")
        if any(qty <= 0 or weight < 0 for qty, weight in self._fragment_rate_overrides.items()):
            raise RuntimeError("invalid Magic fragment-rate override")

        self._operations: dict[int, MagicOperationPolicy] = {}
        operations = raw.get("operations")
        if not isinstance(operations, dict):
            raise RuntimeError("private Magic operations missing")
        for raw_count, row in operations.items():
            if not isinstance(row, dict):
                raise RuntimeError("private Magic operation row malformed")
            count = int(raw_count)
            op = MagicOperationPolicy(
                pull_count=count,
                crystal_cost=int(row.get("crystal_cost") or 0),
                byproduct_rolls=int(row.get("byproduct_rolls") or 0),
                selected_fragment_mode=str(row.get("selected_fragment_mode") or ""),
                selected_fragment_bundles=int(row.get("selected_fragment_bundles") or 0),
            )
            if count not in {1, 10} or op.crystal_cost <= 0 or op.byproduct_rolls <= 0 or op.selected_fragment_bundles != 1:
                raise RuntimeError(f"invalid private Magic operation policy {count}")
            source_cost = source.crystal_cost(count)
            if source_cost != op.crystal_cost:
                raise RuntimeError(f"private Magic cost drifts from recovered source cost for x{count}")
            if count == 1 and op.selected_fragment_mode != "fixed_5":
                raise RuntimeError("Magic single must preserve source fixed-5 fragment rule")
            if count == 10 and op.selected_fragment_mode != "source_weighted_crit_table":
                raise RuntimeError("Magic ten must preserve source crit-table rule")
            self._operations[count] = op

    @property
    def retry_window_ms(self) -> int:
        return max(0, int(self.retry.get("window_ms") or 0))

    def operation(self, pull_count: Any) -> MagicOperationPolicy | None:
        try:
            return self._operations.get(int(pull_count))
        except (TypeError, ValueError):
            return None

    def effective_row_weight(self, row: SummonPoolRow) -> int:
        return self._row_weight_overrides.get(int(row.row_id), max(0, int(row.drop_rate)))

    def effective_fragment_rates(self, source_rates: tuple[MagicFragmentRate, ...]) -> tuple[MagicFragmentRate, ...]:
        if not self._fragment_rate_overrides:
            return source_rates
        return tuple(
            MagicFragmentRate(row.quantity, self._fragment_rate_overrides.get(row.quantity, row.weight))
            for row in source_rates
        )


class MagicSummonPrivatePlanner:
    def __init__(
        self,
        source: MagicSummonSourceCatalog,
        pools: SummonPoolCatalog,
        policy: MagicSummonPrivatePolicy,
        random_source: SummonRandomSource | None = None,
    ) -> None:
        self.source = source
        self.pools = pools
        self.policy = policy
        self.random = random_source or SystemSummonRandomSource()

    def byproduct_pool(self) -> SummonPool:
        pool = self.pools.require(self.source.byproduct_dropbox_id)
        if pool.result_kind != "item":
            raise RuntimeError("Magic byproduct pool must be item-only")
        if len(pool.rows) != self.source.byproduct_row_count:
            raise RuntimeError("Magic byproduct pool row-count drift")
        return pool

    def pick_byproduct(self) -> SummonPoolRow:
        pool = self.byproduct_pool()
        weighted = [(row, self.policy.effective_row_weight(row)) for row in pool.rows]
        total = sum(weight for _row, weight in weighted if weight > 0)
        if total <= 0:
            raise RuntimeError("Magic byproduct policy has no positive effective weights")
        roll = self.random.randbelow(total)
        cursor = 0
        for row, weight in weighted:
            if weight <= 0:
                continue
            cursor += weight
            if roll < cursor:
                return row
        raise RuntimeError("Magic byproduct weighted selection overflow")

    def selected_fragment_quantity(self, pull_count: int) -> int:
        op = self.policy.operation(pull_count)
        if op is None:
            raise RuntimeError("unsupported Magic pull count")
        if op.selected_fragment_mode == "fixed_5":
            return 5
        rates = self.policy.effective_fragment_rates(self.source.fragment_rates())
        weighted = [(row, max(0, int(row.weight))) for row in rates]
        total = sum(weight for _row, weight in weighted if weight > 0)
        if total <= 0:
            raise RuntimeError("Magic fragment policy has no positive effective rates")
        roll = self.random.randbelow(total)
        cursor = 0
        for row, weight in weighted:
            if weight <= 0:
                continue
            cursor += weight
            if roll < cursor:
                return int(row.quantity)
        raise RuntimeError("Magic fragment weighted selection overflow")
