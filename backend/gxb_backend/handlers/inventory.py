"""Backpack/inventory/rune handlers."""

from __future__ import annotations

from gxb_backend.state.mutation_plan import (
    ActorRef, IdempotencySpec, MutationOrigin, MutationPlan, ResourceMutation, StackMutation, TemporalTransition
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

    def open_gift(self, req: dict) -> dict:
        """MID241: source-bounded deterministic ordinary Gift Opening."""
        return self.ctx.state.get_services().gift_opening.open(req)

    def compose_item(self, req: dict) -> dict:
        return {"awards": []}

    def use_magic_items(self, req: dict) -> dict:
        """MID87: atomically consume Event Centre items and credit magic resources.

        Effective EventCentreSellWindow derives exactly one effect per submitted
        item using item.lua magic_energy -> magic_dust -> magic_liquid precedence.
        SelfPlayer removes the input stacks locally only after error.OK, so any
        unrecognized/non-magic row must fail closed rather than return a false OK.
        """
        services = self.ctx.state.get_services()
        raw_items = req.get("items")
        if not isinstance(raw_items, list) or not raw_items:
            return {"error_code": 1}

        stack_counts: dict[int, int] = {}
        resource_credits: dict[str, int] = {}
        for raw in raw_items:
            if not isinstance(raw, dict):
                return {"error_code": 1}
            try:
                item_id = int(raw.get("item_id", 0) or 0)
                item_num = int(raw.get("item_num", 0) or 0)
            except (TypeError, ValueError):
                return {"error_code": 1}
            effect = services.consumable_effects.magic_effect(item_id) if item_id > 0 else None
            if item_num <= 0 or effect is None:
                return {"error_code": 1}
            resource_key, per_item = effect
            stack_counts[item_id] = stack_counts.get(item_id, 0) + item_num
            resource_credits[resource_key] = resource_credits.get(resource_key, 0) + per_item * item_num

        operations = [
            StackMutation(item_id, "DEBIT", count)
            for item_id, count in sorted(stack_counts.items())
        ]
        operations.extend(
            ResourceMutation(resource_key, "CREDIT", amount)
            for resource_key, amount in sorted(resource_credits.items())
            if amount > 0
        )
        if not operations or not resource_credits:
            return {"error_code": 1}

        context = OperationContext(
            actor_player_id=str(services.player.player_id),
            domain="event_centre",
            operation_name="use_magic_items",
            protocol_mid=87,
        )
        try:
            with services.uow.transaction(context):
                services.mutation_settlement.apply(MutationPlan(
                    schema_version=1,
                    plan_id=f"magic-items:{services.uow.current_state_version}",
                    origin=MutationOrigin(domain="event_centre", operation="use_magic_items", protocol_mid=87),
                    actor=ActorRef(player_id=str(services.player.player_id)),
                    expected_state_version=None,
                    idempotency=IdempotencySpec(),
                    preconditions=(),
                    operations=tuple(operations),
                ))
        except MutationSettlementError:
            return {"error_code": 1}
        return {}

    def use_energy_item(self, req: dict) -> dict:
        """MID27: atomically consume a source Energy item and credit timed Energy."""
        services = self.ctx.state.get_services()
        try:
            item_id = int(req.get("item_id", 0) or 0)
            item_num = int(req.get("item_num", 0) or 0)
        except (TypeError, ValueError):
            return {"error_code": 1}
        per_item = services.consumable_effects.energy_effect(item_id) if item_id > 0 else None
        if item_num <= 0 or per_item is None:
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
