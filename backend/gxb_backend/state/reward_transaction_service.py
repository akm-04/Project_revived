"""Typed reward transaction coordinator for source-confirmed rewards."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from gxb_backend.content import CatalogNamespace, ContentRef, GameDataCatalog

from .economy_repository import EconomyRepository
from .hero_repository import HeroRepository
from .inventory_repository import InventoryRepository
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


class RewardTransactionService:
    """Resolve typed content, then delegate mutation to canonical owners."""

    ECONOMY_FIELDS = {"mana", "crystal", "energy", "player_exp"}

    def __init__(
        self,
        catalog: GameDataCatalog,
        economy: EconomyRepository,
        inventory: InventoryRepository,
        heroes: HeroRepository,
        uow: UnitOfWork,
    ) -> None:
        self.catalog = catalog
        self.economy = economy
        self.inventory = inventory
        self.heroes = heroes
        self.uow = uow

    @staticmethod
    def _positive(value: Any, label: str) -> int:
        try:
            amount = int(value)
        except (TypeError, ValueError) as exc:
            raise RewardValidationError(f"{label} must be an integer") from exc
        if amount <= 0:
            raise RewardValidationError(f"{label} must be positive")
        return amount

    def validate(self, plan: RewardPlan) -> RewardPlan:
        for grant in plan.economy:
            if grant.field not in self.ECONOMY_FIELDS:
                raise RewardValidationError(f"unsupported economy reward field {grant.field!r}")
            self._positive(grant.amount, f"economy.{grant.field}")
        for grant in plan.inventory:
            self._positive(grant.amount, "inventory amount")
            if CatalogNamespace(grant.content.namespace) is not CatalogNamespace.ITEM:
                raise RewardValidationError("InventoryGrant must use the item namespace")
            row = self.catalog.get(grant.content)
            # Pass32 proves item.lua also contains non-stack display rows. A
            # typed InventoryGrant is the domain adapter's ownership assertion,
            # but known type=-1 display-only rows are still rejected here.
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

    def apply(self, plan: RewardPlan) -> RewardResult:
        if not self.uow.active:
            raise RewardValidationError("reward mutation requires an active request UnitOfWork")
        self.validate(plan)
        deltas = {"mana_delta": 0, "crystal_delta": 0, "energy_delta": 0, "player_exp_gain": 0}
        for grant in plan.economy:
            amount = int(grant.amount)
            if grant.field == "mana":
                deltas["mana_delta"] += amount
            elif grant.field == "crystal":
                deltas["crystal_delta"] += amount
            elif grant.field == "energy":
                deltas["energy_delta"] += amount
            elif grant.field == "player_exp":
                deltas["player_exp_gain"] += amount

        economy_projection = self.economy.apply_deltas(persist=False, **deltas) if any(deltas.values()) else {}
        item_rows = [
            {"item_id": grant.content.table_id, "item_num": int(grant.amount)}
            for grant in plan.inventory
        ]
        inventory_awards = self.inventory.add_items(item_rows, persist=False) if item_rows else []

        partner_rows: list[dict[str, Any]] = []
        for grant in plan.partners:
            row = self.catalog.get(grant.content)
            partner_rows.append(
                self.heroes.add_owned_hero(
                    {"table_id": grant.content.table_id, "star": int(row.get("star", 0) or 0)},
                    persist=False,
                )
            )
        return RewardResult(economy_projection, inventory_awards, partner_rows)
