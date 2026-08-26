"""Gods Trial / HUNQI campaign domain service.

Pass166 introduced the MID3101 startup projection. Pass170 H5 activates the
source-bounded campaign info, manual battle and auto-battle state machines while
reusing PlayerUnitOfWork, TemporalPolicyService, RewardTransactionService and
the H3 Horcrux generated-reward owner.
"""
from __future__ import annotations

import copy
from typing import Any, Iterable

from gxb_backend.content.game_data_catalog import CatalogNamespace, ContentRef, GameDataCatalog
from gxb_backend.content.horcrux_source_catalog import HorcruxSourceCatalog
from .gods_trial_drop_planner import GodsTrialDropOccurrence, GodsTrialDropPlanner
from .hero_repository import HeroRepository
from .horcrux_policy import HorcruxPolicyRegistry
from .horcrux_repository import HorcruxRepository
from .player_state import PlayerState
from .reward_transaction_service import (
    InventoryGrant,
    RewardOrigin,
    RewardPlan,
    RewardResult,
    RewardTransactionService,
    SpecializedGrant,
)
from .server_clock import ServerClock, ServerDayClock
from .temporal_policy_service import TemporalInsufficientBalance, TemporalPolicyService
from .unit_of_work import OperationContext, UnitOfWork


class GodsTrialServiceError(ValueError):
    pass


