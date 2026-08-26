"""Immutable source-derived Vow/Super Partner acquisition catalog."""
from __future__ import annotations
import json
from dataclasses import dataclass
from pathlib import Path

@dataclass(frozen=True)
class VowTemplate:
    table_id:int
    name:str
    material_hero:tuple[int,...]
    scroll_id:int
    ini_star:int
    equipment:tuple[int,...]
    stone_campaign:int

class VowSourceCatalog:
    SCHEMA_VERSION=1
    def __init__(self,data_dir:Path):
        p=Path(data_dir)/'vow_source_catalog.json'
        raw=json.loads(p.read_text(encoding='utf-8'))
        if int(raw.get('_meta',{}).get('schema_version',0))!=self.SCHEMA_VERSION: raise ValueError('unsupported Vow source catalog schema')
        self.essence_item_id=int(raw.get('essence_item_id',0)); self.exchange_cost=int(raw.get('essence_exchange_cost',0))
        self._rows={}
        for k,v in raw.get('vows',{}).items():
            row=VowTemplate(int(v['table_id']),str(v.get('name','')),tuple(int(x) for x in v.get('material_hero',[])),int(v.get('scroll_id',0)),int(v.get('ini_star',1)),tuple(int(x) for x in v.get('equipment',[])),int(v.get('stone_campaign',0)))
            if len(row.material_hero)!=5 or len(row.equipment)!=6: raise ValueError(f'invalid Vow row {k}')
            self._rows[row.table_id]=row
        if len(self._rows)!=14 or self.essence_item_id<=0 or self.exchange_cost<=0: raise ValueError('incomplete Vow source catalog')
    def get(self,table_id):
        try: return self._rows[int(table_id)]
        except (ValueError,TypeError,KeyError): return None
    def require(self,table_id):
        row=self.get(table_id)
        if row is None: raise ValueError(f'unknown Vow table_id {table_id!r}')
        return row
    def rows(self): return tuple(self._rows[k] for k in sorted(self._rows))
