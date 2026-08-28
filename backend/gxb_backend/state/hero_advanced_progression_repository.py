"""Pass73 source-bounded advanced Hero/Girls progression owner.

Deterministic planes whose client-visible costs/state transitions are complete in
effective src_64 are migrated into the existing PlayerUnitOfWork + MutationPlan
architecture:
- SuperHero post-5 evolution (shared MID52)
- SuperHero six-slot equipment + duplicate enhancement (MID54/MID304)
- ordinary equipment Fumo refinement (MID58)
- Element Equipment equip/strengthen/unload/decompose (MID2849-2853)
- deterministic Inscription insert/remove (MID1402/MID1403)
- deterministic Stone Evolution point/stage transitions (MID2608/MID2609)

Server-hidden candidate generation families (Practice rerolls, Inscription make/
rebuild, Horcrux instance generation) remain explicit PRIVATE_SERVER_POLICY or
fail-closed boundaries rather than being fabricated from client weights.
"""
from __future__ import annotations

from collections import Counter
from collections.abc import Callable
import json
from pathlib import Path
from typing import Any

from .hero_repository import HeroRepository
from .element_equipment_eligibility_policy import ElementEquipmentEligibilityPolicy
from .inventory_repository import InventoryRepository
from .mutation_plan import ActorRef, EntityMutation, IdempotencySpec, MutationOrigin, MutationPlan, ResourceMutation, StackMutation
from .mutation_settlement_service import MutationSettlementError, MutationSettlementService
from .player_state import PlayerState
from .unit_of_work import OperationContext, UnitOfWork


