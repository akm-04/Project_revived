"""Typed Summon result semantics for Pass41.2.

This module models the stock client's source-proven MID50 ``result`` row kinds
without choosing Vending RNG or duplicate-conversion quantities.  Planning,
canonical mutation and wire projection are deliberately separate concerns.
"""
from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Callable, Iterable, Mapping, Any


class SummonResultPlanUnavailable(RuntimeError):
    """Raised when a result row cannot be represented from proven inputs."""


class SummonResultKind(str, Enum):
    HERO = "hero"
    ITEM = "item"
    TO_STONE = "to_stone"


@dataclass(frozen=True)
class SummonResultRowPlan:
    """One server-selected semantic result occurrence.

    ``table_id`` is field-scoped by ``kind``:
    * HERO -> Hero/Partner table id
    * ITEM -> Item table id
    * TO_STONE -> Hero-fragment Item table id

    The duplicate conversion quantity is never derived here.  A TO_STONE row is
    valid only when an evidence-backed positive ``item_num`` is supplied by a
    future result policy/resolver.
    """

    kind: SummonResultKind
    table_id: int
    item_num: int | None = None
    hero_name: str | None = None
    partner_id: int | None = None
    evidence_status: str = "source_contract"

    def __post_init__(self) -> None:
        if int(self.table_id) <= 0:
            raise SummonResultPlanUnavailable("result row table_id must be positive")
        if self.kind is SummonResultKind.HERO:
            if not self.hero_name or not self.partner_id or int(self.partner_id) <= 0:
                raise SummonResultPlanUnavailable("hero row requires hero_name and positive partner_id")
            if self.item_num is not None:
                raise SummonResultPlanUnavailable("hero row cannot carry item_num")
        else:
            if self.hero_name is not None or self.partner_id is not None:
                raise SummonResultPlanUnavailable("item/to_stone rows cannot carry hero identity fields")
            if self.item_num is None or int(self.item_num) <= 0:
                raise SummonResultPlanUnavailable(
                    f"{self.kind.value} row requires an evidence-backed positive item_num"
                )

    @classmethod
    def hero(cls, *, table_id: int, partner_id: int, hero_name: str) -> "SummonResultRowPlan":
        return cls(
            kind=SummonResultKind.HERO,
            table_id=int(table_id),
            partner_id=int(partner_id),
            hero_name=str(hero_name),
        )

    @classmethod
    def item(cls, *, item_id: int, item_num: int) -> "SummonResultRowPlan":
        return cls(kind=SummonResultKind.ITEM, table_id=int(item_id), item_num=int(item_num))

    @classmethod
    def to_stone(cls, *, fragment_item_id: int, item_num: int | None) -> "SummonResultRowPlan":
        if item_num is None:
            raise SummonResultPlanUnavailable(
                "duplicate-to-stone quantity is unrecovered and cannot be inferred"
            )
        return cls(
            kind=SummonResultKind.TO_STONE,
            table_id=int(fragment_item_id),
            item_num=int(item_num),
            evidence_status="server_selected_quantity_required",
        )


@dataclass(frozen=True)
class SummonResultPlan:
    semantic: str
    rows: tuple[SummonResultRowPlan, ...]
    planner_status: str
    source_reference: str | None = None

    @classmethod
    def create(
        cls,
        *,
        semantic: str,
        rows: Iterable[SummonResultRowPlan],
        planner_status: str,
        source_reference: str | None = None,
    ) -> "SummonResultPlan":
        materialized = tuple(rows)
        if not semantic:
            raise SummonResultPlanUnavailable("result plan semantic is required")
        if not materialized:
            raise SummonResultPlanUnavailable("result plan must contain at least one row")
        return cls(
            semantic=str(semantic),
            rows=materialized,
            planner_status=str(planner_status),
            source_reference=source_reference,
        )


class SummonResultRenderer:
    """Pure conversion from typed result plan to stock MID50 wire rows.

    Canonical Hero/Inventory mutation must have happened before rendering.  The
    renderer neither owns player state nor applies Backpack/Hero mutations.
    """

    def render(
        self,
        plan: SummonResultPlan,
        *,
        hero_payload_resolver: Callable[[SummonResultRowPlan], Mapping[str, Any]],
    ) -> list[dict[str, Any]]:
        result: list[dict[str, Any]] = []
        for row in plan.rows:
            if row.kind is SummonResultKind.HERO:
                payload = dict(hero_payload_resolver(row))
                if int(payload.get("table_id") or 0) != row.table_id:
                    raise SummonResultPlanUnavailable("hero payload table_id differs from result plan")
                if int(payload.get("partner_id") or 0) != int(row.partner_id or 0):
                    raise SummonResultPlanUnavailable("hero payload partner_id differs from result plan")
                payload["is_partner"] = True
                payload.pop("to_stone", None)
                result.append(payload)
            elif row.kind is SummonResultKind.ITEM:
                result.append({"table_id": row.table_id, "item_num": int(row.item_num or 0)})
            elif row.kind is SummonResultKind.TO_STONE:
                result.append(
                    {
                        "table_id": row.table_id,
                        "item_num": int(row.item_num or 0),
                        "to_stone": True,
                    }
                )
            else:  # pragma: no cover - Enum exhaustiveness guard
                raise SummonResultPlanUnavailable(f"unsupported result kind: {row.kind}")
        return result
