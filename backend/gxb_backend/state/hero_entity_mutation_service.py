"""Typed Hero aggregate mutation owner (Pass72 + Pass73 advanced progression).

ENTITY remains a bounded domain-verb family.  Pass73 extends the Hero aggregate
with source-complete advanced equipment/refinement verbs; arbitrary dictionary
patches are still forbidden.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from .hero_progression_repository import HeroProgressionRepository
from .hero_repository import HeroRepository
from .mutation_plan import EntityMutation
from .unit_of_work import PlayerUnitOfWork


class HeroEntityMutationError(ValueError):
    pass


@dataclass(frozen=True)
class HeroEntityChange:
    action: str
    entity_id: int
    before: dict[str, Any]
    after: dict[str, Any]
    delta: int | None = None


class HeroEntityMutationService:
    ENTITY_TYPE = "HERO"
    _ACTIONS = {
        "EVOLVE_STAR", "ADD_EXP", "SET_EQUIP_SLOTS", "PROMOTE_COLOR", "UPGRADE_SKILLS",
        "SET_SUPER_EQUIP", "ENHANCE_SUPER_EQUIP", "APPLY_FUMO",
        "ELEMENT_EQUIP", "ELEMENT_STRENGTHEN", "ELEMENT_UNLOAD", "ELEMENT_DESTROY",
        "INSCRIPTION_INSERT", "INSCRIPTION_REMOVE",
        "STONE_EVOLUTION_ADD", "STONE_EVOLUTION_STAGE_UP", "AWAKEN_TABLE_ID", "SET_TWICE_AWAKE_STAGE",
    }

    def __init__(self, heroes: HeroRepository, progression: HeroProgressionRepository, uow: PlayerUnitOfWork) -> None:
        self.heroes=heroes; self.progression=progression; self.uow=uow

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try: return int(value)
        except (TypeError, ValueError): return default

    @classmethod
    def _fixed(cls,value:Any,n:int,default:int=0)->list[int]:
        raw=list(value) if isinstance(value,(list,tuple)) else []
        out=[cls._int(v,default) for v in raw[:n]]
        while len(out)<n: out.append(default)
        return out

    @classmethod
    def _fixed_six(cls,value:Any,default:int)->list[int]: return cls._fixed(value,6,default)

    def _hero(self, entity_id:int)->dict[str,Any]:
        hero=self.heroes.get(entity_id)
        if hero is None: raise HeroEntityMutationError(f"Hero entity {entity_id} does not exist")
        return hero

    def validate(self,op:EntityMutation)->EntityMutation:
        if str(op.entity_type).upper()!=self.ENTITY_TYPE: raise HeroEntityMutationError(f"unsupported Hero entity type {op.entity_type!r}")
        eid=self._int(op.entity_id,0)
        if eid<=0: raise HeroEntityMutationError("Hero entity_id must be positive")
        hero=self._hero(eid); action=str(op.action).upper()
        if action not in self._ACTIONS: raise HeroEntityMutationError(f"unsupported Hero ENTITY action {op.action!r}")
        if action=="EVOLVE_STAR":
            if self._int(op.amount,0)!=1 or self._int(hero.get("star"),0)<=0: raise HeroEntityMutationError("EVOLVE_STAR requires amount=1 and positive star")
        elif action=="ADD_EXP":
            if self._int(op.amount,0)<=0: raise HeroEntityMutationError("ADD_EXP requires positive amount")
        elif action in {"SET_EQUIP_SLOTS","SET_SUPER_EQUIP"}:
            slots=tuple(self._int(v,0) for v in op.indices)
            if not slots or any(v<1 or v>6 for v in slots) or len(set(slots))!=len(slots): raise HeroEntityMutationError(f"{action} requires unique slots 1..6")
        elif action=="ENHANCE_SUPER_EQUIP":
            if len(op.indices)!=1 or not 1<=self._int(op.indices[0],0)<=6 or self._int(op.amount,0)<=0: raise HeroEntityMutationError("ENHANCE_SUPER_EQUIP requires slot and positive amount")
        elif action=="APPLY_FUMO":
            if len(op.indices)!=1 or not 1<=self._int(op.indices[0],0)<=6 or self._int(op.amount,0)<=0 or len(op.counts)!=1 or self._int(op.counts[0],-1)<0: raise HeroEntityMutationError("APPLY_FUMO requires slot, positive gain, resulting level")
        elif action=="PROMOTE_COLOR":
            if self._int(op.amount,0)!=1 or self._int(hero.get("color"),0)<=0: raise HeroEntityMutationError("PROMOTE_COLOR requires amount=1 and positive color")
        elif action=="UPGRADE_SKILLS":
            idx=tuple(self._int(v,0) for v in op.indices); cnt=tuple(self._int(v,0) for v in op.counts)
            if not idx or len(idx)!=len(cnt) or any(v<1 or v>6 for v in idx) or any(v<=0 for v in cnt) or len(set(idx))!=len(idx): raise HeroEntityMutationError("UPGRADE_SKILLS requires unique indexes 1..6 with positive counts")
        elif action=="ELEMENT_EQUIP":
            if len(op.indices)!=2 or not 1<=self._int(op.indices[0],0)<=4 or self._int(op.indices[1],0)<=0: raise HeroEntityMutationError("ELEMENT_EQUIP requires position 1..4 and equip id")
        elif action=="ELEMENT_STRENGTHEN":
            if len(op.indices)!=1 or self._int(op.indices[0],0)<=0: raise HeroEntityMutationError("ELEMENT_STRENGTHEN requires equip id")
        elif action=="ELEMENT_UNLOAD":
            if len(op.indices)!=1 or not 1<=self._int(op.indices[0],0)<=4: raise HeroEntityMutationError("ELEMENT_UNLOAD requires position 1..4")
        elif action=="ELEMENT_DESTROY":
            if len(op.indices)!=1 or self._int(op.indices[0],0)<=0: raise HeroEntityMutationError("ELEMENT_DESTROY requires equip id")
        elif action=="INSCRIPTION_INSERT":
            if len(op.indices)!=3 or self._int(op.indices[0],0)<=0 or self._int(op.indices[1],0)<=0: raise HeroEntityMutationError("INSCRIPTION_INSERT requires pos,item,replace")
        elif action=="INSCRIPTION_REMOVE":
            if len(op.indices)!=2 or self._int(op.indices[0],0)<=0 or self._int(op.indices[1],0)<=0: raise HeroEntityMutationError("INSCRIPTION_REMOVE requires pos,item")
        elif action=="STONE_EVOLUTION_ADD":
            if len(op.indices)!=1 or self._int(op.indices[0],0)<=0 or self._int(op.amount,0)<=0: raise HeroEntityMutationError("STONE_EVOLUTION_ADD requires attr id and positive amount")
        elif action=="STONE_EVOLUTION_STAGE_UP":
            if self._int(op.amount,0)!=1 or op.indices or op.counts: raise HeroEntityMutationError("STONE_EVOLUTION_STAGE_UP requires amount=1")
        elif action=="AWAKEN_TABLE_ID":
            if len(op.indices)!=1 or self._int(op.indices[0],0)<=0 or op.counts: raise HeroEntityMutationError("AWAKEN_TABLE_ID requires target table id")
        elif action=="SET_TWICE_AWAKE_STAGE":
            if self._int(op.amount,-1) not in (0,1,2,3) or op.indices or op.counts: raise HeroEntityMutationError("SET_TWICE_AWAKE_STAGE requires stage 0..3")
        return op

    @classmethod
    def _summary(cls,hero:dict[str,Any])->dict[str,Any]:
        return {
            "partner_id":cls._int(hero.get("partner_id"),0),"table_id":cls._int(hero.get("table_id"),0),"star":cls._int(hero.get("star"),0),
            "lev":cls._int(hero.get("lev"),0),"exp":cls._int(hero.get("exp"),0),"color":cls._int(hero.get("color"),0),
            "skills":cls._fixed(hero.get("skills"),6,1),"equips":cls._fixed(hero.get("equips"),6,0),
            "fumos":cls._fixed(hero.get("fumos"),6,0),"fumo_levels":cls._fixed(hero.get("fumo_levels"),6,0),
            "element_equips":cls._fixed(hero.get("element_equips"),4,0),"element_levels":cls._fixed(hero.get("element_levels"),4,0),
            "element_bak_equips":[cls._int(v,0) for v in list(hero.get("element_bak_equips") or [])],"element_bak_levels":[cls._int(v,0) for v in list(hero.get("element_bak_levels") or [])],
            "inscript_items":[cls._int(v,0) for v in list(hero.get("inscript_items") or [])] if isinstance(hero.get("inscript_items"),(list,tuple)) else [],
            "evo_stage":cls._int(hero.get("evo_stage"),1),
            "twice_awake_stage":cls._int(hero.get("twice_awake_stage"),0),
            "evo_attr_points":{str(k):cls._int(v,0) for k,v in dict(hero.get("evo_attr_points") or {}).items()} if isinstance(hero.get("evo_attr_points"),dict) else {},
        }

    def apply(self,op:EntityMutation)->HeroEntityChange:
        self.validate(op); eid=self._int(op.entity_id,0); hero=self._hero(eid); before=self._summary(hero); action=str(op.action).upper(); delta=None
        if action=="EVOLVE_STAR":
            hero["star"]=self._int(hero.get("star"),0)+1; table_id=self._int(hero.get("table_id"),0); collected=self.heroes.player.collected_heros.get(str(table_id))
            if isinstance(collected,dict): collected["star"]=max(self._int(collected.get("star"),0),self._int(hero["star"])); collected["is_collected"]=1
            delta=1
        elif action=="ADD_EXP":
            gain=self._int(op.amount,0); old=self.progression.normalized_total_exp(hero); new=self.progression.grant_exp_amount(eid,gain,persist=False)
            if new is None: raise HeroEntityMutationError("ADD_EXP could not mutate Hero")
            delta=int(new)-int(old)
        elif action in {"SET_EQUIP_SLOTS","SET_SUPER_EQUIP"}:
            equips=self._fixed_six(hero.get("equips"),0); changed=0
            for slot in op.indices:
                i=self._int(slot,0)-1
                if equips[i]==0: equips[i]=1; changed+=1
            hero["equips"]=equips; delta=changed
        elif action=="ENHANCE_SUPER_EQUIP":
            equips=self._fixed_six(hero.get("equips"),0); i=self._int(op.indices[0],0)-1
            if equips[i]<=0: raise HeroEntityMutationError("cannot enhance unequipped SuperHero item")
            equips[i]+=self._int(op.amount,0); hero["equips"]=equips; delta=self._int(op.amount,0)
        elif action=="APPLY_FUMO":
            fumos=self._fixed_six(hero.get("fumos"),0); levels=self._fixed_six(hero.get("fumo_levels"),0); i=self._int(op.indices[0],0)-1
            fumos[i]+=self._int(op.amount,0); levels[i]=self._int(op.counts[0],0); hero["fumos"]=fumos; hero["fumo_levels"]=levels; delta=self._int(op.amount,0)
        elif action=="PROMOTE_COLOR":
            hero["color"]=self._int(hero.get("color"),0)+1; hero["equips"]=[0]*6; hero["fumos"]=[0]*6; hero["fumo_levels"]=[0]*6; delta=1
        elif action=="UPGRADE_SKILLS":
            skills=self._fixed_six(hero.get("skills"),1); total=0
            for index,count in zip(op.indices,op.counts): skills[self._int(index,0)-1]+=self._int(count,0); total+=self._int(count,0)
            hero["skills"]=skills; delta=total
        elif action=="ELEMENT_EQUIP":
            pos=self._int(op.indices[0],0)-1; new_id=self._int(op.indices[1],0); eq=self._fixed(hero.get("element_equips"),4,0); lv=self._fixed(hero.get("element_levels"),4,0); bak=[self._int(v,0) for v in list(hero.get("element_bak_equips") or [])]; baklv=[self._int(v,0) for v in list(hero.get("element_bak_levels") or [])]
            while len(baklv)<len(bak): baklv.append(0)
            new_level=0
            if new_id in bak:
                idx=bak.index(new_id); new_level=baklv[idx]; bak.pop(idx); baklv.pop(idx)
            old_id,old_level=eq[pos],lv[pos]
            if old_id>0: bak.append(old_id); baklv.append(old_level)
            eq[pos]=new_id; lv[pos]=new_level; hero["element_equips"]=eq; hero["element_levels"]=lv; hero["element_bak_equips"]=bak; hero["element_bak_levels"]=baklv; delta=1
        elif action=="ELEMENT_STRENGTHEN":
            target=self._int(op.indices[0],0); eq=self._fixed(hero.get("element_equips"),4,0); lv=self._fixed(hero.get("element_levels"),4,0); bak=[self._int(v,0) for v in list(hero.get("element_bak_equips") or [])]; baklv=[self._int(v,0) for v in list(hero.get("element_bak_levels") or [])]
            changed=False
            for i,v in enumerate(eq):
                if v==target: lv[i]+=1; changed=True; break
            if not changed:
                for i,v in enumerate(bak):
                    if v==target:
                        while len(baklv)<=i: baklv.append(0)
                        baklv[i]+=1; changed=True; break
            if not changed: raise HeroEntityMutationError("element equip id not owned by Hero")
            hero["element_levels"]=lv; hero["element_bak_levels"]=baklv; delta=1
        elif action=="ELEMENT_UNLOAD":
            pos=self._int(op.indices[0],0)-1; eq=self._fixed(hero.get("element_equips"),4,0); lv=self._fixed(hero.get("element_levels"),4,0); bak=[self._int(v,0) for v in list(hero.get("element_bak_equips") or [])]; baklv=[self._int(v,0) for v in list(hero.get("element_bak_levels") or [])]
            if eq[pos]<=0: raise HeroEntityMutationError("element slot already empty")
            bak.append(eq[pos]); baklv.append(lv[pos]); eq[pos]=0; lv[pos]=0; hero["element_equips"]=eq; hero["element_levels"]=lv; hero["element_bak_equips"]=bak; hero["element_bak_levels"]=baklv; delta=1
        elif action=="ELEMENT_DESTROY":
            target=self._int(op.indices[0],0); eq=self._fixed(hero.get("element_equips"),4,0); lv=self._fixed(hero.get("element_levels"),4,0); bak=[self._int(v,0) for v in list(hero.get("element_bak_equips") or [])]; baklv=[self._int(v,0) for v in list(hero.get("element_bak_levels") or [])]; changed=False
            for i,v in enumerate(eq):
                if v==target: eq[i]=0; lv[i]=0; changed=True; break
            if not changed and target in bak:
                i=bak.index(target); bak.pop(i); 
                if i<len(baklv): baklv.pop(i)
                changed=True
            if not changed: raise HeroEntityMutationError("element equip id not owned by Hero")
            hero["element_equips"]=eq; hero["element_levels"]=lv; hero["element_bak_equips"]=bak; hero["element_bak_levels"]=baklv; delta=1
        elif action=="INSCRIPTION_INSERT":
            pos,item,replace=(self._int(v,0) for v in op.indices); items=[self._int(v,0) for v in list(hero.get("inscript_items") or [])] if isinstance(hero.get("inscript_items"),(list,tuple)) else []
            if replace>0:
                try: items.remove(replace)
                except ValueError: raise HeroEntityMutationError("replace inscription not equipped")
            items.append(item); hero["inscript_items"]=items; delta=1
        elif action=="INSCRIPTION_REMOVE":
            _pos,item=(self._int(v,0) for v in op.indices); items=[self._int(v,0) for v in list(hero.get("inscript_items") or [])] if isinstance(hero.get("inscript_items"),(list,tuple)) else []
            try: items.remove(item)
            except ValueError: raise HeroEntityMutationError("inscription not equipped")
            hero["inscript_items"]=items; delta=-1
        elif action=="STONE_EVOLUTION_ADD":
            attr=self._int(op.indices[0],0); amount=self._int(op.amount,0); points=dict(hero.get("evo_attr_points") or {}) if isinstance(hero.get("evo_attr_points"),dict) else {}
            key=str(attr); points[key]=self._int(points.get(key),0)+amount; hero["evo_attr_points"]=points; delta=amount
        elif action=="STONE_EVOLUTION_STAGE_UP":
            hero["evo_stage"]=self._int(hero.get("evo_stage"),1)+1; hero["evo_attr_points"]={}; delta=1
        elif action=="AWAKEN_TABLE_ID":
            old_table=self._int(hero.get("table_id"),0); target=self._int(op.indices[0],0)
            if target<=0 or target==old_table: raise HeroEntityMutationError("invalid awakening target")
            hero["table_id"]=target
            old_collected=self.heroes.player.collected_heros.get(str(old_table))
            if isinstance(old_collected,dict): old_collected["is_collected"]=1
            new_collected=self.heroes.player.collected_heros.setdefault(str(target),{})
            if isinstance(new_collected,dict):
                new_collected["table_id"]=target; new_collected["is_collected"]=1; new_collected["star"]=max(self._int(new_collected.get("star"),0),self._int(hero.get("star"),0))
            delta=target
        elif action=="SET_TWICE_AWAKE_STAGE":
            stage=self._int(op.amount,0); hero["twice_awake_stage"]=stage; delta=stage
        else: raise HeroEntityMutationError(f"unsupported Hero action {action}")
        self.uow.request_save(); after=self._summary(hero); return HeroEntityChange(action,eid,before,after,delta)
