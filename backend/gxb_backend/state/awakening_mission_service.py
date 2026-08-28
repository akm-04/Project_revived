"""Pass74 source-bounded Hero Awakening/Blood Awakening mission owner.

The live client does not finalize awakening through the stale/undefined
``AWAKE_HERO`` symbol.  It owns awakening as TaskType.AWAKE state:
TASK_AWAKE_OPEN -> qualifying battle proof -> TAKE_MISSION_AWARD.
This service persists that mission state and coordinates final Hero ENTITY
mutations while leaving general Campaign ownership separate.
"""
from __future__ import annotations

import copy
from pathlib import Path
from typing import Any, Callable

from gxb_backend.content.awakening_source_catalog import AwakeningSourceCatalog
from gxb_backend.content.awakening_compatibility_policy import AwakeningCompatibilityPolicy

from .hero_repository import HeroRepository
from .inventory_repository import InventoryRepository
from .kongming_awake_skill_service import KongMingAwakeSkillService
from .mutation_plan import ActorRef, EntityMutation, IdempotencySpec, MutationOrigin, MutationPlan, StackMutation
from .mutation_settlement_service import MutationSettlementError, MutationSettlementService
from .player_state import PlayerState
from .awakening_state_v2 import AwakeningStateV2
from .awakening_projection_builder import AwakeningProjectionBuilder
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
        source: AwakeningSourceCatalog | None = None,
        projection: AwakeningProjectionBuilder | None = None,
        compatibility: AwakeningCompatibilityPolicy | None = None,
    ) -> None:
        self.player = player
        self.data_dir = Path(data_dir)
        self._save_callback = save_callback
        self.heroes = heroes
        self.inventory = inventory
        self.uow = uow
        self.settlement = settlement
        # Pass205 Stage A replaces the legacy derived metadata read with one
        # immutable effective-src64 SOURCE_FACT catalog. Compatibility policy is
        # deliberately kept out of this authority.
        self.source = source if source is not None else AwakeningSourceCatalog(self.data_dir)
        self.projection = projection if projection is not None else AwakeningProjectionBuilder()
        self.compatibility = compatibility if compatibility is not None else AwakeningCompatibilityPolicy(self.data_dir)
        self.state = AwakeningStateV2(player, uow)
        self._validate_compatibility_policy()

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _domain(self) -> dict[str, Any]:
        return self.state.root()

    def _rows(self, awake_type: int):
        return self.source.rows(awake_type)

    def _row(self, mission_id: Any, awake_type: int | None = None) -> dict[str, Any] | None:
        row = self.source.mission(self._int(mission_id, 0), awake_type)
        return dict(row) if row is not None else None

    def _active(self, awake_type: int) -> dict[str, Any] | None:
        return self.state.active(awake_type)

    def _set_active(self, awake_type: int, rec: dict[str, Any] | None) -> None:
        self.state.set_active(awake_type, rec)

    def active_snapshot(self, awake_type: Any) -> dict[str, Any] | None:
        """Return a detached canonical active-mission snapshot for collaborators."""
        rec = self._active(self._int(awake_type, 0))
        return copy.deepcopy(rec) if isinstance(rec, dict) else None

    def mission_source_row(self, mission_id: Any, awake_type: Any) -> dict[str, Any] | None:
        """Expose the immutable source row through the mission owner boundary."""
        row = self._row(mission_id, self._int(awake_type, 0))
        return copy.deepcopy(row) if isinstance(row, dict) else None

    def complete_campaign_objective(self, *, mission_id: Any, generation: Any) -> dict[str, Any]:
        """Mark the validated ordinary final Campaign task complete in the caller UoW."""
        if not self.uow.active:
            raise MutationSettlementError("Awakening Campaign completion requires active PlayerUnitOfWork")
        mid = self._int(mission_id, 0); gen = self._int(generation, 0)
        rec = self._active(self.HERO)
        if not rec or self._int(rec.get("mission_id"), 0) != mid or self._int(rec.get("generation"), 0) != gen:
            raise MutationSettlementError("Awakening Campaign generation changed")
        if self._int(rec.get("stage"), 0) != 2 or bool(rec.get("complete")):
            raise MutationSettlementError("Awakening Campaign final task is not incomplete")
        row = self._row(mid, self.HERO) or {}
        rec = dict(rec)
        rec["complete"] = True
        rec["count"] = max(1, self._int(row.get("task_num"), 1))
        self._set_active(self.HERO, rec)
        response = self.projection.mission_delta(self.HERO, [rec])
        self.state.remember_transition(
            awake_type=self.HERO, generation=gen, mission_id=mid,
            operation="campaign_final_complete", replay_payload=response,
        )
        return response

    def _route(self, mission_id: Any, awake_type: int):
        return self.source.stage1_route(self._int(mission_id, 0), awake_type)

    def _validate_compatibility_policy(self) -> None:
        for policy in self.compatibility.event_rows:
            awake_type=self._int(policy.get("awake_type")); mission_id=self._int(policy.get("mission_id"))
            route=self._route(mission_id,awake_type)
            if route is None or str(route.get("route_class") or "")!="EVENT_OUTLIER":
                raise ValueError(f"event entitlement route drift {awake_type}/{mission_id}")
            gear=self._int(policy.get("exclusive_gear_item")); material=self._int(policy.get("intermediate_item"))
            if gear!=self._int(route.get("exclusive_gear_item")) or material<=0:
                raise ValueError(f"event entitlement recipe drift {awake_type}/{mission_id}")

    @staticmethod
    def _merge_payloads(*payloads: dict[str, Any]) -> dict[str, Any]:
        out: dict[str, Any]={}
        for payload in payloads:
            if isinstance(payload,dict): out.update(payload)
        return out

    def _event_activation_grant(self, *, awake_type: int, mission_id: int, generation: int) -> tuple[list[Any], dict[str, Any] | None]:
        policy=self.compatibility.event(awake_type,mission_id)
        if policy is None:return [],None
        item_id=self._int(policy.get("intermediate_item")); ent=self.state.event_entitlement(awake_type,mission_id)
        should_grant=ent is None or str(ent.get("status") or "")=="RESTORABLE"
        if not should_grant:return [],None
        prior_restores=self._int(ent.get("restoration_count"),0) if isinstance(ent,dict) else 0
        record={
            "mission_id":mission_id,"awake_type":awake_type,"intermediate_item":item_id,
            "exclusive_gear_item":self._int(policy.get("exclusive_gear_item")),
            "status":"LIVE","first_generation":self._int((ent or {}).get("first_generation"),generation),
            "last_generation":generation,"grant_count":1,"restoration_count":prior_restores+(1 if ent is not None else 0),
        }
        self.state.set_event_entitlement(awake_type,mission_id,record)
        return [StackMutation(item_id,"CREDIT",1)], self.projection.extra_drops(({"table_id":item_id,"item_num":1},))

    def _hero_by_table(self, table_id: int) -> dict[str, Any] | None:
        for hero in self.player.heroes.values() if isinstance(self.player.heroes, dict) else []:
            if isinstance(hero, dict) and self._int(hero.get("table_id"), 0) == table_id:
                return hero
        return None

    def _task_payload(self, rec: dict[str, Any], *, is_going: int = 1) -> dict[str, Any]:
        return self.projection.task_row(rec, is_going=is_going)

    def mission_list(self) -> dict[str, Any]:
        out = []
        for awake_type in (self.HERO, self.HERO_TWICE):
            rec = self._active(awake_type)
            if rec:
                out.append(rec)
        return self.projection.mission_list(out)

    def bootstrap_channels(self) -> dict[str, Any]:
        """Authoritative legacy LOAD_MISSION overlay for Awakening task channels.

        Modern relog hydration uses MID2561/TASK_LOAD_BY_TYPE full replacement.
        LOAD_MISSION is older/additive, so it must never resurrect generic mission
        shadow state; publish only the canonical AwakeningMissionService records.
        """
        out: dict[str, Any] = {"awake_mission_": [], "twice_awake_mission_": []}
        for awake_type in (self.HERO, self.HERO_TWICE):
            rec = self._active(awake_type)
            if rec:
                out.update(self.projection.mission_delta(awake_type, [rec]))
        return out

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
        mission_id=self._int(req.get("mission_id"),0); awake_type=self._int(req.get("awake_type"),0)
        row=self._row(mission_id,awake_type)
        if row is None or self._int(row.get("stage"),0)!=1:return {"error_code":1,"msg":"invalid_awake_mission"}
        active=self._active(awake_type)
        if active:
            if self._int(active.get("mission_id"))==mission_id:
                replay=self.state.find_replay(awake_type=awake_type,generation=self._int(active.get("generation")),mission_id=mission_id,operation="open")
                if replay is not None:return replay
            return {"error_code":1,"msg":"awake_mission_already_active"}
        hero=self._hero_by_table(self._int(row.get("table_id"),0))
        if hero is None:return {"error_code":1,"msg":"awake_hero_not_owned"}
        if awake_type==self.HERO:
            if self._int(hero.get("lev"),0)<self.ORDINARY_OPEN_LEVEL:return {"error_code":1,"msg":"awake_level_too_low"}
        elif awake_type==self.HERO_TWICE:
            if self._int(hero.get("lev"),0)<self.BLOOD_OPEN_LEVEL or self._int(hero.get("color"),0)<self.BLOOD_OPEN_COLOR:return {"error_code":1,"msg":"blood_awake_requirement_not_met"}
            if self._int(hero.get("twice_awake_stage"),0)!=0:return {"error_code":1,"msg":"blood_awake_already_started"}
        else:return {"error_code":1,"msg":"unsupported_awake_type"}
        def mutate():
            generation=self.state.allocate_generation(awake_type)
            rec={"mission_id":mission_id,"awake_type":awake_type,"hero_partner_id":self._int(hero.get("partner_id"),0),"hero_table_id":self._int(row.get("table_id"),0),"stage":1,"generation":generation,"complete":False,"count":0,"opened_at":self.player.now()}
            self._set_active(awake_type,rec)
            ops,extra=self._event_activation_grant(awake_type=awake_type,mission_id=mission_id,generation=generation)
            if awake_type==self.HERO_TWICE:ops.append(EntityMutation("HERO",rec["hero_partner_id"],"SET_TWICE_AWAKE_STAGE",amount=1))
            if ops:
                self.settlement.apply(MutationPlan(schema_version=1,plan_id=f"awakening:open:{awake_type}:{mission_id}:{generation}",origin=MutationOrigin(domain="awakening_mission",operation="open",protocol_mid=2738),actor=ActorRef(player_id=str(self.player.player_id)),expected_state_version=None,idempotency=IdempotencySpec(),preconditions=(),operations=tuple(ops)))
            response=self._merge_payloads(self.projection.mission_delta(awake_type,[rec]),extra or {})
            self.state.remember_transition(awake_type=awake_type,generation=generation,mission_id=mission_id,operation="open",replay_payload=response)
            return response
        try:return self._run(mid=2738,operation="open",fn=mutate)
        except MutationSettlementError:return {"error_code":1}

    def give_up(self, req: dict[str, Any]) -> dict[str, Any]:
        mission_id=self._int(req.get("mission_id"),0); awake_type=self._int(req.get("awake_type"),0); rec=self._active(awake_type)
        if not rec:
            replay=self.state.find_latest_replay(awake_type=awake_type,mission_id=mission_id,operation="give_up")
            return replay if replay is not None else {"error_code":1,"msg":"awake_mission_not_active"}
        if self._int(rec.get("mission_id"),0)!=mission_id:return {"error_code":1,"msg":"awake_mission_not_active"}
        row=self._row(mission_id,awake_type) or {}; generation=self._int(rec.get("generation"),1)
        def mutate():
            ops=[]; purged={}
            for item_id in row.get("delete_items") or []:
                iid=self._int(item_id,0); count=self.inventory.get_item_num(iid)
                if iid>0 and count>0:ops.append(StackMutation(iid,"DEBIT",count)); purged[iid]=count
            if awake_type==self.HERO_TWICE:ops.append(EntityMutation("HERO",self._int(rec.get("hero_partner_id"),0),"SET_TWICE_AWAKE_STAGE",amount=0))
            if ops:self.settlement.apply(MutationPlan(schema_version=1,plan_id=f"awakening:giveup:{awake_type}:{mission_id}:{generation}",origin=MutationOrigin(domain="awakening_mission",operation="give_up",protocol_mid=2737),actor=ActorRef(player_id=str(self.player.player_id)),expected_state_version=None,idempotency=IdempotencySpec(),preconditions=(),operations=tuple(ops)))
            policy=self.compatibility.event(awake_type,mission_id); ent=self.state.event_entitlement(awake_type,mission_id)
            if policy is not None and ent is not None and bool(policy.get("odin_restore_after_source_giveup")):
                material=self._int(policy.get("intermediate_item")); gear=self._int(policy.get("exclusive_gear_item"))
                if purged.get(material,0)>0 and self.inventory.get_item_num(gear)<=0:
                    updated=dict(ent); updated["status"]="RESTORABLE"; updated["last_giveup_generation"]=generation; self.state.set_event_entitlement(awake_type,mission_id,updated)
            self._set_active(awake_type,None)
            response=self.projection.mission_delta(awake_type,[rec],is_going=0)
            self.state.remember_transition(awake_type=awake_type,generation=generation,mission_id=mission_id,operation="give_up",replay_payload=response)
            return response
        try:return self._run(mid=2737,operation="give_up",fn=mutate)
        except MutationSettlementError:return {"error_code":1}

    def stage1_equipment_context(self, partner_id: Any, equip_index: Any) -> tuple[int, dict[str, Any], int] | None:
        """Resolve the one active source-special stage-one equipment command."""
        pid=self._int(partner_id,0); index=self._int(equip_index,0)
        if pid<=0 or not (1<=index<=6): return None
        for awake_type in (self.HERO,self.HERO_TWICE):
            rec=self._active(awake_type)
            if not rec or self._int(rec.get("stage"),0)!=1 or self._int(rec.get("hero_partner_id"),0)!=pid: continue
            route=self._route(self._int(rec.get("mission_id")),awake_type)
            exclusive=self._int((route or {}).get("exclusive_gear_item"),0)
            if exclusive>0: return awake_type,rec,exclusive
        return None

    def mark_stage1_equipped(self, *, awake_type: int, generation: int, mission_id: int,
                              partner_id: int, equip_index: int, request_fingerprint: str) -> dict[str, Any]:
        """Mark stage1 complete inside an already-active request UoW."""
        if not self.uow.active: raise MutationSettlementError("stage1 equipment completion requires active UoW")
        rec=self._active(awake_type)
        if not rec or self._int(rec.get("mission_id"))!=self._int(mission_id) or self._int(rec.get("generation"))!=self._int(generation):
            raise MutationSettlementError("awakening stage1 generation changed")
        if self._int(rec.get("hero_partner_id"))!=self._int(partner_id) or self._int(rec.get("stage"))!=1:
            raise MutationSettlementError("awakening stage1 Hero mismatch")
        row=self._row(mission_id,awake_type) or {}
        rec=dict(rec); rec["complete"]=True; rec["count"]=max(1,self._int(row.get("task_num"),1)); rec["equip_index"]=self._int(equip_index)
        self._set_active(awake_type,rec)
        response=self.projection.mission_delta(awake_type,[rec])
        self.state.remember_transition(awake_type=awake_type,generation=generation,mission_id=mission_id,
            operation="stage1_equip",request_fingerprint=request_fingerprint,replay_payload=response)
        return response

    def get_awake_item(self, req: dict[str, Any]) -> dict[str, Any]:
        if self._int(req.get("item_num",1),1)!=1:return {"error_code":1}
        rec=self._active(self.HERO)
        if not rec or self._int(rec.get("stage"),0)!=1:return {"error_code":1,"msg":"ordinary_awake_stage1_not_active"}
        route=self._route(self._int(rec.get("mission_id")),self.HERO)
        material=self._int((route or {}).get("material_item"),0)
        if not self.compatibility.wish_allowed(material):return {"error_code":1,"msg":"awake_wish_not_available"}
        def mutate():
            self.settlement.apply(MutationPlan(schema_version=1,plan_id=f"awakening:wish:{self._int(rec.get('generation'),1)}:{self.uow.current_state_version}",origin=MutationOrigin(domain="awakening_mission",operation="wish_bottle",protocol_mid=171),actor=ActorRef(player_id=str(self.player.player_id)),expected_state_version=None,idempotency=IdempotencySpec(),preconditions=(),operations=(StackMutation(self.compatibility.wish_item_id,"DEBIT",1),StackMutation(material,"CREDIT",1))))
            return {"item_id":material,"item_num":1}
        try:return self._run(mid=171,operation="wish_bottle",fn=mutate)
        except MutationSettlementError:return {"error_code":1}

    def claim(self, table_id: Any) -> dict[str, Any] | None:
        mission_id = self._int(table_id, 0)
        rec = None; awake_type = 0
        for candidate in (self.HERO, self.HERO_TWICE):
            active = self._active(candidate)
            if active and self._int(active.get("mission_id"), 0) == mission_id:
                rec, awake_type = active, candidate; break
        if rec is None:
            # MID161 has no nonce/generation field. Stage-one and terminal claims
            # therefore retain bounded semantic replay records for commit-then-
            # response-loss recovery. Mission IDs are disjoint across types/stages.
            for candidate in (self.HERO,self.HERO_TWICE):
                replay=self.state.find_latest_replay(awake_type=candidate,mission_id=mission_id,operation="claim_stage1")
                if replay is not None: return replay
                replay=self.state.find_latest_replay(awake_type=candidate,mission_id=mission_id,operation="claim_terminal",terminal=True)
                if replay is not None: return replay
            return None
        if not rec.get("complete"):
            return {"error_code": 1, "msg": "awake_mission_incomplete"}
        row = self._row(mission_id, awake_type) or {}
        next_id = self._int(row.get("next_task_id"), 0)
        generation=self._int(rec.get("generation"),1)

        def mutate():
            if next_id > 0:
                nxt = self._row(next_id, awake_type)
                if nxt is None:
                    return {"error_code": 1, "msg": "awake_next_mission_missing"}
                next_rec = {**rec, "mission_id": next_id, "stage": self._int(nxt.get("stage"), 2),
                    "complete": False, "count": 0}
                next_rec.pop("equip_index",None)
                self._set_active(awake_type, next_rec)
                response=self.projection.mission_delta(awake_type,[next_rec])
                if awake_type == self.HERO_TWICE:
                    self._entity(self._int(rec.get("hero_partner_id"), 0), "SET_TWICE_AWAKE_STAGE", amount=2)
                    response=self._merge_payloads(response,self.projection.twice_awake_stage(
                        table_id=self._int(rec.get("hero_table_id"),0),stage=2))
                self.state.remember_transition(awake_type=awake_type,generation=generation,mission_id=mission_id,
                    operation="claim_stage1",replay_payload=response)
                return response

            # Stage E terminal settlement. Persist the durable Hero mutation
            # before responding, but do not project ordinary table_id: stock
            # TaskAwakeCell looks up the old Hero identity inside the MID161 callback
            # and only then changes its local table ID.
            pid = self._int(rec.get("hero_partner_id"), 0)
            ops: list[Any] = []
            response: dict[str, Any] = {}
            if awake_type == self.HERO:
                target = self._int(row.get("awaken_table_id"), 0)
                if target <= 0:
                    return {"error_code": 1, "msg": "awake_target_missing"}
                ops.append(EntityMutation("HERO", pid, "AWAKEN_TABLE_ID", indices=(target,)))
                # COMPATIBILITY_POLICY P204-COMP-KONGMING-BOOKS: all recovered
                # ZhugeFestival acquisition surfaces are dead. Final ordinary
                # KongMing Awakening grants one of each missing persistent Book-V
                # ownership token; only newly granted tokens are projected.
                if mission_id == 1144003 and target == KongMingAwakeSkillService.AWAKEN_TABLE_ID:
                    granted = []
                    for item_id in KongMingAwakeSkillService.ownership_books():
                        if self.inventory.get_item_num(item_id) <= 0:
                            ops.append(StackMutation(item_id, "CREDIT", 1))
                            granted.append({"table_id": item_id, "item_num": 1})
                    if granted:
                        response.update(self.projection.extra_drops(granted))
            else:
                ops.append(EntityMutation("HERO", pid, "SET_TWICE_AWAKE_STAGE", amount=3))
                response.update(self.projection.twice_awake_stage(
                    table_id=self._int(rec.get("hero_table_id"), 0), stage=3
                ))
            self.settlement.apply(MutationPlan(
                schema_version=1,
                plan_id=f"awakening:terminal:{awake_type}:{mission_id}:{generation}",
                origin=MutationOrigin(domain="awakening_mission",operation="claim_terminal",protocol_mid=161),
                actor=ActorRef(player_id=str(self.player.player_id)),
                expected_state_version=None,idempotency=IdempotencySpec(),preconditions=(),operations=tuple(ops),
            ))
            self._set_active(awake_type, None)
            self.state.remember_transition(
                awake_type=awake_type,generation=generation,mission_id=mission_id,
                operation="claim_terminal",replay_payload=response,terminal=True,
            )
            return response
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
        return self.projection.mission_delta(self.HERO, [rec])

    def unlimited_start(self, req: dict[str, Any]) -> dict[str, Any]:
        mid = self._int(req.get("twice_awake_mission"), 0)
        rec = self._active(self.HERO_TWICE)
        if not rec or self._int(rec.get("mission_id"), 0) != mid or self._int(rec.get("stage"), 0) != 2:
            return {"error_code": 1, "msg": "blood_awake_mission_not_active"}
        if self._int(req.get("incubus_id"), 0) != mid:
            return {"error_code": 1, "msg": "blood_awake_incubus_mismatch"}
        if bool(rec.get("complete")):
            return {"error_code": 1, "msg": "blood_awake_trial_already_complete"}
        row = self._row(mid, self.HERO_TWICE) or {}
        if mid not in [self._int(v,0) for v in row.get("trial_challenge") or []]:
            return {"error_code": 1, "msg": "blood_awake_trial_source_mismatch"}
        generation = self._int(rec.get("generation"), 0)
        def mutate():
            current = self._active(self.HERO_TWICE)
            if not current or self._int(current.get("generation"),0) != generation or bool(current.get("complete")):
                raise MutationSettlementError("blood awakening generation changed")
            current = dict(current)
            current["trial_session"] = {
                "mission_id": mid,
                "incubus_id": mid,
                "generation": generation,
                "started_at": self.player.now(),
            }
            self._set_active(self.HERO_TWICE, current)
            return {}
        try:
            return self._run(mid=866, operation="blood_fight_start", fn=mutate)
        except MutationSettlementError:
            return {"error_code": 1}

    def unlimited_result(self, req: dict[str, Any]) -> dict[str, Any]:
        mid = self._int(req.get("twice_awake_mission"), 0)
        rec = self._active(self.HERO_TWICE)
        if mid <= 0 or not rec or self._int(rec.get("mission_id"), 0) != mid or self._int(rec.get("stage"), 0) != 2:
            return {"error_code": 1, "msg": "blood_awake_result_not_active"}
        if self._int(req.get("incubus_id"), 0) != mid:
            return {"error_code": 1, "msg": "blood_awake_incubus_mismatch"}
        # SOURCE_FACT: recovered winning Blood branch sends num=20,npc_ids=[];
        # losses return locally and do not call MID867. No roster is available.
        if self._int(req.get("num"), -1) != 20:
            return {"error_code": 1, "msg": "blood_awake_terminal_num_mismatch"}
        npc_ids = req.get("npc_ids")
        if not isinstance(npc_ids, list) or npc_ids:
            return {"error_code": 1, "msg": "blood_awake_terminal_npc_mismatch"}
        generation = self._int(rec.get("generation"), 0)
        if bool(rec.get("complete")):
            replay = self.state.find_replay(
                awake_type=self.HERO_TWICE,generation=generation,mission_id=mid,
                operation="blood_trial_complete",
            )
            return replay if replay is not None else {"error_code":1,"msg":"blood_awake_result_already_complete"}
        session = rec.get("trial_session") if isinstance(rec.get("trial_session"), dict) else None
        if not session or self._int(session.get("mission_id"),0)!=mid or self._int(session.get("incubus_id"),0)!=mid or self._int(session.get("generation"),0)!=generation:
            return {"error_code": 1, "msg": "blood_awake_trial_session_missing"}
        row = self._row(mid, self.HERO_TWICE) or {}
        if mid not in [self._int(v,0) for v in row.get("trial_challenge") or []]:
            return {"error_code": 1, "msg": "blood_awake_trial_source_mismatch"}
        def mutate():
            current = self._active(self.HERO_TWICE)
            if not current or self._int(current.get("generation"),0)!=generation or bool(current.get("complete")):
                raise MutationSettlementError("blood awakening result generation changed")
            current = dict(current)
            current["complete"] = True
            current["count"] = max(1, self._int(row.get("task_num"), 1))
            trial = dict(current.get("trial_session") or {})
            trial["terminal_num"] = 20
            trial["terminal_npc_ids"] = []
            current["trial_session"] = trial
            self._set_active(self.HERO_TWICE, current)
            response = {**self.projection.mission_delta(self.HERO_TWICE, [current]), "items": []}
            self.state.remember_transition(
                awake_type=self.HERO_TWICE,generation=generation,mission_id=mid,
                operation="blood_trial_complete",replay_payload=response,
            )
            return response
        try:
            return self._run(mid=867, operation="blood_fight_result", fn=mutate)
        except MutationSettlementError:
            return {"error_code": 1}
