"""Server-authored tutorial milestones and guide-sensitive policy outputs.

Pass33 establishes a rigid trust boundary: client MID26 story/guide cursors are
presentation continuity, never proof that gameplay milestones occurred.  This
repository stores only facts produced by successful canonical domain
transactions and may coordinate explicit semantic outputs such as Function
announcements.  It does not advance client guide IDs or absorb Campaign rules.
"""
from __future__ import annotations

from collections.abc import Callable
from typing import Any

from .function_state_repository import FunctionStateRepository
from .player_state import PlayerState


class TutorialMilestoneRepository:
    SCHEMA_VERSION = 1
    NORMAL_PRE_SKILL_TERMINAL_FIGHT_COMMITTED = "normal_pre_skill_terminal_fight_committed"

    # Pass33.1 local compatibility policy.  Clean-app-data runtime places the
    # committed normal Campaign100007 victory at the terminal pre-Skill fight.
    # This is a server-observable anchor, unlike MID26 guide_id.  It remains
    # explicitly labeled compatibility policy rather than a claim about the
    # historical server's hidden release algorithm.
    _CAMPAIGN_CLEAR_MILESTONES = {
        100007: NORMAL_PRE_SKILL_TERMINAL_FIGHT_COMMITTED,
    }
    _FUNCTION_RELEASES = {
        NORMAL_PRE_SKILL_TERMINAL_FIGHT_COMMITTED: (33,),
    }

    def __init__(
        self,
        player: PlayerState,
        function_state: FunctionStateRepository,
        save_callback: Callable[[], None] | None = None,
    ) -> None:
        self.player = player
        self.function_state = function_state
        self._save_callback = save_callback
        self.normalize()

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _root(self) -> dict[str, Any]:
        root = self.player.tutorial_state
        if not isinstance(root, dict):
            root = {}
            self.player.tutorial_state = root
        return root

    def normalize(self) -> bool:
        root = self._root()
        changed = False
        if self._int(root.get("schema_version"), 0) != self.SCHEMA_VERSION:
            root["schema_version"] = self.SCHEMA_VERSION
            changed = True
        milestones = root.get("milestones")
        if not isinstance(milestones, dict):
            root["milestones"] = {}
            changed = True
        else:
            cleaned = {
                str(key): 1
                for key, value in milestones.items()
                if str(key) and self._int(value, 0) != 0
            }
            if cleaned != milestones:
                root["milestones"] = cleaned
                changed = True
        return changed

    def has(self, milestone: str) -> bool:
        self.normalize()
        milestones = self._root().get("milestones") or {}
        return self._int(milestones.get(str(milestone)), 0) != 0

    def mark(self, milestone: str, *, persist: bool = False) -> list[int]:
        """Record one authoritative milestone and stage its explicit policies."""
        milestone = str(milestone or "").strip()
        if not milestone:
            return []
        self.normalize()
        root = self._root()
        milestones = root["milestones"]
        changed = self._int(milestones.get(milestone), 0) == 0
        if changed:
            milestones[milestone] = 1

        announced = self.function_state.announce(
            self._FUNCTION_RELEASES.get(milestone, ()),
            persist=False,
        )
        if persist and (changed or announced):
            self._save()
        return announced

    def record_campaign_clear(
        self,
        campaign_id: Any,
        campaign_type: Any,
        star: Any,
        *,
        canonical_session: bool,
        persist: bool = False,
    ) -> list[int]:
        """Observe a committed Campaign fact; never consume StoryData cursors."""
        if not canonical_session:
            return []
        if self._int(campaign_type, 0) != 1 or self._int(star, 0) <= 0:
            return []
        milestone = self._CAMPAIGN_CLEAR_MILESTONES.get(self._int(campaign_id, 0))
        if milestone is None:
            return []
        return self.mark(milestone, persist=persist)

    def _save(self) -> None:
        if self._save_callback:
            self._save_callback()
