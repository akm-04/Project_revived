"""Achievement handlers used by MainSceneTopWindow and achievement panels."""

from __future__ import annotations

from .context import HandlerContext


class AchievementHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_achievement_info(self, req: dict) -> dict:
        return self.ctx.state.get_player().achievement_payload()

    def get_achievement_award(self, req: dict) -> dict:
        return self.ctx.state.get_player().achievement_award_payload()