class GodsTrialService:
    SPIRIT_OWNER = "SPIRIT"
    TERMINAL_REPLAY_ERROR = 30005

    def __init__(
        self,
        player: PlayerState,
        source: HorcruxSourceCatalog,
        policy: HorcruxPolicyRegistry,
        repository: HorcruxRepository,
        temporal: TemporalPolicyService,
        uow: UnitOfWork,
        *,
        heroes: HeroRepository,
        catalog: GameDataCatalog,
        rewards: RewardTransactionService,
        drops: GodsTrialDropPlanner,
        server_clock: ServerClock | None = None,
    ) -> None:
        self.player = player
        self.source = source
        self.policy = policy
        self.repository = repository
        self.temporal = temporal
        self.uow = uow
        self.heroes = heroes
        self.catalog = catalog
        self.rewards = rewards
        self.drops = drops
        self.server_clock = server_clock or ServerClock()
        self.day_clock = ServerDayClock(self.server_clock)

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _context(self, mid: int, operation: str, key: str | None = None) -> OperationContext:
        return OperationContext(
            actor_player_id=str(self.player.player_id),
            domain="horcrux.trial",
            operation_name=operation,
            protocol_mid=mid,
            idempotency_key=key,
            idempotency_mode="POSTCONDITION" if key else "NONE",
            server_time=self.server_clock.now(),
        )

    @property
    def _trial(self) -> dict[str, Any]:
        state = self.repository.state
        trial = state.get("trial")
        if not isinstance(trial, dict):
            raise GodsTrialServiceError("Gods Trial state is not initialized")
        return trial

    def _mark_state(self) -> None:
        if not self.uow.active:
            raise RuntimeError("Gods Trial mutation requires active PlayerUnitOfWork")
        self.uow.mark_changed("horcrux_state")

    def _source_day_id(self) -> int:
        return int(self.day_clock.day_id())

    def current_weekday(self) -> int:
        # Source-day 0 is 1970-01-01, a Thursday (ISO weekday 4).
        return ((self._source_day_id() + 3) % 7) + 1

    def _base_info_raw(self) -> dict[str, int]:
        auto = self._trial.get("auto")
        auto = auto if isinstance(auto, dict) else {}
        running = str(auto.get("status") or "IDLE").upper() == "RUNNING"
        return {
            "auto_campaign": self._int(auto.get("campaign_id"), 0) if running else 0,
            "auto_times": self._int(auto.get("times"), 0) if running else 0,
            "auto_start_time": self._int(auto.get("auto_start_time"), 0) if running else 0,
        }

    def base_info(self, *, materialize_energy: bool = False) -> dict[str, int]:
        if not materialize_energy:
            return self._base_info_raw()
        with self.uow.transaction(self._context(3101, "materialize_startup")):
            self.temporal.materialize("spirit_energy", persist=False, publish=True)
            return self._base_info_raw()

    def startup_payload(self, *, materialize_temporal: bool = True) -> dict[str, int]:
        # Preserve the H1 compatibility seam used by maintenance/self-tests while
        # making the default MID3101 path materialize the canonical Spirit Energy.
        if materialize_temporal:
            if self.uow.active:
                self.temporal.materialize("spirit_energy", persist=False, publish=False)
            else:
                with self.uow.transaction(self._context(3101, "startup_info")):
                    self.temporal.materialize("spirit_energy", persist=False, publish=False)
        return self._base_info_raw()

    def _progress(self, campaign_id: int) -> int:
        root = self._trial.get("campaign_progress")
        if not isinstance(root, dict):
            return 0
        row = root.get(str(int(campaign_id)))
        return max(0, self._int(row.get("win_count"), 0)) if isinstance(row, dict) else 0

    def _set_progress(self, campaign_id: int, win_count: int) -> None:
        if not self.uow.active:
            raise RuntimeError("Gods Trial progression mutation requires active PlayerUnitOfWork")
        root = self._trial.setdefault("campaign_progress", {})
        if not isinstance(root, dict):
            root = {}
            self._trial["campaign_progress"] = root
        root[str(int(campaign_id))] = {"win_count": max(0, int(win_count))}
        self._mark_state()

    def _campaign(self, campaign_id: Any) -> tuple[int, Any]:
        cid = self._int(campaign_id, 0)
        row = self.source.campaign(cid)
        if cid <= 0 or row is None:
            raise GodsTrialServiceError(f"unknown Gods Trial campaign_id {cid}")
        return cid, row

    def _is_open(self, campaign_id: int, row: Any, *, weekday: int | None = None) -> bool:
        day = self.current_weekday() if weekday is None else int(weekday)
        if int(row.get("day", 0) or 0) != day:
            return False
        if int(row.get("is_open", 0) or 0) == 0:
            return False
        if int(self.player.lev or 0) < int(row.get("level", 0) or 0):
            return False
        previous = int(row.get("last_campaign", 0) or 0)
        return previous <= 0 or self._progress(previous) > 0

    def campaign_info(self) -> dict[str, Any]:
        with self.uow.transaction(self._context(3097, "get_campaign_info")):
            self.temporal.materialize("spirit_energy", persist=False, publish=True)
            day = self.current_weekday()
            infos: dict[str, dict[str, int]] = {}
            for row in self.source.campaigns_for_day(day):
                cid = int(row.get("id", 0) or 0)
                infos[str(cid)] = {
                    "is_open": 1 if self._is_open(cid, row, weekday=day) else 0,
                    "win_count": self._progress(cid),
                }
            return {
                "base_info": self._base_info_raw(),
                "campaign_infos": infos,
                "day": day,
                "day_info": {},
            }

    def _validate_campaign_entry(self, campaign_id: Any, campaign_type: Any, *, require_cleared: bool = False):
        cid, row = self._campaign(campaign_id)
        ctype = self._int(campaign_type, 0)
        if ctype != self.source.trial_campaign_type:
            raise GodsTrialServiceError(
                f"invalid Gods Trial campaign_type {ctype}; expected {self.source.trial_campaign_type}"
            )
        if not self._is_open(cid, row):
            raise GodsTrialServiceError(f"Gods Trial campaign {cid} is not currently open")
        if require_cleared and self._progress(cid) <= 0:
            raise GodsTrialServiceError(f"Gods Trial campaign {cid} has not been cleared")
        if self.repository.owned_count() >= self.source.spirit_num_limit:
            raise GodsTrialServiceError("Horcruxes have reached MAX")
        return cid, row

    def _formation(self, value: Any) -> tuple[int, ...]:
        if isinstance(value, str):
            parts = [part for part in value.split("|") if part != ""]
        elif isinstance(value, (list, tuple)):
            parts = list(value)
        else:
            raise GodsTrialServiceError("formation must be a pipe string or list")
        if not 1 <= len(parts) <= 6:
            raise GodsTrialServiceError("Gods Trial formation must contain 1..6 Heroes")
        out: list[int] = []
        for raw in parts:
            pid = self._int(raw, 0)
            if pid <= 0 or self.heroes.get(pid) is None:
                raise GodsTrialServiceError(f"unknown formation partner_id {pid}")
            out.append(pid)
        if len(set(out)) != len(out):
            raise GodsTrialServiceError("Gods Trial formation contains duplicate Heroes")
        return tuple(out)

    def _energy_balance(self) -> int:
        return int(self.temporal.preview("spirit_energy", "MATERIALIZE", 0).materialized.balance)

    def _require_energy(self, amount: int) -> None:
        amount = max(0, int(amount))
        if self._energy_balance() < amount:
            raise GodsTrialServiceError("insufficient Spirit Energy")

    def start_fight(self, campaign_id: Any, campaign_type: Any, formation: Any, pet_id: Any = 0) -> dict[str, Any]:
        cid, row = self._validate_campaign_entry(campaign_id, campaign_type)
        normalized_formation = self._formation(formation)
        pet = max(0, self._int(pet_id, 0))
        self._require_energy(int(row.get("win_cost_num", 0) or 0))

        active = self._trial.get("active_battle")
        active = active if isinstance(active, dict) else {}
        same_stage = (
            str(active.get("status") or "").upper() == "STAGED"
            and self._int(active.get("campaign_id"), 0) == cid
            and self._int(active.get("campaign_type"), 0) == self.source.trial_campaign_type
            and tuple(self._int(v, 0) for v in active.get("formation", []) if self._int(v, 0) > 0) == normalized_formation
            and self._int(active.get("pet_id"), 0) == pet
        )
        if same_stage:
            payload = active.get("staged_response")
            return copy.deepcopy(payload) if isinstance(payload, dict) else {}

        # Validation above is deliberately complete before replacing a prior
        # staged/terminal session, so malformed retries cannot destroy it.
        with self.uow.transaction(self._context(3092, "start_fight", f"battle:{cid}")):
            # Re-check state-sensitive entry conditions inside transaction.
            self._validate_campaign_entry(cid, campaign_type)
            self._formation(normalized_formation)
            self._require_energy(int(row.get("win_cost_num", 0) or 0))
            self._trial["active_battle"] = {
                "status": "STAGED",
                "campaign_id": cid,
                "campaign_type": self.source.trial_campaign_type,
                "formation": list(normalized_formation),
                "pet_id": pet,
                "source_day_id": self._source_day_id(),
                "weekday": self.current_weekday(),
                "started_at": self.server_clock.now(),
                "staged_response": {},
            }
            self._mark_state()
        return {}

    @staticmethod
    def _reward_wire(result: RewardResult) -> tuple[list[dict[str, int]], list[dict[str, Any]]]:
        return list(result.inventory_awards), list(result.specialized_awards.get("SPIRIT", []))

    def _reward_plan(
        self, campaign_id: int, occurrences: Iterable[GodsTrialDropOccurrence],
        *, first_clear: bool, protocol_mid: int = 3093, operation: str | None = None,
    ) -> RewardPlan:
        inventory: list[InventoryGrant] = []
        specialized: list[SpecializedGrant] = []
        for occurrence in occurrences:
            ref = ContentRef(CatalogNamespace.ITEM, int(occurrence.item_id))
            item = self.catalog.get(ref)
            amount = int(occurrence.quantity)
            if int(item.get("type", 0) or 0) == 24:
                specialized.append(SpecializedGrant(owner=self.SPIRIT_OWNER, content=ref, amount=amount))
            else:
                inventory.append(InventoryGrant(content=ref, amount=amount))
        return RewardPlan(
            origin=RewardOrigin(
                domain="horcrux.trial",
                operation=operation or ("first_clear" if first_clear else "repeat_clear"),
                protocol_mid=int(protocol_mid),
                source_table="data/tables/spirit_campaign.lua+campaign_dropbox.lua",
                source_id=int(campaign_id),
                field_path="init_dropbox" if first_clear else "dropbox",
            ),
            inventory=tuple(inventory),
            specialized=tuple(specialized),
        )

    def _terminal_replay(self, active: dict[str, Any]) -> dict[str, Any]:
        payload = active.get("terminal_response")
        out = copy.deepcopy(payload) if isinstance(payload, dict) else {"items": [], "spirit_items": []}
        out["error_code"] = self.TERMINAL_REPLAY_ERROR
        return out

    def fight_result(
        self,
        campaign_id: Any,
        campaign_type: Any,
        partner_ids: Any,
        star: Any,
        pet_id: Any = 0,
    ) -> dict[str, Any]:
        cid = self._int(campaign_id, 0)
        ctype = self._int(campaign_type, 0)
        try:
            formation = self._formation(partner_ids)
        except GodsTrialServiceError:
            formation = ()
        pet = max(0, self._int(pet_id, 0))
        active = self._trial.get("active_battle")
        active = active if isinstance(active, dict) else {}
        status = str(active.get("status") or "").upper()
        same_identity = (
            self._int(active.get("campaign_id"), 0) == cid
            and self._int(active.get("campaign_type"), 0) == ctype
            and tuple(self._int(v, 0) for v in active.get("formation", []) if self._int(v, 0) > 0) == formation
            and self._int(active.get("pet_id"), 0) == pet
        )
        if status == "TERMINAL" and same_identity:
            return self._terminal_replay(active)
        if status != "STAGED" or not same_identity:
            # Stock client treats 30005 as a terminal result-drain condition.
            return {"error_code": self.TERMINAL_REPLAY_ERROR, "items": [], "spirit_items": []}

        cid, row = self._campaign(cid)
        won = self._int(star, 0) > 0
        with self.uow.transaction(self._context(3093, "fight_result", f"battle:{cid}")):
            current = self._trial.get("active_battle")
            if not isinstance(current, dict) or str(current.get("status") or "").upper() != "STAGED":
                raise GodsTrialServiceError("Gods Trial battle is not staged")
            if (
                self._int(current.get("campaign_id"), 0) != cid
                or self._int(current.get("campaign_type"), 0) != ctype
                or tuple(self._int(v, 0) for v in current.get("formation", []) if self._int(v, 0) > 0) != formation
                or self._int(current.get("pet_id"), 0) != pet
            ):
                raise GodsTrialServiceError("Gods Trial result does not match staged battle")

            cost = int(row.get("win_cost_num" if won else "lose_cost_num", 0) or 0)
            try:
                self.temporal.debit("spirit_energy", cost, persist=False, publish=True)
            except TemporalInsufficientBalance as exc:
                raise GodsTrialServiceError("insufficient Spirit Energy") from exc

            items: list[dict[str, int]] = []
            spirits: list[dict[str, Any]] = []
            if won:
                before = self._progress(cid)
                first_clear = before == 0
                pool_id = int(row.get("init_dropbox" if first_clear else "dropbox", 0) or 0)
                occurrences = self.drops.first_clear(pool_id) if first_clear else self.drops.repeat(pool_id)
                result = self.rewards.apply(self._reward_plan(cid, occurrences, first_clear=first_clear))
                items, spirits = self._reward_wire(result)
                self._set_progress(cid, before + 1)

            terminal = {"items": items, "spirit_items": spirits}
            current["status"] = "TERMINAL"
            current["settled_at"] = self.server_clock.now()
            current["star"] = self._int(star, 0)
            current["terminal_response"] = copy.deepcopy(terminal)
            self._mark_state()
            return terminal

    def start_auto(self, campaign_id: Any, times: Any) -> dict[str, int]:
        cid, row = self._campaign(campaign_id)
        try:
            times_i = int(times)
        except (TypeError, ValueError) as exc:
            raise GodsTrialServiceError("auto times must be an integer") from exc
        if not 1 <= times_i <= self.source.spirit_auto_limit:
            raise GodsTrialServiceError(f"auto times must be 1..{self.source.spirit_auto_limit}")

        auto = self._trial.get("auto")
        auto = auto if isinstance(auto, dict) else {}
        if str(auto.get("status") or "IDLE").upper() == "RUNNING":
            if self._int(auto.get("campaign_id"), 0) == cid and self._int(auto.get("times"), 0) == times_i:
                return self._base_info_raw()
            raise GodsTrialServiceError("Gods Trial auto fight is already running")

        self._validate_campaign_entry(cid, self.source.trial_campaign_type, require_cleared=True)
        cost = int(row.get("win_cost_num", 0) or 0) * times_i
        self._require_energy(cost)

        now = self.server_clock.now()
        with self.uow.transaction(self._context(3099, "start_auto", f"auto:{cid}:{times_i}")):
            self._validate_campaign_entry(cid, self.source.trial_campaign_type, require_cleared=True)
            auto = self._trial.get("auto")
            if isinstance(auto, dict) and str(auto.get("status") or "IDLE").upper() == "RUNNING":
                if self._int(auto.get("campaign_id"), 0) == cid and self._int(auto.get("times"), 0) == times_i:
                    return self._base_info_raw()
                raise GodsTrialServiceError("Gods Trial auto fight is already running")
            try:
                self.temporal.debit("spirit_energy", cost, persist=False, publish=True)
            except TemporalInsufficientBalance as exc:
                raise GodsTrialServiceError("insufficient Spirit Energy") from exc
            run_id = max(1, self._int(self._trial.get("next_auto_run_id"), 1))
            self._trial["next_auto_run_id"] = run_id + 1
            self._trial["auto"] = {
                "status": "RUNNING",
                "run_id": run_id,
                "campaign_id": cid,
                "times": times_i,
                "auto_start_time": now,
                "complete_at": now + times_i * self.source.spirit_auto_minutes * 60,
            }
            self._trial["last_auto_collection"] = {}
            self._mark_state()
            return self._base_info_raw()

    def collect_auto(self) -> dict[str, Any]:
        auto = self._trial.get("auto")
        auto = auto if isinstance(auto, dict) else {}
        if str(auto.get("status") or "IDLE").upper() != "RUNNING":
            last = self._trial.get("last_auto_collection")
            if isinstance(last, dict) and isinstance(last.get("terminal_response"), dict):
                return copy.deepcopy(last["terminal_response"])
            raise GodsTrialServiceError("Gods Trial auto reward is not running")

        now = self.server_clock.now()
        complete_at = self._int(auto.get("complete_at"), 0)
        if now < complete_at:
            raise GodsTrialServiceError("Gods Trial auto reward is not ready")
        run_id = self._int(auto.get("run_id"), 0)
        cid = self._int(auto.get("campaign_id"), 0)
        times_i = self._int(auto.get("times"), 0)
        _, row = self._campaign(cid)

        with self.uow.transaction(self._context(3100, "collect_auto", f"auto-run:{run_id}")):
            current = self._trial.get("auto")
            if not isinstance(current, dict) or str(current.get("status") or "IDLE").upper() != "RUNNING":
                last = self._trial.get("last_auto_collection")
                if isinstance(last, dict) and isinstance(last.get("terminal_response"), dict):
                    return copy.deepcopy(last["terminal_response"])
                raise GodsTrialServiceError("Gods Trial auto reward is not running")
            if self._int(current.get("run_id"), 0) != run_id or self.server_clock.now() < self._int(current.get("complete_at"), 0):
                raise GodsTrialServiceError("Gods Trial auto reward is not ready")

            occurrences: list[GodsTrialDropOccurrence] = []
            pool_id = int(row.get("dropbox", 0) or 0)
            for _ in range(times_i):
                occurrences.extend(self.drops.repeat(pool_id))
            result = self.rewards.apply(self._reward_plan(
                cid, occurrences, first_clear=False, protocol_mid=3100, operation="auto_repeat",
            ))
            awards, spirit_awards = self._reward_wire(result)
            self._set_progress(cid, self._progress(cid) + times_i)
            self._trial["auto"] = {
                "status": "IDLE", "run_id": 0, "campaign_id": 0, "times": 0,
                "auto_start_time": 0, "complete_at": 0,
            }
            terminal = {
                "awards": awards,
                "spirit_awards": spirit_awards,
                "base_info": self._base_info_raw(),
            }
            self._trial["last_auto_collection"] = {
                "run_id": run_id,
                "campaign_id": cid,
                "times": times_i,
                "terminal_response": copy.deepcopy(terminal),
            }
            self._mark_state()
            return terminal
