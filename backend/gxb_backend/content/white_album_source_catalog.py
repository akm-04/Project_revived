"""Immutable effective-src_64 authority for P1 White Album."""
from __future__ import annotations
from pathlib import Path
from typing import Any, Mapping
from .p1_source_common import freeze_rows, load_source_json

class WhiteAlbumSourceCatalog:
    def __init__(self,data_dir:Path):
        raw=load_source_json(data_dir,"p1_white_album_source_catalog.json"); tables=raw.get("tables") or {}
        self.normal=freeze_rows(tables.get("normal")); self.special=freeze_rows(tables.get("special"))
        if len(self.normal)!=132 or len(self.special)!=23: raise ValueError("White Album source census drift")
        if set(self.special)!=set(range(1,24)): raise ValueError("White Album special ids drift")
        if {int(r.get("type",0) or 0) for r in self.special.values()}!={1}: raise ValueError("White Album effective special type drift")
    def origin(self,table_id:Any)->Mapping[str,Any]|None:
        try:return self.normal.get(int(table_id))
        except (TypeError,ValueError):return None
    @staticmethod
    def _pipe_ints(value:Any)->tuple[int,...]:
        if isinstance(value,(list,tuple)):
            raw=value
        else:
            raw=str(value or "").split("|")
        out=[]
        for item in raw:
            try:
                number=int(item)
            except (TypeError,ValueError):
                continue
            if number>0: out.append(number)
        return tuple(out)
    def special_set(self,set_id:Any)->Mapping[str,Any]|None:
        try:return self.special.get(int(set_id))
        except (TypeError,ValueError):return None
    def quality_stages(self,table_id:Any)->tuple[int,...]:
        row=self.origin(table_id)
        return self._pipe_ints(row.get("quality")) if row else ()
    def star_stages(self,table_id:Any)->tuple[int,...]:
        row=self.origin(table_id)
        return self._pipe_ints(row.get("star")) if row else ()
    def special_partner_ids(self,set_id:Any)->tuple[int,...]:
        row=self.special_set(set_id)
        return self._pipe_ints(row.get("partner_id")) if row else ()
