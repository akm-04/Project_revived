"""Typed settlement for scalar resources, Backpack stacks, temporal pools, and Pass72 entities."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from gxb_backend.content import CatalogNamespace, ContentRef, GameDataCatalog

from .economy_ledger import EconomyLedger
from .mutation_plan import (
    EntityMutation,
    JournalEntry,
    MutationPlan,
    Precondition,
    ResourceMutation,
    StackMutation,
    TemporalTransition,
)
from .stack_inventory import StackInventory
from .temporal_policy_service import TemporalPolicyError, TemporalPolicyService
from .unit_of_work import PlayerUnitOfWork


class MutationSettlementError(ValueError):
    pass


class MutationPreconditionError(MutationSettlementError):
    pass


class UnsupportedMutationOperation(MutationSettlementError):
    pass


@dataclass(frozen=True)
class SettlementProjection:
    economy: dict[str, int]
    inventory_awards: list[dict[str, int]]


@dataclass(frozen=True)
class SettlementDraft:
    """Pre-commit settlement data held inside the active PlayerUnitOfWork.

    The frozen MutationResult contract is reserved for committed/replayed/no-op
    outcomes. Pass69 therefore refuses to label pre-commit data COMMITTED.
    Pass70 consumes the post-durability UoW journal for response projection; the
    in-transaction draft remains explicitly non-committed planning data.
    """
    plan_id: str
    actor_player_id: str
    state_version_before: int
    journal: tuple[JournalEntry, ...]
    projection: SettlementProjection


class MutationSettlementService:
    """Apply the currently implemented MutationPlan leaf families inside UoW.

    The service deliberately requires an already-active PlayerUnitOfWork.  It
    does not create a hidden transaction boundary and therefore cannot split a
    domain command into multiple durable commits.
    """

    def __init__(
        self,
        *,
        catalog: GameDataCatalog,
        ledger: EconomyLedger,
        stacks: StackInventory,
        uow: PlayerUnitOfWork,
        temporal: TemporalPolicyService | None = None,
    ) -> None:
        self.catalog = catalog
        self.ledger = ledger
        self.stacks = stacks
        self.uow = uow
        self.temporal = temporal
        self._entity_owners: dict[str, Any] = {}

    def register_entity_owner(self, entity_type: str, owner: Any) -> None:
        """Register a typed aggregate owner for the frozen ENTITY family."""
        key = str(entity_type or "").strip().upper()
        if not key:
            raise MutationSettlementError("ENTITY owner key must be non-empty")
        if not hasattr(owner, "validate") or not hasattr(owner, "apply"):
            raise MutationSettlementError(f"ENTITY owner {key} lacks validate/apply")
        self._entity_owners[key] = owner

    def _entity_owner(self, entity_type: str) -> Any:
        key = str(entity_type or "").strip().upper()
        owner = self._entity_owners.get(key)
        if owner is None:
            raise UnsupportedMutationOperation(f"ENTITY owner is unavailable for {key or '<empty>'}")
        return owner

    @staticmethod
    def _positive(value: Any, label: str) -> int:
        try:
            amount = int(value)
        except (TypeError, ValueError) as exc:
            raise MutationSettlementError(f"{label} must be an integer") from exc
        if amount <= 0:
            raise MutationSettlementError(f"{label} must be positive")
        return amount

    def _validate_stack_catalog(self, item_id: int, *, action: str) -> None:
        row = self.catalog.maybe_get(ContentRef(CatalogNamespace.ITEM, int(item_id)))
        if row is None:
            # Debit-only operations may act on an already-persisted Backpack
            # stack whose full item row is absent from the compact runtime
            # GameDataCatalog.  The owning domain must still validate semantics
            # from its own source-derived catalog (MID82/MID86 uses
            # ItemSaleCatalog). Unknown CREDIT remains fail-closed.
            if str(action).upper() == "DEBIT" and self.stacks.quantity(item_id) > 0:
                return
            raise MutationSettlementError(f"unknown Backpack item {item_id}")
        item_type = int(row.get("type", 0) or 0)
        if item_type == -1:
            raise MutationSettlementError(f"item {item_id} is display-only, not a Backpack stack")
        if item_type == 3 and int(row.get("partner_id", 0) or 0) <= 0:
            raise MutationSettlementError(f"partner-scroll item {item_id} lacks partner_id")

    def validate(self, plan: MutationPlan) -> MutationPlan:
        if int(plan.schema_version) != 1:
            raise MutationSettlementError(f"unsupported MutationPlan schema {plan.schema_version}")
        if str(plan.actor.player_id) != str(self.uow.player.player_id):
            raise MutationSettlementError("MutationPlan actor does not match bound PlayerUnitOfWork")
        if plan.expected_state_version is not None and int(plan.expected_state_version) != self.uow.current_state_version:
            raise MutationPreconditionError(
                f"MutationPlan expected state_version={plan.expected_state_version}, actual={self.uow.current_state_version}"
            )
        if not self.uow.active:
            raise MutationSettlementError("MutationPlan settlement requires active PlayerUnitOfWork")

        resource_deltas: dict[str, int] = {}
        stack_deltas: dict[int, int] = {}
        for op in plan.operations:
            if isinstance(op, ResourceMutation):
                amount = self._positive(op.amount, f"resource {op.resource_key} amount")
                action = str(op.action).upper()
                if action not in {"CREDIT", "DEBIT"}:
                    raise UnsupportedMutationOperation(f"unsupported RESOURCE action {op.action!r}")
                delta = amount if action == "CREDIT" else -amount
                resource_deltas[op.resource_key] = resource_deltas.get(op.resource_key, 0) + delta
            elif isinstance(op, StackMutation):
                item_id = int(op.item_id)
                if item_id <= 0:
                    raise MutationSettlementError("STACK item_id must be positive")
                amount = self._positive(op.amount, f"stack {item_id} amount")
                action = str(op.action).upper()
                if action not in {"CREDIT", "DEBIT"}:
                    raise UnsupportedMutationOperation(f"unsupported STACK action {op.action!r}")
                self._validate_stack_catalog(item_id, action=action)
                delta = amount if action == "CREDIT" else -amount
                stack_deltas[item_id] = stack_deltas.get(item_id, 0) + delta
            elif isinstance(op, TemporalTransition):
                if self.temporal is None:
                    raise UnsupportedMutationOperation("TEMPORAL settlement service is unavailable")
                action = str(op.action).upper()
                amount = int(op.amount or 0)
                try:
                    # Side-effect-free source-policy validation. Multiple operations
                    # for one temporal key are uncommon in the current migration;
                    # the active UoW still guarantees rollback if a later apply fails.
                    self.temporal.preview(str(op.resource_key), action, amount)
                except TemporalPolicyError as exc:
                    raise MutationPreconditionError(str(exc)) from exc
            elif isinstance(op, EntityMutation):
                owner = self._entity_owner(str(op.entity_type))
                try:
                    owner.validate(op)
                except Exception as exc:
                    raise MutationPreconditionError(str(exc)) from exc
            else:
                raise UnsupportedMutationOperation(f"operation family not implemented in current settlement: {type(op).__name__}")

        # Full preflight before leaf mutation so multi-owner plans cannot partially
        # spend and then fail on the second owner.
        try:
            self.ledger.validate_deltas(resource_deltas)
            self.stacks.validate_deltas(stack_deltas)
        except Exception as exc:
            # Normalize leaf-owner balance/quantity failures into the public
            # settlement error family so domain handlers fail closed instead of
            # leaking owner-specific ValueErrors as HTTP 5xx responses.
            raise MutationPreconditionError(str(exc)) from exc
        self._validate_preconditions(plan.preconditions)
        return plan

    def _validate_preconditions(self, rows: tuple[Precondition, ...]) -> None:
        for row in rows:
            kind = str(row.kind).upper()
            subject = dict(row.subject)
            if kind == "RESOURCE_AT_LEAST":
                key = str(subject.get("resource_key") or subject.get("key") or "")
                amount = self._positive(row.amount, f"precondition resource {key}")
                if self.ledger.balance(key) < amount:
                    raise MutationPreconditionError(f"resource precondition failed: {key} < {amount}")
            elif kind == "STACK_AT_LEAST":
                item_id = int(subject.get("item_id", 0) or 0)
                amount = self._positive(row.amount, f"precondition stack {item_id}")
                if self.stacks.quantity(item_id) < amount:
                    raise MutationPreconditionError(f"stack precondition failed: {item_id} < {amount}")
            elif kind == "EXPECTED_VERSION":
                expected = int(row.expected)
                if expected != self.uow.current_state_version:
                    raise MutationPreconditionError(
                        f"version precondition failed: expected={expected} actual={self.uow.current_state_version}"
                    )
            else:
                # Other frozen preconditions belong to later domain owners.  A
                # caller may not smuggle them through this partial implementation.
                raise UnsupportedMutationOperation(f"precondition not implemented in current settlement: {row.kind}")

    def apply(self, plan: MutationPlan) -> SettlementDraft:
        self.validate(plan)
        version_before = self.uow.current_state_version
        journal: list[JournalEntry] = []
        economy_projection: dict[str, int] = {}
        inventory_awards: list[dict[str, int]] = []

        resource_deltas: dict[str, int] = {}
        stack_deltas: dict[int, int] = {}
        for op in plan.operations:
            if isinstance(op, ResourceMutation):
                amount = int(op.amount)
                delta = amount if str(op.action).upper() == "CREDIT" else -amount
                resource_deltas[op.resource_key] = resource_deltas.get(op.resource_key, 0) + delta
            elif isinstance(op, StackMutation):
                amount = int(op.amount)
                delta = amount if str(op.action).upper() == "CREDIT" else -amount
                stack_deltas[int(op.item_id)] = stack_deltas.get(int(op.item_id), 0) + delta

        resource_records = self.ledger.apply_deltas(resource_deltas, persist=False) if resource_deltas else ()
        stack_records = self.stacks.apply_deltas(stack_deltas, persist=False) if stack_deltas else ()
        temporal_records = []
        if self.temporal is not None:
            for op in plan.operations:
                if isinstance(op, TemporalTransition):
                    temporal_records.append((op, self.temporal.apply_transition(
                        str(op.resource_key), str(op.action), int(op.amount or 0),
                        persist=False, publish=False,
                        origin_ref=f"{plan.origin.domain}:{plan.origin.operation}",
                        stage_journal=False,
                    )))

        entity_records = []
        for op in plan.operations:
            if isinstance(op, EntityMutation):
                owner = self._entity_owner(str(op.entity_type))
                try:
                    entity_records.append((op, owner, owner.apply(op)))
                except Exception as exc:
                    # The outer PlayerUnitOfWork restores already-applied RESOURCE,
                    # STACK, TEMPORAL and ENTITY state on this exception.
                    raise MutationSettlementError(str(exc)) from exc

        seq = 0
        origin_ref = f"{plan.origin.domain}:{plan.origin.operation}"
        for record in resource_records:
            seq += 1
            economy_projection[record.key] = record.after
            journal.append(JournalEntry(
                seq=seq,
                owner="EconomyLedger",
                category="RESOURCE",
                subject={"resource_key": record.key},
                action="CREDIT" if record.delta > 0 else "DEBIT",
                before=record.before,
                after=record.after,
                delta=record.delta,
                projection_tags=("economy_",),
                origin_ref=origin_ref,
            ))
        for record in stack_records:
            seq += 1
            if record.delta > 0:
                inventory_awards.append({"item_id": record.item_id, "item_num": record.delta})
            journal.append(JournalEntry(
                seq=seq,
                owner="StackInventory",
                category="STACK",
                subject={"item_id": record.item_id},
                action="CREDIT" if record.delta > 0 else "DEBIT",
                before=record.before,
                after=record.after,
                delta=record.delta,
                projection_tags=("awards",) if record.delta > 0 else (),
                origin_ref=origin_ref,
            ))
        for op, change in temporal_records:
            if not change.changed:
                continue
            seq += 1
            if bool(op.publish) and self.temporal is not None and self.temporal.projection_allowed(change.resource_key):
                economy_projection[change.resource_key] = change.after.balance
                tags = ("economy_",)
            else:
                tags = ()
            journal.append(JournalEntry(
                seq=seq,
                owner="TemporalPolicyService",
                category="TEMPORAL",
                subject={"resource_key": change.resource_key},
                action=change.action,
                before=change.before.summary(),
                after=change.after.summary(),
                delta=change.delta,
                projection_tags=tags,
                origin_ref=origin_ref,
            ))

        for op, owner, change in entity_records:
            seq += 1
            journal.append(JournalEntry(
                seq=seq,
                owner=type(owner).__name__,
                category="ENTITY",
                subject={"entity_type": str(op.entity_type).upper(), "entity_id": int(op.entity_id)},
                action=str(change.action),
                before=change.before,
                after=change.after,
                delta=change.delta,
                # Hero callbacks already reconcile star/color/skills/equipment
                # locally or consume explicit response fields. Do not synthesize
                # a generic entity response channel and double-apply client state.
                projection_tags=(),
                origin_ref=origin_ref,
            ))

        for event in plan.semantic_events:
            self.uow.stage_semantic(event.channel, event.value)
        for entry in journal:
            self.uow.stage_journal(entry.as_dict())
        if economy_projection:
            # The Pass68 semantic bus remains a compatibility bridge for legacy
            # request code. Pass70's ResponseProjector consumes the committed
            # UoW journal afterwards, and journal values win on collision.
            self.uow.stage_semantic("economy_", economy_projection)

        projection = SettlementProjection(economy_projection, inventory_awards)
        return SettlementDraft(
            plan_id=plan.plan_id,
            actor_player_id=str(plan.actor.player_id),
            state_version_before=version_before,
            journal=tuple(journal),
            projection=projection,
        )
