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

    def get_story_drop_partner(self, req: dict) -> dict:
        """Grant the source-selected special-story partner for MID2064.

        BattleSpecialStory.lua will not advance unless ``story_drop_awards`` is
        non-empty.  The selected table ID is validated against source-derived
        campaign metadata, then the owned Hero record and Campaign
        ``is_partner_drop`` marker are committed together before MID114.
        """
        world = self.ctx.state.get_world_repository()
        prepared = world.prepare_story_drop_claim(
            req.get("campaign_id"),
            req.get("story_drop_partner"),
            req.get("campaign_type"),
        )
        status = prepared.get("status")
        hero_repo = self.ctx.state.get_hero_repository()

        if status == "existing":
            hero = hero_repo.get(prepared.get("partner_id"))
            if (
                hero is not None
                and int(hero.get("table_id") or 0) == int(prepared.get("table_id") or 0)
            ):
                award = dict(hero)
                award["is_partner"] = True
                return {"story_drop_awards": [award]}
            return {"story_drop_awards": []}

        if status != "new":
            return {"story_drop_awards": []}

        record = hero_repo.add_owned_hero(
            {
                "table_id": int(prepared["table_id"]),
                "star": int(prepared["star"]),
            },
            persist=False,
        )
        if not world.record_story_drop_claim(
            req.get("campaign_id"),
            prepared["table_id"],
            record.get("partner_id"),
            persist=False,
        ):
            # Validation was performed immediately above under the request-scoped
            # state lock.  This branch is defensive; do not return an uncommitted
            # reward if the world marker could not be staged.
            return {"story_drop_awards": []}

        self.ctx.state.save()
        award = dict(record)
        award["is_partner"] = True
        return {"story_drop_awards": [award]}

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
