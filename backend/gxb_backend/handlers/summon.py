"""Summon state handlers."""

from __future__ import annotations

from .context import HandlerContext


class SummonHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_summon_info(self, req: dict) -> dict:
        return self.ctx.state.get_player().summon_payload()
