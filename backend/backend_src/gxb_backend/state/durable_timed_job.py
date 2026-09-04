"""Stateless finite-job timing primitives shared by P1 Course/Workshop domains."""
from __future__ import annotations
from dataclasses import dataclass
from enum import Enum
from typing import Any

class DurableJobState(str, Enum):
    IDLE="IDLE"; RUNNING="RUNNING"; READY="READY"

@dataclass(frozen=True)
class DurableJobSnapshot:
    start_time:int; need_time:int; now:int; state:DurableJobState; elapsed:int; remaining:int; progress:float

class DurableTimedJobPolicy:
    @staticmethod
    def _int(value:Any, default:int=0)->int:
        try:return int(value)
        except (TypeError,ValueError):return default

    def snapshot(self, *, start_time:Any, need_time:Any, now:Any) -> DurableJobSnapshot:
        start=max(0,self._int(start_time)); need=max(0,self._int(need_time)); current=max(0,self._int(now))
        if start<=0 or need<=0:
            return DurableJobSnapshot(start,need,current,DurableJobState.IDLE,0,0,0.0)
        elapsed=max(0,current-start)
        remaining=max(0,need-elapsed)
        state=DurableJobState.READY if remaining==0 else DurableJobState.RUNNING
        return DurableJobSnapshot(start,need,current,state,min(need,elapsed),remaining,min(1.0,max(0.0,elapsed/need)))
