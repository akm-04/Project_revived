"""Typed adapter for the client's five parallel per-Hero Course arrays."""
from __future__ import annotations
from dataclasses import dataclass
from typing import Any

@dataclass(frozen=True)
class HeroCourseRecord:
    course_id:int; progress:int; skill:int; quality:int; exp:int

class HeroCourseStateAdapter:
    FIELDS=("courses","courses_progress","courses_skill","courses_quality","courses_exp")
    @staticmethod
    def _int(value:Any,default:int=0)->int:
        try:return int(value)
        except (TypeError,ValueError):return default
    @classmethod
    def _arrays(cls,hero:dict[str,Any])->list[list[Any]]:
        arrays=[]
        for field in cls.FIELDS:
            value=hero.get(field)
            arrays.append(list(value) if isinstance(value,(list,tuple)) else [])
        return arrays
    @classmethod
    def records(cls,hero:dict[str,Any])->tuple[HeroCourseRecord,...]:
        arrays=cls._arrays(hero); size=min((len(a) for a in arrays),default=0); out=[]
        for i in range(size):
            cid=cls._int(arrays[0][i])
            if cid<=0: continue
            out.append(HeroCourseRecord(cid,max(0,min(100,cls._int(arrays[1][i]))),max(0,cls._int(arrays[2][i])),max(1,cls._int(arrays[3][i],1)),max(0,cls._int(arrays[4][i]))))
        return tuple(out)
    @classmethod
    def _write(cls,hero:dict[str,Any],records:list[HeroCourseRecord])->None:
        hero["courses"]=[r.course_id for r in records]; hero["courses_progress"]=[r.progress for r in records]; hero["courses_skill"]=[r.skill for r in records]; hero["courses_quality"]=[r.quality for r in records]; hero["courses_exp"]=[r.exp for r in records]
    @classmethod
    def acquire(cls,hero:dict[str,Any],course_id:int)->bool:
        records=list(cls.records(hero))
        if any(r.course_id==course_id for r in records): return False
        records.append(HeroCourseRecord(int(course_id),0,0,1,0)); cls._write(hero,records); return True
    @classmethod
    def set_progress(cls,hero:dict[str,Any],course_id:int,progress:int)->bool:
        records=list(cls.records(hero)); changed=False; out=[]
        for r in records:
            if r.course_id==course_id:
                nr=HeroCourseRecord(r.course_id,max(0,min(100,int(progress))),r.skill,r.quality,r.exp); changed|=nr!=r; out.append(nr)
            else: out.append(r)
        if changed: cls._write(hero,out)
        return changed
    @classmethod
    def bind_skill(cls,hero:dict[str,Any],course_id:int,skill:int)->bool:
        records=list(cls.records(hero)); skill=max(0,int(skill)); found=False; changed=False; out=[]
        for r in records:
            new_skill=r.skill
            if r.course_id==course_id: new_skill=skill; found=True
            elif skill>0 and r.skill==skill: new_skill=0
            nr=HeroCourseRecord(r.course_id,r.progress,new_skill,r.quality,r.exp); changed|=nr!=r; out.append(nr)
        if not found:return False
        if changed:cls._write(hero,out)
        return changed
    @classmethod
    def set_exp_quality(cls,hero:dict[str,Any],course_id:int,quality:int,exp:int)->bool:
        records=list(cls.records(hero)); changed=False; out=[]
        for r in records:
            nr=HeroCourseRecord(r.course_id,r.progress,r.skill,max(1,int(quality)),max(0,int(exp))) if r.course_id==course_id else r; changed|=nr!=r; out.append(nr)
        if changed:cls._write(hero,out)
        return changed
    @classmethod
    def forget(cls,hero:dict[str,Any],course_id:int)->bool:
        records=list(cls.records(hero)); out=[r for r in records if r.course_id!=course_id]
        if len(out)==len(records):return False
        cls._write(hero,out); return True
