"""Generic reward/side-effect handlers shared by lobby windows."""

from __future__ import annotations

from .context import HandlerContext


class RewardHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def awards_empty(self, req: dict) -> dict:
        return {"awards": []}

    def status_only(self, req: dict) -> dict:
        return {}

    def get_offline_info(self, req: dict) -> dict:
        return self.ctx.state.get_player().offline_payload()

    def get_building_list(self, req: dict) -> dict:
        return self.ctx.state.get_player().building_list_payload()

    def get_tea_talk_info(self, req: dict) -> dict:
        return self.ctx.state.get_player().tea_talk_payload()

    def get_class_info(self, req: dict) -> dict:
        return self.ctx.state.get_player().class_info_payload()

    def get_study_infos(self, req: dict) -> dict:
        return self.ctx.state.get_player().study_payload()

    def get_gift_box_info(self, req: dict) -> dict:
        return self.ctx.state.get_player().gift_box_payload()

    def get_hero_recommend_scores(self, req: dict) -> dict:
        return self.ctx.state.get_player().hero_recommend_payload()

    def battle_pass_get_info(self, req: dict) -> dict:
        return self.ctx.state.get_player().battle_pass_payload()

    def hunqi_start_game_get_info(self, req: dict) -> dict:
        return self.ctx.state.get_player().hunqi_start_payload()
