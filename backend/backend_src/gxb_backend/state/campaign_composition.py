"""Shared Campaign collaborator construction for request and maintenance roots.

This module owns *construction only*.  It deliberately does not absorb Campaign
policy or state mutation: Challenge/Super catalogs, projections, access policy,
and Function31 coordination remain distinct authorities.
"""
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from gxb_backend.content.challenge_campaign_catalog import ChallengeCampaignCatalog
from gxb_backend.content.super_campaign_catalog import SuperCampaignCatalog

from .challenge_projection_service import ChallengeProjectionService
from .elite_campaign_unlock_coordinator import EliteCampaignUnlockCoordinator
from .function_state_repository import FunctionStateRepository
from .player_state import PlayerState
from .super_campaign_access_policy import SuperCampaignAccessPolicy
from .super_campaign_projection_service import SuperCampaignProjectionService
from .unit_of_work import UnitOfWork


@dataclass(frozen=True)
class CampaignComposition:
    """Canonical Campaign collaborator bundle for one player graph.

    The bundle is a composition-root convenience, not a new domain owner.  It
    exists to prevent request and maintenance construction from drifting into
    parallel Super/Challenge authority graphs.
    """

    challenge_catalog: ChallengeCampaignCatalog
    challenge_projection: ChallengeProjectionService
    super_catalog: SuperCampaignCatalog
    super_projection: SuperCampaignProjectionService
    super_access: SuperCampaignAccessPolicy
    elite_campaign_unlock: EliteCampaignUnlockCoordinator

    @classmethod
    def build(
        cls,
        player: PlayerState,
        data_dir: Path,
        function_state: FunctionStateRepository,
        *,
        uow: UnitOfWork | None = None,
    ) -> "CampaignComposition":
        data_dir = Path(data_dir)
        challenge_catalog = ChallengeCampaignCatalog(data_dir)
        challenge_projection = ChallengeProjectionService(challenge_catalog)
        super_catalog = SuperCampaignCatalog(data_dir)
        super_projection = SuperCampaignProjectionService(player, super_catalog, uow)
        super_access = SuperCampaignAccessPolicy(player, super_catalog, function_state)
        elite_campaign_unlock = EliteCampaignUnlockCoordinator(
            player, function_state, super_projection, uow
        )
        bundle = cls(
            challenge_catalog=challenge_catalog,
            challenge_projection=challenge_projection,
            super_catalog=super_catalog,
            super_projection=super_projection,
            super_access=super_access,
            elite_campaign_unlock=elite_campaign_unlock,
        )
        bundle.validate(player, function_state, uow=uow)
        return bundle

    def validate(
        self,
        player: PlayerState,
        function_state: FunctionStateRepository,
        *,
        uow: UnitOfWork | None,
    ) -> None:
        """Assert one internally coherent collaborator graph by object identity."""
        checks = (
            (self.challenge_projection.catalog is self.challenge_catalog, "challenge projection/catalog"),
            (self.super_projection.player is player, "super projection/player"),
            (self.super_projection.catalog is self.super_catalog, "super projection/catalog"),
            (self.super_projection.uow is uow, "super projection/uow"),
            (self.super_access.player is player, "super access/player"),
            (self.super_access.catalog is self.super_catalog, "super access/catalog"),
            (self.super_access.function_state is function_state, "super access/function state"),
            (self.elite_campaign_unlock.player is player, "elite unlock/player"),
            (self.elite_campaign_unlock.function_state is function_state, "elite unlock/function state"),
            (self.elite_campaign_unlock.projection is self.super_projection, "elite unlock/projection"),
            (self.elite_campaign_unlock.uow is uow, "elite unlock/uow"),
        )
        broken = [label for ok, label in checks if not ok]
        if broken:
            raise ValueError("Campaign composition identity mismatch: " + ", ".join(broken))
