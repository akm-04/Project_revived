"""Typed reward adapter over the Pass69 MutationPlan settlement foundation."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from gxb_backend.content import CatalogNamespace, ContentRef, GameDataCatalog

from .player_progression_service import PlayerProgressionService
from .hero_repository import HeroRepository
from .inventory_repository import InventoryRepository
from .mutation_plan import (
    ActorRef,
    IdempotencySpec,
    MutationOrigin,
    MutationPlan,
    ResourceMutation,
    StackMutation,
    TemporalTransition,
)
from .mutation_settlement_service import MutationSettlementService, SettlementDraft
from .resource_registry import ResourceRegistry
from .unit_of_work import UnitOfWork


class RewardValidationError(ValueError):
    pass


@dataclass(frozen=True)
class RewardOrigin:
    domain: str
    operation: str
    protocol_mid: int | None = None
    source_table: str | None = None
    source_id: int | None = None
    field_path: str | None = None


@dataclass(frozen=True)
class EconomyGrant:
    field: str
    amount: int


@dataclass(frozen=True)
class InventoryGrant:
    content: ContentRef
    amount: int


@dataclass(frozen=True)
class PartnerGrant:
    content: ContentRef
    amount: int = 1


@dataclass(frozen=True)
class RewardPlan:
    origin: RewardOrigin
    economy: tuple[EconomyGrant, ...] = ()
    inventory: tuple[InventoryGrant, ...] = ()
    partners: tuple[PartnerGrant, ...] = ()


@dataclass(frozen=True)
class RewardResult:
    economy: dict[str, int]
    inventory_awards: list[dict[str, int]]
    partners: list[dict[str, Any]]
    mutation_plan_id: str | None = None
    mutation_journal: tuple[dict[str, Any], ...] = ()


class RewardTransactionService:
    """Compatibility RewardPlan adapter that now emits typed MutationPlans.

    Scalar-ledger grants and Backpack stack grants route through MutationSettlementService.
    Energy routes through the specialized TEMPORAL operation family. Pass94 routes
    player EXP directly through PlayerProgressionService instead of the legacy
    EconomyRepository facade. Partner/entity grants remain aggregate-owned but
    share the same outer UoW.
    """

    TEMPORAL_FIELDS = frozenset({"energy"})
    PROGRESSION_FIELDS = frozenset({"player_exp"})

    def __init__(
        self,
        catalog: GameDataCatalog,
        progression: PlayerProgressionService,
        inventory: InventoryRepository,
        heroes: HeroRepository,
        uow: UnitOfWork,
        *,
        resource_registry: ResourceRegistry,
        settlement: MutationSettlementService,
    ) -> None:
        self.catalog = catalog
        self.progression = progression
        self.inventory = inventory
        self.heroes = heroes
        self.uow = uow
        self.resource_registry = resource_registry
        self.settlement = settlement
        self._plan_sequence = 0

    @staticmethod
    def _positive(value: Any, label: str) -> int:
        try:
            amount = int(value)
        except (TypeError, ValueError) as exc:
            raise RewardValidationError(f"{label} must be an integer") from exc
        if amount <= 0:
            raise RewardValidationError(f"{label} must be positive")
        return amount

    def _is_scalar_reward(self, field: str) -> bool:
        desc = self.resource_registry.get(field)
        return bool(desc and desc.legacy_adapter_class == "scalar_ledger" and desc.owner_service == "EconomyLedger")

    def validate(self, plan: RewardPlan) -> RewardPlan:
        for grant in plan.economy:
            if (
                not self._is_scalar_reward(grant.field)
                and grant.field not in self.TEMPORAL_FIELDS
                and grant.field not in self.PROGRESSION_FIELDS
            ):
                raise RewardValidationError(f"unsupported economy reward field {grant.field!r}")
            self._positive(grant.amount, f"economy.{grant.field}")
        for grant in plan.inventory:
            self._positive(grant.amount, "inventory amount")
            if CatalogNamespace(grant.content.namespace) is not CatalogNamespace.ITEM:
                raise RewardValidationError("InventoryGrant must use the item namespace")
            row = self.catalog.get(grant.content)
            item_type = int(row.get("type", 0) or 0)
            if item_type == -1:
                raise RewardValidationError("item type=-1 is not a stackable InventoryGrant")
            if item_type == 3 and int(row.get("partner_id", 0) or 0) <= 0:
                raise RewardValidationError("partner-scroll item lacks explicit partner_id cross-reference")
        for grant in plan.partners:
            if self._positive(grant.amount, "partner amount") != 1:
                raise RewardValidationError("PartnerGrant currently supports amount=1 only")
            if CatalogNamespace(grant.content.namespace) not in {
                CatalogNamespace.PARTNER,
                CatalogNamespace.SUPER_PARTNER,
            }:
                raise RewardValidationError("PartnerGrant must use a partner namespace")
            row = self.catalog.get(grant.content)
            if int(row.get("star", 0) or 0) <= 0:
                raise RewardValidationError("partner catalog row lacks source star")
        return plan

    def _next_plan_id(self, origin: RewardOrigin) -> str:
        self._plan_sequence += 1
        return f"reward:{origin.domain}:{origin.operation}:{self._plan_sequence}"

    def _mutation_plan(self, plan: RewardPlan) -> MutationPlan | None:
        operations = []
        for grant in plan.economy:
            if self._is_scalar_reward(grant.field):
                operations.append(ResourceMutation(grant.field, "CREDIT", int(grant.amount)))
            elif grant.field in self.TEMPORAL_FIELDS:
                operations.append(TemporalTransition(grant.field, "CREDIT", int(grant.amount)))
        for grant in plan.inventory:
            operations.append(StackMutation(int(grant.content.table_id), "CREDIT", int(grant.amount)))
        if not operations:
            return None
        return MutationPlan(
            schema_version=1,
            plan_id=self._next_plan_id(plan.origin),
            origin=MutationOrigin(
                domain=plan.origin.domain,
                operation=plan.origin.operation,
                protocol_mid=plan.origin.protocol_mid,
                source_table=plan.origin.source_table,
                source_id=plan.origin.source_id,
                field_path=plan.origin.field_path,
            ),
            actor=ActorRef(
                player_id=str(self.uow.player.player_id),
                account_uid=str(getattr(self.uow.player, "account_uid", "") or "") or None,
            ),
            expected_state_version=self.uow.current_state_version,
            idempotency=IdempotencySpec(mode="NONE"),
            preconditions=(),
            operations=tuple(operations),
            semantic_events=(),
            metadata={"adapter": "RewardPlan", "pass": "69.0"},
        )

    def apply(self, plan: RewardPlan) -> RewardResult:
        if not self.uow.active:
            raise RewardValidationError("reward mutation requires an active request UnitOfWork")
        self.validate(plan)

        mutation_plan = self._mutation_plan(plan)
        draft: SettlementDraft | None = self.settlement.apply(mutation_plan) if mutation_plan is not None else None
        economy_projection = dict(draft.projection.economy) if draft is not None else {}
        inventory_awards = list(draft.projection.inventory_awards) if draft is not None else []

        # Non-scalar progression owner remains in the same outer PlayerUoW.
        player_exp_gain = sum(int(g.amount) for g in plan.economy if g.field == "player_exp")
        if player_exp_gain:
            progression_projection = self.progression.grant_exp(
                player_exp_gain,
                persist=False,
            )
            economy_projection.update(progression_projection)

        partner_rows: list[dict[str, Any]] = []
        for grant in plan.partners:
            row = self.catalog.get(grant.content)
            partner_rows.append(
                self.heroes.add_owned_hero(
                    {"table_id": grant.content.table_id, "star": int(row.get("star", 0) or 0)},
                    persist=False,
                )
            )

        return RewardResult(
            economy=economy_projection,
            inventory_awards=inventory_awards,
            partners=partner_rows,
            mutation_plan_id=draft.plan_id if draft is not None else None,
            mutation_journal=tuple(entry.as_dict() for entry in draft.journal) if draft is not None else (),
        )
