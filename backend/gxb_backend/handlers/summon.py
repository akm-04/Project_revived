"""Summon/Vending handlers.

Pass41.6 keeps classic MID50 activation and adds the separately recovered/private-policy
Magic MID70/MID71 plane. Deferred Vending variants and SX remain fail closed; MID59
fragment synthesis is unchanged.
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

    def magic_summon(self, req: dict) -> dict:
        return self.ctx.state.get_summon_repository().magic_summon_hero(req)

    def magic_summon_switch(self, req: dict) -> dict:
        return self.ctx.state.get_summon_repository().magic_switch_hero(req)
