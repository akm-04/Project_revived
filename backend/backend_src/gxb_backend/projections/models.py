from __future__ import annotations
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Mapping

@dataclass(frozen=True)
class LiveProjectionRow:
    scope_type:str; scope_id:str; rank_type:str; subject_type:str; subject_id:str; score:int; source_version:int; tiebreak:Mapping[str,Any]

@dataclass(frozen=True)
class RankSnapshotRow:
    scope_type:str; scope_id:str; rank_type:str; generation_id:str; snapshot_at:datetime; subject_type:str; subject_id:str; rank:int; score:int; tiebreak:Mapping[str,Any]; reward_band:str|None=None; metadata:Mapping[str,Any]|None=None
