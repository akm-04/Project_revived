"""P1-I4B Cabinet skill research lifecycle.

Source authority comes from effective src_64 Cabinet/EventCentre tables.  This
service owns only the server-authored research lifecycle and durable global
book_info/cabinet_info state; Hero skill effects remain projected through the
existing typed Hero mutation owner.
"""
from __future__ import annotations
import math
from typing import Any

from gxb_backend.content import CatalogNamespace, ContentRef, GameDataCatalog
from gxb_backend.content.workshop_source_catalog import WorkshopSourceCatalog
from .durable_timed_job import DurableJobState, DurableTimedJobPolicy
from .event_centre_acceleration_policy import EventCentreAccelerationPolicy
from .event_centre_building_service import EventCentreBuildingService
from .hero_entity_mutation_service import HeroEntityMutationService
from .hero_repository import HeroRepository
from .inventory_repository import InventoryRepository
from .mutation_plan import ActorRef, EntityMutation, IdempotencySpec, MutationOrigin, MutationPlan, ResourceMutation, StackMutation
from .mutation_settlement_service import MutationSettlementService
from .player_state import PlayerState
from .server_clock import ServerClock
from .unit_of_work import OperationContext, PlayerUnitOfWork


class CabinetResearchError(ValueError):
    pass


class CabinetResearchService:
    RESOURCE_KEYS = {1: "mana", 11: "magic_dust", 12: "magic_liquid", 13: "magic_energy"}
    SLICE = "workshop_cabinet"

    def __init__(self, player: PlayerState, source: WorkshopSourceCatalog, game_data: GameDataCatalog,
                 heroes: HeroRepository, hero_entities: HeroEntityMutationService,
                 inventory: InventoryRepository, settlement: MutationSettlementService,
                 jobs: DurableTimedJobPolicy, acceleration: EventCentreAccelerationPolicy,
                 buildings: EventCentreBuildingService, clock: ServerClock,
                 uow: PlayerUnitOfWork) -> None:
        self.player=player; self.source=source; self.game_data=game_data; self.heroes=heroes
        self.hero_entities=hero_entities; self.inventory=inventory; self.settlement=settlement
        self.jobs=jobs; self.acceleration=acceleration; self.buildings=buildings
        self.clock=clock; self.uow=uow

    @staticmethod
    def _int(value: Any, default: int=0) -> int:
        try:return int(value)
        except (TypeError,ValueError):return default

    def _context(self, mid:int, operation:str) -> OperationContext:
        return OperationContext(actor_player_id=str(self.player.player_id),domain="workshop_cabinet",operation_name=operation,protocol_mid=mid,server_time=self.clock.now())

    def _plan(self,mid:int,operation:str,ops:tuple[Any,...])->MutationPlan:
        return MutationPlan(schema_version=1,plan_id=f"cabinet:{mid}:{operation}:{self.uow.current_state_version}",origin=MutationOrigin(domain="workshop_cabinet",operation=operation,protocol_mid=mid),actor=ActorRef(player_id=str(self.player.player_id)),expected_state_version=None,idempotency=IdempotencySpec(),preconditions=(),operations=ops)

    def _settle(self,mid:int,operation:str,ops:tuple[Any,...])->None:
        if ops:self.settlement.apply(self._plan(mid,operation,ops))

    def _state(self)->dict[str,Any]:
        raw=self.player.workshop_state if isinstance(self.player.workshop_state,dict) else {}
        out=dict(raw)
        out["book_info"]=dict(out.get("book_info") or {}) if isinstance(out.get("book_info"),dict) else {}
        cab=dict(out.get("cabinet_info") or {}) if isinstance(out.get("cabinet_info"),dict) else {}
        for key in ("cur_learn_skill","need_time","start_time","recent_complete_skill"):
            cab[key]=max(0,self._int(cab.get(key)))
        cab["cost_snapshot"]=dict(cab.get("cost_snapshot") or {}) if isinstance(cab.get("cost_snapshot"),dict) else {}
        out["cabinet_info"]=cab
        out["building_jobs"]=dict(out.get("building_jobs") or {}) if isinstance(out.get("building_jobs"),dict) else {}
        return out

    def _save(self,state:dict[str,Any])->None:
        self.player.workshop_state=state; self.uow.mark_changed(self.SLICE)

    def _cabinet_wire(self,state:dict[str,Any])->dict[str,int]:
        cab=state.get("cabinet_info") if isinstance(state.get("cabinet_info"),dict) else {}
        return {k:max(0,self._int(cab.get(k))) for k in ("cur_learn_skill","need_time","start_time","recent_complete_skill")}

    def _book_levels(self,state:dict[str,Any],book_id:int)->dict[str,dict[str,int]]:
        raw=(state.get("book_info") or {}).get(str(book_id),{}) if isinstance(state.get("book_info"),dict) else {}
        valid=set(self.source.cabinet_book_skills(book_id)); out={}
        if isinstance(raw,dict):
            for sid in valid:
                row=raw.get(str(sid),raw.get(sid))
                lev=self._int(row.get("lev"),0) if isinstance(row,dict) else self._int(row,0)
                if lev>0: out[str(sid)]={"lev":min(self.source.cabinet_book_star(book_id),lev)}
        return out

    def _book_levels_complete_wire(self,state:dict[str,Any],book_id:int)->dict[str,dict[str,int]]:
        # SOURCE_FACT (effective src_64 EventCentre:speedUpSkill): MID1078 walks
        # every skill_id in the completed book and directly dereferences
        # response.book_info[tostring(skill_id)].lev.  Durable storage remains
        # sparse, but this response contract must be complete, including lev=0.
        sparse=self._book_levels(state,book_id)
        return {str(sid):{"lev":self._int((sparse.get(str(sid)) or {}).get("lev"),0)}
                for sid in self.source.cabinet_book_skills(book_id)}

    def _book_info_wire(self,state:dict[str,Any])->dict[str,dict[str,dict[str,int]]]:
        # EventCentre:getCabinetInfo gates book rendering on book_info[book_id]
        # being present, so return all effective books even when no skill is learned.
        return {str(book_id):self._book_levels(state,book_id) for book_id in self.source.cabinet_books}

    def _skill_level(self,state:dict[str,Any],skill_id:int)->int:
        book=self.source.cabinet_skill_book(skill_id)
        row=self._book_levels(state,book).get(str(skill_id),{})
        return max(0,self._int(row.get("lev")))

    def _set_skill_level(self,state:dict[str,Any],skill_id:int,level:int)->None:
        book=self.source.cabinet_skill_book(skill_id); star=self.source.cabinet_book_star(book)
        if book<=0 or star<=0: raise CabinetResearchError("cabinet skill book is unknown")
        info=dict(state.get("book_info") or {}); bucket=dict(info.get(str(book)) or {})
        if level>0:bucket[str(skill_id)]={"lev":min(star,max(0,int(level)))}
        else:bucket.pop(str(skill_id),None)
        info[str(book)]=bucket; state["book_info"]=info

    def _cabinet_building(self)->dict[str,int]:
        # Materialize any naturally READY building job before enforcing the
        # source Cabinet-level/research-during-upgrade checks.
        payload=self.buildings.get_building_list()
        row=dict((payload.get("building_list") or {}).get(str(self.source.CABINET_BUILDING_TYPE)) or {})
        return {"lev":max(1,self._int(row.get("lev"),1)),"need_time":max(0,self._int(row.get("need_time"))),"start_time":max(0,self._int(row.get("start_time"))),"new_evolve":max(0,self._int(row.get("new_evolve")))}

    def _hero_for_source_partner(self,source_table_id:int)->dict[str,Any]|None:
        matches=[]
        for hero in self.player.heroes.values() if isinstance(self.player.heroes,dict) else ():
            if not isinstance(hero,dict):continue
            tid=self._int(hero.get("table_id")); pid=self._int(hero.get("partner_id"))
            if tid<=0 or pid<=0:continue
            row=self.game_data.maybe_get(ContentRef(CatalogNamespace.PARTNER,tid))
            first=self._int(row.get("first_table_id"),0) if row is not None else 0
            origin=first if first>0 else tid
            if origin==source_table_id:matches.append((pid,hero))
        return min(matches,key=lambda v:v[0])[1] if matches else None

    def _project_hero(self,skill_id:int,level:int,*,mid:int,operation:str)->None:
        source_partner=self.source.cabinet_skill_partner(skill_id)
        hero=self._hero_for_source_partner(source_partner)
        if hero is None:return
        pid=self._int(hero.get("partner_id"))
        self._settle(mid,operation,(EntityMutation("HERO",pid,"SET_CABINET_SKILL_LEVEL",amount=level,indices=(skill_id,)),))

    def _costs(self,skill_id:int,target_level:int)->tuple[list[tuple[int,str,int]],int,int]:
        resources=[]; page_id=0; page_num=0
        book=self.source.cabinet_skill_book(skill_id); skillpage=self.source.cabinet_book_skillpage(book)
        for rid,num in self.source.cabinet_skill_cost(skill_id,target_level):
            if rid==-1:
                if skillpage<=0:raise CabinetResearchError("Cabinet skill-page source mismatch")
                page_id=skillpage; page_num+=num
            else:
                key=self.RESOURCE_KEYS.get(rid)
                if key is None:raise CabinetResearchError(f"unsupported Cabinet resource id {rid}")
                resources.append((rid,key,num))
        return resources,page_id,page_num

    def _complete(self,state:dict[str,Any],skill_id:int,*,mid:int,operation:str)->tuple[int,int]:
        current=self._skill_level(state,skill_id); book=self.source.cabinet_skill_book(skill_id); star=self.source.cabinet_book_star(book)
        if current>=star: raise CabinetResearchError("Cabinet skill is already max level")
        target=current+1
        self._project_hero(skill_id,target,mid=mid,operation=operation+"_hero_projection")
        self._set_skill_level(state,skill_id,target)
        cab=dict(state.get("cabinet_info") or {}); cab.update({"cur_learn_skill":0,"need_time":0,"start_time":0,"recent_complete_skill":skill_id,"cost_snapshot":{}}); state["cabinet_info"]=cab
        self._save(state)
        return book,target

    def _materialize_ready(self,*,mid:int,operation:str)->bool:
        state=self._state(); cab=state["cabinet_info"]; skill=self._int(cab.get("cur_learn_skill"))
        if skill<=0 or self._int(cab.get("start_time"))<=0 or self._int(cab.get("need_time"))<=0:return False
        snap=self.jobs.snapshot(start_time=cab["start_time"],need_time=cab["need_time"],now=self.clock.now())
        if snap.state!=DurableJobState.READY:return False
        with self.uow.transaction(self._context(mid,operation)):
            self._complete(state,skill,mid=mid,operation=operation)
        return True

    def reconcile_ready(self,*,mid:int=1059,operation:str="cabinet_lazy_complete")->bool:
        return self._materialize_ready(mid=mid,operation=operation)

    def get_info(self)->dict[str,Any]:
        self._materialize_ready(mid=1059,operation="get_cabinet_info_complete")
        state=self._state()
        return {"book_info":self._book_info_wire(state),"cabinet_info":self._cabinet_wire(state)}

    def learn(self,skill_id:Any)->dict[str,Any]:
        sid=self._int(skill_id); skill=self.source.cabinet_skill(sid)
        if sid<=0 or skill is None:raise CabinetResearchError("unknown Cabinet skill")
        self._materialize_ready(mid=1060,operation="learn_preflight_complete")
        state=self._state(); cab=state["cabinet_info"]
        active=self._int(cab.get("cur_learn_skill"))
        if active>0:
            if active==sid:return {"cabinet_info":self._cabinet_wire(state)}
            raise CabinetResearchError("another Cabinet skill is researching")
        if self._int(cab.get("recent_complete_skill"))>0:raise CabinetResearchError("Cabinet skill confirmation is pending")
        building=self._cabinet_building()
        if building["start_time"]>0 or building["need_time"]>0:raise CabinetResearchError("Cabinet building is upgrading")
        book=self.source.cabinet_skill_book(sid); star=self.source.cabinet_book_star(book)
        if book<=0 or star<=0:raise CabinetResearchError("Cabinet skill book is unknown")
        if building["lev"]<star:raise CabinetResearchError("Cabinet level is too low")
        if self.inventory.quantity(book)<=0:raise CabinetResearchError("Cabinet book is not owned")
        current=self._skill_level(state,sid)
        if current>=star:raise CabinetResearchError("Cabinet skill is already max level")
        target=current+1
        for prereq in self.source.cabinet_skill_prerequisites(sid):
            # Effective UI requires prerequisite level > target skill current
            # level, equivalently prerequisite level >= target level.
            if self._skill_level(state,prereq)<target:raise CabinetResearchError("Cabinet skill prerequisite is not met")
        resources,page_id,page_num=self._costs(sid,target)
        need=self.source.cabinet_skill_need_time(sid,target,building["lev"]); now=self.clock.now()
        ops=[ResourceMutation(key,"DEBIT",num) for _,key,num in resources]
        if page_num>0:ops.append(StackMutation(page_id,"DEBIT",page_num))
        with self.uow.transaction(self._context(1060,"learn_cabinet_skill")):
            self._settle(1060,"learn_cabinet_skill_cost",tuple(ops))
            cab=dict(state["cabinet_info"])
            snapshot={"skill_id":sid,"target_level":target,"need_time":need,"resources":[{"resource_id":rid,"resource_key":key,"amount":num} for rid,key,num in resources],"skill_page_id":page_id,"skill_page_num":page_num}
            if need<=0:
                cab.update({"cur_learn_skill":sid,"need_time":0,"start_time":0,"cost_snapshot":snapshot}); state["cabinet_info"]=cab
                self._complete(state,sid,mid=1060,operation="learn_immediate_complete")
            else:
                cab.update({"cur_learn_skill":sid,"need_time":need,"start_time":now,"recent_complete_skill":0,"cost_snapshot":snapshot}); state["cabinet_info"]=cab; self._save(state)
        return {"cabinet_info":self._cabinet_wire(self._state())}

    def cancel(self,skill_id:Any)->dict[str,Any]:
        sid=self._int(skill_id); state=self._state(); cab=state["cabinet_info"]; active=self._int(cab.get("cur_learn_skill"))
        if active<=0:return {"cabinet_info":self._cabinet_wire(state),"return_skillpage":0}
        if sid>0 and sid!=active:raise CabinetResearchError("Cabinet cancel skill mismatch")
        snap=self.jobs.snapshot(start_time=cab.get("start_time"),need_time=cab.get("need_time"),now=self.clock.now())
        if snap.state==DurableJobState.READY:
            self._materialize_ready(mid=1061,operation="cancel_ready_cabinet_complete")
            return {"cabinet_info":self._cabinet_wire(self._state()),"return_skillpage":0}
        cost=dict(cab.get("cost_snapshot") or {}); credits=[]
        for item in cost.get("resources",[]) if isinstance(cost.get("resources"),list) else ():
            if not isinstance(item,dict):continue
            rid=self._int(item.get("resource_id")); key=str(item.get("resource_key") or ""); amount=max(0,self._int(item.get("amount")))
            refund=math.floor(amount*snap.remaining/max(1,snap.need_time))
            if refund>0 and self.RESOURCE_KEYS.get(rid)==key:credits.append(ResourceMutation(key,"CREDIT",refund))
        page_id=max(0,self._int(cost.get("skill_page_id"))); page_num=max(0,self._int(cost.get("skill_page_num")))
        with self.uow.transaction(self._context(1061,"give_up_cabinet_skill")):
            self._settle(1061,"give_up_cabinet_skill_refund",tuple(credits))
            # Source response exposes return_skillpage and the client explicitly
            # adds that stack locally.  Restore through the canonical stack owner
            # without synthesizing a generic awards projection that would double it.
            if page_id>0 and page_num>0:self.inventory.apply_deltas({page_id:page_num},persist=False)
            cab=dict(state["cabinet_info"]); cab.update({"cur_learn_skill":0,"need_time":0,"start_time":0,"cost_snapshot":{}}); state["cabinet_info"]=cab; self._save(state)
        return {"cabinet_info":self._cabinet_wire(self._state()),"return_skillpage":page_num}

    def speed(self,skill_id:Any)->dict[str,Any]:
        sid=self._int(skill_id); state=self._state(); cab=state["cabinet_info"]; active=self._int(cab.get("cur_learn_skill"))
        if active<=0:
            # State-based replay after a successful speed/ready completion.
            if sid>0 and self._int(cab.get("recent_complete_skill"))==sid:
                book=self.source.cabinet_skill_book(sid)
                return {"cabinet_info":self._cabinet_wire(state),"book_id":str(book),"book_info":self._book_levels_complete_wire(state,book)}
            raise CabinetResearchError("no Cabinet skill is researching")
        if sid>0 and sid!=active:raise CabinetResearchError("Cabinet speed skill mismatch")
        snap=self.jobs.snapshot(start_time=cab.get("start_time"),need_time=cab.get("need_time"),now=self.clock.now())
        with self.uow.transaction(self._context(1078,"speed_up_cabinet_skill")):
            if snap.state==DurableJobState.RUNNING:
                self._settle(1078,"speed_up_cabinet_skill_cost",(ResourceMutation("crystal","DEBIT",self.acceleration.crystal_cost(snap.remaining)),))
            book,_=self._complete(state,active,mid=1078,operation="speed_up_cabinet_skill_complete")
        final=self._state()
        return {"cabinet_info":self._cabinet_wire(final),"book_id":str(book),"book_info":self._book_levels_complete_wire(final,book)}

    def confirm(self)->dict[str,Any]:
        state=self._state(); cab=state["cabinet_info"]
        if self._int(cab.get("recent_complete_skill"))<=0:return {}
        with self.uow.transaction(self._context(1079,"confirm_cabinet_skill")):
            cab=dict(cab); cab["recent_complete_skill"]=0; state["cabinet_info"]=cab; self._save(state)
        return {}
