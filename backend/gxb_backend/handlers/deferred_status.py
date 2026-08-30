"""Thin explicit routes for missing deferred read-only status MIDs."""
from __future__ import annotations
from .context import HandlerContext


class DeferredStatusHandlers:
    def __init__(self, ctx: HandlerContext) -> None: self.ctx = ctx
    def treasure_info(self, req: dict) -> dict: return self.ctx.state.get_services().deferred_status.response(530)
    def guild_war_red_point(self, req: dict) -> dict: return self.ctx.state.get_services().deferred_status.response(1152)
