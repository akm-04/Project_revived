"""Canonical Summon state with classic/private Vending activation.

Recovered MID50 operation/cost/pool/client contracts remain source authority.
The deterministic tutorial pulls stay intact, the runtime-mapped classic
paid operations execute under Custom Private Server Policy v1, and Pass41.9
adds the source/runtime-confirmed post-tutorial Small free-pull state split for
the same MID50 (type=1,index=1) protocol tuple. Pass42.6 corrects SX/Soul Box content classification and dynamic reward planning
through a dedicated private planner while ticket/coupon variants remain
fail closed; Pass42.14 activates the source/runtime-confirmed Small x100 topology; private policy is never represented as historical official RNG.
"""

from __future__ import annotations

import copy
import json
import time
from collections.abc import Callable
from pathlib import Path
from typing import Any

from gxb_backend.content import (
    AmbiguousContentReference,
    CatalogNamespace,
    GameDataCatalog,
    ResolveContext,
    UnknownContentReference,
)

from gxb_backend.content.magic_summon_source_catalog import MagicSummonSourceCatalog, MagicSummonTarget
from gxb_backend.content.summon_operation_catalog import (
    SummonOperationCatalog,
    SummonOperationDescriptor,
)

from .hero_repository import HeroRepository
from .inventory_repository import InventoryRepository
from .economy_repository import EconomyMutationError, EconomyRepository
from .reward_transaction_service import (
    InventoryGrant,
    RewardOrigin,
    RewardPlan,
    RewardTransactionService,
    RewardValidationError,
)
from .summon_operation_registry import SummonOperationRegistry
from .summon_cost_plan import SummonCostPlanRegistry
from .summon_counter_policy import (
    SummonCounterPolicyRegistry,
    SummonCounterEngine,
    SummonCounterTransitionUnavailable,
    UnresolvedSummonCounterEngine,
)
from .summon_duplicate_conversion import (
    SummonDuplicateCandidate,
    SummonDuplicateConversionResolver,
    SummonDuplicateConversionUnavailable,
    UnresolvedSummonDuplicateConversionResolver,
)
from .summon_operation_receipt import (
    PaidSummonOperationReceiptStore,
    SummonOperationReceiptStore,
    SummonReceiptIdentity,
)
from .summon_private_policy import ClassicVendingPrivatePlanner, SummonPrivateServerPolicy
from .summon_featured_rotation import SummonFeaturedRotationPolicy
from .medium_legacy_private_policy import MediumLegacyPrivatePlanner, MediumLegacyPrivatePolicy
from .magic_summon_private_policy import MagicSummonPrivatePlanner, MagicSummonPrivatePolicy
from gxb_backend.content.sx_soul_box_source_catalog import SXSoulBoxSourceCatalog
from .sx_soul_box_private_policy import SXSoulBoxPrivatePlanner, SXSoulBoxPrivatePolicy
from .summon_result_plan import (
    SummonResultPlan,
    SummonResultPlanUnavailable,
    SummonResultRenderer,
    SummonResultRowPlan,
)
from .summon_result_policy import SummonResultPolicyRegistry
from .summon_state_contract import SummonStateContract
from .unit_of_work import OperationContext, UnitOfWork
from .player_state import PlayerState


SANDBOX_UID = "13371337"


