"""Illusion/paradise handlers."""

from __future__ import annotations

from .context import HandlerContext


class IllusionHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_info(self, req: dict) -> dict:
        return self.ctx.state.get_player().illusion_payload()
