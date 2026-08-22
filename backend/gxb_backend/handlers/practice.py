"""Hero/pet practice domain (Pass 19 finite dynamic MID family 124-133)."""
from __future__ import annotations
from .context import HandlerContext

class PracticeHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def hero_info(self, req: dict) -> dict:
        return self.ctx.state.get_player().practice_payload(False)

    def pet_info(self, req: dict) -> dict:
        return self.ctx.state.get_player().practice_payload(True)

    def hero_mutation(self, req: dict) -> dict:
        # Effective src_64 does not reveal the authoritative random candidate
        # generation / roll algorithm. A false OK lets the client create local-
        # only Hero practice state, so Hero Practice remains explicitly closed.
        return {"error_code": 1, "msg": "hero_practice_server_algorithm_unresolved"}

    def pet_mutation(self, req: dict) -> dict:
        return {**self.pet_info(req), "awards": []}
