"""Permanent Girl skin ownership/equip state for MID60/MID61/MID2979.

Source boundary: MID60 is dual-purpose. A new permanent skin item unlocks ownership
and consumes one physical item while preserving the currently equipped skin;
an already-owned permanent skin switches equipment without consuming an item.
MID61 unequips the skill/current-skin axis while preserving ownership. MID2979
selects the distinct illusion/cosmetic appearance axis without consuming inventory.
Temporary skin acquisition/expiry and Pet MID60 overload remain out of this service.
"""
from __future__ import annotations
from typing import Any
from gxb_backend.content.skin_source_catalog import SkinSourceCatalog, SkinSourceRow
from .hero_repository import HeroRepository
from .stack_inventory import StackInventory, StackInventoryError
from .unit_of_work import OperationContext, PlayerUnitOfWork

class SkinOwnershipError(ValueError): pass

class SkinOwnershipService:
    HERO_SLICE='heroes'
    def __init__(self, player, catalog:SkinSourceCatalog, heroes:HeroRepository, stacks:StackInventory, uow:PlayerUnitOfWork):
        self.player=player; self.catalog=catalog; self.heroes=heroes; self.stacks=stacks; self.uow=uow
    @staticmethod
    def _i(v,d=0):
        try:return int(v)
        except:return d
    @staticmethod
    def _ownership(raw:Any)->tuple[set[int],dict[str,int],str]:
        """Return permanent models, timed map, and original shape kind."""
        permanent=set(); timed={}
        if isinstance(raw,list):
            for v in raw:
                try:
                    n=int(v)
                    if n>0: permanent.add(n)
                except: pass
            return permanent,timed,'list'
        if isinstance(raw,dict):
            for k,v in raw.items():
                try:model=int(k); expiry=int(v)
                except: continue
                if model<=0: continue
                if expiry==-1: permanent.add(model)
                else: timed[str(model)]=expiry
            return permanent,timed,'dict'
        return permanent,timed,'list'
    @staticmethod
    def _serialize(permanent:set[int],timed:dict[str,int],shape:str):
        if shape=='dict' or timed:
            out={str(k):int(v) for k,v in timed.items()}
            for model in sorted(permanent): out[str(model)]=-1
            return out
        return sorted(permanent)
    def _hero_and_row(self,partner_id:Any,item_id:Any)->tuple[dict,SkinSourceRow]:
        hero=self.heroes.get(partner_id)
        if hero is None: raise SkinOwnershipError('hero_not_owned')
        row=self.catalog.skin(item_id)
        if row is None: raise SkinOwnershipError('skin_item_not_supported_permanent_girl_skin')
        table_id=self._i(hero.get('table_id'))
        if table_id not in row.accepted_hero_table_ids:
            raise SkinOwnershipError('skin_does_not_belong_to_hero')
        return hero,row
    def ownership_state_for_item(self, item_id: Any) -> dict[str, Any]:
        """Read permanent/timed ownership for one canonical Girl skin item.

        This is a read-only Commerce availability helper. It never grants,
        consumes, equips, or opens a transaction.
        """
        row = self.catalog.skin(item_id)
        if row is None:
            return {"supported": False, "hero_owned": False, "permanent": False, "timed": False}
        matches = []
        for hero in self.player.heroes.values():
            if not isinstance(hero, dict):
                continue
            if self._i(hero.get("table_id")) not in row.accepted_hero_table_ids:
                continue
            permanent, timed, _shape = self._ownership(hero.get("skin_ids"))
            matches.append({
                "partner_id": self._i(hero.get("partner_id")),
                "permanent": row.model_id in permanent,
                "timed": str(row.model_id) in timed,
            })
        return {
            "supported": True,
            "hero_owned": bool(matches),
            "permanent": any(x["permanent"] for x in matches),
            "timed": any(x["timed"] for x in matches),
            "matches": matches,
            "model_id": int(row.model_id),
            "skin_item_id": int(row.skin_item_id),
        }

    def grant_permanent_skin_item(self, item_id: Any) -> dict[str, Any] | None:
        """Grant permanent ownership to an already-owned matching Girl.

        Phase C Commerce calls this only inside its existing active UoW. If the
        player does not own a matching Girl, return ``None`` so Commerce can
        grant the physical skin item through RewardTransactionService instead.
        Temporary ownership of the same model remains unresolved/fail-closed.
        """
        if not self.uow.active:
            raise SkinOwnershipError("permanent_skin_grant_requires_active_uow")
        row = self.catalog.skin(item_id)
        if row is None:
            raise SkinOwnershipError("skin_item_not_supported_permanent_girl_skin")
        matches = []
        for hero in self.player.heroes.values():
            if isinstance(hero, dict) and self._i(hero.get("table_id")) in row.accepted_hero_table_ids:
                matches.append(hero)
        if not matches:
            return None
        # getHeroIgnoreAwaken() resolves one owned representative of the source
        # Hero ID. Prefer the lowest partner_id deterministically if duplicates
        # exist in preservation state.
        hero = min(matches, key=lambda h: self._i(h.get("partner_id"), 2**31 - 1))
        permanent, timed, shape = self._ownership(hero.get("skin_ids"))
        if str(row.model_id) in timed and row.model_id not in permanent:
            raise SkinOwnershipError("temporary_skin_to_permanent_conversion_unresolved")
        if row.model_id in permanent:
            raise SkinOwnershipError("skin_already_owned")
        permanent.add(row.model_id)
        skin_ids = self._serialize(permanent, timed, shape)
        hero["skin_ids"] = skin_ids
        self.uow.mark_changed(self.HERO_SLICE)
        return {
            "partner_id": self._i(hero.get("partner_id")),
            "model_id": int(row.model_id),
            "skin_ids": skin_ids,
        }

    def skin_on(self,partner_id:Any,item_id:Any)->dict[str,Any]:
        try: hero,row=self._hero_and_row(partner_id,item_id)
        except SkinOwnershipError as exc: return {'error_code':1,'msg':str(exc)}
        permanent,timed,shape=self._ownership(hero.get('skin_ids'))
        model=row.model_id
        # Timed ownership of the same model is source-distinct; permanent conversion semantics are not recovered.
        if str(model) in timed and model not in permanent:
            return {'error_code':1,'msg':'temporary_skin_to_permanent_conversion_unresolved'}
        is_owned=model in permanent
        if not is_owned and self.stacks.quantity(row.skin_item_id)<1:
            return {'error_code':1,'msg':'skin_item_not_owned'}
        ctx=OperationContext(actor_player_id=str(self.player.player_id),protocol_mid=60,domain='skin',operation_name='skin_on')
        try:
            with self.uow.transaction(ctx):
                if is_owned:
                    hero['current_skin_id']=model
                    remove_item=0
                else:
                    self.stacks.apply_deltas({row.skin_item_id:-1},persist=False)
                    permanent.add(model)
                    hero['skin_ids']=self._serialize(permanent,timed,shape)
                    # Source HeroMainWindow activation deliberately preserves currently equipped skin.
                    hero['current_skin_id']=self._i(hero.get('current_skin_id'),0)
                    remove_item=1
                self.uow.mark_changed(self.HERO_SLICE)
                skin_ids=self._serialize(permanent,timed,shape)
                hero['skin_ids']=skin_ids
                return {'current_skin_id':self._i(hero.get('current_skin_id'),0),'skin_ids':skin_ids,'remove_item':remove_item}
        except (SkinOwnershipError,StackInventoryError) as exc:
            return {'error_code':1,'msg':str(exc)}
    def skin_cancel(self,partner_id:Any)->dict[str,Any]:
        hero=self.heroes.get(partner_id)
        if hero is None: return {'error_code':1,'msg':'hero_not_owned'}
        ctx=OperationContext(actor_player_id=str(self.player.player_id),protocol_mid=61,domain='skin',operation_name='skin_cancel')
        with self.uow.transaction(ctx):
            hero['current_skin_id']=0
            self.uow.mark_changed(self.HERO_SLICE)
            return {'current_skin_id':0,'skin_ids':hero.get('skin_ids',[])}
    def use_illusion_skin_item(self,partner_id:Any,item_id:Any)->dict[str,Any]:
        """MID2979: persist the source-distinct cosmetic appearance selector.

        Source HeroMainWindow sends sentinel item_id 0/1 for normal/awakened
        appearance and a permanent skin item id for a selected owned skin. The
        response callback consumes only ``illusion_skin_id``. This operation does
        not consume a physical skin item and does not alter ``current_skin_id``.
        """
        hero=self.heroes.get(partner_id)
        if hero is None: return {'error_code':1,'msg':'hero_not_owned'}
        requested=self._i(item_id,-1)
        if requested in (0,1):
            illusion_id=requested
        else:
            try: _hero,row=self._hero_and_row(partner_id,requested)
            except SkinOwnershipError as exc: return {'error_code':1,'msg':str(exc)}
            permanent,timed,_shape=self._ownership(hero.get('skin_ids'))
            if row.model_id not in permanent:
                if str(row.model_id) in timed:
                    return {'error_code':1,'msg':'temporary_skin_illusion_lifecycle_unresolved'}
                return {'error_code':1,'msg':'skin_not_unlocked'}
            illusion_id=row.model_id
        ctx=OperationContext(actor_player_id=str(self.player.player_id),protocol_mid=2979,domain='skin',operation_name='use_illusion_skin_item')
        with self.uow.transaction(ctx):
            hero['illusion_skin_id']=illusion_id
            self.uow.mark_changed(self.HERO_SLICE)
            return {'illusion_skin_id':illusion_id}
