"""Factory helpers for deterministic Stage 1 state."""

from __future__ import annotations

from .account import AccountIdentity
from .player_state import PlayerState


def default_account() -> AccountIdentity:
    return AccountIdentity()


def default_player() -> PlayerState:
    return PlayerState()
