"""Guild/team domain handlers with source-consumed empty structures."""
from __future__ import annotations
from .context import HandlerContext

class GuildHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def get_self_guild(self, req: dict) -> dict:
        return self.ctx.state.get_player().guild_payload()

    def guild_list(self, req: dict) -> dict:
        return {"list": [], "guild_infos": []}

    def team_data(self, req: dict) -> dict:
        return {"guild_log": [], "team_info": {}, "members": []}

    def load_drink_info(self, req: dict) -> dict:
        return {
            "buy_drink_status": 0, "daily_exchange": 0, "free_have_drink": 0,
            "normal_drink_times": 0, "normal_have_drink": 0, "normal_time": 0,
            "special_drink_times": 0, "special_have_drink": 0, "special_time": 0,
        }

    def drink_action(self, req: dict) -> dict:
        return {"drink_info": self.load_drink_info(req), "member_name": self.ctx.state.get_player().player_name, "guild_huoyue": 0}

    def load_sent_heros(self, req: dict) -> dict:
        return {"heroes": []}

    def rent_hero(self, req: dict) -> dict:
        return {"rent_info": {}, "rent_list": []}

    def guild_campaign_list(self, req: dict) -> dict:
        return {"chapter_list": []}

    def guild_map(self, req: dict) -> dict:
        return {"chapter_list": [], "copy_list": []}

    def guild_awards(self, req: dict) -> dict:
        return {"award_infos": [], "award_next_time": 0, "guild_equip_apply_times": 0, "self_apply_info": {}}

    def damage_rank(self, req: dict) -> dict:
        return {"rank_list": []}

    def all_server_damage_rank(self, req: dict) -> dict:
        return {"boss_killer": {}, "fast_boss_killer": {}, "rank_list": []}

    def fight_prepare(self, req: dict) -> dict:
        return {"last_fight_time": 0, "stage": 0, "start_fight_time": 0}

    def distribute_record(self, req: dict) -> dict:
        return {"logs": []}

    def rent_pets(self, req: dict) -> dict:
        return {"pets": [], "rent_count": 0, "rent_info": {}, "rent_list": []}

    def guild_status_only(self, req: dict) -> dict:
        return {}
