"""Immutable effective-src_64 authority for P1 Element Equipment invariants."""
from __future__ import annotations
import copy
from pathlib import Path
from types import MappingProxyType
from typing import Any, Mapping
from .p1_source_common import freeze_rows, load_source_json

class ElementEquipmentSourceCatalog:
    NORMAL=1; CORE=2; SP_CORE=3
    def __init__(self,data_dir:Path):
        raw=load_source_json(data_dir,"p1_element_source_catalog.json"); tables=raw.get("tables") or {}
        rows=freeze_rows(tables.get("element_equip")); self.by_row_id=rows
        self.by_item_id=MappingProxyType({int(r.get("item_id",0) or 0):r for r in rows.values()})
        strength=tables.get("element_strth") or []
        self.strength_rows=tuple(MappingProxyType(copy.deepcopy(dict(r))) for r in strength if isinstance(r,dict))
        if len(rows)!=80 or len(self.by_item_id)!=80 or len(self.strength_rows)!=11: raise ValueError("Element source census drift")
        dist={t:sum(1 for r in rows.values() if int(r.get("equip_type",0) or 0)==t) for t in (1,2,3)}
        if dist!={1:18,2:6,3:56}: raise ValueError("Element equip type distribution drift")
    def item(self,item_id:Any)->Mapping[str,Any]|None:
        try:return self.by_item_id.get(int(item_id))
        except (TypeError,ValueError):return None
