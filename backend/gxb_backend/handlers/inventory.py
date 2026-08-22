"""Backpack/inventory/rune handlers."""

from __future__ import annotations

from gxb_backend.content import CatalogNamespace, ContentRef
from gxb_backend.state.mutation_plan import (
    ActorRef, IdempotencySpec, MutationOrigin, MutationPlan, StackMutation, TemporalTransition
)
from gxb_backend.state.mutation_settlement_service import MutationSettlementError
from gxb_backend.state.unit_of_work import OperationContext

from .context import HandlerContext


class InventoryHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_backpack(self, req: dict) -> dict:
        return self.ctx.state.get_inventory_repository().payload()

    def load_rune(self, req: dict) -> dict:
        return self.ctx.state.get_player().rune_payload()

    def load_scrolls(self, req: dict) -> dict:
        return {"list": self.ctx.state.get_player().scrolls}

    def load_essences(self, req: dict) -> dict:
        return {"list": self.ctx.state.get_player().essences}

    def sell_item(self, req: dict) -> dict:
        return self.ctx.state.get_services().inventory_sales.sell_one(req)

    def sell_items(self, req: dict) -> dict:
        return self.ctx.state.get_services().inventory_sales.sell_many(req)

    def compose_item(self, req: dict) -> dict:
        return {"awards": []}

    def use_magic_items(self, req: dict) -> dict:
        return {"awards": []}

    def use_energy_item(self, req: dict) -> dict:
        """MID27: atomically consume the source item and credit timed Energy."""
        services = self.ctx.state.get_services()
        item_id = int(req.get("item_id", 0) or 0)
        item_num = int(req.get("item_num", 0) or 0)
        row = services.catalog.maybe_get(ContentRef(CatalogNamespace.ITEM, item_id)) if item_id > 0 else None
        per_item = int(row.get("energy", 0) or 0) if row is not None else 0
        if item_num <= 0 or per_item <= 0 or services.inventory.get_item_num(item_id) < item_num:
            return {"error_code": 1}

        context = OperationContext(
            actor_player_id=str(services.player.player_id),
            domain="temporal",
            operation_name="use_energy_item",
            protocol_mid=27,
        )
        try:
            with services.uow.transaction(context):
                plan = MutationPlan(
                    schema_version=1,
                    plan_id=f"energy-item:{item_id}:{item_num}:{services.uow.current_state_version}",
                    origin=MutationOrigin(domain="temporal", operation="use_energy_item", protocol_mid=27),
                    actor=ActorRef(player_id=str(services.player.player_id)),
                    expected_state_version=None,
                    idempotency=IdempotencySpec(),
                    preconditions=(),
                    operations=(
                        StackMutation(item_id, "DEBIT", item_num),
                        TemporalTransition("energy", "CREDIT", per_item * item_num),
                    ),
                )
                services.mutation_settlement.apply(plan)
        except MutationSettlementError:
            return {"error_code": 1}

        # SelfPlayer USE_ENERGY_ITEM removes the submitted Backpack stack locally.
        # The committed TEMPORAL journal supplies cumulative economy_.energy.
        return {}

    def use_skill_point_item(self, req: dict) -> dict:
        return self.ctx.state.get_hero_progression_repository().use_skill_point_item(req)

    def use_exp_item(self, req: dict) -> dict:
        return self.ctx.state.get_hero_progression_repository().use_exp_item(req)

    def use_exp_items(self, req: dict) -> dict:
        return self.ctx.state.get_hero_progression_repository().use_exp_items(req)

    def sort_type(self, req: dict) -> dict:
        return {}
