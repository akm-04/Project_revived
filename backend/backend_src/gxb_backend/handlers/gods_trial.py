"""Thin protocol adapters for Pass170 Gods Trial HUNQI campaign MIDs."""
from __future__ import annotations

from gxb_backend.state.gods_trial_service import GodsTrialServiceError
from gxb_backend.transport.result import EngineTransportResult
from .context import HandlerContext


class GodsTrialHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def _svc(self):
        return self.ctx.state.get_services().gods_trial

    @staticmethod
    def _fail(exc: Exception) -> EngineTransportResult:
        return EngineTransportResult(
            body={"error_code": 1, "msg": str(exc)}, status_code=409
        )

    def _call(self, fn, *args, **kwargs):
        try:
            return fn(*args, **kwargs)
        except (GodsTrialServiceError, ValueError) as exc:
            return self._fail(exc)

    def get_campaign_info(self, req):
        return self._call(self._svc().campaign_info)

    def start_fight(self, req):
        return self._call(
            self._svc().start_fight,
            req.get("campaign_id"), req.get("campaign_type"),
            req.get("formation"), req.get("pet_id", 0),
        )

    def fight_result(self, req):
        return self._call(
            self._svc().fight_result,
            req.get("campaign_id"), req.get("campaign_type"),
            req.get("partner_ids"), req.get("star"), req.get("pet_id", 0),
        )

    def start_auto(self, req):
        return self._call(self._svc().start_auto, req.get("campaign_id"), req.get("times"))

    def collect_auto(self, req):
        return self._call(self._svc().collect_auto)
