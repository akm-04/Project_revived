"""Mission/task domain handlers."""
from __future__ import annotations
from .context import HandlerContext

class TaskHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_mission(self, req: dict) -> dict:
        payload = dict(self.ctx.state.get_player().task_bootstrap_payload())
        # Pass210 Stage E: legacy bootstrap may contain stale generic awake/twice
        # buckets. AwakeningMissionService is the sole canonical mission owner.
        payload.update(self.ctx.state.get_awakening_mission_service().bootstrap_channels())
        return payload

    def task_load_by_type(self, req: dict) -> dict:
        mission_type = req.get("mission_type") or req.get("type")
        awake = self.ctx.state.get_awakening_mission_service().load_by_type(mission_type)
        if awake is not None:
            return awake
        projected = self.ctx.state.get_mission_repository().load_by_type(mission_type)
        if projected is not None:
            return projected
        return self.ctx.state.get_player().mission_payload(mission_type)

    def take_mission_award(self, req: dict) -> dict:
        result = self.ctx.state.get_awakening_mission_service().claim(req.get("table_id"))
        if result is not None:
            return result
        result = self.ctx.state.get_mission_repository().claim(req.get("table_id"))
        if result is not None:
            return result
        # Other mission families remain the pre-Pass30 compatibility skeleton.
        return {"awards": []}

    def awake_mission_list(self, req: dict) -> dict:
        return self.ctx.state.get_awakening_mission_service().mission_list()

    def awake_open(self, req: dict) -> dict:
        return self.ctx.state.get_awakening_mission_service().open_task(req)

    def awake_give_up(self, req: dict) -> dict:
        return self.ctx.state.get_awakening_mission_service().give_up(req)

    def awake_get_item(self, req: dict) -> dict:
        return self.ctx.state.get_awakening_mission_service().get_awake_item(req)

    def mission_status(self, req: dict) -> dict:
        return {"awards": []}

    def huoyue_award(self, req: dict) -> dict:
        return {"awards": [], "huoyue_info": {}}
