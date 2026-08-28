"""P1-I3 deterministic Electives/Courses lifecycle owner.

Course stat/battle semantics stay client-owned.  This service owns only the
server-authored durable lifecycle: acquisition, room occupancy/timers,
progress persistence, binding, proficiency/quality, forgetting, and safe
responses for unrecovered recommendation/gift-box server policy.
"""
from __future__ import annotations
from typing import Any

from gxb_backend.content.course_source_catalog import CourseSourceCatalog

from .course_study_progress_policy import CourseStudyProgressPolicy
from .durable_timed_job import DurableJobState, DurableTimedJobPolicy
from .hero_course_state_adapter import HeroCourseStateAdapter, HeroCourseRecord
from .hero_entity_mutation_service import HeroEntityMutationService
from .hero_repository import HeroRepository
from .inventory_repository import InventoryRepository
from .mutation_plan import (
    ActorRef, EntityMutation, IdempotencySpec, MutationOrigin, MutationPlan,
    ResourceMutation, StackMutation,
)
from .mutation_settlement_service import MutationSettlementError, MutationSettlementService
from .player_state import PlayerState
from .server_clock import ServerClock
from .unit_of_work import OperationContext, PlayerUnitOfWork
from .vip_policy import VipPrivilegeResolver


class CourseServiceError(ValueError):
    pass


