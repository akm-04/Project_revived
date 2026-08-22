"""Atomic generic Backpack sale settlement for MID82/MID86.

Pass69.1 deliberately routes sales through the Part-2 backbone:
STACK debit + scalar RESOURCE credit in one PlayerUnitOfWork transaction.
"""
from __future__ import annotations

from typing import Any, Iterable

from gxb_backend.content.item_sale_catalog import (
    ItemSaleCatalog,
    ItemSaleCatalogError,
)

from .mutation_plan import (
    ActorRef,
    IdempotencySpec,
    MutationOrigin,
    MutationPlan,
    ResourceMutation,
    StackMutation,
)
from .mutation_settlement_service import MutationSettlementError, MutationSettlementService
from .player_state import PlayerState
from .stack_inventory import StackInventoryError
from .unit_of_work import OperationContext, PlayerUnitOfWork


class InventorySaleError(ValueError):
    pass


class InventorySaleService:
    """Source-validated generic item sales; specialized families fail closed."""

    def __init__(
        self,
        player: PlayerState,
        sale_catalog: ItemSaleCatalog,
        settlement: MutationSettlementService,
        uow: PlayerUnitOfWork,
    ) -> None:
        self.player = player
        self.sale_catalog = sale_catalog
        self.settlement = settlement
        self.uow = uow

    @staticmethod
    def _positive(value: Any, label: str) -> int:
        try:
            result = int(value)
        except (TypeError, ValueError) as exc:
            raise InventorySaleError(f"{label} must be an integer") from exc
        if result <= 0:
            raise InventorySaleError(f"{label} must be positive")
        return result

    def _normalize_rows(self, rows: Iterable[dict[str, Any]]) -> tuple[tuple[int, int], ...]:
        merged: dict[int, int] = {}
        for row in rows:
            if not isinstance(row, dict):
                raise InventorySaleError("sale row must be an object")
            item_id = self._positive(row.get("item_id"), "item_id")
            item_num = self._positive(row.get("item_num"), f"item {item_id} quantity")
            merged[item_id] = merged.get(item_id, 0) + item_num
        if not merged:
            raise InventorySaleError("sale request is empty")
        return tuple(sorted(merged.items()))

    def _plan(self, rows: tuple[tuple[int, int], ...], *, mid: int, operation: str) -> MutationPlan:
        stack_ops: list[StackMutation] = []
        credits: dict[str, int] = {}
        source_rows: list[dict[str, Any]] = []
        for item_id, item_num in rows:
            desc = self.sale_catalog.require_generic(item_id)
            unit_price = desc.unit_price
            if unit_price <= 0:
                raise InventorySaleError(f"item {item_id} has no positive sale price")
            resource = desc.resource_key
            amount = unit_price * item_num
            credits[resource] = credits.get(resource, 0) + amount
            stack_ops.append(StackMutation(item_id=item_id, action="DEBIT", amount=item_num))
            source_rows.append({
                "item_id": item_id,
                "item_num": item_num,
                "unit_price": unit_price,
                "resource_key": resource,
            })

        resource_ops = [
            ResourceMutation(resource_key=key, action="CREDIT", amount=amount)
            for key, amount in sorted(credits.items())
        ]
        plan_key = ",".join(f"{item_id}x{item_num}" for item_id, item_num in rows)
        return MutationPlan(
            schema_version=1,
            plan_id=f"inventory:{operation}:{self.uow.current_state_version}:{plan_key}",
            origin=MutationOrigin(
                domain="inventory",
                operation=operation,
                protocol_mid=mid,
                source_table="item.lua",
                field_path="mana|crystal",
            ),
            actor=ActorRef(str(self.player.player_id), str(self.player.account_uid or "") or None),
            expected_state_version=self.uow.current_state_version,
            idempotency=IdempotencySpec(mode="NONE"),
            preconditions=(),
            operations=tuple([*stack_ops, *resource_ops]),
            metadata={"sale_rows": tuple(source_rows)},
        )

    def sell_rows(self, rows: Iterable[dict[str, Any]], *, mid: int, operation: str) -> dict[str, Any]:
        normalized = self._normalize_rows(rows)
        context = OperationContext(
            actor_player_id=str(self.player.player_id),
            domain="inventory",
            operation_name=operation,
            protocol_mid=int(mid),
        )
        try:
            with self.uow.transaction(context):
                self.settlement.apply(self._plan(normalized, mid=mid, operation=operation))
                # Current client updates scalar balances from the common economy_
                # envelope and removes sold stacks locally after success. Keep
                # the historical endpoint body minimal; Pass70 projects the
                # committed RESOURCE journal (with the old semantic bus retained
                # only as a compatibility bridge).
                return {"awards": []}
        except (InventorySaleError, ItemSaleCatalogError, MutationSettlementError, StackInventoryError) as exc:
            print(f"[INVENTORY SALE] rejected operation={operation}: {exc}")
            return {"error_code": 1, "awards": []}

    def sell_one(self, req: dict[str, Any]) -> dict[str, Any]:
        return self.sell_rows((req,), mid=82, operation="sell_item")

    def sell_many(self, req: dict[str, Any]) -> dict[str, Any]:
        rows = req.get("items") if isinstance(req, dict) else None
        if not isinstance(rows, list):
            return {"error_code": 1, "awards": []}
        return self.sell_rows(rows, mid=86, operation="sell_items")
