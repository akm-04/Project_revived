"""Mutation-free server authorization for Super Campaign entry."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from gxb_backend.content.super_campaign_catalog import (
    SUPER_CAMPAIGN_TYPE,
    SUPER_FUNCTION_ID,
    SuperCampaignCatalog,
)

from .function_state_repository import FunctionStateRepository
from .player_state import PlayerState


@dataclass(frozen=True)
class SuperCampaignAccessDecision:
    allowed: bool
    reason: str
    super_campaign_id: int
    normal_anchor_id: int = 0


class SuperCampaignAccessPolicy:
    """Validate feature, projection and related-Normal authority without mutation."""

    def __init__(
        self,
        player: PlayerState,
        catalog: SuperCampaignCatalog,
        function_state: FunctionStateRepository,
    ) -> None:
        self.player = player
        self.catalog = catalog
        self.function_state = function_state

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def function_open(self) -> bool:
        return SUPER_FUNCTION_ID in set(self.function_state.announced_ids())

    def _find_row(self, key: str, campaign_id: int) -> dict[str, Any] | None:
        world = self.player.world_map if isinstance(self.player.world_map, dict) else {}
        rows = world.get(key)
        if not isinstance(rows, list):
            return None
        for row in rows:
            if isinstance(row, dict) and self._int(row.get("campaign_id"), 0) == campaign_id:
                return row
        return None

    def evaluate(self, campaign_id: Any, campaign_type: Any = SUPER_CAMPAIGN_TYPE) -> SuperCampaignAccessDecision:
        cid = self._int(campaign_id, 0)
        if self._int(campaign_type, 0) != SUPER_CAMPAIGN_TYPE or not self.catalog.contains(cid):
            return SuperCampaignAccessDecision(False, "campaign_super_source_membership_invalid", cid)
        if not self.function_open():
            return SuperCampaignAccessDecision(False, "campaign_super_function_locked", cid)
        if self._find_row("super", cid) is None:
            return SuperCampaignAccessDecision(False, "campaign_super_not_unlocked", cid)
        anchor = self.catalog.related_normal_id(cid)
        if anchor <= 0:
            return SuperCampaignAccessDecision(False, "campaign_super_relation_invalid", cid)
        normal = self._find_row("normal", anchor)
        if normal is None or self._int(normal.get("star"), 0) <= 0:
            return SuperCampaignAccessDecision(False, "campaign_normal_prerequisite_locked", cid, anchor)
        return SuperCampaignAccessDecision(True, "ok", cid, anchor)
