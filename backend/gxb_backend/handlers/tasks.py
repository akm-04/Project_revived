"""Mission/task handlers."""

from __future__ import annotations

from .context import HandlerContext


class TaskHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def task_load_by_type(self, req: dict) -> dict:
        return {"mission_list": []}

    def take_mission_award(self, req: dict) -> dict:
        return {"awards": []}
