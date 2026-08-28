"""Minimal Occult/Sorcery War dependency required by P2 Awakening (Pass211 Stage F)."""
from __future__ import annotations
from typing import Any
from gxb_backend.content.occult_source_catalog import OccultSourceCatalog
from .awakening_mission_service import AwakeningMissionService
from .mutation_plan import ActorRef,EntityMutation,IdempotencySpec,MutationOrigin,MutationPlan,StackMutation
from .mutation_settlement_service import MutationSettlementError,MutationSettlementService
from .occult_entity_mutation_service import OccultEntityMutationService
from .player_state import PlayerState
from .unit_of_work import OperationContext,PlayerUnitOfWork

class OccultServiceError(ValueError):pass

class OccultService:
    MID_GET_INFO=2362; MID_SWEEP=2385
    def __init__(self,player:PlayerState,source:OccultSourceCatalog,awakening:AwakeningMissionService,owner:OccultEntityMutationService,settlement:MutationSettlementService,uow:PlayerUnitOfWork)->None:
        self.player=player;self.source=source;self.awakening=awakening;self.owner=owner;self.settlement=settlement;self.uow=uow
    @staticmethod
    def _int(value:Any,default:int=0)->int:
        try:return int(value)
        except (TypeError,ValueError):return default
    def _context(self,mid:int,operation:str)->OperationContext:
        return OperationContext(actor_player_id=str(self.player.player_id),domain='occult',operation_name=operation,protocol_mid=mid,idempotency_mode='NONE')
    def _active_occult(self)->tuple[dict[str,Any],dict[str,Any]]|None:
        rec=self.awakening.active_snapshot(AwakeningMissionService.HERO)
        if not isinstance(rec,dict) or self._int(rec.get('stage'),0)!=1:return None
        mission_id=self._int(rec.get('mission_id'),0); route=self.source.awakening_route(mission_id)
        if route is None:return None
        return rec,dict(route)
    def _base_info(self)->dict[str,Any]:
        snap=self.owner.snapshot(); max_points=[0]*len(self.source.chapters)
        active=self._active_occult()
        if active:
            chapter_id=self._int(active[1].get('chapter_id'),0)
            if 1<=chapter_id<=len(max_points):max_points[chapter_id-1]=1
        return {'room_id':0,'chapter_id':0,'cost_energy':snap['cost_energy'],'max_points':max_points,'dispatch_limit':self.source.dispatch_hero_limit}
    def get_info(self)->dict[str,Any]:
        # Read-only compatibility projection: do not manufacture a manual clear.
        return {'base_info':self._base_info(),'occult_ticket':self.owner.snapshot()['occult_ticket']}
    def sweep(self,chapter_id:Any)->dict[str,Any]:
        cid=self._int(chapter_id,0)
        if self.source.chapter(cid) is None:raise OccultServiceError('unknown Occult chapter_id')
        active=self._active_occult()
        if active is None:raise OccultServiceError('no active ordinary Occult Awakening mission')
        rec,route=active
        if self._int(route.get('chapter_id'),0)!=cid:raise OccultServiceError('Occult chapter does not match active Awakening mission')
        fragment=self._int(route.get('fragment_item'),0)
        if fragment<=0:raise OccultServiceError('active Occult Awakening route lacks fragment item')
        def mutate()->dict[str,Any]:
            try:
                self.settlement.apply(MutationPlan(
                    schema_version=1,
                    plan_id=f'occult:sweep:{cid}:{self._int(rec.get("mission_id"),0)}:{self._int(rec.get("generation"),0)}:{self.uow.current_state_version}',
                    origin=MutationOrigin(domain='occult',operation='awakening_sweep',protocol_mid=self.MID_SWEEP,source_table='creats_chapter_select',source_id=cid),
                    actor=ActorRef(player_id=str(self.player.player_id)),expected_state_version=None,idempotency=IdempotencySpec(),preconditions=(),
                    operations=(EntityMutation('OCCULT',1,'CONSUME_TICKET',amount=1),StackMutation(fragment,'CREDIT',1)),
                    metadata={'evidence_class':'COMPATIBILITY_POLICY','active_awakening_mission_id':self._int(rec.get('mission_id'),0),'activation_generation':self._int(rec.get('generation'),0),'raw_awaken_num':self._int(route.get('awaken_num_raw'),0),'raw_sweep_reward_rate':self.source.sweep_reward_rate_raw,'deterministic_fragment_quantity':1},
                ))
            except MutationSettlementError as exc: raise OccultServiceError(str(exc)) from exc
            return {'awards':[{'item_id':fragment,'item_num':1}],'occult_ticket':self.owner.snapshot()['occult_ticket']}
        with self.uow.transaction(self._context(self.MID_SWEEP,'awakening_sweep')):
            return mutate()
