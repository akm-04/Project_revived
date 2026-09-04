"""KongMing permanent Awakening skill switch owner (Pass210 Stage E).

Effective src_64 uses MID2144 from SkillTipsWindow with {partner_id,
skill_index, skill_item}.  The corresponding Book-V item is an ownership gate;
the client does not consume it on successful switching.  HeroRepository remains
the canonical persistence owner through the typed HERO entity mutation seam.
"""
from __future__ import annotations

from typing import Any

from .hero_repository import HeroRepository
from .inventory_repository import InventoryRepository
from .mutation_plan import ActorRef, EntityMutation, IdempotencySpec, MutationOrigin, MutationPlan
from .mutation_settlement_service import MutationSettlementError, MutationSettlementService
from .player_state import PlayerState
from .unit_of_work import OperationContext, UnitOfWork


class KongMingAwakeSkillService:
    MID = 2144
    BASE_TABLE_ID = 10001144
    AWAKEN_TABLE_ID = 11001144
    AWAKE_SKILL_INDEX = 5
    # SOURCE_FACT: all five mappings exist in the recovered skill/book/battle
    # corpus.  Effective partner1.lua currently exposes only Wind/Dark/Water in
    # the stock slot-5 picker; Fire/Thunder remain valid raw skill/book mappings
    # and historical/persisted values, so the server preserves all five.
    SKILL_BY_BOOK = {
        50000005: 60010144,  # Wind Book V
        50000010: 60020144,  # Dark Book V
        50000015: 60030144,  # Water Book V
        50000020: 60040144,  # Fire Book V
        50000025: 60050144,  # Thunder Book V
    }

    def __init__(
        self,
        player: PlayerState,
        heroes: HeroRepository,
        inventory: InventoryRepository,
        settlement: MutationSettlementService,
        uow: UnitOfWork,
    ) -> None:
        self.player = player
        self.heroes = heroes
        self.inventory = inventory
        self.settlement = settlement
        self.uow = uow

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    @classmethod
    def ownership_books(cls) -> tuple[int, ...]:
        return tuple(cls.SKILL_BY_BOOK)

    def change(self, req: dict[str, Any]) -> dict[str, Any]:
        partner_id = self._int(req.get("partner_id"), 0)
        skill_index = self._int(req.get("skill_index"), 0)
        book_id = self._int(req.get("skill_item"), 0)
        skill_id = self.SKILL_BY_BOOK.get(book_id, 0)
        hero = self.heroes.get(partner_id)
        if not isinstance(hero, dict):
            return {"error_code": 1, "msg": "kongming_hero_not_owned"}
        # Stock UI cannot enter this path until KongMing's Awake slot is active.
        # Requiring the durable awakened identity prevents a crafted MID2144
        # request from enabling the switch before final ordinary Awakening.
        if self._int(hero.get("table_id"), 0) != self.AWAKEN_TABLE_ID:
            return {"error_code": 1, "msg": "kongming_not_awakened"}
        if skill_index != self.AWAKE_SKILL_INDEX:
            return {"error_code": 1, "msg": "kongming_skill_slot_mismatch"}
        if skill_id <= 0:
            return {"error_code": 1, "msg": "kongming_skill_book_invalid"}
        if self.inventory.get_item_num(book_id) <= 0:
            return {"error_code": 1, "msg": "kongming_skill_book_not_owned"}

        def mutate() -> dict[str, Any]:
            self.settlement.apply(MutationPlan(
                schema_version=1,
                plan_id=f"kongming:skill:{partner_id}:{skill_index}:{skill_id}:{self.uow.current_state_version}",
                origin=MutationOrigin(
                    domain="kongming_awake_skill", operation="change", protocol_mid=self.MID,
                    source_table="skill/item", source_id=skill_id,
                ),
                actor=ActorRef(player_id=str(self.player.player_id)),
                expected_state_version=None,
                idempotency=IdempotencySpec(),
                preconditions=(),
                operations=(EntityMutation(
                    "HERO", partner_id, "SET_SKILL_ID_AT_INDEX",
                    amount=skill_id, indices=(skill_index,),
                ),),
            ))
            current = self.heroes.get(partner_id) or {}
            raw = current.get("skill_ids")
            values = list(raw) if isinstance(raw, (list, tuple)) else []
            out = [self._int(v, 0) for v in values[:6]]
            while len(out) < 6:
                out.append(0)
            return {"skill_ids": out}

        ctx = OperationContext(
            actor_player_id=str(self.player.player_id),
            domain="kongming_awake_skill",
            operation_name="change",
            protocol_mid=self.MID,
        )
        try:
            with self.uow.transaction(ctx):
                return mutate()
        except MutationSettlementError:
            return {"error_code": 1}