class HeroAdvancedProgressionRepository:
    def __init__(
        self,
        player: PlayerState,
        data_dir: Path,
        save_callback: Callable[[], None] | None = None,
        *,
        inventory: InventoryRepository,
        heroes: HeroRepository,
        uow: UnitOfWork | None,
        settlement: MutationSettlementService | None,
        element_eligibility: ElementEquipmentEligibilityPolicy | None = None,
    ) -> None:
        self.player = player
        self.data_dir = Path(data_dir)
        self._save_callback = save_callback
        self.inventory = inventory
        self.heroes = heroes
        self.uow = uow
        self.settlement = settlement
        self.element_eligibility = element_eligibility
        self.meta = self._load("hero_advanced_progression_meta.json")
        self.equip_meta = self._load("hero_equipment_meta.json")
        self.super_partners = self.meta.get("super_partners") or {}
        self.super_stars = self.meta.get("super_stars") or {}
        self.super_enhance = self.meta.get("super_equip_enhance") or {}
        self.advanced_items = self.meta.get("advanced_items") or {}
        self.element_equips = self.meta.get("element_equips") or {}
        self.element_strength = self.meta.get("element_strength") or {}
        self.inscription_item_to_type = self.meta.get("inscription_item_to_type") or {}
        self.inscription_exchange_materials = tuple(self.meta.get("inscription_exchange_materials") or ())
        self.partner_stones = self.meta.get("partner_stones") or {}
        self.stone_evolution = self.meta.get("stone_evolution") or {}
        self.stone_tickets = self.meta.get("stone_tickets") or {}
        self.remove_inscription_crystal = self._int(self.meta.get("remove_inscription_crystal"), 20)
        self.live_super_max_star = self._int(self.meta.get("live_super_max_star"), 8)
        self.element_max_rank = self._int(self.meta.get("element_max_rank"), 10)

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try: return int(value)
        except (TypeError, ValueError): return default

    def _load(self, filename: str) -> dict[str, Any]:
        try:
            raw=json.loads((self.data_dir/filename).read_text(encoding="utf-8"))
            return raw if isinstance(raw,dict) else {}
        except Exception as exc:
            print(f"[HERO ADVANCED] could not load {filename}: {exc}")
            return {}

    def is_super(self, hero: dict[str,Any] | None) -> bool:
        return bool(hero and str(self._int(hero.get("table_id"),0)) in self.super_partners)

    def _apply(self, *, mid:int, operation:str, partner_id:int, operations: tuple[Any,...]) -> bool:
        if self.uow is None or self.settlement is None: return False
        ctx=OperationContext(actor_player_id=str(self.player.player_id),domain="hero_advanced_progression",operation_name=operation,protocol_mid=mid)
        try:
            with self.uow.transaction(ctx):
                self.settlement.apply(MutationPlan(
                    schema_version=1,
                    plan_id=f"hero-advanced:{mid}:{partner_id}:{operation}:{self.uow.current_state_version}",
                    origin=MutationOrigin(domain="hero_advanced_progression",operation=operation,protocol_mid=mid),
                    actor=ActorRef(player_id=str(self.player.player_id)),
                    expected_state_version=None,idempotency=IdempotencySpec(),preconditions=(),operations=operations,
                ))
            return True
        except MutationSettlementError:
            return False

    def super_evolve(self, req: dict[str,Any]) -> dict[str,Any]:
        """Shared MID52 post-5 SuperHero evolution, live cap star 8."""
        pid=self._int(req.get("partner_id"),0); hero=self.heroes.get(pid)
        if not self.is_super(hero): return {"error_code":1}
        current=self._int(hero.get("star"),0); target=current+1
        if current < 5 or target>self.live_super_max_star: return {"error_code":1}
        row=self.super_stars.get(str(target)) or {}
        mana=max(0,self._int(row.get("mana_cost"),0)); stones=max(0,self._int(row.get("stone_cost"),0))
        sp=self.super_partners.get(str(self._int(hero.get("table_id"),0))) or {}; stone_id=self._int(sp.get("stone_id"),0)
        ops=[]
        if stones>0:
            if stone_id<=0: return {"error_code":1}
            ops.append(StackMutation(stone_id,"DEBIT",stones))
        if mana>0: ops.append(ResourceMutation("mana","DEBIT",mana))
        ops.append(EntityMutation("HERO",pid,"EVOLVE_STAR",amount=1))
        return {} if self._apply(mid=52,operation="super_evolve",partner_id=pid,operations=tuple(ops)) else {"error_code":1}

    def super_set_equip(self, partner_id:Any, equip_index:Any) -> dict[str,Any]:
        pid=self._int(partner_id,0); slot=self._int(equip_index,0); hero=self.heroes.get(pid)
        if not self.is_super(hero) or not 1<=slot<=6: return {"error_code":1}
        sp=self.super_partners.get(str(self._int(hero.get("table_id"),0))) or {}; eq=list(sp.get("equipment") or [])
        if len(eq)<slot: return {"error_code":1}
        item=self._int(eq[slot-1],0); equips=list(hero.get("equips") or [0]*6)
        while len(equips)<6: equips.append(0)
        if item<=0 or self._int(equips[slot-1],0)!=0: return {"error_code":1}
        ops=(StackMutation(item,"DEBIT",1),EntityMutation("HERO",pid,"SET_SUPER_EQUIP",indices=(slot,)))
        return {} if self._apply(mid=54,operation="super_set_equip",partner_id=pid,operations=ops) else {"error_code":1}

    def super_one_click_equip(self, partner_id:Any) -> dict[str,Any]:
        pid=self._int(partner_id,0); hero=self.heroes.get(pid)
        if not self.is_super(hero): return {"error_code":1}
        sp=self.super_partners.get(str(self._int(hero.get("table_id"),0))) or {}; items=list(sp.get("equipment") or [])
        equips=list(hero.get("equips") or [0]*6); equips=(equips+[0]*6)[:6]
        ops=[]; slots=[]
        for i,item in enumerate(items[:6],start=1):
            item=self._int(item,0)
            if item>0 and self._int(equips[i-1],0)==0 and self.inventory.get_item_num(item)>0:
                ops.append(StackMutation(item,"DEBIT",1)); slots.append(i)
        if not slots: return {"equips":equips}
        ops.append(EntityMutation("HERO",pid,"SET_SUPER_EQUIP",indices=tuple(slots)))
        if not self._apply(mid=62,operation="super_one_click_equip",partner_id=pid,operations=tuple(ops)): return {"error_code":1}
        return {"equips":list((self.heroes.get(pid) or hero).get("equips") or [0]*6)[:6]}

    def super_enhance_equip(self, req:dict[str,Any])->dict[str,Any]:
        pid=self._int(req.get("partner_id"),0); slot=self._int(req.get("equip_index"),0); times=self._int(req.get("enhance_times"),0); hero=self.heroes.get(pid)
        if not self.is_super(hero) or not 1<=slot<=6 or times<=0: return {"error_code":1}
        star=self._int(hero.get("star"),0); star_row=self.super_stars.get(str(star)) or {}; cap=self._int(star_row.get("equipment_limit"),0)
        equips=(list(hero.get("equips") or [])+[0]*6)[:6]; raw=self._int(equips[slot-1],0)
        if raw<=0: return {"error_code":1}
        current_level=raw-1
        if current_level+times>cap: return {"error_code":1}
        sp=self.super_partners.get(str(self._int(hero.get("table_id"),0))) or {}; item=self._int((sp.get("equipment") or [0]*6)[slot-1],0)
        if item<=0: return {"error_code":1}
        needed=0
        for level in range(current_level+1,current_level+times+1):
            tier=(level+9)//10; row=self.super_enhance.get(str(tier)) or {}
            if self._int(row.get("need_star"),999)>star: return {"error_code":1}
            needed += max(0,self._int(row.get("need_num"),0))
        if needed<=0: return {"error_code":1}
        ops=(StackMutation(item,"DEBIT",needed),EntityMutation("HERO",pid,"ENHANCE_SUPER_EQUIP",amount=times,indices=(slot,)))
        return {} if self._apply(mid=304,operation="super_enhance_equip",partner_id=pid,operations=ops) else {"error_code":1}

    def _normal_equip_item_id(self, hero:dict[str,Any],slot:int)->int:
        if self.is_super(hero): return 0
        partners=self.equip_meta.get("partners") or {}; row=partners.get(str(self._int(hero.get("table_id"),0))) or {}; lists=row.get("equip_lists") or {}; ids=list(lists.get(str(self._int(hero.get("color"),1))) or [])
        return self._int(ids[slot-1],0) if 1<=slot<=len(ids) else 0

    def fumo(self, req:dict[str,Any])->dict[str,Any]:
        pid=self._int(req.get("partner_id"),0); slot=self._int(req.get("equip_index"),0); hero=self.heroes.get(pid); materials=req.get("materials")
        if hero is None or self.is_super(hero) or not 1<=slot<=6 or not isinstance(materials,(list,tuple)) or not materials: return {"error_code":1}
        equips=(list(hero.get("equips") or [])+[0]*6)[:6]
        if self._int(equips[slot-1],0)<=0: return {"error_code":1}
        target=self._normal_equip_item_id(hero,slot); target_meta=self.advanced_items.get(str(target)) or {}; thresholds=[self._int(v,0) for v in target_meta.get("fumo_thresholds",[]) if self._int(v,0)>0]
        mana_per=max(0,self._int(target_meta.get("fumo_mana"),0)); cap=sum(thresholds)
        fumos=(list(hero.get("fumos") or [])+[0]*6)[:6]; old=max(0,self._int(fumos[slot-1],0))
        if cap<=0 or old>=cap or mana_per<=0: return {"error_code":1}
        counts=Counter(self._int(v,0) for v in materials); counts.pop(0,None); raw_gain=0
        for item_id,count in counts.items():
            row=self.advanced_items.get(str(item_id)) or {}; mon=max(0,self._int(row.get("moneng"),0))
            if mon<=0: return {"error_code":1}
            raw_gain += mon*count
        gain=min(raw_gain,cap-old)
        if gain<=0: return {"error_code":1}
        new_total=old+gain; remain=new_total; level=0
        for need in thresholds:
            if remain>=need: remain-=need; level+=1
            else: break
        ops=[StackMutation(i,"DEBIT",c) for i,c in sorted(counts.items())]
        ops.extend((ResourceMutation("mana","DEBIT",gain*mana_per),EntityMutation("HERO",pid,"APPLY_FUMO",amount=gain,indices=(slot,),counts=(level,))))
        if not self._apply(mid=58,operation="fumo",partner_id=pid,operations=tuple(ops)): return {"error_code":1}
        refreshed=self.heroes.get(pid) or hero
        return {"fumo":self._int((refreshed.get("fumos") or [0]*6)[slot-1],0),"fumo_lev":[self._int(v,0) for v in (refreshed.get("fumo_levels") or [0]*6)[:6]]}

    @staticmethod
    def _pipe(values:Any)->str:
        return "|".join(str(int(v or 0)) for v in list(values or []))

    def _element_payload(self, hero:dict[str,Any])->dict[str,Any]:
        return {"element_equips":self._pipe((list(hero.get("element_equips") or [])+[0]*4)[:4]),"element_levels":self._pipe((list(hero.get("element_levels") or [])+[0]*4)[:4]),"element_bak_equips":self._pipe(hero.get("element_bak_equips") or []),"element_bak_levels":self._pipe(hero.get("element_bak_levels") or [])}

    def _element_hero_access(self, hero:dict[str,Any] | None)->bool:
        if hero is None:
            return False
        if self.element_eligibility is None:
            return True
        return self.element_eligibility.normal_common_eligible(hero,is_super=self.is_super(hero))

    def element_equip(self, req:dict[str,Any])->dict[str,Any]:
        pid=self._int(req.get("partner_id"),0); eid=self._int(req.get("equip_id"),0); pos=self._int(req.get("equip_pos"),0); hero=self.heroes.get(pid); meta=self.element_equips.get(str(eid)) or {}
        if hero is None or not meta or not 1<=pos<=4 or not self._element_hero_access(hero): return {"error_code":1}
        if self.element_eligibility is not None:
            if not self.element_eligibility.position_accepts(hero,meta,pos): return {"error_code":1}
        else:
            restricted=self._int(meta.get("partner_id"),0); table_id=self._int(hero.get("table_id"),0)
            if restricted and restricted!=table_id: return {"error_code":1}
        backups=list(hero.get("element_bak_equips") or []); from_backup=eid in [self._int(v,0) for v in backups]
        ops=[]
        if not from_backup:
            base=self._int(meta.get("item_id"),0)
            if base<=0: return {"error_code":1}
            ops.append(StackMutation(base,"DEBIT",1))
        ops.append(EntityMutation("HERO",pid,"ELEMENT_EQUIP",indices=(pos,eid)))
        if not self._apply(mid=2849,operation="element_equip",partner_id=pid,operations=tuple(ops)): return {"error_code":1}
        return self._element_payload(self.heroes.get(pid) or hero)

    def _element_location(self,hero:dict[str,Any],eid:int)->tuple[str,int,int] | None:
        equipped=(list(hero.get("element_equips") or [])+[0]*4)[:4]; levels=(list(hero.get("element_levels") or [])+[0]*4)[:4]
        for i,v in enumerate(equipped):
            if self._int(v,0)==eid: return ("equipped",i,self._int(levels[i],0))
        backups=list(hero.get("element_bak_equips") or []); bl=list(hero.get("element_bak_levels") or [])
        for i,v in enumerate(backups):
            if self._int(v,0)==eid: return ("backup",i,self._int(bl[i] if i<len(bl) else 0,0))
        return None

    def _element_costs(self, level:int, equip_type:int, *, decompose:bool)->list[tuple[int,int]]:
        row=self.element_strength.get(str(level)) or {}; prefix="dec" if decompose else "strth"; ids=list(row.get(f"{prefix}_mtrs{equip_type}") or []); nums=list(row.get(f"{prefix}_nums{equip_type}") or [])
        return [(self._int(i,0),self._int(nums[n],0) if n<len(nums) else 0) for n,i in enumerate(ids) if self._int(i,0)>0 and n<len(nums) and self._int(nums[n],0)>0]

    def element_strengthen(self, req:dict[str,Any])->dict[str,Any]:
        pid=self._int(req.get("partner_id"),0); eid=self._int(req.get("equip_id"),0); hero=self.heroes.get(pid); meta=self.element_equips.get(str(eid)) or {}
        if hero is None or not meta or not self._element_hero_access(hero): return {"error_code":1}
        loc=self._element_location(hero,eid)
        if loc is None or loc[2]>=self.element_max_rank: return {"error_code":1}
        costs=self._element_costs(loc[2],self._int(meta.get("equip_type"),0),decompose=False)
        if not costs: return {"error_code":1}
        ops=[StackMutation(i,"DEBIT",n) for i,n in costs]; ops.append(EntityMutation("HERO",pid,"ELEMENT_STRENGTHEN",indices=(eid,)))
        if not self._apply(mid=2850,operation="element_strengthen",partner_id=pid,operations=tuple(ops)): return {"error_code":1}
        return self._element_payload(self.heroes.get(pid) or hero)

    def element_unload(self,req:dict[str,Any])->dict[str,Any]:
        pid=self._int(req.get("partner_id"),0); pos=self._int(req.get("equip_pos"),0); hero=self.heroes.get(pid)
        if hero is None or not 1<=pos<=4 or not self._element_hero_access(hero): return {"error_code":1}
        eq=(list(hero.get("element_equips") or [])+[0]*4)[:4]
        if self._int(eq[pos-1],0)<=0: return {"error_code":1}
        if not self._apply(mid=2851,operation="element_unload",partner_id=pid,operations=(EntityMutation("HERO",pid,"ELEMENT_UNLOAD",indices=(pos,)),)): return {"error_code":1}
        return self._element_payload(self.heroes.get(pid) or hero)

    def _decompose_ops(self,eid:int,level:int)->list[StackMutation] | None:
        meta=self.element_equips.get(str(eid)) or {}; costs=self._element_costs(level,self._int(meta.get("equip_type"),0),decompose=True)
        return [StackMutation(i,"CREDIT",n) for i,n in costs] if costs else None

    def element_destroy_on_hero(self,req:dict[str,Any])->dict[str,Any]:
        pid=self._int(req.get("partner_id"),0); eid=self._int(req.get("equip_id"),0); hero=self.heroes.get(pid)
        if hero is None or not self._element_hero_access(hero): return {"error_code":1}
        loc=self._element_location(hero,eid)
        if loc is None: return {"error_code":1}
        credits=self._decompose_ops(eid,loc[2])
        if credits is None: return {"error_code":1}
        ops=tuple(credits+[EntityMutation("HERO",pid,"ELEMENT_DESTROY",indices=(eid,))])
        if not self._apply(mid=2852,operation="element_destroy_on_hero",partner_id=pid,operations=ops): return {"error_code":1}
        return self._element_payload(self.heroes.get(pid) or hero)

    def element_destroy_backpack(self,req:dict[str,Any])->dict[str,Any]:
        eid=self._int(req.get("equip_id"),0); meta=self.element_equips.get(str(eid)) or {}; base=self._int(meta.get("item_id"),0)
        if base<=0: return {"error_code":1}
        credits=self._decompose_ops(eid,0)
        if credits is None or self.uow is None or self.settlement is None: return {"error_code":1}
        ops=tuple([StackMutation(base,"DEBIT",1),*credits])
        return {} if self._apply(mid=2853,operation="element_destroy_backpack",partner_id=0,operations=ops) else {"error_code":1}

    def _inscription_pos(self, item_id: int) -> int:
        inscription_id=self._int(self.inscription_item_to_type.get(str(item_id)),0)
        return self._int((self.meta.get("inscriptions") or {}).get(str(inscription_id),{}).get("item_pos"),0) if inscription_id>0 else 0

    def _equipped_inscription_for_pos(self, hero: dict[str,Any], pos: int) -> int:
        for value in self._inscription_response(hero):
            if self._inscription_pos(value)==pos:
                return value
        return 0

    def inscription_insert(self,req:dict[str,Any])->dict[str,Any]:
        pid=self._int(req.get("partner_id"),0); item=self._int(req.get("item_id"),0); replace=self._int(req.get("replace_item_id"),0); hero=self.heroes.get(pid)
        if hero is None: return {"error_code":1}
        item_pos=self._inscription_pos(item)
        if item_pos<=0: return {"error_code":1}
        current=self._equipped_inscription_for_pos(hero,item_pos)
        if current>0 and replace<=0: return {"error_code":1}
        if replace>0 and current!=replace: return {"error_code":1}
        ops=[StackMutation(item,"DEBIT",1)]
        if replace>0:
            ops.extend((ResourceMutation("crystal","DEBIT",self.remove_inscription_crystal),StackMutation(replace,"CREDIT",1)))
        ops.append(EntityMutation("HERO",pid,"INSCRIPTION_INSERT",indices=(item_pos,item,replace)))
        if not self._apply(mid=1402,operation="inscription_insert",partner_id=pid,operations=tuple(ops)): return {"error_code":1}
        return {"inscript_items":self._inscription_response(self.heroes.get(pid) or hero)}

    def _inscription_response(self,hero:dict[str,Any])->list[int]:
        raw=hero.get("inscript_items") or []
        if isinstance(raw,(list,tuple)):
            return [self._int(v,0) for v in raw if self._int(v,0)>0]
        if isinstance(raw,dict):
            # Compatibility migration for any hand-edited older state. Values
            # are emitted as the source expects: a dense item-id array.
            return [self._int(v,0) for _,v in sorted(raw.items(),key=lambda kv:self._int(kv[0],0)) if self._int(v,0)>0]
        return []

    def inscription_remove(self,req:dict[str,Any])->dict[str,Any]:
        pid=self._int(req.get("partner_id"),0); item=self._int(req.get("item_id"),0); hero=self.heroes.get(pid)
        if hero is None: return {"error_code":1}
        pos=self._inscription_pos(item)
        if pos<=0 or self._equipped_inscription_for_pos(hero,pos)!=item: return {"error_code":1}
        ops=(ResourceMutation("crystal","DEBIT",self.remove_inscription_crystal),StackMutation(item,"CREDIT",1),EntityMutation("HERO",pid,"INSCRIPTION_REMOVE",indices=(pos,item)))
        if not self._apply(mid=1403,operation="inscription_remove",partner_id=pid,operations=ops): return {"error_code":1}
        return {"inscript_items":self._inscription_response(self.heroes.get(pid) or hero)}


    def inscription_resolve(self, req:dict[str,Any])->dict[str,Any]:
        """MID1404 deterministic emblem dissolve.

        Inscription.lua removes the dissolved emblem locally on OK. The source
        resolve-material identifiers 19/20/21 are scalar certificate balances,
        not Backpack item IDs, so persist STACK debit + RESOURCE credit and let
        the Pass70 journal-aware economy projector reconcile the new cumulative
        certificate balance exactly once.
        """
        item=self._int(req.get("item_id"),0); count=self._int(req.get("resolve_num"),0)
        ins_id=self._int(self.inscription_item_to_type.get(str(item)),0)
        row=(self.meta.get("inscriptions") or {}).get(str(ins_id)) or {}
        material=self._int(row.get("resolve_material"),0); per=max(0,self._int(row.get("resolve_num"),0))
        if item<=0 or count<=0 or material<=0 or per<=0: return {"error_code":1}
        total=per*count
        # Inscription material IDs 19/20/21 are not Backpack item IDs.
        # Inscription:getMaterialNumByID maps them to SelfPlayer degreeCer /
        # graduateCer / patentCer, which are the scalar-ledger wire keys
        # degree_cer / graduate_cer / patent_cer.  Let the Pass70 journal-aware
        # projector emit the cumulative economy_ value; emitting extra_drops_
        # would incorrectly create a Backpack item with table_id 19/20/21.
        resource_by_material={19:"degree_cer",20:"graduate_cer",21:"patent_cer"}
        resource_key=resource_by_material.get(material)
        if resource_key is None: return {"error_code":1}
        ops=(StackMutation(item,"DEBIT",count),ResourceMutation(resource_key,"CREDIT",total))
        if not self._apply(mid=1404,operation="inscription_resolve",partner_id=0,operations=ops): return {"error_code":1}
        return {}

    def inscription_exchange_materials_all(self, req:dict[str,Any])->dict[str,Any]:
        """MID1407: exchange all held source materials into certificate ledgers.

        Effective Inscription.lua sends an empty request and snapshots every held
        stack from misc.inscript_cost_items before the request. item.lua's
        economic_value maps those three items to currency IDs 19/20/21 at 5 per
        material.  The mutation is one atomic StackInventory + ResourceMutation
        plan; the ordinary response projector emits cumulative economy_ balances.
        """
        if not isinstance(req,dict): return {"error_code":1}
        resource_by_currency={19:"degree_cer",20:"graduate_cer",21:"patent_cer"}
        ops=[]; changes=[]
        for row in self.inscription_exchange_materials:
            if not isinstance(row,dict): return {"error_code":1}
            item_id=self._int(row.get("item_id"),0); currency=self._int(row.get("currency_id"),0); per=max(0,self._int(row.get("per_item"),0))
            resource=resource_by_currency.get(currency)
            if item_id<=0 or resource is None or per<=0: return {"error_code":1}
            count=max(0,self.inventory.get_item_num(item_id))
            if count<=0: continue
            change=count*per
            ops.extend((StackMutation(item_id,"DEBIT",count),ResourceMutation(resource,"CREDIT",change)))
            changes.append({"currency":currency,"change":change})
        if not ops:
            return {"currency_change":[]}
        if not self._apply(mid=1407,operation="inscription_exchange_materials",partner_id=0,operations=tuple(ops)):
            return {"error_code":1}
        return {"currency_change":changes}

    def _daily_consume_state(self)->dict[str,Any]:
        # Pass79: DailyResetCoordinator is the sole owner of source-day
        # rollover. This repository only owns consume counters within the
        # already-materialized day and must never calculate UTC/local days.
        root=self.player.daily_consume_state if isinstance(self.player.daily_consume_state,dict) else {}
        self.player.daily_consume_state=root
        counts=root.setdefault("counts",{})
        if not isinstance(counts,dict): root["counts"]={}
        return root

    def daily_consume_load(self)->dict[str,Any]:
        state=self._daily_consume_state(); counts=state.get("counts") or {}
        # Source DailyConsumeType is 1..10 and older consumers split this pipe.
        values=[self._int(counts.get(str(i)),0) for i in range(1,11)]
        return {"buy_times":"|".join(str(v) for v in values),"awards":[],"point":0,"items":[]}

    def quick_fumo(self, req:dict[str,Any])->dict[str,Any]:
        """MID29 consume_id=2: 20 Crystals for 150 Fumo, once per day."""
        if self._int(req.get("consume_id"),0)!=2: return {"error_code":1}
        pid=self._int(req.get("partner_id"),0); slot=self._int(req.get("equip_index"),0); hero=self.heroes.get(pid)
        if hero is None or self.is_super(hero) or not 1<=slot<=6: return {"error_code":1}
        state=self._daily_consume_state(); counts=state.get("counts") or {}
        if self._int(counts.get("2"),0)>=1: return {"error_code":1,"msg":"daily_consume_limit"}
        equips=(list(hero.get("equips") or [])+[0]*6)[:6]
        if self._int(equips[slot-1],0)<=0: return {"error_code":1}
        target=self._normal_equip_item_id(hero,slot); target_meta=self.advanced_items.get(str(target)) or {}
        thresholds=[self._int(v,0) for v in target_meta.get("fumo_thresholds",[]) if self._int(v,0)>0]; cap=sum(thresholds)
        fumos=(list(hero.get("fumos") or [])+[0]*6)[:6]; old=max(0,self._int(fumos[slot-1],0))
        gain=min(150,max(0,cap-old))
        if cap<=0 or gain<=0: return {"error_code":1}
        new_total=old+gain; remain=new_total; level=0
        for need in thresholds:
            if remain>=need: remain-=need; level+=1
            else: break
        ops=(ResourceMutation("crystal","DEBIT",20),EntityMutation("HERO",pid,"APPLY_FUMO",amount=gain,indices=(slot,),counts=(level,)))
        if self.uow is None or self.settlement is None: return {"error_code":1}
        ctx=OperationContext(actor_player_id=str(self.player.player_id),domain="hero_advanced_progression",operation_name="quick_fumo",protocol_mid=29)
        try:
            with self.uow.transaction(ctx):
                self.settlement.apply(MutationPlan(schema_version=1,plan_id=f"hero-advanced:29:{pid}:quick_fumo:{self.uow.current_state_version}",origin=MutationOrigin(domain="hero_advanced_progression",operation="quick_fumo",protocol_mid=29),actor=ActorRef(player_id=str(self.player.player_id)),expected_state_version=None,idempotency=IdempotencySpec(),preconditions=(),operations=ops))
                state=self._daily_consume_state(); state.setdefault("counts",{})["2"]=1
                self.uow.request_save()
        except MutationSettlementError:
            return {"error_code":1}
        refreshed=self.heroes.get(pid) or hero
        return {"fumo":self._int((refreshed.get("fumos") or [0]*6)[slot-1],0)}

    def _stone_owner_row(self, hero: dict[str,Any]) -> dict[str,Any]:
        table_id=self._int(hero.get("table_id"),0)
        if self.is_super(hero):
            return dict(self.super_partners.get(str(table_id)) or {})
        return dict(self.partner_stones.get(str(table_id)) or {})

    def _evo_info(self, hero: dict[str,Any]) -> dict[str,Any]:
        points=hero.get("evo_attr_points") if isinstance(hero.get("evo_attr_points"),dict) else {}
        return {
            "evo_attr_points": {str(k): self._int(v,0) for k,v in points.items() if self._int(v,0)>=0},
            "evo_stage": max(1,self._int(hero.get("evo_stage"),1)),
        }

    def _stone_reject(self, hero: dict[str,Any] | None, reason: str) -> dict[str,Any]:
        """Return a client-safe rejected Stone Evolution response.

        Effective SelfPlayer.lua gates its mutation block on transport status,
        not JSON ``error_code``.  Backend.lua reports every HTTP-200 engine
        response as xyd.error.OK, so a body containing only ``error_code`` makes
        breachStoneAdd/breachStoneEvolve dereference a nil ``evo_info``.  Keep
        the server transaction fail-closed, but include the unchanged canonical
        evo_info so the callback is shape-safe and the visible Hero state cannot
        become nil/corrupt.  MID2608's client may temporarily decrement its local
        cost-item count on such a rejected request; the server does not debit it,
        and the next authoritative Backpack hydration repairs that client-local
        discrepancy.  We intentionally do not fabricate a reward/refund popup.
        """
        body: dict[str,Any] = {"error_code":1, "msg":str(reason)}
        if isinstance(hero,dict):
            body["evo_info"] = self._evo_info(hero)
        return body

    def breach_stone_add(self, req:dict[str,Any])->dict[str,Any]:
        """MID2608: debit one source-authorized stone family and add stage points.

        SelfPlayer:breachStoneAdd removes ``cost_item`` locally on OK, so the
        response carries only authoritative ``evo_info`` while STACK settlement
        remains silent in projection.
        """
        pid=self._int(req.get("partner_id"),0); attr=self._int(req.get("attr_id"),0); add_num=self._int(req.get("add_num"),0); cost_item=self._int(req.get("cost_item"),0)
        hero=self.heroes.get(pid)
        if hero is None: return self._stone_reject(None,"stone_hero_missing")
        if attr<=0 or add_num<=0 or cost_item<=0: return self._stone_reject(hero,"stone_request_invalid")
        stage=max(1,self._int(hero.get("evo_stage"),1)); stage_row=self.stone_evolution.get(str(stage)) or {}
        allowed_attrs=[self._int(v,0) for v in list(stage_row.get("attrs") or [])]
        limit=max(0,self._int(stage_row.get("limit_num"),0)); need_level=self._int(stage_row.get("level"),0); need_star=self._int(stage_row.get("star"),0)
        if attr not in allowed_attrs or limit<=0: return self._stone_reject(hero,"stone_attr_or_stage_invalid")
        if self._int(hero.get("lev"),0)<need_level or self._int(hero.get("star"),0)<need_star: return self._stone_reject(hero,"stone_stage_requirement_not_met")
        points=hero.get("evo_attr_points") if isinstance(hero.get("evo_attr_points"),dict) else {}; current=max(0,self._int(points.get(str(attr)),0))
        if current+add_num>limit: return self._stone_reject(hero,"stone_attr_limit")
        owner=self._stone_owner_row(hero); own_stone=self._int(owner.get("stone_id"),0); ticket_type=self._int(owner.get("stone_ticket"),0)
        allowed_items={own_stone} if own_stone>0 else set()
        allowed_items.update(self._int(v,0) for v in list(self.stone_tickets.get(str(ticket_type)) or []))
        allowed_items.discard(0)
        if cost_item not in allowed_items: return self._stone_reject(hero,"stone_cost_item_invalid")
        ops=(StackMutation(cost_item,"DEBIT",add_num),EntityMutation("HERO",pid,"STONE_EVOLUTION_ADD",amount=add_num,indices=(attr,)))
        if not self._apply(mid=2608,operation="breach_stone_add",partner_id=pid,operations=ops): return self._stone_reject(hero,"stone_settlement_rejected")
        return {"evo_info":self._evo_info(self.heroes.get(pid) or hero)}

    def breach_stone_evolve(self, req:dict[str,Any])->dict[str,Any]:
        """MID2609: advance a fully-filled Stone Evolution stage.

        HeroMainWindow gates the button by the *next* stage's level/star row.
        The client receives and installs a fresh ``evo_info``; current-stage
        point counters reset because cumulative prior-stage stats are derived by
        StoneEvolutionTable, not carried forward in ``evo_attr_points``.
        """
        pid=self._int(req.get("partner_id"),0); hero=self.heroes.get(pid)
        if hero is None: return self._stone_reject(None,"stone_hero_missing")
        stage=max(1,self._int(hero.get("evo_stage"),1)); max_stage=max((self._int(k,0) for k in self.stone_evolution.keys()),default=0)
        if stage<=0 or stage>=max_stage: return self._stone_reject(hero,"stone_stage_maxed_or_invalid")
        current_row=self.stone_evolution.get(str(stage)) or {}; next_row=self.stone_evolution.get(str(stage+1)) or {}
        attrs=[self._int(v,0) for v in list(current_row.get("attrs") or [])]; limit=max(0,self._int(current_row.get("limit_num"),0)); points=hero.get("evo_attr_points") if isinstance(hero.get("evo_attr_points"),dict) else {}
        if not attrs or limit<=0 or any(self._int(points.get(str(attr)),0)<limit for attr in attrs): return self._stone_reject(hero,"stone_stage_incomplete")
        if self._int(hero.get("lev"),0)<self._int(next_row.get("level"),0) or self._int(hero.get("star"),0)<self._int(next_row.get("star"),0): return self._stone_reject(hero,"stone_next_stage_requirement_not_met")
        ops=(EntityMutation("HERO",pid,"STONE_EVOLUTION_STAGE_UP",amount=1),)
        if not self._apply(mid=2609,operation="breach_stone_evolve",partner_id=pid,operations=ops): return self._stone_reject(hero,"stone_stage_settlement_rejected")
        return {"evo_info":self._evo_info(self.heroes.get(pid) or hero)}

