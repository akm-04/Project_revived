"""P1-I3 Electives/Courses protocol handlers."""
from __future__ import annotations
from gxb_backend.state.course_service import CourseServiceError
from gxb_backend.state.mutation_settlement_service import MutationSettlementError
from gxb_backend.transport.result import EngineTransportResult
from .context import HandlerContext


class CourseHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def _service(self):
        return self.ctx.state.get_course_service()

    @staticmethod
    def _fail(exc: Exception) -> EngineTransportResult:
        return EngineTransportResult(body={"error_code": 1, "msg": str(exc)}, status_code=409)

    def _call(self, fn, *args):
        try:
            return fn(*args)
        except (CourseServiceError, MutationSettlementError, ValueError) as exc:
            return self._fail(exc)

    def apply_course(self, req: dict): return self._call(self._service().apply_course, req.get("partner_id"), req.get("course_id"))
    def get_course_info(self, req: dict): return self._call(self._service().get_course_info, req.get("partner_id"))
    def get_studyroom_info(self, req: dict): return self._call(self._service().get_studyroom_info, req)
    def study(self, req: dict): return self._call(self._service().study, req.get("partner_id"), req.get("course_id"))
    def speed_study(self, req: dict): return self._call(self._service().speed_study, req.get("partner_id"), req.get("course_id"))
    def add_skill(self, req: dict): return self._call(self._service().add_skill, req.get("partner_id"), req.get("course_id"), req.get("skill_index"))
    def forget_course(self, req: dict): return self._call(self._service().forget_course, req.get("partner_id"), req.get("course_id"))
    def enter_room(self, req: dict): return self._call(self._service().enter_room, req.get("partner_id"))
    def leave_room(self, req: dict): return self._call(self._service().leave_room, req.get("partner_id"))
    def get_study_infos(self, req: dict): return self._call(self._service().get_study_infos, req)
    def cancel_study(self, req: dict): return self._call(self._service().cancel_study, req.get("partner_id"))
    def get_gift_box_info(self, req: dict): return self._call(self._service().gift_box_info, req)
    def incr_course_exp(self, req: dict): return self._call(self._service().incr_course_exp, req)
    def continue_study(self, req: dict): return self._call(self._service().continue_study, req.get("partner_id"), req.get("course_id"))
    def get_courses_recommend(self, req: dict): return self._call(self._service().courses_recommend, req)

    def open_gift_box(self, req: dict):
        # Server-authored award generation is unrecovered; do not fabricate RNG.
        return EngineTransportResult(
            body={"error_code": 1, "msg": "course_gift_box_awards_deferred"},
            status_code=409,
        )
