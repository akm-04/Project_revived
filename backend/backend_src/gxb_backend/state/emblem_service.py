"""Cohesive Emblem/Inscription protocol owner.

Pass241 I0 installed the source/policy/state/RNG foundation. Pass242 I1 moved
deterministic public MIDs 1402/1403/1404/1407 here; Pass243 I2 added
eligibility/Heart integration. Pass244 I3 activates internal RNG/pending-
proposal planning. Pass246 I4 opened MID1400 Forge using authoritative cost preflight before
entropy. Pass247 I5 opened the stock Reforge proposal/save/abandon lifecycle; Pass248 I6 hardens the integrated operational/state/runtime boundaries
(MID1401/1405/1406) on the Pass244 frozen latest-proposal machinery.
"""
from __future__ import annotations

from typing import Any

from gxb_backend.content.emblem_source_catalog import EmblemSourceCatalog

from .emblem_outcome_planner import EmblemOutcomePlanner
from .emblem_policy import EmblemPolicyRegistry
from .emblem_state_repository import EmblemStateRepository
from .emblem_eligibility_coordinator import EmblemEligibilityCoordinator
from .hero_repository import HeroRepository
from .inventory_repository import InventoryRepository
from .mutation_plan import (
    ActorRef,
    EntityMutation,
    IdempotencySpec,
    MutationOrigin,
    MutationPlan,
    Precondition,
    ResourceMutation,
    StackMutation,
)
from .mutation_settlement_service import MutationSettlementError, MutationSettlementService
from .player_state import PlayerState
from .unit_of_work import OperationContext, UnitOfWork


