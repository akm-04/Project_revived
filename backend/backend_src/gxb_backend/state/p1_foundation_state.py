"""Pass186 additive/load-time P1 state normalization and migration."""
from __future__ import annotations
from typing import Any
from gxb_backend.content import CatalogNamespace, ContentRef, GameDataCatalog
from gxb_backend.content.white_album_source_catalog import WhiteAlbumSourceCatalog
from gxb_backend.content.workshop_source_catalog import WorkshopSourceCatalog
from .player_state import PlayerState

class P1FoundationStateNormalizer:
    def __init__(self,player:PlayerState,*,album:WhiteAlbumSourceCatalog,workshop:WorkshopSourceCatalog,game_data:GameDataCatalog|None=None)->None:
        self.player=player; self.album=album; self.workshop=workshop; self.game_data=game_data
    @staticmethod
    def _int(value:Any,default:int=0)->int:
        try:return int(value)
        except (TypeError,ValueError):return default

    def _normal_hero(self,hero:dict[str,Any])->bool:
        if self.game_data is None:return True
        tid=self._int(hero.get("table_id"),0)
        return tid>0 and self.game_data.exists(ContentRef(CatalogNamespace.PARTNER,tid))

    def _normalize_study_infos(self)->bool:
        raw=self.player.study_infos
        if isinstance(raw,dict) and isinstance(raw.get("study_infos"),list): raw=raw.get("study_infos")
        rows=[]
        if isinstance(raw,list):
            for value in raw:
                if not isinstance(value,dict):continue
                row=dict(value)
                for key in ("partner_id","course_id","enter_time","start_time","need_time"):
                    if key in row:row[key]=max(0,self._int(row.get(key)))
                rows.append(row)
        if self.player.study_infos!=rows:
            self.player.study_infos=rows; return True
        return False

    def _normalize_album(self)->bool:
        raw=self.player.white_album_state if isinstance(self.player.white_album_state,dict) else {}
        claims=raw.get("special_claims") if isinstance(raw.get("special_claims"),dict) else {}
        normalized={}
        for sid in self.album.special:
            value=claims.get(str(sid),claims.get(sid,0))
            if self._int(value,0)>0: normalized[str(sid)]=1
        out=dict(raw); out["special_claims"]=normalized
        if self.player.white_album_state!=out:
            self.player.white_album_state=out; return True
        return False

    def _building_rows(self)->dict[str,dict[str,Any]]:
        raw=self.player.building_list; rows={}
        if isinstance(raw,dict):
            for key,value in raw.items():
                if isinstance(value,dict): rows[str(key)]=dict(value)
        elif isinstance(raw,list):
            for value in raw:
                if not isinstance(value,dict):continue
                bid=self._int(value.get("building_id",value.get("id")),0)
                if bid>0: rows[str(bid)]=dict(value)
        return rows

    def _normalize_workshop(self)->bool:
        changed=False
        rows=self._building_rows(); shelf_key=str(self.workshop.BOOKSHELF_BUILDING_TYPE); shelf=dict(rows.get(shelf_key) or {})
        building_level=max(1,min(100,self._int(shelf.get("lev"),1)))
        hero_level=0
        for hero in self.player.heroes.values() if isinstance(self.player.heroes,dict) else ():
            if isinstance(hero,dict) and self._normal_hero(hero): hero_level=max(hero_level,min(100,max(0,self._int(hero.get("book_shelf_lev"),0))))
        canonical=max(building_level,hero_level)
        shelf.update({"lev":canonical,"need_time":max(0,self._int(shelf.get("need_time"),0)),"start_time":max(0,self._int(shelf.get("start_time"),0)),"new_evolve":max(0,self._int(shelf.get("new_evolve"),0))})
        rows[shelf_key]=shelf
        if self.player.building_list!=rows:self.player.building_list=rows; changed=True
        for hero in self.player.heroes.values() if isinstance(self.player.heroes,dict) else ():
            if isinstance(hero,dict) and self._normal_hero(hero) and self._int(hero.get("book_shelf_lev"),0)!=canonical:
                hero["book_shelf_lev"]=canonical; changed=True

        raw=self.player.workshop_state if isinstance(self.player.workshop_state,dict) else {}
        book_info=raw.get("book_info") if isinstance(raw.get("book_info"),dict) else {}
        # Pass190/P1-I4B: effective EventCentre.getCabinetInfo consumes nested
        # book_info[book_id][skill_id].lev.  Monotonically migrate the earlier
        # unused flat skill_id->level placeholder instead of shadowing it.
        normalized_book={}
        def merge_skill(sid:int, level:int)->None:
            skill=self.workshop.cabinet_skill(sid)
            if skill is None:return
            book_id=self.workshop.cabinet_skill_book(sid); star=self.workshop.cabinet_book_star(book_id)
            level=max(0,min(star,level))
            if book_id<=0 or level<=0:return
            bucket=normalized_book.setdefault(str(book_id),{})
            current=bucket.get(str(sid)) if isinstance(bucket.get(str(sid)),dict) else {}
            if level>self._int(current.get("lev"),0):bucket[str(sid)]={"lev":level}
        for raw_key,raw_value in book_info.items():
            key=self._int(raw_key,0)
            if key in self.workshop.cabinet_books and isinstance(raw_value,dict):
                valid=set(self.workshop.cabinet_book_skills(key))
                for raw_sid,raw_level in raw_value.items():
                    sid=self._int(raw_sid,0)
                    if sid not in valid:continue
                    level=self._int(raw_level.get("lev"),0) if isinstance(raw_level,dict) else self._int(raw_level,0)
                    merge_skill(sid,level)
            elif key in self.workshop.cabinet_skills:
                level=self._int(raw_value.get("lev"),0) if isinstance(raw_value,dict) else self._int(raw_value,0)
                merge_skill(key,level)
        for hero in self.player.heroes.values() if isinstance(self.player.heroes,dict) else ():
            if not isinstance(hero,dict):continue
            info=hero.get("skill_book_info")
            if not isinstance(info,dict):continue
            for raw_sid,raw_level in info.items():merge_skill(self._int(raw_sid,0),max(0,self._int(raw_level,0)))
        cabinet=raw.get("cabinet_info") if isinstance(raw.get("cabinet_info"),dict) else {}
        cabinet_out=dict(cabinet)
        for key in ("cur_learn_skill","need_time","start_time","recent_complete_skill"):
            cabinet_out[key]=max(0,self._int(cabinet_out.get(key),0))
        if not isinstance(cabinet_out.get("cost_snapshot"),dict): cabinet_out["cost_snapshot"]={}
        jobs=raw.get("building_jobs") if isinstance(raw.get("building_jobs"),dict) else {}
        out=dict(raw); out["book_info"]=normalized_book; out["cabinet_info"]=cabinet_out; out["building_jobs"]=dict(jobs)
        if self.player.workshop_state!=out:self.player.workshop_state=out; changed=True
        return changed

    def normalize(self)->bool:
        return self._normalize_study_infos() | self._normalize_album() | self._normalize_workshop()
