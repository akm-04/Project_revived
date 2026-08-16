"""World/campaign/trial/march/adventure handlers."""
from __future__ import annotations
from .context import HandlerContext

class WorldHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_world_map(self, req: dict) -> dict:
        return self.ctx.state.get_player().world_map_payload()

    def load_trial_infos(self, req: dict) -> dict:
        return self.ctx.state.get_player().trial_infos_payload()

    def load_march(self, req: dict) -> dict:
        return self.ctx.state.get_player().march_payload()

    def march_action(self, req: dict) -> dict:
        return {**self.load_march(req), "awards": []}

    def fight(self, req: dict) -> dict:
        return {"battle_id": 1, "report": {}, "seed": 1, "enemy_info": {}}

    def fight_result(self, req: dict) -> dict:
        return {"awards": [], "is_win": 1, "result": 1}

    def sweep_campaign(self, req: dict) -> dict:
        return {"awards": [], "campaign_id": req.get("campaign_id", 100001)}

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