class EmblemService:
    UNRESOLVED_MESSAGE = "advanced_progression_server_algorithm_unresolved"
    _RESOURCE_BY_SOURCE_ID = {
        19: "degree_cer",
        20: "graduate_cer",
        21: "patent_cer",
    }

    def __init__(
        self,
        player: PlayerState,
        source: EmblemSourceCatalog,
        policy: EmblemPolicyRegistry,
        outcomes: EmblemOutcomePlanner,
        state: EmblemStateRepository,
        eligibility: EmblemEligibilityCoordinator,
        *,
        inventory: InventoryRepository,
        heroes: HeroRepository,
        settlement: MutationSettlementService,
        uow: UnitOfWork,
    ) -> None:
        self.player = player
        self.source = source
        self.policy = policy
        self.outcomes = outcomes
        self.state = state
        self.eligibility = eligibility
        self.inventory = inventory
        self.heroes = heroes
        self.settlement = settlement
        self.uow = uow

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    @classmethod
    def fail_closed(cls, req: dict[str, Any] | None = None) -> dict[str, Any]:
        return {"error_code": 1, "msg": cls.UNRESOLVED_MESSAGE}

    def _apply(
        self,
        *,
        mid: int,
        operation: str,
        partner_id: int,
        operations: tuple[Any, ...],
    ) -> bool:
        ctx = OperationContext(
            actor_player_id=str(self.player.player_id),
            domain="emblem",
            operation_name=operation,
            protocol_mid=mid,
        )
        try:
            with self.uow.transaction(ctx):
                self.settlement.apply(
                    MutationPlan(
                        schema_version=1,
                        plan_id=(
                            f"emblem:{mid}:{partner_id}:{operation}:"
                            f"{self.uow.current_state_version}"
                        ),
                        origin=MutationOrigin(
                            domain="emblem",
                            operation=operation,
                            protocol_mid=mid,
                        ),
                        actor=ActorRef(player_id=str(self.player.player_id)),
                        expected_state_version=None,
                        idempotency=IdempotencySpec(),
                        preconditions=(),
                        operations=operations,
                    )
                )
            return True
        except MutationSettlementError:
            return False

    def _inscription_response(self, hero: dict[str, Any]) -> list[int]:
        raw = hero.get("inscript_items") or []
        if isinstance(raw, (list, tuple)):
            return [self._int(value) for value in raw if self._int(value) > 0]
        if isinstance(raw, dict):
            # Compatibility migration for hand-edited/older state. The stock
            # client expects a dense concrete-item array, not a position map.
            return [
                self._int(value)
                for _, value in sorted(
                    raw.items(), key=lambda kv: self._int(kv[0])
                )
                if self._int(value) > 0
            ]
        return []

    def _equipped_for_position(self, hero: dict[str, Any], position: int) -> int:
        for item_id in self._inscription_response(hero):
            if self.source.physical_position(item_id) == position:
                return item_id
        return 0

    def _equipped_layout_valid(self, hero: dict[str, Any]) -> bool:
        """Validate the stock dense three-position Emblem equipment invariant.

        Do not destructively repair unknown/duplicate-position legacy equipment
        here: insertion fails closed while MID1403 removal remains available as a
        recovery path. HeroRepository separately normalizes the wire container to
        a dense integer list without inventing source ownership.
        """
        items = self._inscription_response(hero)
        if len(items) > 3:
            return False
        positions: set[int] = set()
        for item_id in items:
            position = self.source.physical_position(item_id)
            if position not in (1, 2, 3) or position in positions:
                return False
            positions.add(position)
        return True

    def runtime_audit_snapshot(self) -> dict[str, Any]:
        """Safe aggregate state for I7 runtime logging; never changes wire state."""
        raw = self.player.emblem_state if isinstance(self.player.emblem_state, dict) else {}
        rng = raw.get("scholarship_rng") if isinstance(raw.get("scholarship_rng"), dict) else {}
        pending = raw.get("pending_rebuild") if isinstance(raw.get("pending_rebuild"), dict) else None
        def misses(lane: str) -> int:
            row = rng.get(lane) if isinstance(rng.get(lane), dict) else {}
            return max(0, self._int(row.get("misses_since_special"), 0))
        return {
            "policy_version": self.policy.version,
            "state_policy_version": str(raw.get("policy_version") or ""),
            "proposal_generation": max(0, self._int(raw.get("proposal_generation"), 0)),
            "pending_generation": max(0, self._int((pending or {}).get("generation"), 0)),
            "pending_candidate_count": len((pending or {}).get("candidates") or ()),
            "forge_misses_since_special": misses("forge"),
            "reforge_misses_since_special": misses("reforge"),
        }

    # ------------------------------------------------------------------
    # Pass244 I3 internal RNG/proposal foundation. These helpers are not wire
    # handlers. I4/I5 may call them only after authoritative protocol/cost
    # preflight inside the same active PlayerUnitOfWork transaction.
    # ------------------------------------------------------------------
    def _plan_generated_candidate_internal(
        self,
        *,
        lane: str,
        inscription_id: int,
        source_item_id: int = 0,
    ):
        if self.uow is None or not self.uow.active:
            raise RuntimeError("Emblem RNG planning requires active PlayerUnitOfWork")
        misses = self.state.misses_since_special(lane)
        draw = self.outcomes.generated_candidate(
            inscription_id,
            lane=lane,
            misses_since_special=misses,
            source_item_id=source_item_id,
        )
        if draw.gate is not None:
            self.state.apply_scholarship_result(
                lane,
                misses_before=draw.gate.misses_before,
                hit=draw.gate.hit,
            )
        return draw

    def _stage_rebuild_proposal_internal(
        self,
        *,
        source_item_id: int,
        rebuild_num: int,
        cost_type: int,
    ) -> dict[str, Any]:
        """Generate and persist one latest-wins proposal after caller preflight.

        This intentionally performs no Mana/diamond debit in I3; the public
        MID1401 route remains fenced until I5. The helper exists so I5 can add
        authoritative cost settlement *before* invoking the exact same frozen
        candidate/proposal machinery.
        """

        if self.uow is None or not self.uow.active:
            raise RuntimeError("Emblem proposal staging requires active PlayerUnitOfWork")
        source_item_id = self._int(source_item_id)
        rebuild_num = self._int(rebuild_num)
        cost_type = self._int(cost_type)
        if rebuild_num not in {1, 10} or cost_type not in {1, 2}:
            raise ValueError("invalid Emblem rebuild proposal shape")
        item = self.source.concrete_item(source_item_id)
        if item is None:
            raise ValueError("unknown Emblem rebuild source item")
        source_inscription_id = self._int(item.get("inscription_id"))
        row = self.source.inscription(source_inscription_id)
        if row is None or self._int(row.get("special")) != 0:
            raise ValueError("Scholarship medals cannot be reforged")

        candidates: list[int] = []
        for _ in range(rebuild_num):
            draw = self._plan_generated_candidate_internal(
                lane="reforge",
                inscription_id=source_inscription_id,
                source_item_id=source_item_id,
            )
            candidates.append(int(draw.item_id))
        return self.state.replace_pending(
            {
                "source_item_id": source_item_id,
                "source_inscription_id": source_inscription_id,
                "rebuild_num": rebuild_num,
                "cost_type": cost_type,
                "candidates": candidates,
                "policy_version": self.policy.version,
            }
        )

    # ------------------------------------------------------------------
    # Pass246 I4: MID1400 Forge only. Cost validation is deliberately split
    # into a side-effect-free canonical settlement preflight that runs before
    # EmblemOutcomePlanner consumes entropy or mutates the durable Forge pity
    # counter. The final cost + generated-medal plan is then settled inside the
    # same PlayerUnitOfWork transaction. No receipt/nonce is staged: stock
    # MID1400 has no nonce, so an accepted repeat is another paid forge.
    # ------------------------------------------------------------------
    def _make_cost_operations(self, row: Any) -> tuple[Any, ...]:
        resource_id = self._int(row.get("compound_material"))
        resource_key = self._RESOURCE_BY_SOURCE_ID.get(resource_id)
        certificate_cost = self._int(row.get("compound_num"))
        level = self._int(row.get("level"))
        compound_item = self._int(row.get("compound_item"))
        compound_item_num = self._int(row.get("compound_item_num"))
        if resource_key is None or certificate_cost <= 0:
            raise ValueError("invalid Emblem Forge certificate cost")
        if level == self._int(self.source.rules.get("scholarship_level"), 7):
            if compound_item != self.source.HEART_ITEM or compound_item_num != 1:
                raise ValueError("invalid Lv7 Emblem Heart cost")
        elif compound_item != 0 or compound_item_num != 0:
            raise ValueError("unexpected non-Lv7 Emblem compound item cost")

        operations: list[Any] = [
            ResourceMutation(resource_key, "DEBIT", certificate_cost)
        ]
        if compound_item_num > 0:
            operations.append(StackMutation(compound_item, "DEBIT", compound_item_num))
        return tuple(operations)

    def _make_plan(
        self,
        *,
        operations: tuple[Any, ...],
        suffix: str,
    ) -> MutationPlan:
        return MutationPlan(
            schema_version=1,
            plan_id=(
                f"emblem:1400:0:inscription_make:{suffix}:"
                f"{self.uow.current_state_version}"
            ),
            origin=MutationOrigin(
                domain="emblem",
                operation="inscription_make",
                protocol_mid=1400,
            ),
            actor=ActorRef(player_id=str(self.player.player_id)),
            expected_state_version=None,
            idempotency=IdempotencySpec(),
            preconditions=(),
            operations=operations,
        )

    def make(self, req: dict[str, Any]) -> dict[str, Any]:
        if not isinstance(req, dict):
            return {"error_code": 1}
        # Pass248 I6: Forge/Reforge are operational only while the account owns
        # at least one canonical Blood-stage-3, level-100 Hero. Function45 is
        # explicitly not authorization. Gate before catalog/cost/RNG/state work.
        if not self.eligibility.operationally_enabled():
            return {"error_code": 1}
        inscription_id = self._int(req.get("inscript_id"))
        make_num = self._int(req.get("make_num"))
        row = self.source.inscription(inscription_id)
        if (
            make_num != 1
            or row is None
            or self._int(row.get("special")) != 0
            or self._int(row.get("item_type")) not in (1, 2, 3)
            or self._int(row.get("level")) not in range(1, 8)
        ):
            return {"error_code": 1}

        try:
            cost_operations = self._make_cost_operations(row)
            ctx = OperationContext(
                actor_player_id=str(self.player.player_id),
                domain="emblem",
                operation_name="inscription_make",
                protocol_mid=1400,
            )
            with self.uow.transaction(ctx):
                # I4 invariant: this complete scalar/Heart preflight is the last
                # operation before any Emblem entropy/pity mutation. validate()
                # is side-effect free and uses the canonical ledger/stack owners.
                self.settlement.validate(
                    self._make_plan(operations=cost_operations, suffix="preflight")
                )

                draw = self._plan_generated_candidate_internal(
                    lane="forge",
                    inscription_id=inscription_id,
                )
                generated_item_id = int(draw.item_id)
                self.settlement.apply(
                    self._make_plan(
                        operations=cost_operations
                        + (StackMutation(generated_item_id, "CREDIT", 1),),
                        suffix="settle",
                    )
                )
            # SOURCE_FACT: stock callback expects raw concrete IDs and builds
            # reward objects locally. Do not mirror this medal via generic
            # awards/extra_drops_ projection.
            return {"inscript_items": [generated_item_id]}
        except (MutationSettlementError, ValueError, RuntimeError):
            return {"error_code": 1}

    # ------------------------------------------------------------------
    # Pass247 I5: MID1401 proposal generation + MID1405 Save + MID1406
    # Abandon. Stock wire has no proposal token/nonce: every accepted MID1401
    # is a fresh paid proposal and atomically replaces the previous pending
    # proposal. The original medal is not debited until MID1405 Save.
    # ------------------------------------------------------------------
    def _rebuild_cost_operations(self, row: Any, *, rebuild_num: int, cost_type: int) -> tuple[Any, ...]:
        rebuild_num = self._int(rebuild_num)
        cost_type = self._int(cost_type)
        if rebuild_num not in {1, 10} or cost_type not in {1, 2}:
            raise ValueError("invalid Emblem rebuild cost shape")
        if cost_type == 1:
            resource_key = "crystal"
            unit_cost = self._int(row.get("change_crystal"))
        else:
            resource_key = "mana"
            unit_cost = self._int(row.get("change_gold"))
        if unit_cost <= 0:
            raise ValueError("invalid Emblem rebuild source cost")
        return (ResourceMutation(resource_key, "DEBIT", unit_cost * rebuild_num),)

    def _rebuild_plan(
        self,
        *,
        mid: int,
        operation: str,
        operations: tuple[Any, ...],
        preconditions: tuple[Precondition, ...] = (),
        suffix: str,
    ) -> MutationPlan:
        return MutationPlan(
            schema_version=1,
            plan_id=(
                f"emblem:{mid}:0:{operation}:{suffix}:"
                f"{self.uow.current_state_version}"
            ),
            origin=MutationOrigin(
                domain="emblem",
                operation=operation,
                protocol_mid=mid,
            ),
            actor=ActorRef(player_id=str(self.player.player_id)),
            expected_state_version=None,
            idempotency=IdempotencySpec(),
            preconditions=preconditions,
            operations=operations,
        )

    def rebuild(self, req: dict[str, Any]) -> dict[str, Any]:
        if not isinstance(req, dict):
            return {"error_code": 1}
        # Same global operational gate as Forge. Save/Abandon remain recovery
        # operations for already-paid proposals and therefore are not gated.
        if not self.eligibility.operationally_enabled():
            return {"error_code": 1}
        source_item_id = self._int(req.get("item_id"))
        rebuild_num = self._int(req.get("rebuild_num"))
        cost_type = self._int(req.get("cost_type"))
        if source_item_id <= 0 or rebuild_num not in {1, 10} or cost_type not in {1, 2}:
            return {"error_code": 1}

        item = self.source.concrete_item(source_item_id)
        if item is None or self.source.is_scholarship_item(source_item_id):
            return {"error_code": 1}
        source_inscription_id = self._int(item.get("inscription_id"))
        row = self.source.inscription(source_inscription_id)
        if row is None or self._int(row.get("special")) != 0:
            return {"error_code": 1}

        try:
            cost_operations = self._rebuild_cost_operations(
                row, rebuild_num=rebuild_num, cost_type=cost_type
            )
            source_owned = (
                Precondition(
                    kind="STACK_AT_LEAST",
                    subject={"item_id": source_item_id},
                    amount=1,
                ),
            )
            ctx = OperationContext(
                actor_player_id=str(self.player.player_id),
                domain="emblem",
                operation_name="inscription_rebuild",
                protocol_mid=1401,
            )
            with self.uow.transaction(ctx):
                # I5 invariant: complete source ownership + Mana/Crystal
                # affordability is validated before *any* Reforge entropy, pity
                # mutation or latest-proposal replacement. This is especially
                # authoritative for Crystal because current client source shows
                # the recharge alert branch does not return before MID1401.
                self.settlement.validate(
                    self._rebuild_plan(
                        mid=1401,
                        operation="inscription_rebuild",
                        operations=cost_operations,
                        preconditions=source_owned,
                        suffix="preflight",
                    )
                )
                pending = self._stage_rebuild_proposal_internal(
                    source_item_id=source_item_id,
                    rebuild_num=rebuild_num,
                    cost_type=cost_type,
                )
                self.settlement.apply(
                    self._rebuild_plan(
                        mid=1401,
                        operation="inscription_rebuild",
                        operations=cost_operations,
                        preconditions=source_owned,
                        suffix="settle",
                    )
                )
            return {"inscript_items": [int(v) for v in pending["candidates"]]}
        except (MutationSettlementError, ValueError, RuntimeError):
            return {"error_code": 1}

    def save_rebuild(self, req: dict[str, Any]) -> dict[str, Any]:
        if not isinstance(req, dict):
            return {"error_code": 1}
        selected_item_id = self._int(req.get("item_id"))
        if selected_item_id <= 0:
            return {"error_code": 1}
        pending = self.state.pending_rebuild()
        if pending is None:
            return {"error_code": 1}
        candidates = [self._int(v) for v in pending.get("candidates") or ()]
        if selected_item_id not in candidates:
            # Latest proposal is authoritative. Never accept a candidate from a
            # superseded/abandoned proposal merely because the item ID is valid.
            return {"error_code": 1}
        source_item_id = self._int(pending.get("source_item_id"))
        if source_item_id <= 0:
            return {"error_code": 1}

        # Compatibility policy sealed in Pass240: if the original source medal
        # disappeared after proposal generation, clear the stale pending record
        # and fail. Clearing is itself durable so reacquiring the same ID later
        # cannot resurrect an already-paid ancient proposal.
        if self.inventory.quantity(source_item_id) < 1:
            try:
                ctx = OperationContext(
                    actor_player_id=str(self.player.player_id),
                    domain="emblem",
                    operation_name="inscription_save_rebuild_stale_clear",
                    protocol_mid=1405,
                )
                with self.uow.transaction(ctx):
                    self.state.clear_pending()
            except (ValueError, RuntimeError):
                return {"error_code": 1}
            return {"error_code": 1}

        try:
            operations = (
                StackMutation(source_item_id, "DEBIT", 1),
                StackMutation(selected_item_id, "CREDIT", 1),
            )
            source_owned = (
                Precondition(
                    kind="STACK_AT_LEAST",
                    subject={"item_id": source_item_id},
                    amount=1,
                ),
            )
            ctx = OperationContext(
                actor_player_id=str(self.player.player_id),
                domain="emblem",
                operation_name="inscription_save_rebuild",
                protocol_mid=1405,
            )
            with self.uow.transaction(ctx):
                # Save is deterministic: commit one frozen candidate from the
                # latest persisted proposal. Never reroll or reinterpret it under
                # the current policy version.
                self.settlement.apply(
                    self._rebuild_plan(
                        mid=1405,
                        operation="inscription_save_rebuild",
                        operations=operations,
                        preconditions=source_owned,
                        suffix="settle",
                    )
                )
                self.state.clear_pending()
            # SOURCE_FACT: stock client removes the original locally and passes
            # rebuild_items to handleRewards(), which requires table_id/item_num.
            # Generic stack-credit projection remains disabled, preventing double
            # client application while server inventory is already authoritative.
            return {"rebuild_items": [{"table_id": selected_item_id, "item_num": 1}]}
        except (MutationSettlementError, ValueError, RuntimeError):
            return {"error_code": 1}

    def abandon_rebuild(self, req: dict[str, Any]) -> dict[str, Any]:
        if not isinstance(req, dict):
            return {"error_code": 1}
        if self.state.pending_rebuild() is None:
            # Stock request is empty and has no nonce. Compatibility policy makes
            # repeated abandonment a successful no-op. No refund is ever issued.
            return {}
        try:
            ctx = OperationContext(
                actor_player_id=str(self.player.player_id),
                domain="emblem",
                operation_name="inscription_abandon_rebuild",
                protocol_mid=1406,
            )
            with self.uow.transaction(ctx):
                self.state.clear_pending()
            return {}
        except (ValueError, RuntimeError):
            return {"error_code": 1}

    # ------------------------------------------------------------------
    # Pass242 I1 deterministic ownership reconciliation.
    # Pass243 I2 adds source-bounded per-Hero insert eligibility; removal,
    # dissolve and Star exchange intentionally remain recovery/economy paths.
    # ------------------------------------------------------------------
    def insert(self, req: dict[str, Any]) -> dict[str, Any]:
        if not isinstance(req, dict):
            return {"error_code": 1}
        partner_id = self._int(req.get("partner_id"))
        item_id = self._int(req.get("item_id"))
        replace_item_id = self._int(req.get("replace_item_id"))
        hero = self.heroes.get(partner_id)
        if hero is None:
            return {"error_code": 1}
        # Pass243 I2 SOURCE_FACT: both current NormalHero and SuperHero expose
        # Emblem only for Blood-Awakened Heroes at Function45 level (100).
        # Function45 announcement itself is not an authorization boundary.
        if not self.eligibility.hero_eligible(hero):
            return {"error_code": 1, "msg": "emblem_hero_not_eligible"}
        # I6 dense-layout hardening: never append into a malformed imported
        # layout. Removal remains available to unwind such state safely.
        if not self._equipped_layout_valid(hero):
            return {"error_code": 1}

        position = self.source.physical_position(item_id)
        if position not in (1, 2, 3):
            return {"error_code": 1}
        current = self._equipped_for_position(hero, position)
        if current > 0 and replace_item_id <= 0:
            return {"error_code": 1}
        if replace_item_id > 0 and current != replace_item_id:
            return {"error_code": 1}

        operations: list[Any] = [StackMutation(item_id, "DEBIT", 1)]
        if replace_item_id > 0:
            operations.extend(
                (
                    ResourceMutation(
                        "crystal", "DEBIT", self.source.remove_replace_crystal
                    ),
                    StackMutation(replace_item_id, "CREDIT", 1),
                )
            )
        operations.append(
            EntityMutation(
                "HERO",
                partner_id,
                "INSCRIPTION_INSERT",
                indices=(position, item_id, replace_item_id),
            )
        )
        if not self._apply(
            mid=1402,
            operation="inscription_insert",
            partner_id=partner_id,
            operations=tuple(operations),
        ):
            return {"error_code": 1}
        return {
            "inscript_items": self._inscription_response(
                self.heroes.get(partner_id) or hero
            )
        }

    def remove(self, req: dict[str, Any]) -> dict[str, Any]:
        if not isinstance(req, dict):
            return {"error_code": 1}
        partner_id = self._int(req.get("partner_id"))
        item_id = self._int(req.get("item_id"))
        hero = self.heroes.get(partner_id)
        if hero is None:
            return {"error_code": 1}
        position = self.source.physical_position(item_id)
        if position not in (1, 2, 3):
            return {"error_code": 1}
        if self._equipped_for_position(hero, position) != item_id:
            return {"error_code": 1}

        operations = (
            ResourceMutation("crystal", "DEBIT", self.source.remove_replace_crystal),
            StackMutation(item_id, "CREDIT", 1),
            EntityMutation(
                "HERO",
                partner_id,
                "INSCRIPTION_REMOVE",
                indices=(position, item_id),
            ),
        )
        if not self._apply(
            mid=1403,
            operation="inscription_remove",
            partner_id=partner_id,
            operations=operations,
        ):
            return {"error_code": 1}
        return {
            "inscript_items": self._inscription_response(
                self.heroes.get(partner_id) or hero
            )
        }

    def resolve(self, req: dict[str, Any]) -> dict[str, Any]:
        """MID1404 deterministic Emblem dissolve.

        The concrete medal determines its inscription row. Source material IDs
        19/20/21 are scalar Emblem certificate resources, never Backpack item
        IDs. The generic response projector publishes their cumulative economy_
        balances from the committed journal while the stock client removes the
        dissolved medals locally on OK.
        """
        if not isinstance(req, dict):
            return {"error_code": 1}
        item_id = self._int(req.get("item_id"))
        count = self._int(req.get("resolve_num"))
        item = self.source.concrete_item(item_id)
        if item is None or count <= 0:
            return {"error_code": 1}
        inscription = self.source.inscription(item.get("inscription_id"))
        if inscription is None:
            return {"error_code": 1}
        resource_id = self._int(inscription.get("resolve_material"))
        per_item = max(0, self._int(inscription.get("resolve_num")))
        resource_key = self._RESOURCE_BY_SOURCE_ID.get(resource_id)
        if resource_key is None or per_item <= 0:
            return {"error_code": 1}
        operations = (
            StackMutation(item_id, "DEBIT", count),
            ResourceMutation(resource_key, "CREDIT", per_item * count),
        )
        if not self._apply(
            mid=1404,
            operation="inscription_resolve",
            partner_id=0,
            operations=operations,
        ):
            return {"error_code": 1}
        return {}

    def exchange_materials(self, req: dict[str, Any]) -> dict[str, Any]:
        """MID1407 exchange all held physical Stars into scalar certificates."""
        if not isinstance(req, dict):
            return {"error_code": 1}
        operations: list[Any] = []
        changes: list[dict[str, int]] = []
        for row in self.source.exchange_materials:
            item_id = self._int(row.get("item_id"))
            resource_id = self._int(row.get("resource_id"))
            per_item = max(0, self._int(row.get("per_item")))
            resource_key = self._RESOURCE_BY_SOURCE_ID.get(resource_id)
            if item_id <= 0 or resource_key is None or per_item <= 0:
                return {"error_code": 1}
            count = max(0, self.inventory.get_item_num(item_id))
            if count <= 0:
                continue
            change = count * per_item
            operations.extend(
                (
                    StackMutation(item_id, "DEBIT", count),
                    ResourceMutation(resource_key, "CREDIT", change),
                )
            )
            changes.append({"currency": resource_id, "change": change})
        if not operations:
            return {"currency_change": []}
        if not self._apply(
            mid=1407,
            operation="inscription_exchange_materials",
            partner_id=0,
            operations=tuple(operations),
        ):
            return {"error_code": 1}
        return {"currency_change": changes}
