"""Immutable MID50 operation descriptors generated from effective summon source.

Pass41.1 keeps source/config meaning separate from player mutation and adds typed state/cost/counter references.  The catalog
identifies a summon operation by the protocol MID plus the client-provided
``summon_type`` and ``summon_index`` pair.  It does not spend currency, perform
RNG, mutate player state, or authorize unsupported vending operations.
"""
from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path
from typing import Any


@dataclass(frozen=True, order=True)
class SummonOperationKey:
    protocol_mid: int
    summon_type: int
    summon_index: int

    @classmethod
    def create(cls, protocol_mid: Any, summon_type: Any, summon_index: Any) -> "SummonOperationKey":
        return cls(int(protocol_mid), int(summon_type), int(summon_index))

    def token(self) -> str:
        return f"{self.protocol_mid}:{self.summon_type}:{self.summon_index}"


@dataclass(frozen=True)
class SummonOperationDescriptor:
    key: SummonOperationKey
    semantic: str
    support_status: str
    strategy: str | None
    source_summon_row: int | None
    source_family: str | None
    special_dropbox_id: int | None
    hero_name: str | None
    hero_table_id: int | None
    partner_id: int | None
    star: int | None
    reward_item_id: int | None
    reward_item_num: int | None
    receipt_name: str | None
    pull_count: int
    cost_plan_id: str | None
    counter_policy_id: str | None
    state_family: str | None
    rng_status: str
    vip_min: int
    evidence: dict[str, Any]

    @property
    def supported(self) -> bool:
        return self.support_status in {
            "tutorial_supported",
            "private_policy_supported",
            "private_sx_policy_supported",
        } and bool(self.strategy)


class SummonOperationCatalog:
    """Read-only typed operation catalog for the MID50 Vending/Summon surface."""

    DATA_FILE = "summon_operation_catalog.json"

    def __init__(self, data_dir: Path | str) -> None:
        self.data_dir = Path(data_dir)
        path = self.data_dir / self.DATA_FILE
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:  # pragma: no cover - startup guard
            raise RuntimeError(f"cannot load summon operation catalog {path}: {exc}") from exc
        if not isinstance(raw, dict) or not isinstance(raw.get("operations"), list):
            raise RuntimeError(f"invalid summon operation catalog: {path}")
        self.meta = dict(raw.get("_meta") or {})
        self._by_key: dict[SummonOperationKey, SummonOperationDescriptor] = {}
        for row in raw["operations"]:
            if not isinstance(row, dict):
                raise RuntimeError(f"invalid summon operation row in {path}")
            key = SummonOperationKey.create(
                row.get("protocol_mid"), row.get("summon_type"), row.get("summon_index")
            )
            if key in self._by_key:
                raise RuntimeError(f"duplicate summon operation key {key.token()} in {path}")
            desc = SummonOperationDescriptor(
                key=key,
                semantic=str(row.get("semantic") or ""),
                support_status=str(row.get("support_status") or "deferred_fail_closed"),
                strategy=(str(row["strategy"]) if row.get("strategy") else None),
                source_summon_row=(int(row["source_summon_row"]) if row.get("source_summon_row") is not None else None),
                source_family=(str(row["source_family"]) if row.get("source_family") else None),
                special_dropbox_id=(int(row["special_dropbox_id"]) if row.get("special_dropbox_id") is not None else None),
                hero_name=(str(row["hero_name"]) if row.get("hero_name") else None),
                hero_table_id=(int(row["hero_table_id"]) if row.get("hero_table_id") is not None else None),
                partner_id=(int(row["partner_id"]) if row.get("partner_id") is not None else None),
                star=(int(row["star"]) if row.get("star") is not None else None),
                reward_item_id=(int(row["reward_item_id"]) if row.get("reward_item_id") is not None else None),
                reward_item_num=(int(row["reward_item_num"]) if row.get("reward_item_num") is not None else None),
                receipt_name=(str(row["receipt_name"]) if row.get("receipt_name") else None),
                pull_count=max(1, int(row.get("pull_count") or 1)),
                cost_plan_id=(str(row["cost_plan_id"]) if row.get("cost_plan_id") else None),
                counter_policy_id=(str(row["counter_policy_id"]) if row.get("counter_policy_id") else None),
                state_family=(str(row["state_family"]) if row.get("state_family") else None),
                rng_status=str(row.get("rng_status") or "unrecovered_fail_closed"),
                vip_min=max(0, int(row.get("vip_min") or 0)),
                evidence=dict(row.get("evidence") or {}),
            )
            if not desc.semantic:
                raise RuntimeError(f"summon operation {key.token()} lacks semantic name")
            if desc.supported and desc.key.protocol_mid != 50:
                raise RuntimeError(f"Pass41.1 catalog may only activate MID50 operations: {key.token()}")
            self._by_key[key] = desc

    def get(self, key: SummonOperationKey) -> SummonOperationDescriptor | None:
        return self._by_key.get(key)

    def require(self, key: SummonOperationKey) -> SummonOperationDescriptor:
        desc = self.get(key)
        if desc is None:
            raise KeyError(key.token())
        return desc

    def keys(self) -> tuple[SummonOperationKey, ...]:
        return tuple(sorted(self._by_key))
