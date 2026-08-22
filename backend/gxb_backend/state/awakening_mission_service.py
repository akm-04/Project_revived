"""Pass74 source-bounded Hero Awakening/Blood Awakening mission owner.

The live client does not finalize awakening through the stale/undefined
``AWAKE_HERO`` symbol.  It owns awakening as TaskType.AWAKE state:
TASK_AWAKE_OPEN -> qualifying battle proof -> TAKE_MISSION_AWARD.
This service persists that mission state and coordinates final Hero ENTITY
mutations while leaving general Campaign ownership separate.
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Callable

from .hero_repository import HeroRepository
from .inventory_repository import InventoryRepository
from .mutation_plan import ActorRef, EntityMutation, IdempotencySpec, MutationOrigin, MutationPlan, StackMutation
from .mutation_settlement_service import MutationSettlementError, MutationSettlementService
from .player_state import PlayerState
from .unit_of_work import OperationContext, UnitOfWork


class AwakeningMissionService:
    HERO = 1
    HERO_TWICE = 2
    TASK_TYPE_AWAKE = 5
    ORDINARY_OPEN_LEVEL = 90
    BLOOD_OPEN_LEVEL = 100
    BLOOD_OPEN_COLOR = 15

    def __init__(
        self,
        player: PlayerState,
        data_dir: Path,
        save_callback: Callable[[], None] | None = None,
        *,
        heroes: HeroRepository,
        inventory: InventoryRepository,
        uow: UnitOfWork,
        settlement: MutationSettlementService,
    ) -> None:
        self.player = player
        self.data_dir = Path(data_dir)
        self._save_callback = save_callback
        self.heroes = heroes
        self.inventory = inventory
        self.uow = uow
        self.settlement = settlement
        try:
            raw = json.loads((self.data_dir / "awakening_mission_meta.json").read_text(encoding="utf-8"))
        except Exception as exc:
            print(f"[AWAKENING] could not load metadata: {exc}")
            raw = {}
        self.ordinary = raw.get("ordinary") or {}
        self.blood = raw.get("blood") or {}

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _domain(self) -> dict[str, Any]:
        root = self.player.awakening_state if isinstance(self.player.awakening_state, dict) else {}
        self.player.awakening_state = root
        active = root.setdefault("active", {})
        if not isinstance(active, dict):
            root["active"] = {}
        root.setdefault("schema_version", 1)
        return root

    def _rows(self, awake_type: int) -> dict[str, dict[str, Any]]:
        return self.ordinary if awake_type == self.HERO else self.blood if awake_type == self.HERO_TWICE else {}

    def _row(self, mission_id: Any, awake_type: int | None = None) -> dict[str, Any] | None:
        key = str(self._int(mission_id, 0))
        if awake_type is not None:
            row = self._rows(awake_type).get(key)
            return dict(row) if isinstance(row, dict) else None
        for rows in (self.ordinary, self.blood):
            row = rows.get(key)
            if isinstance(row, dict):
                return dict(row)
        return None

    def _active(self, awake_type: int) -> dict[str, Any] | None:
        active = self._domain().get("active") or {}
        rec = active.get(str(awake_type)) if isinstance(active, dict) else None
        return rec if isinstance(rec, dict) else None

    def _set_active(self, awake_type: int, rec: dict[str, Any] | None) -> None:
        active = self._domain().setdefault("active", {})
        if rec is None:
            # Persist an explicit tombstone. Pass68 merge-preserving JSON writes
            # intentionally retain unknown nested extensions, so a bare pop can
            # resurrect the stale mission from the previous document on save.
            active[str(awake_type)] = None
        else:
            active[str(awake_type)] = rec
        self.uow.request_save()

    def _hero_by_table(self, table_id: int) -> dict[str, Any] | None:
        for hero in self.player.heroes.values() if isinstance(self.player.heroes, dict) else []:
            if isinstance(hero, dict) and self._int(hero.get("table_id"), 0) == table_id:
                return hero
        return None

    def _task_payload(self, rec: dict[str, Any], *, is_going: int = 1) -> dict[str, Any]:
        return {
            "table_id": self._int(rec.get("mission_id"), 0),
            "awake_type": self._int(rec.get("awake_type"), 0),
            "is_going": 1 if self._int(is_going, 0) else 0,
            "is_complete": 1 if rec.get("complete") and self._int(is_going, 0) else 0,
            "is_open": 1,
            "is_reward": 0,
            "count": self._int(rec.get("count"), 0) if self._int(is_going, 0) else 0,
        }

    def mission_list(self) -> dict[str, Any]:
        out = []
        for awake_type in (self.HERO, self.HERO_TWICE):
            rec = self._active(awake_type)
            if rec:
                out.append(self._task_payload(rec))
        return {"mission_list": out}

    def load_by_type(self, mission_type: Any) -> dict[str, Any] | None:
        if self._int(mission_type, 0) != self.TASK_TYPE_AWAKE:
            return None
        return self.mission_list()

    def _run(self, *, mid: int, operation: str, fn):
        ctx = OperationContext(
            actor_player_id=str(self.player.player_id),
            domain="awakening_mission",
            operation_name=operation,
            protocol_mid=mid,
        )
        with self.uow.transaction(ctx):
            return fn()

    def _entity(self, partner_id: int, action: str, *, amount: int = 0, indices: tuple[int, ...] = ()) -> None:
        self.settlement.apply(MutationPlan(
            schema_version=1,
            plan_id=f"awakening:{action}:{partner_id}:{self.uow.current_state_version}",
            origin=MutationOrigin(domain="awakening_mission", operation=action.lower()),
            actor=ActorRef(player_id=str(self.player.player_id)),
            expected_state_version=None,
            idempotency=IdempotencySpec(), preconditions=(),
            operations=(EntityMutation("HERO", partner_id, action, amount=amount, indices=indices),),
        ))

    def open_task(self, req: dict[str, Any]) -> dict[str, Any]:
        mission_id = self._int(req.get("mission_id"), 0)
        awake_type = self._int(req.get("awake_type"), 0)
        row = self._row(mission_id, awake_type)
        if row is None or self._int(row.get("stage"), 0) != 1:
            return {"error_code": 1, "msg": "invalid_awake_mission"}
        if self._active(awake_type):
            return {"error_code": 1, "msg": "awake_mission_already_active"}
        hero = self._hero_by_table(self._int(row.get("table_id"), 0))
        if hero is None:
            return {"error_code": 1, "msg": "awake_hero_not_owned"}
        if awake_type == self.HERO:
            if self._int(hero.get("lev"), 0) < self.ORDINARY_OPEN_LEVEL:
                return {"error_code": 1, "msg": "awake_level_too_low"}
        elif awake_type == self.HERO_TWICE:
            if self._int(hero.get("lev"), 0) < self.BLOOD_OPEN_LEVEL or self._int(hero.get("color"), 0) < self.BLOOD_OPEN_COLOR:
                return {"error_code": 1, "msg": "blood_awake_requirement_not_met"}
            if self._int(hero.get("twice_awake_stage"), 0) != 0:
                return {"error_code": 1, "msg": "blood_awake_already_started"}
        else:
            return {"error_code": 1, "msg": "unsupported_awake_type"}

        def mutate():
            rec = {
                "mission_id": mission_id, "awake_type": awake_type,
                "hero_partner_id": self._int(hero.get("partner_id"), 0),
                "hero_table_id": self._int(row.get("table_id"), 0),
                "stage": 1,
                # The live open action originates from the exclusive-gear UI.
                # The client is the source-defined stage-1 gate; canonical server
                # state records the opened gear objective as immediately claimable.
                "complete": True, "count": max(1, self._int(row.get("task_num"), 1)),
                "opened_at": self.player.now(),
            }
            self._set_active(awake_type, rec)
            if awake_type == self.HERO_TWICE:
                self._entity(rec["hero_partner_id"], "SET_TWICE_AWAKE_STAGE", amount=1)
            # Task:openAwakeTask only emits ON_MISSION_STATE_CHANGE after an
            # HTTP-success callback; it does not insert the mission itself.
            # Backend:extraWebResponseCheck_ feeds these extra response channels
            # into Task:onTaskBackendEvent before that callback, which is the live
            # source path that makes the newly-opened task appear immediately.
            key = "awake_mission_" if awake_type == self.HERO else "twice_awake_mission_"
            return {key: [self._task_payload(rec)]}
        try:
            return self._run(mid=2738, operation="open", fn=mutate)
        except MutationSettlementError:
            return {"error_code": 1}

    def give_up(self, req: dict[str, Any]) -> dict[str, Any]:
        mission_id = self._int(req.get("mission_id"), 0)
        awake_type = self._int(req.get("awake_type"), 0)
        rec = self._active(awake_type)
        if not rec or self._int(rec.get("mission_id"), 0) != mission_id:
            return {"error_code": 1, "msg": "awake_mission_not_active"}
        row = self._row(mission_id, awake_type) or {}

        def mutate():
            ops = []
            for item_id in row.get("delete_items") or []:
                iid = self._int(item_id, 0)
                count = self.inventory.get_item_num(iid)
                if iid > 0 and count > 0:
                    ops.append(StackMutation(iid, "DEBIT", count))
            if awake_type == self.HERO_TWICE:
                ops.append(EntityMutation("HERO", self._int(rec.get("hero_partner_id"), 0), "SET_TWICE_AWAKE_STAGE", amount=0))
            if ops:
                self.settlement.apply(MutationPlan(
                    schema_version=1,
                    plan_id=f"awakening:giveup:{mission_id}:{self.uow.current_state_version}",
                    origin=MutationOrigin(domain="awakening_mission", operation="give_up", protocol_mid=2737),
                    actor=ActorRef(player_id=str(self.player.player_id)), expected_state_version=None,
                    idempotency=IdempotencySpec(), preconditions=(), operations=tuple(ops),
                ))
            self._set_active(awake_type, None)
            # Task:giveUpTask does not remove the local Awake row.  It only
            # dispatches ON_MISSION_STATE_CHANGE, so the response must overwrite
            # that exact row as inactive; otherwise the client retains a stale
            # is_going=1 task and cannot reopen it without a relog.  The client
            # already performs source-defined delete_item cleanup and Blood-stage
            # reset locally after the HTTP-success callback.
            key = "awake_mission_" if awake_type == self.HERO else "twice_awake_mission_"
            return {key: [self._task_payload(rec, is_going=0)]}
        try:
            return self._run(mid=2737, operation="give_up", fn=mutate)
        except MutationSettlementError:
            return {"error_code": 1}

    def claim(self, table_id: Any) -> dict[str, Any] | None:
        mission_id = self._int(table_id, 0)
        rec = None; awake_type = 0
        for candidate in (self.HERO, self.HERO_TWICE):
            active = self._active(candidate)
            if active and self._int(active.get("mission_id"), 0) == mission_id:
                rec, awake_type = active, candidate; break
        if rec is None:
            return None
        if not rec.get("complete"):
            return {"error_code": 1, "msg": "awake_mission_incomplete"}
        row = self._row(mission_id, awake_type) or {}
        next_id = self._int(row.get("next_task_id"), 0)

        def mutate():
            if next_id > 0:
                nxt = self._row(next_id, awake_type)
                if nxt is None:
                    return {"error_code": 1, "msg": "awake_next_mission_missing"}
                next_rec = {
                    **rec, "mission_id": next_id, "stage": self._int(nxt.get("stage"), 2),
                    "complete": False, "count": 0,
                }
                self._set_active(awake_type, next_rec)
                if awake_type == self.HERO_TWICE:
                    self._entity(self._int(rec.get("hero_partner_id"), 0), "SET_TWICE_AWAKE_STAGE", amount=2)
                key = "awake_mission_" if awake_type == self.HERO else "twice_awake_mission_"
                return {key: [self._task_payload(next_rec)]}

            pid = self._int(rec.get("hero_partner_id"), 0)
            if awake_type == self.HERO:
                target = self._int(row.get("awaken_table_id"), 0)
                if target <= 0:
                    return {"error_code": 1, "msg": "awake_target_missing"}
                self._entity(pid, "AWAKEN_TABLE_ID", indices=(target,))
            else:
                self._entity(pid, "SET_TWICE_AWAKE_STAGE", amount=3)
            self._set_active(awake_type, None)
            return {}
        try:
            return self._run(mid=161, operation="claim", fn=mutate)
        except MutationSettlementError:
            return {"error_code": 1}

    def record_campaign_result(self, req: dict[str, Any]) -> dict[str, Any]:
        mission_id = self._int(req.get("awake_mission"), 0)
        if mission_id <= 0:
            return {}
        rec = self._active(self.HERO)
        if not rec or self._int(rec.get("mission_id"), 0) != mission_id or self._int(rec.get("stage"), 0) != 2:
            return {}
        row = self._row(mission_id, self.HERO) or {}
        campaign_id = self._int(req.get("campaign_id"), 0)
        if campaign_id not in [self._int(v, 0) for v in row.get("go_ids") or []]:
            return {}
        if self._int(req.get("star"), 0) <= 0:
            return {}
        rec["complete"] = True; rec["count"] = max(1, self._int(row.get("task_num"), 1))
        self._set_active(self.HERO, rec)
        return {"awake_mission_": [self._task_payload(rec)]}

    def unlimited_start(self, req: dict[str, Any]) -> dict[str, Any]:
        mid = self._int(req.get("twice_awake_mission"), 0)
        rec = self._active(self.HERO_TWICE)
        if not rec or self._int(rec.get("mission_id"), 0) != mid or self._int(rec.get("stage"), 0) != 2:
            return {"error_code": 1, "msg": "blood_awake_mission_not_active"}
        if self._int(req.get("incubus_id"), 0) != mid:
            return {"error_code": 1, "msg": "blood_awake_incubus_mismatch"}
        return {}

    def unlimited_result(self, req: dict[str, Any]) -> dict[str, Any]:
        mid = self._int(req.get("twice_awake_mission"), 0)
        rec = self._active(self.HERO_TWICE)
        if mid <= 0 or not rec or self._int(rec.get("mission_id"), 0) != mid or self._int(rec.get("stage"), 0) != 2:
            return {"error_code": 1, "msg": "blood_awake_result_not_active"}
        if self._int(req.get("incubus_id"), 0) != mid:
            return {"error_code": 1, "msg": "blood_awake_incubus_mismatch"}
        def mutate():
            rec["complete"] = True; rec["count"] = 1
            self._set_active(self.HERO_TWICE, rec)
            return {"twice_awake_mission_": [self._task_payload(rec)], "items": []}
        return self._run(mid=867, operation="blood_fight_result", fn=mutate)
