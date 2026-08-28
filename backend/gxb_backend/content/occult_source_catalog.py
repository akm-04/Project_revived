"""Immutable effective-src64 Occult/Sorcery War source authority (Pass211 Stage F)."""
from __future__ import annotations
import copy, json
from pathlib import Path
from types import MappingProxyType
from typing import Any, Mapping
from .p1_source_common import EXPECTED_SOURCE_SHA256

class OccultSourceCatalog:
    SCHEMA_VERSION=1
    EXPECTED_CHAPTERS=6
    EXPECTED_AWAKENING_ROUTES=22
    def __init__(self,data_dir:Path)->None:
        self.path=Path(data_dir)/'occult_source_catalog.json'
        raw=json.loads(self.path.read_text(encoding='utf-8'))
        meta=raw.get('_meta') or {}; counts=raw.get('counts') or {}; constants=raw.get('constants') or {}
        if int(raw.get('schema_version',0) or 0)!=1 or int(meta.get('schema_version',0) or 0)!=1: raise ValueError('invalid OccultSourceCatalog schema')
        if meta.get('source_resolution')!='effective_src64' or meta.get('epistemic_class')!='SOURCE_FACT_ONLY': raise ValueError('OccultSourceCatalog source authority drift')
        if meta.get('source_archive_sha256')!=EXPECTED_SOURCE_SHA256 or int(meta.get('effective_src64_file_count',0) or 0)!=4370: raise ValueError('OccultSourceCatalog asset authority drift')
        if int(counts.get('chapters',0) or 0)!=6 or int(counts.get('ordinary_awakening_routes',0) or 0)!=22: raise ValueError('OccultSourceCatalog census drift')
        self.ticket_energy_threshold=int(constants.get('ticket_energy_threshold',0) or 0)
        self.ticket_cap=int(constants.get('ticket_cap',0) or 0)
        self.sweep_reward_rate_raw=float(constants.get('sweep_reward_rate_raw',0) or 0)
        self.dispatch_hero_limit=int(constants.get('dispatch_hero_limit',0) or 0)
        if (self.ticket_energy_threshold,self.ticket_cap,self.sweep_reward_rate_raw)!=(3000,2,0.6): raise ValueError('Occult source constants drift')
        chapters={};
        for row in raw.get('chapters') or []:
            if not isinstance(row,dict): raise ValueError('invalid Occult chapter row')
            cid=int(row.get('chapter_id',0) or 0)
            if cid<=0 or cid in chapters: raise ValueError('invalid/duplicate Occult chapter')
            chapters[cid]=MappingProxyType(copy.deepcopy(row))
        routes={};
        for key,row in (raw.get('awakening_routes') or {}).items():
            mid=int(key)
            if not isinstance(row,dict) or int(row.get('mission_id',0) or 0)!=mid: raise ValueError('invalid Occult Awakening route')
            routes[mid]=MappingProxyType(copy.deepcopy(row))
        if len(chapters)!=6 or len(routes)!=22: raise ValueError('Occult source maps drift')
        if any(int(r.get('awaken_num_raw',0) or 0)!=30 for r in routes.values()): raise ValueError('Occult raw awaken_num drift')
        self._meta=MappingProxyType(copy.deepcopy(meta)); self._chapters=MappingProxyType(chapters); self._routes=MappingProxyType(routes)
    @property
    def metadata(self)->Mapping[str,Any]: return self._meta
    @property
    def chapters(self)->Mapping[int,Mapping[str,Any]]: return self._chapters
    @property
    def routes(self)->Mapping[int,Mapping[str,Any]]: return self._routes
    def chapter(self,chapter_id:Any)->Mapping[str,Any]|None:
        try:return self._chapters.get(int(chapter_id))
        except (TypeError,ValueError):return None
    def awakening_route(self,mission_id:Any)->Mapping[str,Any]|None:
        try:return self._routes.get(int(mission_id))
        except (TypeError,ValueError):return None
