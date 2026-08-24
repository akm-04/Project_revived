"""MID241 Gift Opening domain.

Pass138 established deterministic ordinary Gift Opening over canonical owners.
Pass140 activates the source-bounded ordinary random lane through a thin
request-scoped ``gift.open`` RandomOutcomeService adapter.  Probability policy,
pool ordering, batching, validation, settlement, and wire projection remain in
this Gift domain; ROS owns entropy mechanics only.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Sequence

from gxb_backend.content import CatalogNamespace, ContentRef
from gxb_backend.content.gift_opening_source_catalog import (
    GiftOpeningOperation,
    GiftOpeningSourceCatalog,
)

from .mutation_settlement_service import MutationSettlementError
from .random_outcome_service import RandomOutcomeService
from .reward_transaction_service import (
    EconomyGrant,
    InventoryGrant,
    RewardOrigin,
    RewardPlan,
    RewardTransactionService,
    RewardValidationError,
)
from .stack_inventory import StackInventory, StackInventoryError
from .unit_of_work import OperationContext, PlayerUnitOfWork


GIFT_OPEN_RNG_NAMESPACE = "gift.open"


class GiftOpeningError(ValueError):
    pass


class GiftRandomOutcomeAdapter:
    """Thin Gift-domain binding to request-scoped entropy mechanics.

    The adapter deliberately owns no pool/rate semantics.  The planner supplies
    already-reviewed integer weights in source order; ROS performs one weighted
    mechanical draw under the fixed ``gift.open`` namespace.
    """

    def __init__(
        self,
        service: RandomOutcomeService,
        namespace: str = GIFT_OPEN_RNG_NAMESPACE,
    ) -> None:
        if not isinstance(service, RandomOutcomeService):
            raise TypeError("service must be a RandomOutcomeService")
        if str(namespace) != GIFT_OPEN_RNG_NAMESPACE:
            raise ValueError(f"unsupported Gift Opening RNG namespace: {namespace!r}")
        self._service = service
        self.namespace = GIFT_OPEN_RNG_NAMESPACE

    def weighted_index(self, weights: Sequence[int]) -> int:
        return self._service.weighted_index(self.namespace, weights)


@dataclass(frozen=True)
class GiftOpeningResolvedRequest:
    operation: GiftOpeningOperation
    num: int


@dataclass(frozen=True)
class GiftOpeningPlan:
    operation: GiftOpeningOperation
    num: int
    rewards: RewardPlan
    wire_awards: tuple[tuple[int, int], ...]


class GiftOpeningPlanner:
    """Stateless source/capability policy planner for MID241.

    Deterministic/elective operations remain entropy-free.  For Phase3 ordinary
    random operations the planner owns the compatibility policy: positive raw
    ``drop_rate`` values are denominator-free relative integer weights, zero
    weights cannot win, each ordered ``gift.drops`` occurrence is one draw, and
    ``num`` repeats the whole gift operation before aggregation.
    """

    def __init__(
        self,
        source: GiftOpeningSourceCatalog,
        random_outcomes: GiftRandomOutcomeAdapter | None = None,
    ) -> None:
        self.source = source
        self.random_outcomes = random_outcomes

    @staticmethod
    def _positive_int(value: Any, field: str) -> int:
        if isinstance(value, bool):
            raise GiftOpeningError(f"{field} must be a positive integer")
        try:
            parsed = int(value)
        except (TypeError, ValueError) as exc:
            raise GiftOpeningError(f"{field} must be a positive integer") from exc
        if parsed <= 0:
            raise GiftOpeningError(f"{field} must be a positive integer")
        return parsed

    def resolve(self, item_id: Any, gift_id: Any, num: Any = 1) -> GiftOpeningResolvedRequest:
        """Resolve and fully source-validate a request without consuming entropy."""

        item_id = self._positive_int(item_id, "item_id")
        gift_id = self._positive_int(gift_id, "gift_id")
        num = self._positive_int(num, "num")
        operation = self.source.operation(item_id, gift_id)
        if operation is None:
            raise GiftOpeningError("unknown or non-effective MID241 (item_id,gift_id) operation")
        if not operation.supports_num and num != 1:
            raise GiftOpeningError(f"MID241 route {operation.route} supports exactly one source item")

        if operation.status == "DETERMINISTIC" and operation.capability == self.source.PHASE2_CAPABILITY:
            self._validate_deterministic_source(operation)
        elif operation.status == "RANDOM" and operation.capability == self.source.PHASE3_CAPABILITY:
            if self.random_outcomes is None:
                raise GiftOpeningError("ordinary random Gift Opening is not composed with request entropy")
            self._validate_random_source(operation)
        else:
            raise GiftOpeningError(
                f"MID241 operation is outside activated Gift Opening capability: {operation.capability}"
            )
        return GiftOpeningResolvedRequest(operation=operation, num=num)

    @staticmethod
    def _validate_common_fixed_source(operation: GiftOpeningOperation) -> None:
        if len(operation.raw_items) != len(operation.raw_item_nums):
            raise GiftOpeningError("source gift item/item_num cardinality is incomplete")
        if operation.raw_equip not in {"", "0"}:
            raise GiftOpeningError("Gift Opening source contains deferred gift.equip expansion")
        for fixed in operation.fixed_items:
            if fixed.item_id <= 0 or fixed.item_num <= 0:
                raise GiftOpeningError("source gift contains invalid fixed item payload")

    def _validate_deterministic_source(self, operation: GiftOpeningOperation) -> None:
        self._validate_common_fixed_source(operation)
        if operation.drop_occurrences:
            raise GiftOpeningError("deterministic Gift Opening unexpectedly contains drop occurrences")

    def _validate_random_source(self, operation: GiftOpeningOperation) -> None:
        self._validate_common_fixed_source(operation)
        if not operation.drop_occurrences:
            raise GiftOpeningError("ordinary random Gift Opening contains no drop occurrences")
        for occurrence in operation.drop_occurrences:
            if occurrence.missing_source or occurrence.dropbox_id <= 0:
                raise GiftOpeningError("ordinary random Gift Opening references missing dropbox source")
            if not occurrence.candidates:
                raise GiftOpeningError("ordinary random Gift Opening dropbox is empty")
            positive_weight = False
            for candidate in occurrence.candidates:
                if candidate.item_id <= 0 or candidate.item_num <= 0:
                    raise GiftOpeningError("ordinary random candidate has invalid item payload")
                if candidate.drop_rate < 0:
                    raise GiftOpeningError("ordinary random candidate has negative drop_rate")
                # Every recovered generic dropbox row uses roll_type=1.  A future
                # source drift must fail closed until its semantics are researched.
                if candidate.roll_type != 1:
                    raise GiftOpeningError("unsupported ordinary random dropbox roll_type")
                if candidate.item_type in {None, -1, 24}:
                    raise GiftOpeningError("ordinary random candidate requires deferred materialization")
                positive_weight = positive_weight or candidate.drop_rate > 0
            if not positive_weight:
                # Validate before calling ROS so an all-zero pool consumes no draw.
                raise GiftOpeningError("ordinary random dropbox has no positive relative weight")

    def _fixed_components(
        self,
        operation: GiftOpeningOperation,
        num: int,
    ) -> tuple[dict[int, int], list[int], dict[str, int], list[str]]:
        inventory_amounts: dict[int, int] = {}
        inventory_order: list[int] = []
        for fixed in operation.fixed_items:
            if fixed.item_id not in inventory_amounts:
                inventory_order.append(fixed.item_id)
                inventory_amounts[fixed.item_id] = 0
            inventory_amounts[fixed.item_id] += fixed.item_num * num

        economy_amounts: dict[str, int] = {}
        economy_order: list[str] = []
        for source_field, amount in operation.fixed_scalars:
            target_field = self.source.phase2_scalar_map.get(source_field)
            if not target_field:
                raise GiftOpeningError(f"source scalar {source_field!r} has no canonical Gift owner")
            if amount <= 0:
                raise GiftOpeningError(f"source scalar {source_field!r} is not positive")
            if target_field not in economy_amounts:
                economy_order.append(target_field)
                economy_amounts[target_field] = 0
            economy_amounts[target_field] += amount * num
        return inventory_amounts, inventory_order, economy_amounts, economy_order

    @staticmethod
    def _origin(operation: GiftOpeningOperation, *, random_lane: bool) -> RewardOrigin:
        return RewardOrigin(
            domain="gift_opening",
            operation="open_gift",
            protocol_mid=241,
            source_table="gift.lua" if not random_lane else "gift.lua|dropbox.lua",
            source_id=operation.gift_id,
            field_path=(
                "gift.items|gift.scalars"
                if not random_lane
                else "gift.items|gift.scalars|gift.drops->dropbox.drop_rate/item_id/item_num"
            ),
        )

    def preflight_rewards(self, resolved: GiftOpeningResolvedRequest) -> RewardPlan:
        """Return a mutation-free validation superset before any random draw.

        Random operations include every possible ordinary candidate once so the
        canonical RewardTransactionService can reject unsupported ownership before
        entropy is consumed.  Amounts here are validation-only, not settlement.
        """

        operation, num = resolved.operation, resolved.num
        inv, order, economy, economy_order = self._fixed_components(operation, num)
        random_lane = operation.status == "RANDOM"
        if random_lane:
            for occurrence in operation.drop_occurrences:
                for candidate in occurrence.candidates:
                    if candidate.item_id not in inv:
                        order.append(candidate.item_id)
                        inv[candidate.item_id] = 1
        return RewardPlan(
            origin=self._origin(operation, random_lane=random_lane),
            economy=tuple(EconomyGrant(field, economy[field]) for field in economy_order),
            inventory=tuple(
                InventoryGrant(ContentRef(CatalogNamespace.ITEM, item_id), inv[item_id])
                for item_id in order
            ),
        )

    def plan_resolved(self, resolved: GiftOpeningResolvedRequest) -> GiftOpeningPlan:
        operation, num = resolved.operation, resolved.num
        inv, order, economy, economy_order = self._fixed_components(operation, num)
        random_lane = operation.status == "RANDOM"

        if random_lane:
            if self.random_outcomes is None:  # resolve() normally prevents this.
                raise GiftOpeningError("ordinary random Gift Opening has no entropy adapter")
            # Compatibility decision: repeat the selected gift operation once per
            # consumed copy.  Within each copy, execute every source occurrence in
            # source order, including repeated pool IDs, and aggregate first-seen
            # reward item order for the one MID241 response.
            for _copy in range(num):
                for occurrence in operation.drop_occurrences:
                    weights = tuple(candidate.drop_rate for candidate in occurrence.candidates)
                    selected = self.random_outcomes.weighted_index(weights)
                    candidate = occurrence.candidates[selected]
                    if candidate.item_id not in inv:
                        order.append(candidate.item_id)
                        inv[candidate.item_id] = 0
                    inv[candidate.item_id] += candidate.item_num

        reward_plan = RewardPlan(
            origin=self._origin(operation, random_lane=random_lane),
            economy=tuple(EconomyGrant(field, economy[field]) for field in economy_order),
            inventory=tuple(
                InventoryGrant(ContentRef(CatalogNamespace.ITEM, item_id), inv[item_id])
                for item_id in order
                if inv[item_id] > 0
            ),
        )
        if not reward_plan.economy and not reward_plan.inventory:
            raise GiftOpeningError("Gift Opening resolves to no supported reward")
        wire_awards = tuple((item_id, inv[item_id]) for item_id in order if inv[item_id] > 0)
        return GiftOpeningPlan(
            operation=operation,
            num=num,
            rewards=reward_plan,
            wire_awards=wire_awards,
        )

    def plan(self, item_id: Any, gift_id: Any, num: Any = 1) -> GiftOpeningPlan:
        return self.plan_resolved(self.resolve(item_id, gift_id, num))


class GiftOpeningService:
    """Own MID241 validation, source debit, canonical reward settlement and wire projection."""

    def __init__(
        self,
        source: GiftOpeningSourceCatalog,
        planner: GiftOpeningPlanner,
        stacks: StackInventory,
        rewards: RewardTransactionService,
        uow: PlayerUnitOfWork,
    ) -> None:
        self.source = source
        self.planner = planner
        self.stacks = stacks
        self.rewards = rewards
        self.uow = uow

    @staticmethod
    def _request_num(req: dict[str, Any]) -> Any:
        value = req.get("num", 1)
        return 1 if value is None else value

    def open(self, req: dict[str, Any]) -> dict[str, Any]:
        if not isinstance(req, dict):
            return {"error_code": 1}
        try:
            # Preflight exact operation/capability/source shape, source quantity,
            # and every possible canonical reward owner before consuming entropy.
            resolved = self.planner.resolve(
                req.get("item_id"),
                req.get("gift_id"),
                self._request_num(req),
            )
            if self.stacks.quantity(resolved.operation.item_id) < resolved.num:
                raise GiftOpeningError("insufficient source gift quantity")
            self.rewards.validate(self.planner.preflight_rewards(resolved))

            plan = self.planner.plan_resolved(resolved)
            self.rewards.validate(plan.rewards)
            context = OperationContext(
                actor_player_id=str(self.uow.player.player_id),
                domain="gift_opening",
                operation_name="open_gift",
                protocol_mid=241,
            )
            with self.uow.transaction(context):
                remaining = self.stacks.consume_item(
                    plan.operation.item_id,
                    plan.num,
                    persist=False,
                )
                if remaining is None:
                    raise GiftOpeningError("insufficient source gift quantity during settlement")
                self.rewards.apply(plan.rewards)
        except (
            GiftOpeningError,
            RewardValidationError,
            MutationSettlementError,
            StackInventoryError,
            ValueError,
        ):
            return {"error_code": 1}

        # Client SelfPlayer removes the submitted source package locally after
        # error.OK.  Reward rows therefore contain reward amount, never net stack
        # deltas, and use the recovered table_id/item_num wire shape.
        return {
            "awards": [
                {"table_id": item_id, "item_num": item_num}
                for item_id, item_num in plan.wire_awards
            ]
        }
