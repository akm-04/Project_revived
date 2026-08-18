"""Explicit request-scoped global response semantics.

The recovered client processes selected cumulative fields from the MID-agnostic
``economy_`` envelope before endpoint-local callbacks.  This helper is the
server-side opt-in boundary for such semantics: domains explicitly stage only
source-confirmed cumulative fields after their canonical mutation succeeds.

It intentionally does *not* infer fields from arbitrary PlayerState diffs and
has no gameplay ownership of its own.
"""
from __future__ import annotations

from typing import Any

from .player_state import PlayerState
from .unit_of_work import UnitOfWork


class GlobalResponseSemantics:
    """Typed semantic projection boundary for global client response buses."""

    def __init__(self, player: PlayerState, uow: UnitOfWork) -> None:
        self.player = player
        self.uow = uow

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def stage_skill_point(self) -> None:
        """Project the canonical cumulative Skill Point total through ``economy_``.

        ``SelfPlayer.useSkillPointItem()`` consumes no direct resource response
        field, while ``SelfPlayer.economySyncEvent_()`` explicitly consumes
        ``economy_.skill_point``.  Keep this endpoint/domain opt-in rather than
        enabling generic Skill Point diff projection.
        """
        self.uow.stage_semantic(
            "economy_",
            {"skill_point": max(0, self._int(self.player.skill_point))},
        )
