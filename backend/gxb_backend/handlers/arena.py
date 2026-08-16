"""Arena/record handlers."""

from __future__ import annotations

from .context import HandlerContext


class ArenaHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_arena_fight_records(self, req: dict) -> dict:
        return self.ctx.state.get_player().arena_records_payload()

    def peak_records(self, req: dict) -> dict:
        return {"records": []}

    def empty_list(self, req: dict) -> dict:
        return {"list": []}
