"""Canonical Occult/Sorcery War aggregate mutation owner (Pass211 Stage F).

`occult_ticket` is intentionally *not* an EconomyLedger scalar.  The sealed
resource registry assigns it to SorceryWarAggregate with domain-guarded
credit/debit.  This owner therefore mutates the ticket and its stamina progress
(`occult_state.cost_energy`) as one ENTITY authority inside PlayerUnitOfWork.
"""
from __future__ import annotations
from dataclasses import dataclass
from typing import Any

from gxb_backend.content.occult_source_catalog import OccultSourceCatalog
from .mutation_plan import EntityMutation
from .player_state import PlayerState
from .unit_of_work import PlayerUnitOfWork

class OccultEntityMutationError(ValueError): pass

@dataclass(frozen=True)
class OccultEntityChange:
    action:str
    entity_id:int
    before:dict[str,Any]
    after:dict[str,Any]
    delta:int|None=None

class OccultEntityMutationService:
    ENTITY_TYPE='OCCULT'; ENTITY_ID=1
    ACCRUE='ACCRUE_ENERGY'; CONSUME='CONSUME_TICKET'
    def __init__(self,player:PlayerState,source:OccultSourceCatalog,uow:PlayerUnitOfWork)->None:
        self.player=player; self.source=source; self.uow=uow
    @staticmethod
    def _int(value:Any,default:int=0)->int:
        try:return int(value)
        except (TypeError,ValueError):return default
    def _ticket(self)->int: return max(0,min(self.source.ticket_cap,self._int(self.player.occult_ticket,0)))
    def _state(self)->dict[str,int]:
        raw=self.player.occult_state if isinstance(self.player.occult_state,dict) else {}
        progress=max(0,self._int(raw.get('cost_energy'),0))
        if progress>=self.source.ticket_energy_threshold: progress%=self.source.ticket_energy_threshold
        if self._ticket()>=self.source.ticket_cap: progress=0
        return {'schema_version':1,'cost_energy':progress}
    def snapshot(self)->dict[str,int]:
        state=self._state(); return {'occult_ticket':self._ticket(),'cost_energy':state['cost_energy']}
    def validate(self,op:EntityMutation)->EntityMutation:
        if str(op.entity_type).upper()!=self.ENTITY_TYPE or self._int(op.entity_id,0)!=self.ENTITY_ID:
            raise OccultEntityMutationError('invalid OCCULT entity target')
        action=str(op.action).upper(); amount=self._int(op.amount,0)
        if action==self.ACCRUE:
            if amount<=0 or op.indices or op.counts: raise OccultEntityMutationError('ACCRUE_ENERGY requires positive amount only')
        elif action==self.CONSUME:
            if amount!=1 or op.indices or op.counts: raise OccultEntityMutationError('CONSUME_TICKET requires amount=1 only')
            if self._ticket()<1: raise OccultEntityMutationError('occult_ticket is insufficient')
        else: raise OccultEntityMutationError(f'unsupported OCCULT action {op.action!r}')
        return op
    def apply(self,op:EntityMutation)->OccultEntityChange:
        if not self.uow.active: raise OccultEntityMutationError('OCCULT mutation requires active PlayerUnitOfWork')
        self.validate(op)
        action=str(op.action).upper(); amount=self._int(op.amount,0)
        before=self.snapshot(); ticket=before['occult_ticket']; progress=before['cost_energy']
        if action==self.ACCRUE:
            if ticket>=self.source.ticket_cap:
                progress=0
            else:
                total=progress+amount
                earn=min(self.source.ticket_cap-ticket,total//self.source.ticket_energy_threshold)
                ticket+=earn
                progress=0 if ticket>=self.source.ticket_cap else total%self.source.ticket_energy_threshold
        else:
            ticket-=1
        self.player.occult_ticket=ticket
        self.player.occult_state={'schema_version':1,'cost_energy':progress}
        self.uow.mark_changed('occult_state')
        after={'occult_ticket':ticket,'cost_energy':progress}
        delta=ticket-before['occult_ticket']
        if delta:
            # Backend.lua's generic economy_ event reaches SelfPlayer.economySyncEvent_,
            # which has an explicit occult_ticket consumer. This is projection only;
            # durable authority remains this aggregate.
            self.uow.stage_semantic('economy_',{'occult_ticket':ticket})
        return OccultEntityChange(action,self.ENTITY_ID,before,after,delta)