class CourseService:
    MAX_COURSES = 4
    BINDABLE_SKILLS = (1, 2, 3, 4)
    STUDY_SLICE = "course_study_infos"

    def __init__(
        self,
        player: PlayerState,
        source: CourseSourceCatalog,
        heroes: HeroRepository,
        hero_entities: HeroEntityMutationService,
        inventory: InventoryRepository,
        settlement: MutationSettlementService,
        vip: VipPrivilegeResolver,
        jobs: DurableTimedJobPolicy,
        progress_policy: CourseStudyProgressPolicy,
        clock: ServerClock,
        uow: PlayerUnitOfWork,
    ) -> None:
        self.player = player
        self.source = source
        self.heroes = heroes
        self.hero_entities = hero_entities
        self.inventory = inventory
        self.settlement = settlement
        self.vip = vip
        self.jobs = jobs
        self.progress_policy = progress_policy
        self.clock = clock
        self.uow = uow

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _hero(self, partner_id: Any) -> dict[str, Any]:
        pid = self._int(partner_id)
        hero = self.heroes.get(pid)
        if pid <= 0 or hero is None:
            raise CourseServiceError("course hero is not owned")
        return hero

    def _record(self, hero: dict[str, Any], course_id: Any) -> HeroCourseRecord | None:
        cid = self._int(course_id)
        return next((r for r in HeroCourseStateAdapter.records(hero) if r.course_id == cid), None)

    def _course_row(self, course_id: Any):
        cid = self._int(course_id)
        row = self.source.course(cid)
        if cid <= 0 or row is None:
            raise CourseServiceError("unknown course")
        return cid, row

    @staticmethod
    def _course_info(record: HeroCourseRecord) -> dict[str, int]:
        return {
            "progress": int(record.progress),
            "quality": int(record.quality),
            "add_skill": int(record.skill),
            "exp": int(record.exp),
        }

    def _partner_courses(self, hero: dict[str, Any]) -> dict[str, dict[str, int]]:
        return {str(r.course_id): self._course_info(r) for r in HeroCourseStateAdapter.records(hero)}

    def _study_rows(self) -> list[dict[str, int]]:
        raw = self.player.study_infos if isinstance(self.player.study_infos, list) else []
        rows: list[dict[str, int]] = []
        for row in raw:
            if not isinstance(row, dict):
                continue
            pid = max(0, self._int(row.get("partner_id")))
            if pid <= 0:
                continue
            rows.append({
                "partner_id": pid,
                "course_id": max(0, self._int(row.get("course_id"))),
                "enter_time": max(0, self._int(row.get("enter_time"))),
                "start_time": max(0, self._int(row.get("start_time"))),
                "need_time": max(0, self._int(row.get("need_time"), self.source.study_seconds)) or self.source.study_seconds,
            })
        rows.sort(key=lambda r: (r["enter_time"], r["partner_id"]))
        return rows

    def _set_study_rows(self, rows: list[dict[str, int]]) -> None:
        self.player.study_infos = [dict(row) for row in rows]
        self.uow.mark_changed(self.STUDY_SLICE)

    @staticmethod
    def _find_row(rows: list[dict[str, int]], partner_id: int) -> tuple[int, dict[str, int] | None]:
        for idx, row in enumerate(rows):
            if int(row.get("partner_id", 0)) == int(partner_id):
                return idx, row
        return -1, None

    def _context(self, *, mid: int, operation: str) -> OperationContext:
        return OperationContext(
            actor_player_id=str(self.player.player_id), domain="course",
            operation_name=operation, protocol_mid=mid, server_time=self.clock.now(),
        )

    def _plan(self, *, mid: int, operation: str, partner_id: int, operations: tuple[Any, ...]) -> MutationPlan:
        return MutationPlan(
            schema_version=1,
            plan_id=f"course:{mid}:{partner_id}:{operation}:{self.uow.current_state_version}",
            origin=MutationOrigin(domain="course", operation=operation, protocol_mid=mid),
            actor=ActorRef(player_id=str(self.player.player_id)),
            expected_state_version=None,
            idempotency=IdempotencySpec(), preconditions=(), operations=operations,
        )

    def _settle(self, *, mid: int, operation: str, partner_id: int, operations: tuple[Any, ...]) -> None:
        if operations:
            self.settlement.apply(self._plan(mid=mid, operation=operation, partner_id=partner_id, operations=operations))

    def _payload(self, hero: dict[str, Any] | None = None, course_id: int = 0) -> dict[str, Any]:
        out: dict[str, Any] = {"study_infos": self._study_rows()}
        if hero is not None:
            out["partner_courses"] = self._partner_courses(hero)
            rec = self._record(hero, course_id) if course_id else None
            if rec is not None:
                out["course_info"] = self._course_info(rec)
        return out

    def _room_limit(self) -> int:
        return max(0, int(self.vip.study_room_limit()))

    def _require_room_capacity(self, rows: list[dict[str, int]]) -> None:
        limit = self._room_limit()
        if limit <= 0 or len(rows) >= limit:
            raise CourseServiceError("study room limit reached")

    def _start_row(self, rows: list[dict[str, int]], partner_id: int, course_id: int) -> list[dict[str, int]]:
        now = self.clock.now()
        idx, existing = self._find_row(rows, partner_id)
        if existing is None:
            self._require_room_capacity(rows)
            existing = {"partner_id": partner_id, "enter_time": now, "course_id": 0, "start_time": 0, "need_time": self.source.study_seconds}
            rows.append(existing)
            idx = len(rows) - 1
        existing = dict(existing)
        existing.update({"course_id": course_id, "start_time": now, "need_time": self.source.study_seconds})
        rows[idx] = existing
        rows.sort(key=lambda r: (r["enter_time"], r["partner_id"]))
        return rows

    def _materialize_ready(self, *, partner_id: int, mid: int, operation: str) -> bool:
        rows = self._study_rows()
        idx, row = self._find_row(rows, partner_id)
        if row is None or self._int(row.get("start_time")) <= 0 or self._int(row.get("course_id")) <= 0:
            return False
        snap = self.jobs.snapshot(start_time=row["start_time"], need_time=row["need_time"], now=self.clock.now())
        if snap.state != DurableJobState.READY:
            return False
        hero = self._hero(partner_id)
        cid = self._int(row["course_id"])
        rec = self._record(hero, cid)
        if rec is not None and rec.progress < 100:
            target = self.progress_policy.complete(rec.progress)
            self._settle(mid=mid, operation=operation, partner_id=partner_id,
                         operations=(EntityMutation("HERO", partner_id, "COURSE_SET_PROGRESS", amount=target, indices=(cid,)),))
        rows.pop(idx)
        self._set_study_rows(rows)
        return True

    # ----- wire operations -----
    def get_study_infos(self, req: dict[str, Any] | None = None) -> dict[str, Any]:
        return {"study_infos": self._study_rows()}

    def get_studyroom_info(self, req: dict[str, Any] | None = None) -> dict[str, Any]:
        # Do not auto-materialize READY jobs here; the client renders ENDED and
        # asks GET_COURSE_INFO to settle that completion.
        return {"study_infos": self._study_rows()}

    def get_course_info(self, partner_id: Any) -> dict[str, Any]:
        hero = self._hero(partner_id); pid = self._int(partner_id)
        rows = self._study_rows(); _, row = self._find_row(rows, pid)
        cid = self._int(row.get("course_id")) if row else 0
        if row is not None and self._int(row.get("start_time")) > 0:
            with self.uow.transaction(self._context(mid=2129, operation="get_course_info_complete")):
                self._materialize_ready(partner_id=pid, mid=2129, operation="study_complete")
        return self._payload(hero, cid)

    def apply_course(self, partner_id: Any, course_id: Any) -> dict[str, Any]:
        hero = self._hero(partner_id); pid = self._int(partner_id); cid, _ = self._course_row(course_id)
        rec = self._record(hero, cid)
        if rec is not None:
            return self._payload(hero, cid)
        if len(HeroCourseStateAdapter.records(hero)) >= self.MAX_COURSES:
            raise CourseServiceError("hero course capacity reached")
        item_id = self.source.application_item_for_course(cid)
        if item_id <= 0:
            raise CourseServiceError("course application item missing")
        with self.uow.transaction(self._context(mid=2128, operation="apply_course")):
            self._settle(mid=2128, operation="apply_course", partner_id=pid, operations=(
                StackMutation(item_id, "DEBIT", 1), EntityMutation("HERO", pid, "COURSE_ACQUIRE", indices=(cid,)),
            ))
        return self._payload(hero, cid)

    def enter_room(self, partner_id: Any) -> dict[str, Any]:
        hero = self._hero(partner_id); pid = self._int(partner_id); rows = self._study_rows()
        _, row = self._find_row(rows, pid)
        if row is not None:
            return self._payload(hero, self._int(row.get("course_id")))
        self._require_room_capacity(rows)
        now = self.clock.now()
        rows.append({"partner_id": pid, "course_id": 0, "enter_time": now, "start_time": 0, "need_time": self.source.study_seconds})
        with self.uow.transaction(self._context(mid=2135, operation="enter_room")):
            self._set_study_rows(rows)
        return self._payload(hero)

    def study(self, partner_id: Any, course_id: Any) -> dict[str, Any]:
        hero = self._hero(partner_id); pid = self._int(partner_id); cid, _ = self._course_row(course_id)
        rows = self._study_rows(); _, row = self._find_row(rows, pid)
        if row is not None and self._int(row.get("course_id")) == cid and self._int(row.get("start_time")) > 0:
            return self._payload(hero, cid)
        rec = self._record(hero, cid)
        if rec is not None:
            if rec.progress < 100:
                raise CourseServiceError("course already known; use continue study")
            raise CourseServiceError("course study is already complete")
        if len(HeroCourseStateAdapter.records(hero)) >= self.MAX_COURSES:
            raise CourseServiceError("hero course capacity reached")
        item_id = self.source.application_item_for_course(cid)
        if item_id <= 0:
            raise CourseServiceError("course application item missing")
        if row is None:
            self._require_room_capacity(rows)
        with self.uow.transaction(self._context(mid=2131, operation="study")):
            self._settle(mid=2131, operation="study", partner_id=pid, operations=(
                StackMutation(item_id, "DEBIT", 1), EntityMutation("HERO", pid, "COURSE_ACQUIRE", indices=(cid,)),
            ))
            self._set_study_rows(self._start_row(rows, pid, cid))
        return self._payload(hero, cid)

    def continue_study(self, partner_id: Any, course_id: Any) -> dict[str, Any]:
        hero = self._hero(partner_id); pid = self._int(partner_id); cid, _ = self._course_row(course_id)
        rec = self._record(hero, cid)
        if rec is None or rec.progress >= 100:
            raise CourseServiceError("course is not eligible for continued study")
        rows = self._study_rows(); _, row = self._find_row(rows, pid)
        if row is not None and self._int(row.get("course_id")) == cid and self._int(row.get("start_time")) > 0:
            return self._payload(hero, cid)
        if row is not None and self._int(row.get("start_time")) > 0:
            raise CourseServiceError("hero is already studying another course")
        if row is None:
            self._require_room_capacity(rows)
        with self.uow.transaction(self._context(mid=2142, operation="continue_study")):
            self._set_study_rows(self._start_row(rows, pid, cid))
        return self._payload(hero, cid)

    def speed_study(self, partner_id: Any, course_id: Any) -> dict[str, Any]:
        hero = self._hero(partner_id); pid = self._int(partner_id); cid, _ = self._course_row(course_id)
        rows = self._study_rows(); idx, row = self._find_row(rows, pid)
        if row is None:
            return self._payload(hero, cid)  # replay after prior completion
        if self._int(row.get("course_id")) != cid or self._int(row.get("start_time")) <= 0:
            raise CourseServiceError("course is not actively studying")
        rec = self._record(hero, cid)
        if rec is None:
            raise CourseServiceError("course is not owned")
        snap = self.jobs.snapshot(start_time=row["start_time"], need_time=row["need_time"], now=self.clock.now())
        target = self.progress_policy.complete(rec.progress) if rec.progress < 100 else rec.progress
        cost = self.source.speed_cost(snap.remaining)
        ops: list[Any] = []
        if cost > 0:
            ops.append(ResourceMutation("crystal", "DEBIT", cost))
        if target != rec.progress:
            ops.append(EntityMutation("HERO", pid, "COURSE_SET_PROGRESS", amount=target, indices=(cid,)))
        with self.uow.transaction(self._context(mid=2132, operation="speed_study")):
            self._settle(mid=2132, operation="speed_study", partner_id=pid, operations=tuple(ops))
            rows.pop(idx); self._set_study_rows(rows)
        return self._payload(hero, cid)

    def cancel_study(self, partner_id: Any) -> dict[str, Any]:
        hero = self._hero(partner_id); pid = self._int(partner_id); rows = self._study_rows(); idx, row = self._find_row(rows, pid)
        if row is None:
            return self._payload(hero)
        cid = self._int(row.get("course_id"))
        with self.uow.transaction(self._context(mid=2138, operation="cancel_study")):
            rows.pop(idx); self._set_study_rows(rows)
        return self._payload(hero, cid)

    def leave_room(self, partner_id: Any) -> dict[str, Any]:
        hero = self._hero(partner_id); pid = self._int(partner_id); rows = self._study_rows(); idx, row = self._find_row(rows, pid)
        if row is None:
            return self._payload(hero)
        cid = self._int(row.get("course_id"))
        if self._int(row.get("start_time")) > 0:
            snap = self.jobs.snapshot(start_time=row["start_time"], need_time=row["need_time"], now=self.clock.now())
            if snap.state == DurableJobState.RUNNING:
                raise CourseServiceError("cannot leave while course study is running")
            with self.uow.transaction(self._context(mid=2136, operation="leave_ready_room")):
                self._materialize_ready(partner_id=pid, mid=2136, operation="leave_ready_room")
            return self._payload(hero, cid)
        with self.uow.transaction(self._context(mid=2136, operation="leave_room")):
            rows.pop(idx); self._set_study_rows(rows)
        return self._payload(hero, cid)

    def add_skill(self, partner_id: Any, course_id: Any, skill_index: Any) -> dict[str, Any]:
        hero = self._hero(partner_id); pid = self._int(partner_id); cid, _ = self._course_row(course_id); skill = self._int(skill_index)
        rec = self._record(hero, cid)
        if rec is None or rec.progress < 100:
            raise CourseServiceError("course must be fully learned before binding")
        if skill not in self.BINDABLE_SKILLS:
            raise CourseServiceError("course skill slot must be 1..4")
        if rec.skill == skill:
            return self._payload(hero, cid)
        with self.uow.transaction(self._context(mid=2133, operation="add_skill")):
            self._settle(mid=2133, operation="add_skill", partner_id=pid, operations=(
                EntityMutation("HERO", pid, "COURSE_BIND_SKILL", amount=skill, indices=(cid,)),
            ))
        return self._payload(hero, cid)

    def incr_course_exp(self, req: dict[str, Any]) -> dict[str, Any]:
        hero = self._hero(req.get("partner_id")); pid = self._int(req.get("partner_id")); cid, _ = self._course_row(req.get("course_id"))
        item_id = self._int(req.get("item_id")); item_num = self._int(req.get("item_num")); total_num = self._int(req.get("total_num"), -1)
        rec = self._record(hero, cid)
        if rec is None or rec.progress < 100:
            raise CourseServiceError("course must be fully learned before proficiency")
        proficiency = self.source.proficiency_for_item(item_id)
        if proficiency <= 0 or item_num <= 0 or total_num < item_num:
            raise CourseServiceError("invalid course proficiency request")
        current_qty = self.inventory.get_item_num(item_id)
        if current_qty == total_num - item_num:
            # Optimistic-total replay: the exact stack debit already happened.
            return {"item_id": item_id, "total_num": current_qty, "course_info": self._course_info(rec)}
        if current_qty != total_num:
            raise CourseServiceError("stale course proficiency inventory total")
        source_max = self.source.max_total_proficiency()
        if rec.exp >= source_max:
            raise CourseServiceError("course proficiency is already at source maximum")
        # Pass192 P1-I5: effective CourseWindow permits a final whole item whose
        # proficiency delta crosses 1680 (e.g. 1650 + 50). The original server's
        # exact overflow response was not recovered; stock runtime requires a
        # successful terminal action, so compatibility policy consumes the whole
        # submitted item and caps the durable total at the source maximum.
        target_exp = min(source_max, rec.exp + proficiency * item_num)
        quality = self.source.quality_for_exp(target_exp)
        with self.uow.transaction(self._context(mid=2140, operation="incr_course_exp")):
            self._settle(mid=2140, operation="incr_course_exp", partner_id=pid, operations=(
                StackMutation(item_id, "DEBIT", item_num),
                EntityMutation("HERO", pid, "COURSE_SET_EXP_QUALITY", indices=(cid,), counts=(quality, target_exp)),
            ))
        current = self._record(hero, cid)
        return {"item_id": item_id, "total_num": self.inventory.get_item_num(item_id), "course_info": self._course_info(current)}

    def forget_course(self, partner_id: Any, course_id: Any) -> dict[str, Any]:
        hero = self._hero(partner_id); pid = self._int(partner_id); cid, _ = self._course_row(course_id)
        rec = self._record(hero, cid)
        if rec is None:
            return {**self._payload(hero), "return_items": []}
        returns = self.source.forget_returns(rec.quality)
        ops: list[Any] = [ResourceMutation("crystal", "DEBIT", self.source.forget_crystal)]
        ops.extend(StackMutation(item_id, "CREDIT", count) for item_id, count in returns)
        ops.append(EntityMutation("HERO", pid, "COURSE_FORGET", indices=(cid,)))
        rows = self._study_rows(); idx, row = self._find_row(rows, pid)
        with self.uow.transaction(self._context(mid=2134, operation="forget_course")):
            self._settle(mid=2134, operation="forget_course", partner_id=pid, operations=tuple(ops))
            if row is not None and self._int(row.get("course_id")) == cid:
                rows.pop(idx); self._set_study_rows(rows)
        return {**self._payload(hero), "return_items": [{"item_id": i, "item_num": n} for i, n in returns]}

    def courses_recommend(self, req: dict[str, Any] | None = None) -> dict[str, Any]:
        # Server-authored selection policy is unrecovered; safe-empty is explicit.
        return {"recommend_list": []}

    def gift_box_info(self, req: dict[str, Any] | None = None) -> dict[str, Any]:
        payload = self.player.gift_box_payload()
        payload.setdefault("is_has_gift", 0)
        return payload
