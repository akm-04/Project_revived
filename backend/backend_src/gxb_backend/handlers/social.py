"""Friends/social domain handlers."""
from __future__ import annotations
from .context import HandlerContext

class SocialHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_friends(self, req: dict) -> dict:
        return self.ctx.state.get_player().friends_payload()

    def get_self_guild(self, req: dict) -> dict:
        return self.ctx.state.get_player().guild_payload()

    def request_friend(self, req: dict) -> dict:
        return {"player_info": self.ctx.state.get_player().player_brief()}

    def social_status_only(self, req: dict) -> dict:
        return {}

    def search_player(self, req: dict) -> dict:
        return {"list": [], "players": []}

    def load_friend_info(self, req: dict) -> dict:
        return {"player_info": self.ctx.state.get_player().player_brief(), "heros": []}

    def load_get_request_players(self, req: dict) -> dict:
        return {"list": [], "players": []}

    def get_recommend_friends(self, req: dict) -> dict:
        return {"list": [], "players": []}

    def load_send_request_players(self, req: dict) -> dict:
        return {"list": [], "players": []}
