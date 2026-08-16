"""Player identity/state handlers."""

from __future__ import annotations

from .context import HandlerContext


class PlayerHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_player_info(self, req: dict) -> dict:
        region = req.get("region")
        if region is not None:
            try:
                self.ctx.state.set_region(int(region))
            except Exception:
                pass
        return self.ctx.state.get_player().player_info_payload()

    def first_main_touch(self, req: dict) -> dict:
        self.ctx.state.get_player().first_main_touch = 1
        self.ctx.state.save()
        return {}
