"""Explicit EOL compatibility policy for P2 Awakening (Pass206 Stage B)."""
from __future__ import annotations
import json
from pathlib import Path
from types import MappingProxyType
from typing import Any, Mapping

class AwakeningCompatibilityPolicy:
    HERO=1; HERO_TWICE=2
    EVENT_COUNT=18
    def __init__(self,data_dir:Path)->None:
        path=Path(data_dir)/"awakening_compatibility_policy.json"
        raw=json.loads(path.read_text(encoding="utf-8"))
        if int(raw.get("schema_version",0) or 0)!=1: raise ValueError("invalid Awakening compatibility schema")
        rows=raw.get("event_entitlements")
        if not isinstance(rows,list) or len(rows)!=self.EVENT_COUNT: raise ValueError("Awakening event entitlement census drift")
        self._events={}
        for row in rows:
            if not isinstance(row,dict): raise ValueError("invalid Awakening event entitlement row")
            key=(int(row.get("awake_type",0) or 0),int(row.get("mission_id",0) or 0))
            if key in self._events: raise ValueError("duplicate Awakening event entitlement")
            self._events[key]=MappingProxyType(dict(row))
        wish=raw.get("wish_bottle") or {}
        self.wish_item_id=int(wish.get("item_id",0) or 0)
        self.wish_blacklist=frozenset(int(v) for v in (wish.get("blacklisted_intermediate_items") or []))
        if self.wish_item_id!=50005037 or len(self.wish_blacklist)!=11: raise ValueError("Awakening Wish Bottle policy drift")
    def event(self,awake_type:Any,mission_id:Any)->Mapping[str,Any]|None:
        try:return self._events.get((int(awake_type),int(mission_id)))
        except (TypeError,ValueError):return None
    @property
    def event_rows(self): return tuple(self._events.values())
    def wish_allowed(self,intermediate_item:Any)->bool:
        try:i=int(intermediate_item)
        except (TypeError,ValueError):return False
        return i>0 and i not in self.wish_blacklist
