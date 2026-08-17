"""Mission/task domain handlers."""
from __future__ import annotations
from .context import HandlerContext

class TaskHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_mission(self, req: dict) -> dict:
        return self.ctx.state.get_player().task_bootstrap_payload()

    def task_load_by_type(self, req: dict) -> dict:
        mission_type = req.get("mission_type") or req.get("type")
        projected = self.ctx.state.get_mission_repository().load_by_type(mission_type)
        if projected is not None:
            return projected
        return self.ctx.state.get_player().mission_payload(mission_type)

    def take_mission_award(self, req: dict) -> dict:
        result = self.ctx.state.get_mission_repository().claim(req.get("table_id"))
        if result is not None:
            return result
        # Other mission families remain the pre-Pass30 compatibility skeleton.
        return {"awards": []}

    def mission_status(self, req: dict) -> dict:
        return {"awards": []}

    def huoyue_award(self, req: dict) -> dict:
        return {"awards": [], "huoyue_info": {}}