class SummonRepository:
    """Own MID56 state and the explicitly activated MID50 operation slice."""

    META_FILE = "tutorial_summon_meta.json"

    def __init__(
        self,
        player: PlayerState,
        data_dir: Path | None = None,
        save_callback: Callable[[], None] | None = None,
        *,
        heroes: HeroRepository | None = None,
        inventory: InventoryRepository | None = None,
        economy: EconomyRepository | None = None,
        catalog: GameDataCatalog | None = None,
        rewards: RewardTransactionService | None = None,
        operation_catalog: SummonOperationCatalog | None = None,
        operation_registry: SummonOperationRegistry | None = None,
        state_contract: SummonStateContract | None = None,
        cost_plans: SummonCostPlanRegistry | None = None,
        counter_policies: SummonCounterPolicyRegistry | None = None,
        counter_engine: SummonCounterEngine | None = None,
        result_policy: SummonResultPolicyRegistry | None = None,
        result_renderer: SummonResultRenderer | None = None,
        duplicate_conversion: SummonDuplicateConversionResolver | None = None,
        private_policy: SummonPrivateServerPolicy | None = None,
        private_planner: ClassicVendingPrivatePlanner | None = None,
        featured_rotation: SummonFeaturedRotationPolicy | None = None,
        medium_legacy_policy: MediumLegacyPrivatePolicy | None = None,
        medium_legacy_planner: MediumLegacyPrivatePlanner | None = None,
        magic_source: MagicSummonSourceCatalog | None = None,
        magic_policy: MagicSummonPrivatePolicy | None = None,
        magic_planner: MagicSummonPrivatePlanner | None = None,
        sx_source: SXSoulBoxSourceCatalog | None = None,
        sx_policy: SXSoulBoxPrivatePolicy | None = None,
        sx_planner: SXSoulBoxPrivatePlanner | None = None,
        uow: UnitOfWork | None = None,
    ) -> None:
        self.player = player
        self.data_dir = Path(data_dir or "data")
        self._save_callback = save_callback
        self.heroes = heroes
        self.inventory = inventory
        self.economy = economy
        self.catalog = catalog
        self.rewards = rewards
        self.uow = uow
        self.meta = self._load_meta()
        self.operation_catalog = operation_catalog or SummonOperationCatalog(self.data_dir)
        self.operation_registry = operation_registry or SummonOperationRegistry(self.operation_catalog)
        self.state_contract = state_contract or SummonStateContract(self.data_dir)
        self.cost_plans = cost_plans or SummonCostPlanRegistry(self.data_dir)
        self.counter_policies = counter_policies or SummonCounterPolicyRegistry(self.data_dir)
        self.counter_engine = counter_engine or UnresolvedSummonCounterEngine()
        self.result_policy = result_policy or SummonResultPolicyRegistry(self.data_dir)
        self.result_renderer = result_renderer or SummonResultRenderer()
        self.duplicate_conversion = duplicate_conversion or UnresolvedSummonDuplicateConversionResolver()
        self.private_policy = private_policy
        self.private_planner = private_planner
        self.featured_rotation = featured_rotation
        self.medium_legacy_policy = medium_legacy_policy
        self.medium_legacy_planner = medium_legacy_planner
        self.magic_source = magic_source
        self.magic_policy = magic_policy
        self.magic_planner = magic_planner
        self.sx_source = sx_source
        self.sx_policy = sx_policy
        self.sx_planner = sx_planner
        self._validate_state_policy_alignment()

    def _validate_state_policy_alignment(self) -> None:
        """Reject drift between legacy tutorial seed metadata and 41.1 state policy."""
        small = self.state_contract.timer_policy("small")
        medium = self.state_contract.timer_policy("medium")
        free = self.meta.get("free_state") if isinstance(self.meta, dict) else None
        if small is None or medium is None or not isinstance(free, dict):
            raise RuntimeError("summon state policy is missing Small/Medium timer metadata")
        expected = (
            self._int(free.get("mana_duration"), 0),
            self._int(free.get("crystal_duration"), 0),
            self._int(free.get("mana_initial_count"), 0),
        )
        actual = (
            self._int(small.period_seconds, 0),
            self._int(medium.period_seconds, 0),
            self._int(small.configured_free_count, 0),
        )
        if expected != actual:
            raise RuntimeError(f"tutorial summon seed/state policy drift: meta={expected} policy={actual}")

    def _load_meta(self) -> dict[str, Any]:
        path = self.data_dir / self.META_FILE
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            if isinstance(data, dict):
                return data
        except Exception as exc:
            raise RuntimeError(f"cannot load source-derived summon metadata {path}: {exc}") from exc
        raise RuntimeError(f"invalid source-derived summon metadata: {path}")

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    @staticmethod
    def _positive_ids(value: Any, minimum: int) -> bool:
        return (
            isinstance(value, list)
            and len(value) >= minimum
            and all(SummonRepository._int(item, 0) > 0 for item in value[:minimum])
        )

    def _is_credential_tutorial_player(self) -> bool:
        uid = str(getattr(self.player, "account_uid", "") or "")
        if not uid or uid == SANDBOX_UID:
            return False
        guide_end = self._int(self.meta.get("guide_ids", {}).get("summon_end"), 100109)
        guide_id = self._int(getattr(self.player, "guide_id", 0), 0)
        # v0.8.0 credential characters can already be stuck inside this guide.
        # After the summon guide is complete we do not retroactively seed it.
        return guide_id <= guide_end

    def _hero_repo(self) -> HeroRepository:
        if self.heroes is not None:
            return self.heroes
        return HeroRepository(self.player, self._save_callback, self.data_dir)

    def _ensure_aquaris(self) -> bool:
        """Ensure the fresh tutorial's canonical partner_id=1 Aquaris.

        Do not overwrite a conflicting owned partner.  That would silently
        corrupt an already-established character; fresh v0.8.0 credentials have
        no heroes, so the intended migration path is conflict-free.
        """
        hero_meta = self.meta["heroes"]["aquaris"]
        repo = self._hero_repo()
        repo.normalize()
        wanted_pid = self._int(hero_meta["partner_id"])
        wanted_tid = self._int(hero_meta["table_id"])
        existing = repo.get(wanted_pid)
        if existing is not None:
            return False
        # If Aquaris already exists under a different partner id, do not mint a
        # duplicate. The tutorial requires ID 1, but such a state is outside the
        # v0.8.0 fresh-character migration we are repairing.
        for hero in self.player.heroes.values():
            if self._int(hero.get("table_id"), 0) == wanted_tid:
                return False
        repo.add_owned_hero(
            {
                "partner_id": wanted_pid,
                "table_id": wanted_tid,
                "star": self._int(hero_meta["star"], 1),
                "lev": 1,
                "exp": 0,
                "color": 1,
                "skills": [1, 1, 1, 1, 1, 1],
                "equips": [0, 0, 0, 0, 0, 0],
                "fumos": [0, 0, 0, 0, 0, 0],
                "is_board": 1,
                "board_card": 1,
            },
            persist=False,
        )
        return True

    def _mark_small_counter_after_tutorial(self) -> bool:
        policy = self.counter_policies.get("small_classic")
        if policy is None or not policy.transition_supported or not policy.persistence_key:
            return False
        state = self.player.summon
        if self._int(state.get(policy.persistence_key), 0) >= 1:
            return False
        state[policy.persistence_key] = 1
        return True

    def normalize(self, *, fresh_credential: bool | None = None) -> bool:
        """Normalize MID56 state and migrate v0.8 tutorial credentials."""
        changed = False
        if not isinstance(self.player.summon, dict):
            self.player.summon = {}
            changed = True
        state = self.player.summon
        display = self.meta["display_policy"]
        tutorial = self._is_credential_tutorial_player() if fresh_credential is None else bool(fresh_credential)

        for key in ("mana_id", "pet_id"):
            if self._int(state.get(key), 0) <= 0:
                state[key] = self._int(display[key])
                changed = True

        rotation = self.featured_rotation.snapshot() if self.featured_rotation is not None else None
        desired_main = (
            list(rotation.sx_week_ids) if rotation is not None
            else [self._int(v) for v in display["main_ids"]]
        )
        desired_second = (
            list(rotation.sx_day_ids) if rotation is not None
            else [self._int(v) for v in display["second_ids"]]
        )
        if list(state.get("main_ids") or []) != desired_main:
            state["main_ids"] = desired_main
            changed = True
        if list(state.get("second_ids") or []) != desired_second:
            state["second_ids"] = desired_second
            changed = True

        # Medium's server-driven partner_id remains Pandaria during the stock
        # tutorial.  Established characters use the deterministic daily Legacy
        # featured identity.  Changing the daily/manual target rebinds its
        # private pity counter instead of carrying pity to an unrelated Girl.
        desired_medium = self._int(display["partner_id"])
        if not tutorial and rotation is not None:
            desired_medium = int(rotation.medium_featured_id)
        if self._int(state.get("partner_id"), 0) != desired_medium:
            state["partner_id"] = desired_medium
            changed = True
        if not tutorial and self.medium_legacy_policy is not None:
            target_key = self.medium_legacy_policy.featured_target_key
            counter_key = self.medium_legacy_policy.featured_counter_key
            if self._int(state.get(target_key), 0) != desired_medium:
                state[target_key] = desired_medium
                state[counter_key] = 0
                changed = True
        if tutorial:
            if self._int(state.get("tutorial_seed_version"), 0) < 1:
                state["tutorial_seed_version"] = 1
                state["tutorial_enabled"] = 1
                changed = True
            if "mana_free_time" not in state or self._int(state.get("mana_free_time"), -1) < 0:
                state["mana_free_time"] = 0
                changed = True
            # v0.8.0 wrote future placeholder timestamps. Before either mapped
            # tutorial pull has happened, reset them to source "free ready".
            if not state.get("tutorial_mana_done") and not self._has_expected_hero("lavia"):
                if self._int(state.get("mana_free_time"), 0) != 0:
                    state["mana_free_time"] = 0
                    changed = True
            if "crystal_free_time" not in state or self._int(state.get("crystal_free_time"), -1) < 0:
                state["crystal_free_time"] = 0
                changed = True
            if not state.get("tutorial_crystal_done") and not self._has_expected_hero("pandaria"):
                if self._int(state.get("crystal_free_time"), 0) != 0:
                    state["crystal_free_time"] = 0
                    changed = True
            if "mana_free_num" not in state:
                small_policy = self.state_contract.timer_policy("small")
                state["mana_free_num"] = self._int(
                    small_policy.configured_free_count if small_policy is not None else None, 5
                )
                changed = True
            if self._ensure_aquaris():
                changed = True
        else:
            now = int(time.time())
            if "mana_free_time" not in state:
                state["mana_free_time"] = now
                changed = True
            if "crystal_free_time" not in state:
                state["crystal_free_time"] = now
                changed = True
            if "mana_free_num" not in state:
                state["mana_free_num"] = 0
                changed = True

        # Private-policy Small uses the recovered row1 milestone topology as a
        # result-slot counter. The tutorial Small pull is slot 1. Upgrade states
        # that already completed that canonical one-shot so the first paid pull
        # cannot replay the deterministic milestone-1 Lavia result.
        if (
            (self._int(state.get("tutorial_mana_done"), 0) == 1 or self._has_expected_hero("lavia"))
            and self._mark_small_counter_after_tutorial()
        ):
            changed = True

        return changed

    def _payload_from_state(self) -> dict[str, Any]:
        # Pass41.1 makes MID56/MID50 summon_info a named authoritative state
        # contract instead of an ad-hoc repository dict projection. The contract
        # is shape-only: it does not invent reset calendars or hotspot rotation.
        return self.state_contract.project(self.player.summon)

    def payload(self) -> dict[str, Any]:
        changed = self.normalize()
        if changed:
            self._save()
        return self._payload_from_state()

    def _has_expected_hero(self, name: str) -> bool:
        meta = self.meta["heroes"][name]
        pid = self._int(meta["partner_id"])
        tid = self._int(meta["table_id"])
        hero = self.player.heroes.get(str(pid)) if isinstance(self.player.heroes, dict) else None
        return isinstance(hero, dict) and self._int(hero.get("table_id"), 0) == tid

    def _hero_result(self, name: str) -> dict[str, Any]:
        meta = self.meta["heroes"][name]
        hero = self._hero_repo().get(self._int(meta["partner_id"]))
        if not isinstance(hero, dict):
            raise RuntimeError(f"tutorial hero {name} is missing after summon mutation")
        result = dict(hero)
        result["is_partner"] = True
        return result

    def _hero_payload_for_result(self, row: SummonResultRowPlan) -> dict[str, Any]:
        hero = self._hero_repo().get(self._int(row.partner_id, 0))
        if not isinstance(hero, dict):
            raise RuntimeError("summon Hero result is missing after canonical mutation")
        if self._int(hero.get("table_id"), 0) != self._int(row.table_id, 0):
            raise RuntimeError("summon Hero payload table_id differs from result plan")
        result = dict(hero)
        result["is_partner"] = True
        return result

    def _create_expected_hero(self, name: str) -> dict[str, Any]:
        meta = self.meta["heroes"][name]
        repo = self._hero_repo()
        hero = repo.get(self._int(meta["partner_id"]))
        if hero is not None:
            if self._int(hero.get("table_id"), 0) != self._int(meta["table_id"]):
                raise RuntimeError(f"tutorial partner_id conflict for {name}")
            return hero
        return repo.add_owned_hero(
            {
                "partner_id": self._int(meta["partner_id"]),
                "table_id": self._int(meta["table_id"]),
                "star": self._int(meta["star"], 1),
                "lev": 1,
                "exp": 0,
                "color": 1,
                "skills": [1, 1, 1, 1, 1, 1],
                "equips": [0, 0, 0, 0, 0, 0],
                "fumos": [0, 0, 0, 0, 0, 0],
            },
            persist=False,
        )

    @staticmethod
    def _blocked_mid50() -> dict[str, Any]:
        # Runtime Pass41.3: Backend.lua reports HTTP-200 transport as xyd.error.OK
        # even when the JSON body has a nonzero application error_code.
        # SelfPlayer:summonHero() therefore still iterates response.result.
        # Keep the private fail-closed sentinel while supplying the source-required
        # empty collection so rejected paid/RNG operations cannot reach pairs(nil).
        return {"error_code": 1, "result": []}

    @staticmethod
    def _receipt_key(desc: SummonOperationDescriptor) -> str:
        return f"mid{desc.key.protocol_mid}:type{desc.key.summon_type}:index{desc.key.summon_index}"

    def _receipt_identity(self, desc: SummonOperationDescriptor) -> SummonReceiptIdentity:
        return SummonReceiptIdentity(
            key=self._receipt_key(desc),
            semantic=desc.semantic,
            protocol_mid=desc.key.protocol_mid,
            summon_type=desc.key.summon_type,
            summon_index=desc.key.summon_index,
            receipt_name=desc.receipt_name,
        )

    def _receipt_for(self, desc: SummonOperationDescriptor) -> dict[str, Any] | None:
        return SummonOperationReceiptStore(self.player.summon).get(self._receipt_identity(desc))

    @staticmethod
    def _result_plan_summary(plan: SummonResultPlan | None) -> list[dict[str, Any]]:
        if plan is None:
            return []
        return [
            {
                "kind": row.kind.value,
                "table_id": row.table_id,
                "item_num": row.item_num,
                "hero_name": row.hero_name,
                "partner_id": row.partner_id,
                "evidence_status": row.evidence_status,
            }
            for row in plan.rows
        ]

    def _store_receipt(
        self,
        desc: SummonOperationDescriptor,
        response: dict[str, Any],
        *,
        committed_at: int,
        legacy_adoption: bool = False,
        result_plan: SummonResultPlan | None = None,
    ) -> None:
        SummonOperationReceiptStore(self.player.summon).store(
            self._receipt_identity(desc),
            response,
            committed_at=committed_at,
            legacy_adoption=legacy_adoption,
            result_plan_summary=self._result_plan_summary(result_plan),
        )

    def _tutorial_result_plan(
        self, desc: SummonOperationDescriptor, hero_name: str
    ) -> SummonResultPlan:
        if not self._validate_tutorial_descriptor(desc, hero_name):
            raise SummonResultPlanUnavailable("tutorial Hero descriptor does not match canonical metadata")
        row = SummonResultRowPlan.hero(
            table_id=self._int(desc.hero_table_id, 0),
            partner_id=self._int(desc.partner_id, 0),
            hero_name=hero_name,
        )
        plan = SummonResultPlan.create(
            semantic=desc.semantic,
            rows=(row,),
            planner_status="tutorial_deterministic_active",
            source_reference=f"summon.lua:{desc.source_summon_row}",
        )
        self.result_policy.validate_active_plan(plan)
        return plan

    def _render_result_plan(self, plan: SummonResultPlan) -> list[dict[str, Any]]:
        return self.result_renderer.render(
            plan,
            hero_payload_resolver=self._hero_payload_for_result,
        )

    def _plan_duplicate_conversion(
        self,
        *,
        hero_table_id: int,
        fragment_item_id: int,
        source_family: str,
        initial_star: int | None = None,
    ) -> SummonResultRowPlan:
        return self.duplicate_conversion.resolve(
            SummonDuplicateCandidate(
                hero_table_id=int(hero_table_id),
                fragment_item_id=int(fragment_item_id),
                source_family=str(source_family),
                initial_star=(int(initial_star) if initial_star is not None else None),
            )
        )

    def _validate_tutorial_descriptor(self, desc: SummonOperationDescriptor, hero_name: str) -> bool:
        if desc.key.protocol_mid != 50 or not desc.supported or desc.hero_name != hero_name:
            return False
        hero_meta = self.meta.get("heroes", {}).get(hero_name)
        if not isinstance(hero_meta, dict):
            return False
        return (
            self._int(desc.hero_table_id, 0) == self._int(hero_meta.get("table_id"), 0)
            and self._int(desc.partner_id, 0) == self._int(hero_meta.get("partner_id"), 0)
            and self._int(desc.star, 0) == self._int(hero_meta.get("star"), 0)
        )

    def _tutorial_reward(self, desc: SummonOperationDescriptor) -> dict[str, int]:
        if self.catalog is None or self.rewards is None or self.uow is None:
            raise RuntimeError("tutorial summon reward services unavailable")
        item_id = self._int(desc.reward_item_id, 0)
        item_num = self._int(desc.reward_item_num, 0)
        if item_id <= 0 or item_num <= 0:
            raise RuntimeError("tutorial summon reward descriptor is incomplete")
        item_ref = self.catalog.resolve(
            ResolveContext.create(
                field_name="summon_reward",
                source_domain="tutorial_vending_summon",
                expected_namespaces=(CatalogNamespace.ITEM,),
                protocol_mid=50,
                source_path="data/tables/summon.lua",
            ),
            item_id,
        )
        result = self.rewards.apply(
            RewardPlan(
                origin=RewardOrigin(
                    domain="summon",
                    operation=desc.semantic,
                    protocol_mid=50,
                    source_table="summon.lua",
                    source_id=desc.source_summon_row,
                    field_path="summon_reward",
                ),
                inventory=(InventoryGrant(item_ref, item_num),),
            )
        )
        if len(result.inventory_awards) != 1:
            raise RuntimeError("tutorial summon reward did not produce exactly one inventory award")
        award = result.inventory_awards[0]
        if self._int(award.get("item_id"), 0) != item_id or self._int(award.get("item_num"), 0) != item_num:
            raise RuntimeError("tutorial summon reward projection differs from descriptor")
        return {"item_id": item_id, "item_num": item_num}


    def _validate_dispatch_infrastructure(self, desc: SummonOperationDescriptor) -> bool:
        """Require coherent descriptor/CostPlan/counter activation boundaries."""
        plan = self.cost_plans.get(desc.cost_plan_id)
        if plan is None:
            return False
        if plan.family != (desc.state_family or desc.source_family):
            return False
        if plan.pull_count != max(1, self._int(desc.pull_count, 1)):
            return False
        if not plan.result_activation_allowed:
            return False
        if desc.vip_min != plan.vip_min:
            return False
        if self._int(getattr(self.player, "vip", 0), 0) < plan.vip_min:
            return False

        if desc.support_status == "tutorial_supported":
            if not plan.is_free or plan.execution_status != "tutorial_active_free_only":
                return False
            if desc.rng_status != "tutorial_deterministic_only":
                return False
        elif desc.support_status == "private_policy_supported":
            if plan.is_free or plan.execution_status != "private_policy_active":
                return False
            if desc.rng_status != "private_server_policy_v1":
                return False
            if self.private_policy is None or self.private_planner is None:
                return False
            if not self.private_policy.active(desc.semantic):
                return False
        elif desc.support_status == "private_sx_policy_supported":
            if plan.is_free or plan.execution_status != "private_policy_active":
                return False
            if desc.rng_status != "private_sx_policy_v2":
                return False
            if self.sx_source is None or self.sx_policy is None or self.sx_planner is None:
                return False
            if not self.sx_policy.active(desc.semantic):
                return False
            if plan.pull_count != self.sx_policy.result_count or plan.vip_min != self.sx_policy.vip_min:
                return False
        else:
            return False

        if desc.counter_policy_id:
            counter = self.counter_policies.get(desc.counter_policy_id)
            if counter is None or counter.family != plan.family:
                return False
            if desc.support_status in {"private_policy_supported", "private_sx_policy_supported"} and not counter.transition_supported:
                return False
        return True

    def summon_hero(self, req: dict[str, Any]) -> dict[str, Any]:
        """Dispatch only explicitly registered active MID50 operation semantics."""
        if self.normalize():
            self._save()

        decision = self.operation_registry.resolve(
            50,
            req.get("summon_type"),
            req.get("summon_index"),
        )
        if not decision.supported or decision.descriptor is None or not decision.strategy:
            return self._blocked_mid50()
        desc = decision.descriptor
        if (
            desc.support_status == "tutorial_supported"
            and self._int(self.player.summon.get("tutorial_enabled"), 0) != 1
        ):
            return self._blocked_mid50()
        if not self._validate_dispatch_infrastructure(desc):
            return self._blocked_mid50()
        handler = getattr(self, decision.strategy, None)
        if not callable(handler):
            return self._blocked_mid50()
        return handler(desc)

    @staticmethod
    def _blocked_magic() -> dict[str, Any]:
        # Backend.lua treats HTTP 200 as transport OK, so result must always be
        # iterable on MID70 even for a fail-closed handcrafted request.
        return {"error_code": 1, "result": []}

    def _owns_magic_target(self, target: MagicSummonTarget) -> bool:
        repo = self._hero_repo()
        repo.normalize()
        accepted = {int(target.hero_table_id)}
        if int(target.awaken_table_id) > 0:
            accepted.add(int(target.awaken_table_id))
        return any(
            isinstance(hero, dict) and self._int(hero.get("table_id"), 0) in accepted
            for hero in self.player.heroes.values()
        )

    def magic_switch_hero(self, req: dict[str, Any]) -> dict[str, Any]:
        """MID71: persist a source-allowed Magic target that the player owns."""
        if self.normalize():
            self._save()
        if self.magic_source is None or self.uow is None:
            return {"error_code": 1}
        target = self.magic_source.target(req.get("partner_id"))
        if target is None or not self._owns_magic_target(target):
            return {"error_code": 1}
        current = self._int(self.player.summon.get("directional_show_id"), 0)
        if current == int(target.hero_table_id):
            return {"partner_id": int(target.hero_table_id)}
        context = OperationContext(
            actor_player_id=str(self.player.player_id),
            domain="summon",
            operation_name="magic_switch_target",
            protocol_mid=71,
            idempotency_key=f"magic-target:{int(target.hero_table_id)}",
        )
        try:
            with self.uow.transaction(context):
                self.player.summon["directional_show_id"] = int(target.hero_table_id)
                self.uow.mark_changed()
            return {"partner_id": int(target.hero_table_id)}
        except (RuntimeError, ValueError):
            return {"error_code": 1}

    def magic_summon_hero(self, req: dict[str, Any]) -> dict[str, Any]:
        """MID70: execute Private Magic Policy v1 for source-valid 1x/10x buys."""
        if self.normalize():
            self._save()
        if (
            self.uow is None
            or self.inventory is None
            or self.economy is None
            or self.magic_source is None
            or self.magic_policy is None
            or self.magic_planner is None
            or not self.magic_policy.active
        ):
            return self._blocked_magic()

        pull_count = self._int(req.get("summon_time"), 0)
        operation = self.magic_policy.operation(pull_count)
        target = self.magic_source.target(req.get("partner_id"))
        if operation is None or target is None or not self._owns_magic_target(target):
            return self._blocked_magic()
        if self._int(self.player.summon.get("directional_show_id"), 0) != int(target.hero_table_id):
            return self._blocked_magic()

        now_ms = int(time.time() * 1000)
        semantic = f"magic_paid_{pull_count}:target:{int(target.hero_table_id)}"
        paid_receipts = PaidSummonOperationReceiptStore(self.player.summon)
        replay = paid_receipts.replay(
            semantic=semantic,
            now_ms=now_ms,
            window_ms=self.magic_policy.retry_window_ms,
        )
        if replay is not None:
            return replay

        context = OperationContext(
            actor_player_id=str(self.player.player_id),
            domain="summon",
            operation_name=f"magic_paid_{pull_count}",
            protocol_mid=70,
            idempotency_key=f"private-magic:{pull_count}:{int(target.hero_table_id)}:{now_ms}",
        )
        try:
            with self.uow.transaction(context):
                economy_projection = self.economy.apply_deltas(
                    crystal_delta=-int(operation.crystal_cost), persist=False
                )
                result_rows: list[SummonResultRowPlan] = []
                for _ in range(int(operation.byproduct_rolls)):
                    source_row = self.magic_planner.pick_byproduct()
                    item_id = int(source_row.item_id)
                    item_num = int(source_row.item_num)
                    awards = self.inventory.add_items(
                        ({"item_id": item_id, "item_num": item_num},), persist=False
                    )
                    if len(awards) != 1:
                        raise RuntimeError("Magic byproduct did not produce one Backpack award")
                    result_rows.append(SummonResultRowPlan.item(item_id=item_id, item_num=item_num))

                fragment_qty = int(self.magic_planner.selected_fragment_quantity(pull_count))
                fragment_awards = self.inventory.add_items(
                    ({"item_id": int(target.fragment_item_id), "item_num": fragment_qty},),
                    persist=False,
                )
                if len(fragment_awards) != 1:
                    raise RuntimeError("Magic selected fragment bundle did not produce one Backpack award")

                plan = SummonResultPlan.create(
                    semantic=f"magic_paid_{pull_count}",
                    rows=result_rows,
                    planner_status="private_magic_policy_v1",
                    source_reference="summon.lua:33+dropbox.lua:700008+magic_drop_rate.lua/private-policy-v1",
                )
                self.result_policy.validate_active_plan(plan)
                response: dict[str, Any] = {
                    "result": self._render_result_plan(plan),
                    "stick_items": [
                        {"item_id": int(target.fragment_item_id), "item_num": fragment_qty}
                    ],
                    "economy_": dict(economy_projection),
                }
                paid_receipts.store(
                    semantic=semantic,
                    protocol_mid=70,
                    summon_type=33,
                    summon_index=pull_count,
                    committed_at_ms=now_ms,
                    response=response,
                )
                self.uow.mark_changed()
            return response
        except (
            EconomyMutationError,
            KeyError,
            RuntimeError,
            SummonResultPlanUnavailable,
            ValueError,
        ):
            return self._blocked_magic()

    def _summon_hero_source_meta(
        self,
        table_id: int,
        *,
        field_name: str,
        source_domain: str,
        source_path: str,
    ) -> tuple[str, int, int]:
        if self.catalog is None:
            raise RuntimeError("summon content catalog unavailable")
        ref = self.catalog.resolve(
            ResolveContext.create(
                field_name=field_name,
                source_domain=source_domain,
                expected_namespaces=(CatalogNamespace.PARTNER, CatalogNamespace.SUPER_PARTNER),
                protocol_mid=50,
                source_path=source_path,
            ),
            table_id,
        )
        meta = self.catalog.get(ref)
        star = self._int(meta.get("ini_star"), self._int(meta.get("star"), 0))
        fragment_item_id = self._int(meta.get("stone_id"), 0)
        name = str(meta.get("name") or f"hero_{int(table_id)}")
        if star <= 0 or fragment_item_id <= 0:
            raise RuntimeError(f"summon Hero {table_id} lacks source star/stone metadata")
        return name, star, fragment_item_id

    def _classic_hero_source_meta(self, table_id: int) -> tuple[str, int, int]:
        return self._summon_hero_source_meta(
            table_id,
            field_name="dropbox.item_id",
            source_domain="classic_vending_private_policy",
            source_path="data/tables/dropbox.lua",
        )

    def _sx_hero_source_meta(self, table_id: int) -> tuple[str, int, int]:
        # Pass42.6: current partner metadata is the authority for SX identity and
        # fragment mapping.  This deliberately supports the 13 current SX Girls
        # added after the orphan soul_casket snapshot.
        return self._summon_hero_source_meta(
            table_id,
            field_name="partner.table_id",
            source_domain="sx_soul_box_content_policy",
            source_path="data/tables/partner.lua",
        )

    def _classic_spend(self, desc: SummonOperationDescriptor) -> dict[str, int]:
        if self.economy is None:
            raise RuntimeError("summon economy repository unavailable")
        plan = self.cost_plans.require(str(desc.cost_plan_id or ""))
        mana_delta = 0
        crystal_delta = 0
        for component in plan.components:
            if component.kind != "economy" or component.field not in {"mana", "crystal"}:
                # Pass41.4 deliberately activates only the four runtime-mapped
                # currency buttons. Ticket/coupon variants stay fail closed.
                raise RuntimeError("active classic paid CostPlan contains a non-economy component")
            if component.field == "mana":
                mana_delta -= int(component.amount)
            elif component.field == "crystal":
                crystal_delta -= int(component.amount)
        if not mana_delta and not crystal_delta:
            raise RuntimeError("active classic paid CostPlan has no spend")
        return self.economy.apply_deltas(
            mana_delta=mana_delta,
            crystal_delta=crystal_delta,
            persist=False,
        )

    def _classic_pick_ordinary_result(
        self, family: str, *, medium_legacy: bool
    ) -> tuple[Any, Any]:
        """Pick one ordinary non-special classic result under optional Pass42.12 tuning."""
        if self.private_policy is None or self.private_planner is None:
            raise RuntimeError("private classic summon planner unavailable")
        family_policy = self.private_policy.family(family)

        if self.private_planner.category_override_enabled(family):
            category = self.private_planner.pick_ordinary_category(family)
            if category == "girl":
                pool = self.private_planner.pools.require(family_policy.super_pool_id)
                if (
                    medium_legacy
                    and self.medium_legacy_planner is not None
                    and pool.result_kind == "hero"
                    and pool.dropbox_id == family_policy.super_pool_id
                ):
                    pool = self.medium_legacy_planner.augmented_ordinary_hero_pool(pool)
                pool = self.private_planner.partition_hero_pool_by_star(family, pool)
                return pool, self.private_planner.pick_row(pool)
            if category in {"item", "scroll"}:
                pool = self.private_planner.pools.require(family_policy.base_pool_id)
                pool = self.private_planner.partition_item_pool(pool, category)
                return pool, self.private_planner.pick_row(pool)
            raise RuntimeError(f"unsupported classic category override {category}")

        # Legacy pre-Pass42.12 path: preserve the exact two-stage Hero-vs-base
        # decision and row weighting when explicit category tuning is disabled.
        pool = self.private_planner.ordinary_pool(family)
        if pool.result_kind == "hero":
            if (
                medium_legacy
                and self.medium_legacy_planner is not None
                and pool.dropbox_id == family_policy.super_pool_id
            ):
                pool = self.medium_legacy_planner.augmented_ordinary_hero_pool(pool)
                pool = self.private_planner.partition_hero_pool_by_star(family, pool)
                return pool, self.medium_legacy_planner.pick_row(pool)
            pool = self.private_planner.partition_hero_pool_by_star(family, pool)
        return pool, self.private_planner.pick_row(pool)

    def _classic_pick_guarantee_result(
        self, family: str, required_kind: str, *, medium_legacy: bool
    ) -> tuple[Any, Any]:
        """Pick the existing x10 guarantee row without changing guarantee frequency."""
        if self.private_policy is None or self.private_planner is None:
            raise RuntimeError("private classic summon planner unavailable")
        family_policy = self.private_policy.family(family)
        if required_kind == "hero":
            pool = self.private_planner.pools.require(family_policy.super_pool_id)
            if medium_legacy and self.medium_legacy_planner is not None:
                pool = self.medium_legacy_planner.augmented_ordinary_hero_pool(pool)
            pool = self.private_planner.partition_hero_pool_by_star(family, pool)
            if medium_legacy and self.medium_legacy_planner is not None:
                return pool, self.medium_legacy_planner.pick_row(pool)
            return pool, self.private_planner.pick_row(pool)

        if required_kind != "item":
            raise RuntimeError(f"unsupported classic guarantee kind {required_kind}")
        pool = self.private_planner.pools.require(family_policy.base_pool_id)
        if self.private_planner.category_override_enabled(family):
            category = self.private_planner.pick_item_class_category(family)
            if category in {"item", "scroll"}:
                pool = self.private_planner.partition_item_pool(pool, category)
        return pool, self.private_planner.pick_row(pool)

    def _classic_select_results(
        self, desc: SummonOperationDescriptor
    ) -> tuple[list[tuple[Any, Any, bool]], int]:
        if self.private_policy is None or self.private_planner is None:
            raise RuntimeError("private classic summon planner unavailable")
        counter = self.counter_policies.require(str(desc.counter_policy_id or ""))
        if not counter.transition_supported or not counter.persistence_key:
            raise SummonCounterTransitionUnavailable("classic paid counter is not active")
        family = self.cost_plans.require(str(desc.cost_plan_id or "")).family
        current = max(0, self._int(self.player.summon.get(counter.persistence_key), 0))
        medium_legacy = (
            family == "medium"
            and self.medium_legacy_policy is not None
            and self.medium_legacy_planner is not None
            and self.medium_legacy_policy.active(desc.semantic)
        )
        featured_target = 0
        featured_counter = 0
        if medium_legacy:
            featured_target = self._int(self.player.summon.get("partner_id"), 0)
            if featured_target not in self.medium_legacy_policy.catalog.medium_featured_ids():
                raise RuntimeError("Medium featured partner_id is not an eligible Legacy Girl")
            stored_target = self._int(
                self.player.summon.get(self.medium_legacy_policy.featured_target_key), 0
            )
            featured_counter = max(0, self._int(
                self.player.summon.get(self.medium_legacy_policy.featured_counter_key), 0
            ))
            if stored_target != featured_target:
                featured_counter = 0

        selections: list[tuple[Any, Any, bool]] = []
        for _ in range(max(1, self._int(desc.pull_count, 1))):
            transition = self.counter_engine.plan_transition(counter, current, 1)
            current = transition.after
            if transition.selected_special_dropbox is not None:
                pool = self.private_planner.pools.require(transition.selected_special_dropbox)
                selections.append((pool, self.private_planner.pick_row(pool), True))
                continue

            if medium_legacy:
                decision = self.medium_legacy_planner.featured_decision(featured_counter)
                featured_counter = decision.counter_after
                if decision.selected:
                    pool = self.medium_legacy_planner.featured_pool(featured_target)
                    selections.append((pool, pool.rows[0], False))
                    continue

            pool, row = self._classic_pick_ordinary_result(
                family, medium_legacy=medium_legacy
            )
            selections.append((pool, row, False))

        # Source UI exposes a guarantee for classic 10x behavior. The exact
        # historical server formula is unavailable, so Private Policy v1 enforces
        # only the documented semantic class while never replacing a recovered
        # milestone-selected special slot. Pass42.14 treats Small x100 as ten
        # consecutive 10-result guarantee blocks, preserving the already-active
        # Small x10 contract instead of weakening it for the bulk client button.
        pull_count = max(1, self._int(desc.pull_count, 1))
        if pull_count >= 10 and pull_count % 10 == 0:
            family_policy = self.private_policy.family(family)
            required_kind = "item" if family_policy.ten_pull_guarantee == "at_least_one_item" else "hero"
            for block_start in range(0, pull_count, 10):
                block_end = block_start + 10
                if any(
                    pool.result_kind == required_kind
                    for pool, _, _ in selections[block_start:block_end]
                ):
                    continue
                replacement_index = next(
                    (
                        i
                        for i in range(block_end - 1, block_start - 1, -1)
                        if not selections[i][2]
                    ),
                    None,
                )
                if replacement_index is None:
                    raise RuntimeError("ten-pull guarantee has no replaceable ordinary slot")
                replacement_pool, replacement_row = self._classic_pick_guarantee_result(
                    family, required_kind, medium_legacy=medium_legacy
                )
                if replacement_pool.result_kind != required_kind:
                    raise RuntimeError("private ten-pull guarantee pool has the wrong result kind")
                selections[replacement_index] = (replacement_pool, replacement_row, False)

        if medium_legacy:
            self.player.summon[self.medium_legacy_policy.featured_target_key] = featured_target
            self.player.summon[self.medium_legacy_policy.featured_counter_key] = featured_counter
        return selections, current

    def _classic_materialize_results(
        self,
        desc: SummonOperationDescriptor,
        selections: list[tuple[Any, Any, bool]],
    ) -> list[SummonResultRowPlan]:
        """Apply already-selected classic rows through the shared Hero/Inventory seam."""
        if self.inventory is None:
            raise RuntimeError("summon inventory repository unavailable")
        repo = self._hero_repo()
        repo.normalize()
        owned_table_ids = {
            self._int(hero.get("table_id"), 0)
            for hero in self.player.heroes.values()
            if isinstance(hero, dict) and self._int(hero.get("table_id"), 0) > 0
        }
        source_family = self.cost_plans.require(str(desc.cost_plan_id or "")).family
        result_rows: list[SummonResultRowPlan] = []
        for pool, source_row, _special in selections:
            if pool.result_kind == "item":
                item_id = int(source_row.item_id)
                item_num = int(source_row.item_num)
                awards = self.inventory.add_items(
                    ({"item_id": item_id, "item_num": item_num},), persist=False
                )
                if len(awards) != 1:
                    raise RuntimeError("summon item result did not produce one Backpack award")
                result_rows.append(SummonResultRowPlan.item(item_id=item_id, item_num=item_num))
                continue

            if pool.result_kind != "hero":
                raise RuntimeError(f"unsupported classic summon pool result kind {pool.result_kind}")
            table_id = int(source_row.item_id)
            hero_name, initial_star, fragment_item_id = self._classic_hero_source_meta(table_id)
            if table_id in owned_table_ids:
                converted = self._plan_duplicate_conversion(
                    hero_table_id=table_id,
                    fragment_item_id=fragment_item_id,
                    source_family=source_family,
                    initial_star=initial_star,
                )
                awards = self.inventory.add_items(
                    ({"item_id": converted.table_id, "item_num": int(converted.item_num or 0)},),
                    persist=False,
                )
                if len(awards) != 1:
                    raise RuntimeError("duplicate conversion did not produce one fragment award")
                result_rows.append(converted)
            else:
                created = repo.add_owned_hero(
                    {"table_id": table_id, "star": initial_star}, persist=False
                )
                owned_table_ids.add(table_id)
                result_rows.append(
                    SummonResultRowPlan.hero(
                        table_id=table_id,
                        partner_id=self._int(created.get("partner_id"), 0),
                        hero_name=hero_name,
                    )
                )
        return result_rows

    def _classic_paid(self, desc: SummonOperationDescriptor) -> dict[str, Any]:
        """Execute mapped classic paid buttons under Private Policy v1."""
        if (
            self.uow is None
            or self.inventory is None
            or self.catalog is None
            or self.private_policy is None
            or self.private_planner is None
            or not self.private_policy.active(desc.semantic)
        ):
            return self._blocked_mid50()

        now_ms = int(time.time() * 1000)
        paid_receipts = PaidSummonOperationReceiptStore(self.player.summon)
        replay = paid_receipts.replay(
            semantic=desc.semantic,
            now_ms=now_ms,
            window_ms=self.private_policy.retry_window_ms,
        )
        if replay is not None:
            return replay

        counter = self.counter_policies.get(desc.counter_policy_id)
        if counter is None or not counter.persistence_key:
            return self._blocked_mid50()

        context = OperationContext(
            actor_player_id=str(self.player.player_id),
            domain="summon",
            operation_name=desc.semantic,
            protocol_mid=50,
            idempotency_key=f"private:{desc.semantic}:{now_ms}",
        )
        try:
            with self.uow.transaction(context):
                economy_projection = self._classic_spend(desc)
                selections, counter_after = self._classic_select_results(desc)

                result_rows = self._classic_materialize_results(desc, selections)

                self.player.summon[counter.persistence_key] = counter_after
                medium_legacy_active = (
                    self.medium_legacy_policy is not None
                    and self.medium_legacy_policy.active(desc.semantic)
                )
                plan = SummonResultPlan.create(
                    semantic=desc.semantic,
                    rows=result_rows,
                    planner_status=("private_server_policy_v2_medium_legacy" if medium_legacy_active else "private_server_policy_v1"),
                    source_reference=(
                        f"summon.lua:{desc.source_summon_row}+dropbox.lua+private-medium-legacy-v1"
                        if medium_legacy_active
                        else f"summon.lua:{desc.source_summon_row}+dropbox.lua/private-policy-v1"
                    ),
                )
                self.result_policy.validate_active_plan(plan)
                response: dict[str, Any] = {
                    "result": self._render_result_plan(plan),
                    "economy_": dict(economy_projection),
                    "summon_info": self._payload_from_state(),
                }
                paid_receipts.store(
                    semantic=desc.semantic,
                    protocol_mid=desc.key.protocol_mid,
                    summon_type=desc.key.summon_type,
                    summon_index=desc.key.summon_index,
                    committed_at_ms=now_ms,
                    response=response,
                )
                self.uow.mark_changed()
            return response
        except (
            AmbiguousContentReference,
            EconomyMutationError,
            KeyError,
            RuntimeError,
            SummonCounterTransitionUnavailable,
            SummonDuplicateConversionUnavailable,
            SummonResultPlanUnavailable,
            UnknownContentReference,
            ValueError,
        ):
            return self._blocked_mid50()

    def _sx_spend(self, desc: SummonOperationDescriptor) -> dict[str, int]:
        if self.economy is None or self.sx_policy is None:
            raise RuntimeError("SX economy/private policy unavailable")
        plan = self.cost_plans.require(str(desc.cost_plan_id or ""))
        if len(plan.components) != 1:
            raise RuntimeError("SX CostPlan must contain exactly one component")
        component = plan.components[0]
        if component.kind != "economy" or component.field != "crystal":
            raise RuntimeError("SX CostPlan must spend Crystal")
        if int(component.amount) != int(self.sx_policy.crystal_cost):
            raise RuntimeError("SX private cost drifts from recovered CostPlan")
        return self.economy.apply_deltas(
            crystal_delta=-int(component.amount), persist=False
        )

    def _sx_selected_hotspot(self, desc: SummonOperationDescriptor) -> int:
        if self.sx_source is None:
            raise RuntimeError("SX source catalog unavailable")
        selector = int(desc.key.summon_index)
        if selector not in {1, 2}:
            raise RuntimeError("SX selector must be 1 or 2")
        main_ids = self.player.summon.get("main_ids")
        if not isinstance(main_ids, list) or len(main_ids) < selector:
            raise RuntimeError("SX MID56 main_ids is incomplete")
        hero_table_id = self._int(main_ids[selector - 1], 0)
        if hero_table_id <= 0 or not self.sx_source.is_current_sx(hero_table_id):
            raise RuntimeError("SX selected hotspot is not current partner.is_sx")
        return hero_table_id

    def _sx_materialize_dynamic_hero(self, hero_table_id: int) -> SummonResultRowPlan:
        if self.inventory is None:
            raise RuntimeError("SX inventory repository unavailable")
        repo = self._hero_repo()
        repo.normalize()
        name, initial_star, fragment_item_id = self._sx_hero_source_meta(hero_table_id)
        owned = any(
            isinstance(hero, dict) and self._int(hero.get("table_id"), 0) == int(hero_table_id)
            for hero in self.player.heroes.values()
        )
        if owned:
            converted = self._plan_duplicate_conversion(
                hero_table_id=hero_table_id,
                fragment_item_id=fragment_item_id,
                source_family="sx",
                initial_star=initial_star,
            )
            awards = self.inventory.add_items(
                ({"item_id": converted.table_id, "item_num": int(converted.item_num or 0)},),
                persist=False,
            )
            if len(awards) != 1:
                raise RuntimeError("SX duplicate conversion did not produce one fragment award")
            return converted
        created = repo.add_owned_hero(
            {"table_id": int(hero_table_id), "star": int(initial_star)}, persist=False
        )
        return SummonResultRowPlan.hero(
            table_id=int(hero_table_id),
            partner_id=self._int(created.get("partner_id"), 0),
            hero_name=name,
        )

    def _sx_materialize_dynamic_fragment(
        self, hero_table_id: int, item_num: int
    ) -> SummonResultRowPlan:
        if self.inventory is None:
            raise RuntimeError("SX inventory repository unavailable")
        _name, _initial_star, fragment_item_id = self._sx_hero_source_meta(hero_table_id)
        quantity = int(item_num)
        if quantity <= 0:
            raise RuntimeError("SX fragment-class quantity must be positive")
        awards = self.inventory.add_items(
            ({"item_id": int(fragment_item_id), "item_num": quantity},),
            persist=False,
        )
        if len(awards) != 1:
            raise RuntimeError("SX fragment class did not produce one Backpack award")
        return SummonResultRowPlan.item(item_id=int(fragment_item_id), item_num=quantity)

    def _sx_private(self, desc: SummonOperationDescriptor) -> dict[str, Any]:
        """MID50 type4: execute corrected Custom Private Server SX Policy v2.

        Five item rows remain independently selected from recovered pools
        200007..200011.  The sixth row is a mixed Soul-Casket reward class:
        current SX full Hero, normal 3-star fragments, normal 2-star fragments,
        or ordinary full Hero.  Only the rare full-SX class receives hotspot
        rate-up/pity.  Duplicate full Heroes reuse the global recovered 7/14/30
        conversion resolver.
        """
        if (
            self.uow is None
            or self.inventory is None
            or self.economy is None
            or self.catalog is None
            or self.sx_source is None
            or self.sx_policy is None
            or self.sx_planner is None
            or not self.sx_policy.active(desc.semantic)
        ):
            return self._blocked_mid50()
        try:
            selected_hotspot = self._sx_selected_hotspot(desc)
        except (KeyError, RuntimeError, ValueError):
            return self._blocked_mid50()

        now_ms = int(time.time() * 1000)
        semantic = (
            f"{desc.semantic}:target:{selected_hotspot}:policy:{self.sx_policy.policy_version}"
        )
        receipts = PaidSummonOperationReceiptStore(self.player.summon)
        replay = receipts.replay(
            semantic=semantic,
            now_ms=now_ms,
            window_ms=self.sx_policy.retry_window_ms,
        )
        if replay is not None:
            return replay

        context = OperationContext(
            actor_player_id=str(self.player.player_id),
            domain="summon",
            operation_name=desc.semantic,
            protocol_mid=50,
            idempotency_key=f"private-sx:{desc.key.summon_index}:{selected_hotspot}:{now_ms}",
        )
        try:
            with self.uow.transaction(context):
                economy_projection = self._sx_spend(desc)
                result_rows: list[SummonResultRowPlan] = []
                for pool_id in self.sx_policy.static_pool_ids:
                    source_row = self.sx_planner.pick_static_item(pool_id)
                    awards = self.inventory.add_items(
                        ({"item_id": int(source_row.item_id), "item_num": int(source_row.item_num)},),
                        persist=False,
                    )
                    if len(awards) != 1:
                        raise RuntimeError("SX static item slot did not produce one Backpack award")
                    result_rows.append(
                        SummonResultRowPlan.item(
                            item_id=int(source_row.item_id), item_num=int(source_row.item_num)
                        )
                    )

                state = self.player.summon
                stored_target = self._int(state.get(self.sx_policy.counter_target_key), 0)
                counter_before = self._int(state.get(self.sx_policy.counter_key), 0)
                if stored_target != selected_hotspot:
                    counter_before = 0
                dynamic = self.sx_planner.pick_dynamic_reward(
                    selected_hotspot_id=selected_hotspot,
                    counter_before=counter_before,
                )
                if dynamic.full_hero:
                    result_rows.append(self._sx_materialize_dynamic_hero(dynamic.hero_table_id))
                elif dynamic.fragment_item and dynamic.item_num is not None:
                    result_rows.append(
                        self._sx_materialize_dynamic_fragment(
                            dynamic.hero_table_id, dynamic.item_num
                        )
                    )
                else:
                    raise RuntimeError("SX dynamic planner returned unsupported reward shape")
                state[self.sx_policy.counter_target_key] = int(selected_hotspot)
                state[self.sx_policy.counter_key] = int(dynamic.counter_after)

                plan = SummonResultPlan.create(
                    semantic=desc.semantic,
                    rows=result_rows,
                    planner_status="private_sx_policy_v2",
                    source_reference=(
                        "summon.lua:4+dropbox.lua:200007..200011+partner.is_sx+"
                        "orphan:soul_casket.lua:types1/2/5/6/private-sx-v2"
                    ),
                )
                self.result_policy.validate_active_plan(plan)
                response: dict[str, Any] = {
                    "result": self._render_result_plan(plan),
                    "economy_": dict(economy_projection),
                    "summon_info": self._payload_from_state(),
                }
                receipts.store(
                    semantic=semantic,
                    protocol_mid=desc.key.protocol_mid,
                    summon_type=desc.key.summon_type,
                    summon_index=desc.key.summon_index,
                    committed_at_ms=now_ms,
                    response=response,
                )
                self.uow.mark_changed()
            return response
        except (
            AmbiguousContentReference,
            EconomyMutationError,
            KeyError,
            RuntimeError,
            SummonDuplicateConversionUnavailable,
            SummonResultPlanUnavailable,
            UnknownContentReference,
            ValueError,
        ):
            return self._blocked_mid50()

    def _small_free_after_tutorial(self, desc: SummonOperationDescriptor) -> dict[str, Any]:
        """Execute eligible Small free pulls #2-#5 for the stateful MID50 (1,1) tuple.

        The client sends the same protocol tuple for every free Small pull.  Pull #1
        remains the deterministic tutorial Lavia operation; after the tutorial receipt
        is complete, remaining free pulls use the normal Small private planner.  The
        source-backed 600-second timer and server-projected ``mana_free_num`` gate the
        operation.  No reset/replenishment calendar is invented here.
        """
        if (
            self.uow is None
            or self.inventory is None
            or self.catalog is None
            or self.private_policy is None
            or self.private_planner is None
            or not self.private_policy.active("small_free_post_tutorial")
        ):
            return self._blocked_mid50()

        cost_plan = self.cost_plans.get(desc.cost_plan_id)
        counter = self.counter_policies.get(desc.counter_policy_id)
        timer_policy = self.state_contract.timer_policy("small")
        if (
            cost_plan is None
            or not cost_plan.is_free
            or cost_plan.family != "small"
            or counter is None
            or not counter.transition_supported
            or not counter.persistence_key
            or timer_policy is None
            or not timer_policy.free_time_field
            or not timer_policy.free_count_field
            or not timer_policy.period_seconds
        ):
            return self._blocked_mid50()

        now_ms = int(time.time() * 1000)
        repeat_receipts = PaidSummonOperationReceiptStore(self.player.summon)
        replay = repeat_receipts.replay(
            semantic="small_free_post_tutorial",
            now_ms=now_ms,
            window_ms=self.private_policy.retry_window_ms,
        )
        if replay is not None:
            return replay

        state = self.player.summon
        now = now_ms // 1000
        remaining = max(0, self._int(state.get(timer_policy.free_count_field), 0))
        last_free = max(0, self._int(state.get(timer_policy.free_time_field), 0))
        if remaining <= 0:
            return self._blocked_mid50()
        if last_free > 0 and now < last_free + int(timer_policy.period_seconds):
            return self._blocked_mid50()

        context = OperationContext(
            actor_player_id=str(self.player.player_id),
            domain="summon",
            operation_name="small_free_post_tutorial",
            protocol_mid=50,
            idempotency_key=f"private:small_free_post_tutorial:{now_ms}",
        )
        try:
            with self.uow.transaction(context):
                selections, counter_after = self._classic_select_results(desc)
                result_rows = self._classic_materialize_results(desc, selections)
                state[timer_policy.free_time_field] = now
                state[timer_policy.free_count_field] = max(0, remaining - 1)
                state[counter.persistence_key] = counter_after
                plan = SummonResultPlan.create(
                    semantic="small_free_post_tutorial",
                    rows=result_rows,
                    planner_status="private_server_policy_v1",
                    source_reference=(
                        "SummonWindow.lua:freeTimes/timeCount1+SelfPlayer.lua:freeManaSummonDuration"
                        "+summon.lua:1+dropbox.lua/private-policy-v1"
                    ),
                )
                self.result_policy.validate_active_plan(plan)
                response: dict[str, Any] = {
                    "result": self._render_result_plan(plan),
                    "summon_info": self._payload_from_state(),
                }
                repeat_receipts.store(
                    semantic="small_free_post_tutorial",
                    protocol_mid=desc.key.protocol_mid,
                    summon_type=desc.key.summon_type,
                    summon_index=desc.key.summon_index,
                    committed_at_ms=now_ms,
                    response=response,
                )
                self.uow.mark_changed()
            return response
        except (
            AmbiguousContentReference,
            KeyError,
            RuntimeError,
            SummonCounterTransitionUnavailable,
            SummonDuplicateConversionUnavailable,
            SummonResultPlanUnavailable,
            UnknownContentReference,
            ValueError,
        ):
            return self._blocked_mid50()

    def _tutorial_mana(self, desc: SummonOperationDescriptor) -> dict[str, Any]:
        if not self._validate_tutorial_descriptor(desc, "lavia"):
            return self._blocked_mid50()
        if self.uow is None or self.rewards is None or self.catalog is None:
            return self._blocked_mid50()

        state = self.player.summon
        guide_after = self._int(self.meta["guide_ids"]["mana_three"], 100105)
        guide_id = self._int(self.player.guide_id, 0)

        # A committed one-shot receipt is the authority for response replay.
        # guide_id only bounds the stock tutorial recovery window; it never
        # authorizes a new grant.
        receipt = self._receipt_for(desc)
        if receipt is not None:
            if guide_id < guide_after:
                return copy.deepcopy(receipt["response"])
            return self._small_free_after_tutorial(desc)

        has_lavia = self._has_expected_hero("lavia")
        if has_lavia:
            # Upgrade adoption for canonical v0.8.16 tutorial state: that backend
            # could persist Lavia + tutorial_mana_done but had no summon reward
            # or operation receipt.  The canonical old-state marker, not guide_id,
            # authorizes this one-time missing reward migration.  guide_id only
            # limits whether replay is still useful to the tutorial client.
            if guide_id >= guide_after:
                return self._small_free_after_tutorial(desc)
            if self._int(state.get("tutorial_mana_done"), 0) != 1:
                return self._blocked_mid50()
            context = OperationContext(
                actor_player_id=str(self.player.player_id),
                domain="summon",
                operation_name="tutorial_small_free_first_legacy_reward_adoption",
                protocol_mid=50,
                idempotency_key=desc.receipt_name,
            )
            try:
                with self.uow.transaction(context):
                    reward = self._tutorial_reward(desc)
                    now = int(time.time())
                    state["tutorial_mana_reward_backfill_version"] = 1
                    result_plan = self._tutorial_result_plan(desc, "lavia")
                    response = {
                        "result": self._render_result_plan(result_plan),
                        "reward": reward,
                        "summon_info": self._payload_from_state(),
                    }
                    self._store_receipt(
                        desc,
                        response,
                        committed_at=now,
                        legacy_adoption=True,
                        result_plan=result_plan,
                    )
                    self.uow.mark_changed()
                return response
            except (RuntimeError, ValueError, RewardValidationError, UnknownContentReference, AmbiguousContentReference):
                return self._blocked_mid50()

        if guide_id >= guide_after:
            return self._blocked_mid50()
        if self._int(state.get("mana_free_time"), 0) >= 1:
            return self._blocked_mid50()
        if self._int(state.get("mana_free_num"), 0) <= 0:
            return self._blocked_mid50()

        context = OperationContext(
            actor_player_id=str(self.player.player_id),
            domain="summon",
            operation_name=desc.semantic,
            protocol_mid=50,
            idempotency_key=desc.receipt_name,
        )
        try:
            with self.uow.transaction(context):
                self._create_expected_hero("lavia")
                reward = self._tutorial_reward(desc)
                now = int(time.time())
                state["mana_free_time"] = now
                state["mana_free_num"] = max(0, self._int(state.get("mana_free_num"), 0) - 1)
                state["tutorial_mana_done"] = 1
                state["tutorial_mana_claimed_at"] = now
                self._mark_small_counter_after_tutorial()
                result_plan = self._tutorial_result_plan(desc, "lavia")
                response = {
                    "result": self._render_result_plan(result_plan),
                    "reward": reward,
                    "summon_info": self._payload_from_state(),
                }
                self._store_receipt(
                    desc, response, committed_at=now, result_plan=result_plan
                )
                self.uow.mark_changed()
            return response
        except (RuntimeError, ValueError, RewardValidationError, UnknownContentReference, AmbiguousContentReference):
            return self._blocked_mid50()

    def _tutorial_crystal(self, desc: SummonOperationDescriptor) -> dict[str, Any]:
        # Pass40.2 intentionally preserves the established deterministic Pandaria
        # path. The configured Medium Juice reward identity is known, but its
        # historical quantity is not, so no reward field is invented here.
        if not self._validate_tutorial_descriptor(desc, "pandaria"):
            return self._blocked_mid50()
        try:
            result_plan = self._tutorial_result_plan(desc, "pandaria")
        except SummonResultPlanUnavailable:
            return self._blocked_mid50()

        state = self.player.summon
        guide_after = self._int(self.meta["guide_ids"]["crystal_three"], 100108)
        has_pandaria = self._has_expected_hero("pandaria")

        if has_pandaria:
            if self._int(self.player.guide_id, 0) < guide_after:
                return {
                    "result": self._render_result_plan(result_plan),
                    "summon_info": self.payload(),
                }
            return self._blocked_mid50()

        if self._int(self.player.guide_id, 0) >= guide_after:
            return self._blocked_mid50()
        if not (state.get("tutorial_mana_done") or self._has_expected_hero("lavia")):
            return self._blocked_mid50()
        if self._int(state.get("crystal_free_time"), 0) >= 1:
            return self._blocked_mid50()

        self._create_expected_hero("pandaria")
        now = int(time.time())
        state["crystal_free_time"] = now
        state["tutorial_crystal_done"] = 1
        state["tutorial_crystal_claimed_at"] = now
        self._save()
        return {
            "result": self._render_result_plan(result_plan),
            "summon_info": self.payload(),
        }


    _STONE_REQUIRED_BY_STAR = {1: 10, 2: 30, 3: 80, 4: 180, 5: 330}

    @staticmethod
    def _blocked_stone_summon(reason: str) -> dict[str, Any]:
        # Pass29 local compatibility sentinel: fail closed instead of returning
        # a fake OK for a rejected mutating request. This is not asserted to be
        # an official GXB error-code assignment.
        return {"error_code": 1, "msg": f"stone_summon_rejected:{reason}"}

    def stone_summon_hero(self, req: dict[str, Any]) -> dict[str, Any]:
        """Source-mapped MID59 Backpack contract -> owned NormalHero transaction.

        NormalHero:stoneSummonHero sends ``table_id``, ``stone`` and
        ``stone_num``. SelfPlayer:stoneSummonHero treats the successful MID59
        response itself as the full NormalHero payload and removes the submitted
        stone count locally. Canonical mutation therefore validates the typed
        Partner<->Item relationship, source star threshold and Backpack balance,
        consumes the contracts, creates one unique owned hero, and commits once.
        """
        if self.catalog is None or self.inventory is None or self.uow is None:
            return self._blocked_stone_summon("request_services_unavailable")

        table_id = self._int(req.get("table_id"), 0)
        stone_id = self._int(req.get("stone"), 0)
        stone_num = self._int(req.get("stone_num"), 0)
        if table_id <= 0 or stone_id <= 0 or stone_num <= 0:
            return self._blocked_stone_summon("invalid_request_fields")

        try:
            partner_ref = self.catalog.resolve(
                ResolveContext.create(
                    field_name="table_id",
                    source_domain="hero_stone_summon",
                    expected_namespaces=(CatalogNamespace.PARTNER,),
                    protocol_mid=59,
                    source_path="app/model/NormalHero.lua",
                ),
                table_id,
            )
            stone_ref = self.catalog.resolve(
                ResolveContext.create(
                    field_name="stone",
                    source_domain="hero_stone_summon",
                    expected_namespaces=(CatalogNamespace.ITEM,),
                    protocol_mid=59,
                    source_path="app/model/NormalHero.lua",
                ),
                stone_id,
            )
            partner_row = self.catalog.get(partner_ref)
            stone_row = self.catalog.get(stone_ref)
        except (UnknownContentReference, AmbiguousContentReference):
            return self._blocked_stone_summon("unknown_typed_content")

        # Two-way explicit source cross-reference. Numeric prefix is never used.
        if self._int(partner_row.get("stone_id"), 0) != stone_id:
            return self._blocked_stone_summon("partner_stone_mismatch")
        if self._int(stone_row.get("type"), 0) != 3:
            return self._blocked_stone_summon("item_is_not_partner_contract")
        if self._int(stone_row.get("partner_id"), 0) != table_id:
            return self._blocked_stone_summon("stone_partner_mismatch")

        star = self._int(partner_row.get("star"), 0)
        required = self._STONE_REQUIRED_BY_STAR.get(star)
        if required is None or stone_num != required:
            return self._blocked_stone_summon("stone_count_mismatch")

        repo = self._hero_repo()
        repo.normalize()
        for hero in self.player.heroes.values():
            if isinstance(hero, dict) and self._int(hero.get("table_id"), 0) == table_id:
                return self._blocked_stone_summon("partner_already_owned")
        if self.inventory.get_item_num(stone_id) < required:
            return self._blocked_stone_summon("insufficient_contracts")

        context = OperationContext(
            actor_player_id=str(self.player.player_id),
            domain="hero_summon",
            operation_name="stone_summon_hero",
            protocol_mid=59,
        )
        try:
            with self.uow.transaction(context):
                remaining = self.inventory.consume_item(stone_id, required, persist=False)
                if remaining is None:
                    raise RuntimeError("canonical Backpack changed during MID59 transaction")
                hero = repo.add_owned_hero(
                    {
                        "table_id": table_id,
                        "star": star,
                        "lev": 1,
                        "exp": 0,
                        "color": 1,
                        "skills": [1, 1, 1, 1, 1, 1],
                        "equips": [0, 0, 0, 0, 0, 0],
                        "fumos": [0, 0, 0, 0, 0, 0],
                    },
                    persist=False,
                )
                self.uow.mark_changed()
                return dict(hero)
        except (RuntimeError, ValueError):
            return self._blocked_stone_summon("transaction_rejected")

    def _save(self) -> None:
        if self._save_callback:
            self._save_callback()
