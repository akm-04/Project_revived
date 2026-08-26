"""Summon/Vending handlers.

Pass41.6 keeps classic MID50 activation and adds the separately recovered/private-policy
Magic MID70/MID71 plane. Deferred Vending variants and SX remain fail closed; MID59
fragment synthesis is unchanged.
"""

from __future__ import annotations

from .context import HandlerContext
from gxb_backend.transport.result import EngineTransportResult
from gxb_backend.state.vow_service import VowServiceError


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
    @staticmethod
    def _vow_fail(exc: Exception) -> EngineTransportResult:
        return EngineTransportResult(body={"error_code":1,"msg":str(exc)}, status_code=409)

    def summon_super_hero(self, req: dict):
        try:
            return self.ctx.state.get_services().vows.summon_super_hero(req.get("table_id"))
        except (VowServiceError, ValueError) as exc:
            return self._vow_fail(exc)

    def super_hero_stone_exchange(self, req: dict):
        try:
            return self.ctx.state.get_services().vows.exchange_essence(req.get("table_id"), req.get("times"))
        except (VowServiceError, ValueError) as exc:
            return self._vow_fail(exc)

