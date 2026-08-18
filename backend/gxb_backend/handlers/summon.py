"""Summon/Vending handlers.

Only the source-scripted fresh tutorial pulls are implemented in v0.8.1.
"""

from __future__ import annotations

from .context import HandlerContext


class SummonHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_summon_info(self, req: dict) -> dict:
        return self.ctx.state.get_summon_repository().payload()

    def summon_hero(self, req: dict) -> dict:
        return self.ctx.state.get_summon_repository().summon_hero(req)

    def stone_summon_hero(self, req: dict) -> dict:
        return self.ctx.state.get_summon_repository().stone_summon_hero(req)
