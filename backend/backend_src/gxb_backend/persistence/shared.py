"""Explicit I4 repository interfaces for shared/account-global ownership.

No generic shared_resource/EAV table is introduced. Concrete domains implement
one of these typed contracts only when their canonical table exists.
"""
from __future__ import annotations
from typing import Any, Mapping, Protocol

class GuildAuthorityRepository(Protocol):
    def load_for_update(self, transaction:Any, guild_id:int)->Mapping[str,Any]|None: ...
class FiniteClaimResourceRepository(Protocol):
    def load_for_update(self, transaction:Any, resource_kind:str, resource_id:str)->Mapping[str,Any]|None: ...
    def claim(self, transaction:Any, resource_kind:str, resource_id:str, claimant_player_id:int)->Mapping[str,Any]: ...
class SharedEncounterRepository(Protocol):
    def load_for_update(self, transaction:Any, encounter_kind:str, encounter_id:str)->Mapping[str,Any]|None: ...
class CompetitionAuthorityRepository(Protocol):
    def load_generation_for_update(self, transaction:Any, competition_kind:str, generation_id:str)->Mapping[str,Any]|None: ...
