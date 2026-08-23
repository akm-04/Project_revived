"""Privilege composition and source-cost policy for Super Campaign MID116."""
from __future__ import annotations

from typing import Any

from gxb_backend.content.campaign_reset_catalog import CampaignResetSourceCatalog

from .player_state import PlayerState
from .vip_policy import VipPrivilegeResolver


class CampaignResetPolicy:
    """Semantic policy seam consumed by Campaign, not by Commerce.

    VIP owns the base ``num_elite`` allowance. Monthly Privilege is an
    orthogonal entitlement already hydrated on PlayerState; Campaign only asks
    for the composed number and the nth source cost.
    """

    def __init__(
        self,
        player: PlayerState,
        vip_privileges: VipPrivilegeResolver,
        source: CampaignResetSourceCatalog,
    ) -> None:
        self.player = player
        self.vip_privileges = vip_privileges
        self.source = source

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def vip_allowance(self) -> int:
        return max(0, self.vip_privileges.super_campaign_paid_reset_limit())

    def monthly_privilege_active(self) -> bool:
        return self._int(getattr(self.player, "privilege_left_card_day", 0), 0) > 0

    def monthly_privilege_allowance(self) -> int:
        if not self.monthly_privilege_active():
            return 0
        return max(0, int(self.source.monthly_privilege_num_elite))

    def total_allowance(self) -> int:
        return self.vip_allowance() + self.monthly_privilege_allowance()

    def next_cost(self, current_reset_count: Any) -> int:
        count = max(0, self._int(current_reset_count, 0))
        return self.source.cost(count + 1)
