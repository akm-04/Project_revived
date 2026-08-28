"""P1-I4 Workshop/Event Centre protocol handlers."""
from __future__ import annotations
from gxb_backend.state.event_centre_building_service import EventCentreBuildingError
from gxb_backend.state.cabinet_research_service import CabinetResearchError
from gxb_backend.state.mutation_settlement_service import MutationSettlementError
from gxb_backend.transport.result import EngineTransportResult
from .context import HandlerContext

class WorkshopHandlers:
    def __init__(self,ctx:HandlerContext)->None:self.ctx=ctx
    def _service(self):return self.ctx.state.get_workshop_building_service()
    def _cabinet(self):return self.ctx.state.get_cabinet_research_service()
    @staticmethod
    def _fail(exc:Exception)->EngineTransportResult:return EngineTransportResult(body={"error_code":1,"msg":str(exc)},status_code=409)
    def _call(self,fn,*args,**kwargs):
        try:return fn(*args,**kwargs)
        except (EventCentreBuildingError,CabinetResearchError,MutationSettlementError,ValueError) as exc:return self._fail(exc)
    def get_building_list(self,req:dict):
        # GET_BUILDING_LIST carries cabinet_info too; materialize a naturally
        # completed Cabinet research before projecting that shared payload.
        ready=self._call(self._cabinet().reconcile_ready,mid=1056,operation="get_building_list_cabinet_complete")
        if isinstance(ready,EngineTransportResult):return ready
        return self._call(self._service().get_building_list)
    def upgrade_building(self,req:dict):return self._call(self._service().upgrade,req.get("type"))
    def cancel_evolve_building(self,req:dict):return self._call(self._service().cancel,req.get("type"))
    def speed_up_building(self,req:dict):return self._call(self._service().speed,req.get("type"))
    def confirm_building_upgrade(self,req:dict):return self._call(self._service().confirm,req.get("type"))
    def get_cabinet_info(self,req:dict):return self._call(self._cabinet().get_info)
    def learn_skill(self,req:dict):return self._call(self._cabinet().learn,req.get("skill_id"))
    def give_up_learn_skill(self,req:dict):return self._call(self._cabinet().cancel,req.get("skill_id"))
    def speed_up_skill(self,req:dict):return self._call(self._cabinet().speed,req.get("skill_id"))
    def cabinet_skill_confirm(self,req:dict):return self._call(self._cabinet().confirm)
