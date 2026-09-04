"""Immutable effective-src_64 authority for P1 Workshop Bookshelf/Cabinet."""
from __future__ import annotations
from pathlib import Path
from typing import Any, Mapping
from .p1_source_common import freeze_rows, load_source_json

class WorkshopSourceCatalog:
    CABINET_BUILDING_TYPE=1; BOOKSHELF_BUILDING_TYPE=4
    def __init__(self,data_dir:Path):
        raw=load_source_json(data_dir,"p1_workshop_source_catalog.json"); tables=raw.get("tables") or {}
        self.bookshelf=freeze_rows(tables.get("bookshelf")); self.cabinet=freeze_rows(tables.get("cabinet")); self.cabinet_books=freeze_rows(tables.get("cabinet_books")); self.cabinet_skills=freeze_rows(tables.get("cabinet_skills")); self.skill_costs=freeze_rows(tables.get("skill_costs")); self.book_compose=freeze_rows(tables.get("book_compose"))
        if (len(self.bookshelf),len(self.cabinet),len(self.cabinet_books),len(self.cabinet_skills),len(self.book_compose))!=(100,6,54,399,40): raise ValueError("Workshop source census drift")
        if set(self.bookshelf)!=set(range(1,101)) or set(self.cabinet)!=set(range(1,7)): raise ValueError("Workshop level grid drift")
    def bookshelf_level(self,level:Any)->Mapping[str,Any]|None:
        try:return self.bookshelf.get(int(level))
        except (TypeError,ValueError):return None
    def cabinet_level(self,level:Any)->Mapping[str,Any]|None:
        try:return self.cabinet.get(int(level))
        except (TypeError,ValueError):return None
    def cabinet_skill(self,skill_id:Any)->Mapping[str,Any]|None:
        try:return self.cabinet_skills.get(int(skill_id))
        except (TypeError,ValueError):return None
    def cabinet_book(self,book_id:Any)->Mapping[str,Any]|None:
        try:return self.cabinet_books.get(int(book_id))
        except (TypeError,ValueError):return None
    def cabinet_book_compose(self,book_id:Any)->Mapping[str,Any]|None:
        try:return self.book_compose.get(int(book_id))
        except (TypeError,ValueError):return None
    def cabinet_cost_level(self,level:Any)->Mapping[str,Any]|None:
        try:return self.skill_costs.get(int(level))
        except (TypeError,ValueError):return None
    @staticmethod
    def pipe_ints(value:Any)->tuple[int,...]:
        if isinstance(value,(list,tuple)): raw=value
        elif value in (None,""): raw=()
        else: raw=str(value).split("|")
        out=[]
        for item in raw:
            try: out.append(int(item))
            except (TypeError,ValueError): raise ValueError("invalid Workshop source vector") from None
        return tuple(out)
    def cabinet_book_skills(self,book_id:Any)->tuple[int,...]:
        row=self.cabinet_book(book_id); return self.pipe_ints(row.get("skill_id")) if row else ()
    def cabinet_skill_prerequisites(self,skill_id:Any)->tuple[int,...]:
        row=self.cabinet_skill(skill_id)
        if not row:return ()
        values=self.pipe_ints(row.get("last_skill")); return tuple(v for v in values if v>0)
    def cabinet_skill_book(self,skill_id:Any)->int:
        row=self.cabinet_skill(skill_id)
        try:return int(row.get("skillbook",0) or 0) if row else 0
        except (TypeError,ValueError):return 0
    def cabinet_skill_partner(self,skill_id:Any)->int:
        row=self.cabinet_skill(skill_id)
        try:return int(row.get("partner",0) or 0) if row else 0
        except (TypeError,ValueError):return 0
    def cabinet_book_star(self,book_id:Any)->int:
        row=self.cabinet_book(book_id)
        try:return int(row.get("star",0) or 0) if row else 0
        except (TypeError,ValueError):return 0
    def cabinet_book_skillpage(self,book_id:Any)->int:
        row=self.cabinet_book(book_id)
        try:return int(row.get("skillpage",0) or 0) if row else 0
        except (TypeError,ValueError):return 0
    def cabinet_cut_time(self,cabinet_level:Any)->int:
        row=self.cabinet_level(cabinet_level)
        try:return max(0,int(row.get("cut_time",0) or 0)) if row else 0
        except (TypeError,ValueError):return 0
    def cabinet_skill_need_time(self,skill_id:Any,target_level:Any,cabinet_level:Any)->int:
        row=self.cabinet_skill(skill_id)
        try: level=int(target_level)
        except (TypeError,ValueError):return 0
        if not row or level<=0:return 0
        times=self.pipe_ints(row.get("time"))
        if level>len(times):return 0
        return max(0,int(times[level-1])-self.cabinet_cut_time(cabinet_level))
    def cabinet_skill_cost(self,skill_id:Any,target_level:Any)->tuple[tuple[int,int],...]:
        row=self.cabinet_skill(skill_id)
        try: level=int(target_level)
        except (TypeError,ValueError):return ()
        if not row or level<=0:return ()
        try: kind=int(row.get("cost_res_type",1) or 1)
        except (TypeError,ValueError):kind=1
        cost=self.cabinet_cost_level(level)
        if cost is None:return ()
        ids=self.pipe_ints(cost.get(f"cost_res_type{kind}")); nums=self.pipe_ints(cost.get(f"cost_res_num{kind}"))
        if len(ids)!=len(nums):raise ValueError("Cabinet cost source vector mismatch")
        return tuple((rid,num) for rid,num in zip(ids,nums) if num>0)
    def building_level(self,building_type:Any,level:Any)->Mapping[str,Any]|None:
        try: bid=int(building_type); lev=int(level)
        except (TypeError,ValueError): return None
        if bid==self.CABINET_BUILDING_TYPE:return self.cabinet.get(lev)
        if bid==self.BOOKSHELF_BUILDING_TYPE:return self.bookshelf.get(lev)
        return None
    def max_building_level(self,building_type:Any)->int:
        try: bid=int(building_type)
        except (TypeError,ValueError): return 0
        if bid==self.CABINET_BUILDING_TYPE:return max(self.cabinet)
        if bid==self.BOOKSHELF_BUILDING_TYPE:return max(self.bookshelf)
        return 0
