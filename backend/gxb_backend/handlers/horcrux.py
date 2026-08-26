"""Horcrux protocol adapters for H2 lifecycle and H4 strengthening MIDs."""
from __future__ import annotations
from gxb_backend.transport.result import EngineTransportResult
from gxb_backend.state.horcrux_repository import HorcruxRepositoryError
from gxb_backend.state.horcrux_service import HorcruxServiceError
from .context import HandlerContext

class HorcruxHandlers:
    def __init__(self, ctx: HandlerContext) -> None: self.ctx=ctx
    def _svc(self): return self.ctx.state.get_services().horcrux
    @staticmethod
    def _fail(exc: Exception) -> EngineTransportResult:
        return EngineTransportResult(body={"error_code":1,"msg":str(exc)}, status_code=409)
    def _call(self, fn, *args, **kwargs):
        try: return fn(*args, **kwargs)
        except (HorcruxServiceError, HorcruxRepositoryError, ValueError) as exc: return self._fail(exc)
    def strengthen(self, req): return self._call(self._svc().strengthen, req.get("spirit_id"), req.get("spirit_ids"))
    def lock(self, req): return self._call(self._svc().lock, req.get("spirit_id"), locked=True)
    def unlock(self, req): return self._call(self._svc().lock, req.get("spirit_id"), locked=False)
    def equip(self, req): return self._call(self._svc().equip, req.get("partner_id"), req.get("spirit_id"), req.get("pos"))
    def one_key_unequip(self, req): return self._call(self._svc().one_key_unequip, req.get("partner_id"))
    def get_collocation_infos(self, req): return self._svc().collocation_infos()
    def save_collocation(self, req): return self._call(self._svc().save_collocation, name=req.get("name"), collocation=req.get("collocation"), collocation_id=req.get("id"))
    def delete_collocation(self, req): return self._call(self._svc().delete_collocation, req.get("id"))
    def apply_collocation(self, req): return self._call(self._svc().apply_collocation, req.get("id"), req.get("partner_id"))
