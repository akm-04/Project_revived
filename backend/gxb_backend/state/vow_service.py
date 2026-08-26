"""Source-bounded Vow/Super Partner acquisition and essence exchange.

MID305/MID306 complete the Institute -> Vows acquisition tab while reusing the
existing HeroRepository, StackInventory and PlayerUnitOfWork authorities.
"""
from __future__ import annotations
from typing import Any

from gxb_backend.content.game_data_catalog import CatalogNamespace, ContentRef, GameDataCatalog
from gxb_backend.content.vow_source_catalog import VowSourceCatalog, VowTemplate
from .hero_repository import HeroRepository
from .stack_inventory import StackInventory, StackInventoryError
from .unit_of_work import OperationContext, PlayerUnitOfWork

class VowServiceError(ValueError): pass

class VowService:
    PARTNER_TYPE_SUPER = 2
    def __init__(self, player, source:VowSourceCatalog, catalog:GameDataCatalog, heroes:HeroRepository, stacks:StackInventory, uow:PlayerUnitOfWork):
        self.player=player; self.source=source; self.catalog=catalog; self.heroes=heroes; self.stacks=stacks; self.uow=uow

    @staticmethod
    def _int(v, default=0):
        try: return int(v)
        except (TypeError,ValueError): return default

    def _vow(self, table_id:Any)->VowTemplate:
        row=self.source.get(table_id)
        if row is None or not self.catalog.exists(ContentRef(CatalogNamespace.SUPER_PARTNER, self._int(table_id))):
            raise VowServiceError(f'unknown Vow table_id {table_id!r}')
        return row

    def _owned_by_table(self, table_id:int):
        self.heroes.normalize()
        candidates=[]
        for hero in self.player.heroes.values():
            if isinstance(hero,dict) and self._int(hero.get('table_id'))==int(table_id):
                candidates.append(hero)
        if not candidates: return None
        return min(candidates, key=lambda h:self._int(h.get('partner_id'), 1<<60))

    def _material_hero(self, base_table_id:int):
        # Stock SuperPartnerWindow prefers the exact table first, then afterAwaken.
        exact=self._owned_by_table(base_table_id)
        if exact is not None: return exact
        row=self.catalog.maybe_get(ContentRef(CatalogNamespace.PARTNER, int(base_table_id)))
        awaken=self._int(row.get('awaken_table_id')) if row is not None else 0
        return self._owned_by_table(awaken) if awaken>0 else None

    def summon_super_hero(self, table_id:Any)->dict:
        row=self._vow(table_id)
        # Natural exactly-once retry: a Vow is unique by source table_id in the
        # acquisition UI. If the response was lost after commit, return the same
        # owned entity instead of creating another partner_id.
        existing=self._owned_by_table(row.table_id)
        if existing is not None:
            return {'partner_info': dict(existing)}

        materials=[]
        exact_five_star=0
        for material_id in row.material_hero:
            hero=self._material_hero(material_id)
            if hero is None:
                raise VowServiceError(f'missing required Vow material hero {material_id}')
            materials.append(hero)
            if self._int(hero.get('star'))==5:
                exact_five_star += 1
        if exact_five_star <= 0:
            raise VowServiceError('Vow summon requires at least one exactly 5-star material hero')

        context=OperationContext(actor_player_id=str(self.player.player_id), domain='vows', operation_name='summon_super_hero', protocol_mid=305, idempotency_key=f'vow:{row.table_id}')
        with self.uow.transaction(context):
            # Current recovered client performs no prerequisite removal on MID305
            # success. Preserve them and materialize the source-shaped Vow star as
            # the count of prerequisite heroes that are exactly 5-star.
            created=self.heroes.add_owned_hero({
                'table_id':row.table_id,
                'star':exact_five_star,
                'partner_type':self.PARTNER_TYPE_SUPER,
                'lev':1,
                'exp':0,
            }, persist=False)
            self.uow.mark_changed('heroes')
        return {'partner_info': dict(created)}

    def exchange_essence(self, table_id:Any, times:Any)->dict:
        row=self._vow(table_id)
        n=self._int(times)
        if n<=0: raise VowServiceError('times must be positive')
        cost=self.source.exchange_cost*n
        context=OperationContext(actor_player_id=str(self.player.player_id), domain='vows', operation_name='super_hero_stone_exchange', protocol_mid=306)
        try:
            with self.uow.transaction(context):
                self.stacks.apply_deltas({self.source.essence_item_id:-cost, row.scroll_id:n}, persist=False)
        except StackInventoryError as exc:
            raise VowServiceError(str(exc)) from exc
        return {'awards':[{'table_id':row.scroll_id,'item_num':n}]}
