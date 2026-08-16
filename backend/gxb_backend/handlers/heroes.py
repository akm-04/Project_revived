"""Hero and pet collection handlers."""

from __future__ import annotations

from .context import HandlerContext


class HeroHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_heros(self, req: dict) -> dict:
        return self.ctx.state.get_player().heroes_payload()

    def load_pets(self, req: dict) -> dict:
        return self.ctx.state.get_player().pets_payload()
