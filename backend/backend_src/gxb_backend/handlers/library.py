"""Library/background handlers."""

from __future__ import annotations

from .context import HandlerContext


class LibraryHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def get_library_infos(self, req: dict) -> dict:
        return self.ctx.state.get_player().library_payload()

    def set_bg(self, req: dict) -> dict:
        player = self.ctx.state.get_player()
        try:
            bg_id = int(req.get("bg_id", player.bg_main))
            bg_type = int(req.get("_type", 1))
        except Exception:
            return {}
        if bg_type == 1:
            player.bg_main = bg_id
        elif bg_type == 2:
            player.bg_room = bg_id
        self.ctx.state.save()
        return {}
