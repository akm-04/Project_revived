"""Source-derived Summon/Vending dropbox rows used by private-server policy.

The catalog preserves recovered pool membership and row weights. It deliberately
contains no rule for *which* pool should be selected for a pull; that is owned by
``summon_private_policy`` and is explicitly private-server policy where the EOL
historical server formula is unrecoverable.
"""
from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class SummonPoolRow:
    row_id: int
    item_id: int
    item_num: int
    drop_rate: int
    roll_type: int


@dataclass(frozen=True)
class SummonPool:
    dropbox_id: int
    result_kind: str
    source_name: str
    rate_sum: int
    rows: tuple[SummonPoolRow, ...]


class SummonPoolCatalog:
    DATA_FILE = "summon_pool_catalog.json"

    def __init__(self, data_dir: Path | str) -> None:
        path = Path(data_dir) / self.DATA_FILE
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise RuntimeError(f"cannot load summon pool catalog {path}: {exc}") from exc
        if not isinstance(raw, dict) or not isinstance(raw.get("pools"), list):
            raise RuntimeError(f"invalid summon pool catalog: {path}")
        self.meta = dict(raw.get("_meta") or {})
        self._pools: dict[int, SummonPool] = {}
        for row in raw["pools"]:
            if not isinstance(row, dict):
                raise RuntimeError(f"invalid summon pool row in {path}")
            pool_id = int(row.get("dropbox_id") or 0)
            kind = str(row.get("result_kind") or "")
            if pool_id <= 0 or kind not in {"hero", "item"} or pool_id in self._pools:
                raise RuntimeError(f"invalid/duplicate summon pool {pool_id} in {path}")
            materialized: list[SummonPoolRow] = []
            for entry in row.get("rows") or []:
                parsed = SummonPoolRow(
                    row_id=int(entry.get("row_id") or 0),
                    item_id=int(entry.get("item_id") or 0),
                    item_num=int(entry.get("item_num") or 0),
                    drop_rate=int(entry.get("drop_rate") or 0),
                    roll_type=int(entry.get("roll_type") or 0),
                )
                if parsed.row_id <= 0 or parsed.item_id <= 0 or parsed.item_num <= 0 or parsed.drop_rate <= 0:
                    raise RuntimeError(f"invalid row in summon pool {pool_id}")
                materialized.append(parsed)
            if not materialized:
                raise RuntimeError(f"summon pool {pool_id} has no rows")
            self._pools[pool_id] = SummonPool(
                dropbox_id=pool_id,
                result_kind=kind,
                source_name=str(row.get("source_name") or ""),
                rate_sum=int(row.get("rate_sum") or 0),
                rows=tuple(materialized),
            )

    def get(self, pool_id: int) -> SummonPool | None:
        return self._pools.get(int(pool_id))

    def require(self, pool_id: int) -> SummonPool:
        pool = self.get(pool_id)
        if pool is None:
            raise KeyError(int(pool_id))
        return pool

    def ids(self) -> tuple[int, ...]:
        return tuple(sorted(self._pools))
