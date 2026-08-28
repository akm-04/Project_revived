"""P1-I4A Event Centre building lifecycle + Bookshelf projection.

Source-shaped finite building jobs over existing PlayerState.building_list.
Only P1 Workshop building types (Cabinet=1, Bookshelf=4) are mutable here;
other Event Centre buildings remain explicitly deferred.
"""
from __future__ import annotations
import math
from typing import Any

from gxb_backend.content import CatalogNamespace, ContentRef, GameDataCatalog
from gxb_backend.content.workshop_source_catalog import WorkshopSourceCatalog
from .durable_timed_job import DurableJobState, DurableTimedJobPolicy
from .event_centre_acceleration_policy import EventCentreAccelerationPolicy
from .hero_entity_mutation_service import HeroEntityMutationService
from .hero_repository import HeroRepository
from .mutation_plan import ActorRef, EntityMutation, IdempotencySpec, MutationOrigin, MutationPlan, ResourceMutation
from .mutation_settlement_service import MutationSettlementService
from .player_state import PlayerState
from .server_clock import ServerClock
from .unit_of_work import OperationContext, PlayerUnitOfWork


class EventCentreBuildingError(ValueError):
    pass


class EventCentreBuildingService:
    CABINET = 1
    BOOKSHELF = 4
    SUPPORTED = (CABINET, BOOKSHELF)
    RESOURCE_KEYS = {11: "magic_dust", 12: "magic_liquid", 13: "magic_energy", 14: "magic_exp"}
    SLICE = "workshop_buildings"

    def __init__(self, player: PlayerState, source: WorkshopSourceCatalog, game_data: GameDataCatalog,
                 heroes: HeroRepository, hero_entities: HeroEntityMutationService,
                 settlement: MutationSettlementService, jobs: DurableTimedJobPolicy,
                 acceleration: EventCentreAccelerationPolicy, clock: ServerClock,
                 uow: PlayerUnitOfWork) -> None:
        self.player=player; self.source=source; self.game_data=game_data; self.heroes=heroes
        self.hero_entities=hero_entities; self.settlement=settlement; self.jobs=jobs
        self.acceleration=acceleration; self.clock=clock; self.uow=uow

    @staticmethod
    def _int(value: Any, default: int=0) -> int:
        try: return int(value)
        except (TypeError, ValueError): return default

    @classmethod
    def _supported(cls, building_type: Any) -> int:
        bid=cls._int(building_type)
        if bid not in cls.SUPPORTED: raise EventCentreBuildingError("workshop_building_type_deferred")
        return bid

    def _context(self, mid:int, operation:str) -> OperationContext:
        return OperationContext(actor_player_id=str(self.player.player_id),domain="workshop",operation_name=operation,protocol_mid=mid,server_time=self.clock.now())

    def _rows(self) -> dict[str,dict[str,int]]:
        payload=self.player.building_list_payload()["building_list"]
        rows={}
        for key,row in payload.items():
            rows[str(key)]={"lev":max(1,self._int(row.get("lev"),1)),"need_time":max(0,self._int(row.get("need_time"))),"start_time":max(0,self._int(row.get("start_time"))),"new_evolve":1 if self._int(row.get("new_evolve"))>0 else 0}
        return rows

    def _save_rows(self, rows:dict[str,dict[str,int]]) -> None:
        self.player.building_list={str(k):dict(v) for k,v in rows.items()}
        self.uow.mark_changed(self.SLICE)

    def _workshop(self) -> dict[str,Any]:
        raw=self.player.workshop_state if isinstance(self.player.workshop_state,dict) else {}
        out=dict(raw)
        out["book_info"]=dict(out.get("book_info") or {}) if isinstance(out.get("book_info"),dict) else {}
        out["cabinet_info"]=dict(out.get("cabinet_info") or {}) if isinstance(out.get("cabinet_info"),dict) else {}
        out["building_jobs"]=dict(out.get("building_jobs") or {}) if isinstance(out.get("building_jobs"),dict) else {}
        return out

    def _save_workshop(self, state:dict[str,Any]) -> None:
        self.player.workshop_state=state; self.uow.mark_changed(self.SLICE)

    def _source_row(self,bid:int,level:int):
        row=self.source.building_level(bid,level)
        if row is None: raise EventCentreBuildingError("workshop building level is unknown")
        return row

    @staticmethod
    def _pipe(value:Any)->list[int]:
        if isinstance(value,(list,tuple)): raw=value
        else: raw=str(value or "").split("|") if value not in (None,"") else []
        out=[]
        for item in raw:
            try: out.append(int(item))
            except (TypeError,ValueError): raise EventCentreBuildingError("invalid Workshop source vector")
        return out

    def _costs(self,row:dict[str,Any]|Any)->list[tuple[int,str,int]]:
        ids=self._pipe(row.get("resources_id")); nums=self._pipe(row.get("resources_num"))
        if len(ids)!=len(nums): raise EventCentreBuildingError("Workshop source cost vector mismatch")
        result=[]
        for rid,num in zip(ids,nums):
            key=self.RESOURCE_KEYS.get(rid)
            if key is None: raise EventCentreBuildingError(f"unsupported Workshop resource id {rid}")
            if num>0: result.append((rid,key,num))
        return result

    def _plan(self,mid:int,operation:str,ops:tuple[Any,...])->MutationPlan:
        return MutationPlan(schema_version=1,plan_id=f"workshop:{mid}:{operation}:{self.uow.current_state_version}",origin=MutationOrigin(domain="workshop",operation=operation,protocol_mid=mid),actor=ActorRef(player_id=str(self.player.player_id)),expected_state_version=None,idempotency=IdempotencySpec(),preconditions=(),operations=ops)

    def _settle(self,mid:int,operation:str,ops:tuple[Any,...])->None:
        if ops:self.settlement.apply(self._plan(mid,operation,ops))

    def _normal_hero_ids(self)->list[int]:
        out=[]
        for hero in self.player.heroes.values() if isinstance(self.player.heroes,dict) else ():
            if not isinstance(hero,dict): continue
            tid=self._int(hero.get("table_id")); pid=self._int(hero.get("partner_id"))
            if tid>0 and pid>0 and self.game_data.exists(ContentRef(CatalogNamespace.PARTNER,tid)): out.append(pid)
        return out

    def _project_bookshelf(self, level:int, *,mid:int,operation:str)->None:
        ops=[]
        for pid in self._normal_hero_ids():
            hero=self.heroes.get(pid)
            if hero is not None and self._int(hero.get("book_shelf_lev"))!=level:
                ops.append(EntityMutation("HERO",pid,"SET_BOOKSHELF_LEVEL",amount=level))
        self._settle(mid,operation,tuple(ops))

    def _complete(self,bid:int,rows:dict[str,dict[str,int]],state:dict[str,Any],*,mid:int,operation:str)->dict[str,int]:
        key=str(bid); row=dict(rows[key]); maximum=self.source.max_building_level(bid)
        if row["lev"]>=maximum: raise EventCentreBuildingError("Workshop building is already at max level")
        row.update({"lev":row["lev"]+1,"need_time":0,"start_time":0,"new_evolve":1}); rows[key]=row
        jobs=dict(state.get("building_jobs") or {}); jobs.pop(key,None); state["building_jobs"]=jobs
        self._save_rows(rows); self._save_workshop(state)
        if bid==self.BOOKSHELF:self._project_bookshelf(row["lev"],mid=mid,operation=operation+"_bookshelf_projection")
        return dict(row, type=bid)

    def _materialize_ready(self,bid:int,rows:dict[str,dict[str,int]],state:dict[str,Any],*,mid:int,operation:str)->bool:
        row=rows[str(bid)]
        if row["start_time"]<=0 or row["need_time"]<=0:return False
        snap=self.jobs.snapshot(start_time=row["start_time"],need_time=row["need_time"],now=self.clock.now())
        if snap.state!=DurableJobState.READY:return False
        self._complete(bid,rows,state,mid=mid,operation=operation); return True

    def _payload(self)->dict[str,Any]:
        out=self.player.building_list_payload()
        state=self._workshop(); cabinet=dict(state.get("cabinet_info") or {})
        out["cabinet_info"]={
            "cur_learn_skill":max(0,self._int(cabinet.get("cur_learn_skill"))),
            "need_time":max(0,self._int(cabinet.get("need_time"))),
            "start_time":max(0,self._int(cabinet.get("start_time"))),
            "recent_complete_skill":max(0,self._int(cabinet.get("recent_complete_skill"))),
        }
        return out

    def get_building_list(self)->dict[str,Any]:
        rows=self._rows(); state=self._workshop(); ready=[]
        for bid in self.SUPPORTED:
            row=rows[str(bid)]
            if row["start_time"]>0 and self.jobs.snapshot(start_time=row["start_time"],need_time=row["need_time"],now=self.clock.now()).state==DurableJobState.READY:ready.append(bid)
        if ready:
            with self.uow.transaction(self._context(1056,"get_building_list_complete")):
                for bid in ready:self._materialize_ready(bid,rows,state,mid=1056,operation="building_complete")
        return self._payload()

    def upgrade(self,building_type:Any)->dict[str,int]:
        bid=self._supported(building_type); rows=self._rows(); state=self._workshop(); row=rows[str(bid)]
        if row["start_time"]>0:return dict(row,type=bid)  # retry/replay: no second spend
        if row["new_evolve"]>0:raise EventCentreBuildingError("Workshop building upgrade confirmation is pending")
        if row["lev"]>=self.source.max_building_level(bid):raise EventCentreBuildingError("Workshop building is already at max level")
        source=self._source_row(bid,row["lev"]); need=max(0,self._int(source.get("time")))
        req_type=max(0,self._int(source.get("type_request"))); req_level=max(0,self._int(source.get("function_request_level")))
        if req_type>0 and self._int(rows.get(str(req_type),{}).get("lev"),0)<req_level:raise EventCentreBuildingError("Workshop building prerequisite is not met")
        costs=self._costs(source); now=self.clock.now()
        with self.uow.transaction(self._context(1057,"upgrade_building")):
            self._settle(1057,"upgrade_building_cost",tuple(ResourceMutation(key,"DEBIT",num) for _,key,num in costs))
            row=dict(row); row.update({"start_time":now,"need_time":need,"new_evolve":0}); rows[str(bid)]=row
            jobs=dict(state.get("building_jobs") or {}); jobs[str(bid)]={"level":row["lev"],"start_time":now,"need_time":need,"resources":[{"resource_id":rid,"resource_key":key,"amount":num} for rid,key,num in costs]}; state["building_jobs"]=jobs
            self._save_rows(rows); self._save_workshop(state)
        return dict(row,type=bid)

    def speed(self,building_type:Any)->dict[str,int]:
        bid=self._supported(building_type); rows=self._rows(); state=self._workshop(); row=rows[str(bid)]
        if row["start_time"]<=0:
            if row["new_evolve"]>0:return dict(row,type=bid)
            raise EventCentreBuildingError("Workshop building is not upgrading")
        snap=self.jobs.snapshot(start_time=row["start_time"],need_time=row["need_time"],now=self.clock.now())
        with self.uow.transaction(self._context(1077,"speed_up_building")):
            if snap.state==DurableJobState.RUNNING:
                cost=self.acceleration.crystal_cost(snap.remaining)
                self._settle(1077,"speed_up_building_cost",(ResourceMutation("crystal","DEBIT",cost),))
            return self._complete(bid,rows,state,mid=1077,operation="speed_up_building_complete")

    def cancel(self,building_type:Any)->dict[str,Any]:
        bid=self._supported(building_type); rows=self._rows(); state=self._workshop(); row=rows[str(bid)]
        if row["start_time"]<=0:return {"building_info":dict(row),"return_res_id":[],"return_res_num":[]}
        snap=self.jobs.snapshot(start_time=row["start_time"],need_time=row["need_time"],now=self.clock.now())
        if snap.state==DurableJobState.READY:
            with self.uow.transaction(self._context(1058,"cancel_ready_building_complete")):
                completed=self._complete(bid,rows,state,mid=1058,operation="cancel_ready_building_complete")
            return {"building_info":{k:v for k,v in completed.items() if k!="type"},"return_res_id":[],"return_res_num":[]}
        job=dict((state.get("building_jobs") or {}).get(str(bid)) or {}); resources=job.get("resources") if isinstance(job.get("resources"),list) else []
        ids=[]; nums=[]; credits=[]
        for item in resources:
            if not isinstance(item,dict):continue
            rid=self._int(item.get("resource_id")); key=str(item.get("resource_key") or ""); amount=max(0,self._int(item.get("amount")))
            refund=math.floor(amount*snap.remaining/max(1,snap.need_time))
            if refund>0 and rid in self.RESOURCE_KEYS and key==self.RESOURCE_KEYS[rid]:ids.append(rid);nums.append(refund);credits.append(ResourceMutation(key,"CREDIT",refund))
        with self.uow.transaction(self._context(1058,"cancel_evolve_building")):
            self._settle(1058,"cancel_evolve_building_refund",tuple(credits))
            row=dict(row); row.update({"start_time":0,"need_time":0,"new_evolve":0}); rows[str(bid)]=row
            jobs=dict(state.get("building_jobs") or {}); jobs.pop(str(bid),None); state["building_jobs"]=jobs
            self._save_rows(rows); self._save_workshop(state)
        return {"building_info":dict(row),"return_res_id":ids,"return_res_num":nums}

    def confirm(self,building_type:Any)->dict[str,Any]:
        bid=self._supported(building_type); rows=self._rows(); row=rows[str(bid)]
        if row["new_evolve"]<=0:return {}
        with self.uow.transaction(self._context(1080,"confirm_building_upgrade")):
            row=dict(row); row["new_evolve"]=0; rows[str(bid)]=row; self._save_rows(rows)
        return {}
