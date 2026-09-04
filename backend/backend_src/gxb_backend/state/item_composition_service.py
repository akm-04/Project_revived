"""Provider-based MID83 item composition owner (Pass206 Stage B)."""
from __future__ import annotations
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Protocol
from .mutation_plan import ActorRef,IdempotencySpec,MutationOrigin,MutationPlan,ResourceMutation,StackMutation
from .mutation_settlement_service import MutationSettlementError,MutationSettlementService
from .inventory_repository import InventoryRepository
from .unit_of_work import OperationContext,UnitOfWork

@dataclass(frozen=True)
class CompositionRecipe:
    item_id:int; components:tuple[tuple[int,int],...]; mana:int; provider:str; single_owned:bool=False
class CompositionProvider(Protocol):
    def resolve(self,item_id:int)->CompositionRecipe|None: ...

class CabinetCompositionProvider:
    def __init__(self,source): self.source=source
    def resolve(self,item_id:int)->CompositionRecipe|None:
        row=self.source.cabinet_book_compose(item_id)
        if row is None:return None
        return CompositionRecipe(item_id,((int(row.get("fragment_id",0) or 0),int(row.get("fragment_num",0) or 0)),),int(row.get("compose_mana",0) or 0),"workshop_cabinet",True)

class EmblemCompositionProvider:
    """Exact current-src_64 Heart of Medal composition provider."""
    def __init__(self, source) -> None:
        self.source = source

    def resolve(self, item_id: int) -> CompositionRecipe | None:
        row = self.source.heart_recipe
        target = int(row.get("item_id", 0) or 0)
        if item_id != target or target <= 0:
            return None
        components = tuple(
            (int(part.get("item_id", 0) or 0), int(part.get("count", 0) or 0))
            for part in (row.get("components") or ())
        )
        if not components or any(item <= 0 or count <= 0 for item, count in components):
            return None
        return CompositionRecipe(
            target, components, max(0, int(row.get("mana", 0) or 0)),
            "emblem_heart"
        )

class AwakeningCompositionProvider:
    def __init__(self,data_dir:Path,source)->None:
        raw=json.loads((Path(data_dir)/"hero_equipment_meta.json").read_text(encoding="utf-8")); self.items=raw.get("items") or {}
        allowed=set()
        for atype in (1,2):
            routes=source.rows(atype)
            for row in routes.values():
                if int(row.get("stage",0) or 0)!=1: continue
                gear=int(row.get("item",0) or 0)
                if gear>0: allowed.add(gear)
                material=int(row.get("awaken_material",0) or 0)
                if material>0: allowed.add(material)
                if gear>0:
                    meta=self.items.get(str(gear)) or {}; comp=meta.get("compose") or []
                    if comp and int(comp[0] or 0)>0:
                        first=int(comp[0]); firstmeta=self.items.get(str(first)) or {}
                        if firstmeta.get("compose") and int((firstmeta.get("compose") or [0])[0] or 0)>0: allowed.add(first)
        self.allowed=frozenset(allowed)
    def resolve(self,item_id:int)->CompositionRecipe|None:
        if item_id not in self.allowed:return None
        row=self.items.get(str(item_id)) or {}; comp=[int(v or 0) for v in (row.get("compose") or [])]; nums=[int(v or 0) for v in (row.get("compose_num") or [])]
        if not comp or comp[0]<=0 or len(comp)!=len(nums):return None
        pairs=tuple((i,n) for i,n in zip(comp,nums) if i>0 and n>0)
        if len(pairs)!=len(comp):return None
        return CompositionRecipe(item_id,pairs,max(0,int(row.get("compose_mana",0) or 0)),"awakening")

class ItemCompositionService:
    def __init__(self,player,*,inventory:InventoryRepository,settlement:MutationSettlementService,uow:UnitOfWork,providers:tuple[CompositionProvider,...])->None:
        self.player=player; self.inventory=inventory; self.settlement=settlement; self.uow=uow; self.providers=providers
    @staticmethod
    def _int(v,d=0):
        try:return int(v)
        except (TypeError,ValueError):return d
    def compose(self,req:dict[str,Any])->dict[str,Any]:
        item_id=self._int(req.get("item_id")); item_num=self._int(req.get("item_num",1),1)
        if item_id<=0 or item_num<=0:return {"error_code":1}
        recipe=next((r for p in self.providers if (r:=p.resolve(item_id)) is not None),None)
        if recipe is None:return {"awards":[]}
        if recipe.single_owned:
            if item_num!=1:return {"error_code":1}
            if self.inventory.get_item_num(item_id)>0:return {}
        ops=[]
        for component,count in recipe.components: ops.append(StackMutation(component,"DEBIT",count*item_num))
        if recipe.mana>0: ops.append(ResourceMutation("mana","DEBIT",recipe.mana*item_num))
        ops.append(StackMutation(item_id,"CREDIT",item_num))
        ctx=OperationContext(actor_player_id=str(self.player.player_id),domain=recipe.provider,operation_name="compose_item",protocol_mid=83)
        try:
            with self.uow.transaction(ctx):
                self.settlement.apply(MutationPlan(schema_version=1,plan_id=f"compose:{recipe.provider}:{item_id}:{self.uow.current_state_version}",origin=MutationOrigin(domain=recipe.provider,operation="compose_item",protocol_mid=83),actor=ActorRef(player_id=str(self.player.player_id)),expected_state_version=None,idempotency=IdempotencySpec(),preconditions=(),operations=tuple(ops)))
        except MutationSettlementError:return {"error_code":1}
        return {}
