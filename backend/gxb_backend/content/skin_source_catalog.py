"""Immutable source-derived permanent Girl skin catalog for MID60/MID61."""
from __future__ import annotations
from dataclasses import dataclass
import json
from pathlib import Path
from typing import Any

@dataclass(frozen=True)
class SkinSourceRow:
    skin_item_id:int
    skin_partner_id:int
    skin_skill_hero_id:int
    accepted_hero_table_ids:tuple[int,...]
    model_id:int
    skill_id:int
    rare:int
    sell_crystal:int
    stack:int

class SkinSourceCatalog:
    DATA_FILE='skin_source_catalog.json'
    def __init__(self,data_dir:Path|str):
        path=Path(data_dir)/self.DATA_FILE
        raw=json.loads(path.read_text(encoding='utf-8'))
        meta=raw.get('_meta') or {}
        if meta.get('source_resolution')!='effective_src64': raise RuntimeError('Skin catalog is not effective_src64')
        self.meta=dict(meta); self.summary=dict(raw.get('summary') or {}); self.deferred=dict(raw.get('deferred') or {})
        self._by_item={}; self._by_model={}
        for v in raw.get('skins') or []:
            row=SkinSourceRow(
                skin_item_id=int(v['skin_item_id']), skin_partner_id=int(v['skin_partner_id']),
                skin_skill_hero_id=int(v['skin_skill_hero_id']), accepted_hero_table_ids=tuple(int(x) for x in v['accepted_hero_table_ids']),
                model_id=int(v['model_id']), skill_id=int(v.get('skill_id',0)), rare=int(v.get('rare',0)),
                sell_crystal=int(v.get('sell_crystal',0)), stack=int(v.get('stack',0)),
            )
            if row.skin_item_id in self._by_item: raise RuntimeError(f'duplicate skin item {row.skin_item_id}')
            self._by_item[row.skin_item_id]=row; self._by_model.setdefault(row.model_id,[]).append(row)
        if len(self._by_item)!=262: raise RuntimeError(f'unexpected permanent skin count {len(self._by_item)}')
    def skin(self,item_id:Any)->SkinSourceRow|None:
        try:return self._by_item.get(int(item_id))
        except:return None
    def rows(self)->tuple[SkinSourceRow,...]: return tuple(self._by_item.values())
