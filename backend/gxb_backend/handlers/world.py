"""World/campaign/trial/march/adventure handlers."""
from __future__ import annotations
from gxb_backend.observability.campaign_asset_auditor import CampaignAssetAuditor

from .context import HandlerContext


class WorldHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx
        self.asset_auditor = CampaignAssetAuditor(ctx.settings, ctx.resource_gateway)

    def load_world_map(self, req: dict) -> dict:
        return self.ctx.state.get_world_repository().payload()

    def load_trial_infos(self, req: dict) -> dict:
        return self.ctx.state.get_player().trial_infos_payload()

    def load_march(self, req: dict) -> dict:
        return self.ctx.state.get_player().march_payload()

    def march_action(self, req: dict) -> dict:
        return {**self.load_march(req), "awards": []}

    def get_rent_heros(self, req: dict) -> dict:
        """Source-shaped empty MID2768 rental state.

        SelfGuild:loadAllTeamHeros() consumes the two rental containers and root
        rent_count even when the account has no rentable heroes.  Empty rental
        state is sufficient for the normal Campaign vertical slice.
        """
        return {
            "guild_rent_heroes": {
                "partners": [],
                "rent_type": int(req.get("campaign_type") or req.get("rent_type") or 0),
                # SelfGuild compares this nested count against its cached value
                # before accepting/replacing the partner list.
                "rent_count": 0,
            },
            "tutor_rent_heroes": [],
            "rent_count": 0,
        }

    def fight(self, req: dict) -> dict:
        self.asset_auditor.audit(req.get("campaign_id"))
        return self.ctx.state.get_world_repository().begin_fight(req)

    def fight_result(self, req: dict) -> dict:
        return self.ctx.state.get_world_repository().commit_fight_result(req)

    def sweep_campaign(self, req: dict) -> dict:
        return self.ctx.state.get_world_repository().sweep(req)

    def reset_campaign(self, req: dict) -> dict:
        return self.load_world_map(req)

    def get_bonus_award(self, req: dict) -> dict:
        return {"awards": []}

    def challenge_info(self, req: dict) -> dict:
        return {"challenges": [], "campaigns": []}

    def get_adventure_list(self, req: dict) -> dict:
        return self.ctx.state.get_player().adventure_payload()

    def world_boss(self, req: dict) -> dict:
        return self.ctx.state.get_player().world_boss_payload()

    def world_boss_action(self, req: dict) -> dict:
        return {**self.world_boss(req), "awards": []}
