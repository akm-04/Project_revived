"""Mission/task domain handlers."""
from __future__ import annotations
from .context import HandlerContext

class TaskHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_mission(self, req: dict) -> dict:
        return self.ctx.state.get_player().task_bootstrap_payload()

    def task_load_by_type(self, req: dict) -> dict:
        return self.ctx.state.get_player().mission_payload(req.get("mission_type") or req.get("type"))

    def take_mission_award(self, req: dict) -> dict:
        return {"awards": []}

    def mission_status(self, req: dict) -> dict:
        return {"awards": []}

    def huoyue_award(self, req: dict) -> dict:
        return {"awards": [], "huoyue_info": {}}
