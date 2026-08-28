"""Thin protocol adapters for the minimal Pass211 Occult Awakening dependency."""
from __future__ import annotations
from gxb_backend.state.occult_service import OccultServiceError
from gxb_backend.transport.result import EngineTransportResult
from .context import HandlerContext

class OccultHandlers:
    def __init__(self,ctx:HandlerContext)->None:self.ctx=ctx
    def _svc(self):return self.ctx.state.get_services().occult
    @staticmethod
    def _fail(exc:Exception)->EngineTransportResult:return EngineTransportResult(body={'error_code':1,'msg':str(exc)},status_code=409)
    def get_info(self,req):
        try:return self._svc().get_info()
        except (OccultServiceError,ValueError) as exc:return self._fail(exc)
    def sweep(self,req):
        try:return self._svc().sweep(req.get('chapter_id'))
        except (OccultServiceError,ValueError) as exc:return self._fail(exc)
