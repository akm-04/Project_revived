"""Small ordered new-Hero projection seam; intentionally not a domain event bus."""
from __future__ import annotations
from collections.abc import Callable
from typing import Any
from .player_state import PlayerState

HeroInitializer=Callable[[dict[str,Any],PlayerState],None]

class HeroCreationInitializerRegistry:
    def __init__(self)->None:self._entries:list[tuple[str,HeroInitializer]]=[]
    def register(self,name:str,initializer:HeroInitializer)->None:
        key=str(name).strip()
        if not key or not callable(initializer):raise ValueError("initializer requires name/callable")
        if any(existing==key for existing,_ in self._entries):raise ValueError(f"duplicate Hero initializer {key}")
        self._entries.append((key,initializer))
    def apply(self,hero:dict[str,Any],player:PlayerState)->None:
        for _name,initializer in self._entries:initializer(hero,player)
    @property
    def names(self)->tuple[str,...]:return tuple(name for name,_ in self._entries)
