"""Stage-C atomic bridge between Hero equipment and Awakening mission state.

HeroEquipmentRepository remains the sole equipment authority. This coordinator
only authorizes the active stage-one source-special item, settles the planned
Hero/Inventory operations in the request UoW, and marks the mission complete in
the same durable transaction.
"""
from __future__ import annotations
from typing import Any

from .hero_equipment_repository import HeroEquipmentRepository
from .awakening_mission_service import AwakeningMissionService
from .mutation_plan import ActorRef, IdempotencySpec, MutationOrigin, MutationPlan
from .mutation_settlement_service import MutationSettlementError, MutationSettlementService
from .player_state import PlayerState
from .unit_of_work import OperationContext, UnitOfWork


class AwakeningEquipmentCoordinator:
    def __init__(self, player: PlayerState, *, equipment: HeroEquipmentRepository,
                 awakening: AwakeningMissionService, settlement: MutationSettlementService,
                 uow: UnitOfWork) -> None:
        self.player=player; self.equipment=equipment; self.awakening=awakening
        self.settlement=settlement; self.uow=uow

    @staticmethod
    def _int(value: Any, default: int=0) -> int:
        try: return int(value)
        except (TypeError,ValueError): return default

    def set_hero_equip(self, partner_id: Any, equip_index: Any) -> dict[str, Any] | None:
        """Handle only an active stage-one Awakening/Blood special equip.

        Return ``None`` when the request is not an Awakening-special operation so
        the normal HeroEquipmentRepository path can handle it.
        """
        pid=self._int(partner_id); index=self._int(equip_index)
        ctx=self.awakening.stage1_equipment_context(pid,index)
        if ctx is None: return None
        awake_type,rec,exclusive=ctx
        generation=self._int(rec.get("generation"),1); mission_id=self._int(rec.get("mission_id"))
        fp=f"{pid}:{index}"
        if bool(rec.get("complete")):
            replay=self.awakening.state.find_replay(awake_type=awake_type,generation=generation,
                mission_id=mission_id,operation="stage1_equip",request_fingerprint=fp)
            return replay if replay is not None else {"error_code":1,"msg":"awake_stage1_already_complete"}
        planned=self.equipment.plan_equip_operations(pid,index,authorized_special_item=exclusive,
            authorized_blood_lineage=(awake_type==self.awakening.HERO_TWICE))
        if planned is None: return {"error_code":1,"msg":"awake_special_equip_invalid"}
        _item_id,ops=planned
        opctx=OperationContext(actor_player_id=str(self.player.player_id),protocol_mid=54,
            domain="awakening_mission",operation_name="stage1_special_equip",
            idempotency_key=f"awake:{awake_type}:{generation}:equip:{index}")
        try:
            with self.uow.transaction(opctx):
                self.settlement.apply(MutationPlan(schema_version=1,
                    plan_id=f"awakening:stage1-equip:{awake_type}:{mission_id}:{generation}:{self.uow.current_state_version}",
                    origin=MutationOrigin(domain="awakening_mission",operation="stage1_special_equip",protocol_mid=54),
                    actor=ActorRef(player_id=str(self.player.player_id)),expected_state_version=None,
                    idempotency=IdempotencySpec(),preconditions=(),operations=ops))
                response=self.awakening.mark_stage1_equipped(awake_type=awake_type,generation=generation,
                    mission_id=mission_id,partner_id=pid,equip_index=index,request_fingerprint=fp)
            return response
        except MutationSettlementError:
            return {"error_code":1}
