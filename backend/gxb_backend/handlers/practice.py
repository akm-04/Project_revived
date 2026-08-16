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
        return {**self.hero_info(req), "awards": []}

    def pet_mutation(self, req: dict) -> dict:
        return {**self.pet_info(req), "awards": []}
