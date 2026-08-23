"""Canonical Normal/Super Campaign progression and commit helpers.

The supplied client simulates Campaign combat locally. The backend owns
persistent map state around that simulation: the unlocked campaign rows, best
stars, chapter cursor, the pending MID113 -> MID114 session, source-certain
first-clear items, and v0.8.2's canonical Mana/player/Hero EXP transaction.
Source-derived campaign links are packaged in ``data/campaign_meta.json``; no
next campaign ID or repeat-drop RNG is guessed in handler code.
"""
from __future__ import annotations

import json
from collections.abc import Callable
from pathlib import Path
from typing import Any

from gxb_backend.content import CatalogNamespace, ContentRef, GameDataCatalog

from .awakening_mission_service import AwakeningMissionService
from .campaign_drop_planner import CampaignDropPlanner
from .campaign_reset_policy import CampaignResetPolicy
from .economy_repository import EconomyRepository
from .economy_ledger import InsufficientScalarBalance
from .hero_progression_repository import HeroProgressionRepository
from .inventory_repository import InventoryRepository
from .stack_inventory import StackInventoryError
from .mission_repository import MissionRepository
from .mutation_plan import (
    ActorRef, IdempotencySpec, MutationOrigin, MutationPlan, ResourceMutation, StackMutation, TemporalTransition,
)
from .mutation_settlement_service import MutationPreconditionError, MutationSettlementError, MutationSettlementService
from .player_state import PlayerState
from .reward_transaction_service import (
    EconomyGrant, InventoryGrant, RewardOrigin, RewardPlan, RewardTransactionService,
)
from .tutorial_milestone_repository import TutorialMilestoneRepository
from .unit_of_work import OperationContext, UnitOfWork
from .vip_policy import VipPrivilegeResolver, VipProgressionPolicy


class WorldRepository:
    def __init__(
        self,
        player: PlayerState,
        data_dir: Path,
        save_callback: Callable[[], None] | None = None,
        *,
        inventory: InventoryRepository | None = None,
        economy: EconomyRepository | None = None,
        hero_progression: HeroProgressionRepository | None = None,
        missions: MissionRepository | None = None,
        awakening_missions: AwakeningMissionService | None = None,
        catalog: GameDataCatalog | None = None,
        rewards: RewardTransactionService | None = None,
        tutorial: TutorialMilestoneRepository | None = None,
        drop_planner: CampaignDropPlanner | None = None,
        settlement: MutationSettlementService | None = None,
        uow: UnitOfWork | None = None,
        campaign_reset_policy: CampaignResetPolicy | None = None,
        vip_privileges: VipPrivilegeResolver | None = None,
    ) -> None:
        self.player = player
        self.data_dir = Path(data_dir)
        self._save_callback = save_callback
        self.inventory = inventory
        self.economy = economy or EconomyRepository(player, self.data_dir)
        self.hero_progression = hero_progression or HeroProgressionRepository(player, self.data_dir)
        self.missions = missions
        self.awakening_missions = awakening_missions
        self.catalog = catalog
        self.rewards = rewards
        self.tutorial = tutorial
        self.drop_planner = drop_planner
        self.settlement = settlement
        self.uow = uow
        self.campaign_reset_policy = campaign_reset_policy
        self.vip_privileges = vip_privileges or VipPrivilegeResolver(
            player, VipProgressionPolicy(self.data_dir)
        )
        self._campaigns = self._load_campaign_meta()
        self._campaign_ownership = self._load_campaign_ownership_meta()
        self._campaign_rewards = self._load_campaign_reward_meta()
        self._story_drop_campaigns, self._story_drop_partners = self._load_story_drop_meta()

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default


    def _load_campaign_ownership_meta(self) -> dict[str, Any]:
        path = self.data_dir / "pass75_campaign_ownership_meta.json"
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            if not isinstance(data, dict):
                raise ValueError("ownership metadata root must be object")
            meta = data.get("_meta") if isinstance(data.get("_meta"), dict) else {}
            if str(meta.get("source_resolution") or "") != "effective_merged":
                raise ValueError("ownership metadata is not stamped effective_merged")
            return data
        except Exception as exc:
            print(f"[WORLD] could not load Pass75 Campaign ownership metadata {path}: {exc}")
            return {}

    def ownership_meta(self, campaign_id: Any) -> dict[str, Any] | None:
        rows = self._campaign_ownership.get("campaigns") if isinstance(self._campaign_ownership, dict) else {}
        row = rows.get(str(self._int(campaign_id, -1))) if isinstance(rows, dict) else None
        return dict(row) if isinstance(row, dict) else None

    def _source_mode_ids(self, campaign_type: Any) -> list[int]:
        key = "normal_campaign_ids" if self._int(campaign_type, 1) == 1 else "super_campaign_ids"
        raw = self._campaign_ownership.get(key) if isinstance(self._campaign_ownership, dict) else []
        return [self._int(v) for v in raw if self._int(v) > 0] if isinstance(raw, list) else []

    def _source_mode_set(self, campaign_type: Any) -> set[int]:
        return set(self._source_mode_ids(campaign_type))

    def _mode_key(self, campaign_type: Any) -> str:
        return "super" if self._int(campaign_type, 1) == 2 else "normal"

    def _mode_rows(self, campaign_type: Any) -> list[dict[str, Any]]:
        key = self._mode_key(campaign_type)
        wm = self.player.world_map if isinstance(self.player.world_map, dict) else {}
        rows = wm.get(key)
        return rows if isinstance(rows, list) else []

    def _find_mode_row(self, campaign_id: int, campaign_type: Any) -> dict[str, Any] | None:
        for row in self._mode_rows(campaign_type):
            if self._int(row.get("campaign_id"), 0) == campaign_id:
                return row
        return None

    def _next_mode_campaign(self, campaign_id: int, campaign_type: Any) -> int:
        ordered = self._source_mode_ids(campaign_type)
        try:
            idx = ordered.index(int(campaign_id))
        except ValueError:
            return 0
        return ordered[idx + 1] if idx + 1 < len(ordered) else 0

    def _mode_frontier(self, campaign_type: Any) -> int:
        ordered = self._source_mode_ids(campaign_type)
        unlocked = {self._int(row.get("campaign_id"), 0) for row in self._mode_rows(campaign_type)}
        frontier = 0
        for cid in ordered:
            if cid in unlocked:
                frontier = cid
        return frontier

    def _load_campaign_meta(self) -> dict[str, dict[str, int]]:
        path = self.data_dir / "campaign_meta.json"
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            rows = data.get("campaigns") or {}
            return rows if isinstance(rows, dict) else {}
        except Exception as exc:
            print(f"[WORLD] could not load campaign metadata {path}: {exc}")
            return {}

    def _load_campaign_reward_meta(self) -> dict[str, dict[str, Any]]:
        path = self.data_dir / "campaign_reward_meta.json"
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            rows = data.get("campaigns") or {}
            return rows if isinstance(rows, dict) else {}
        except Exception as exc:
            print(f"[WORLD] could not load campaign reward metadata {path}: {exc}")
            return {}

    def _load_story_drop_meta(
        self,
    ) -> tuple[dict[str, dict[str, Any]], dict[str, dict[str, Any]]]:
        path = self.data_dir / "campaign_story_drop_meta.json"
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            campaigns = data.get("campaigns") or {}
            partners = data.get("partners") or {}
            if not isinstance(campaigns, dict) or not isinstance(partners, dict):
                raise ValueError("campaigns/partners must be objects")
            return campaigns, partners
        except Exception as exc:
            print(f"[WORLD] could not load story-drop metadata {path}: {exc}")
            return {}, {}

    def meta(self, campaign_id: Any) -> dict[str, int] | None:
        return self._campaigns.get(str(self._int(campaign_id, -1)))

    def story_drop_options(self, campaign_id: Any) -> list[int]:
        meta = self._story_drop_campaigns.get(str(self._int(campaign_id, -1))) or {}
        raw = meta.get("story_drop_partner") or []
        if not isinstance(raw, list):
            return []
        return [self._int(value) for value in raw if self._int(value) > 0]

    def story_drop_initial_star(self, table_id: Any) -> int:
        meta = self._story_drop_partners.get(str(self._int(table_id, -1))) or {}
        return max(0, self._int(meta.get("ini_star"), 0))

    def prepare_story_drop_claim(
        self, campaign_id: Any, table_id: Any, campaign_type: Any
    ) -> dict[str, Any]:
        """Validate MID2064 against source options and the pending MID113 session.

        BattleSpecialStory runs before MID114.  The current MID113 session is
        therefore the strongest source-compatible guard we have against an
        arbitrary story reward request.  A previously recorded claim in the
        same pending session is returned for idempotent same-choice retries.
        """
        self.normalize()
        cid = self._int(campaign_id, 0)
        selected = self._int(table_id, 0)
        ctype = self._int(campaign_type, 1)
        options = self.story_drop_options(cid)
        if selected <= 0 or selected not in options:
            return {"status": "invalid"}

        current = self._find_row(cid)
        if current is None:
            return {"status": "invalid"}

        pending = (
            self.player.active_campaign_battle
            if isinstance(self.player.active_campaign_battle, dict)
            else {}
        )
        if self._int(pending.get("campaign_id"), 0) != cid:
            return {"status": "invalid"}
        if self._int(pending.get("campaign_type"), 1) != ctype:
            return {"status": "invalid"}

        existing = pending.get("story_drop_claim")
        if isinstance(existing, dict):
            # Recovery-idempotency: the first successful MID2064 claim is the
            # authoritative choice for this pending battle. If the client-side
            # reward callback crashes and the user taps either choice again,
            # return the already-owned reward so BattleSpecialStory can finish
            # rather than wedging on an empty story_drop_awards response.
            existing_table = self._int(existing.get("table_id"), 0)
            existing_partner = self._int(existing.get("partner_id"), 0)
            if existing_table in options and existing_partner > 0:
                return {
                    "status": "existing",
                    "table_id": existing_table,
                    "partner_id": existing_partner,
                }
            return {"status": "already_claimed"}

        if self._int(current.get("is_partner_drop"), 0) == 1:
            return {"status": "already_claimed"}

        star = self.story_drop_initial_star(selected)
        if star <= 0:
            return {"status": "invalid"}
        return {"status": "new", "table_id": selected, "star": star}

    def record_story_drop_claim(
        self, campaign_id: Any, table_id: Any, partner_id: Any, *, persist: bool = True
    ) -> bool:
        """Persist the source-consumed partner-drop marker and pending claim."""
        self.normalize()
        cid = self._int(campaign_id, 0)
        selected = self._int(table_id, 0)
        owned_partner_id = self._int(partner_id, 0)
        current = self._find_row(cid)
        pending = (
            self.player.active_campaign_battle
            if isinstance(self.player.active_campaign_battle, dict)
            else {}
        )
        if (
            current is None
            or selected <= 0
            or owned_partner_id <= 0
            or selected not in self.story_drop_options(cid)
            or self._int(pending.get("campaign_id"), 0) != cid
        ):
            return False
        current["is_partner_drop"] = 1
        pending["story_drop_claim"] = {
            "table_id": selected,
            "partner_id": owned_partner_id,
        }
        self.player.active_campaign_battle = pending
        if persist:
            self._save()
        return True

    @staticmethod
    def _campaign_row(campaign_id: int, star: int) -> dict[str, int]:
        return {
            "campaign_id": int(campaign_id),
            "star": max(0, min(3, int(star))),
            "daily_limit": 0,
            "reset_count": 0,
            "is_partner_drop": 0,
        }

    def normalize(self) -> bool:
        """Normalize source-mode Campaign state without inventing unlocked rows."""
        changed = False
        if not isinstance(self.player.world_map, dict):
            self.player.world_map = {}
            changed = True
        wm = self.player.world_map

        def clean_rows(raw: Any, *, seed_normal: bool = False) -> list[dict[str, Any]]:
            nonlocal changed
            if not isinstance(raw, list):
                raw = []
                changed = True
            cleaned: list[dict[str, Any]] = []
            seen: set[int] = set()
            for row in raw:
                if not isinstance(row, dict):
                    changed = True
                    continue
                cid = self._int(row.get("campaign_id"), 0)
                if cid <= 0 or cid in seen:
                    changed = True
                    continue
                seen.add(cid)
                item = {
                    "campaign_id": cid,
                    "star": max(0, min(3, self._int(row.get("star"), 0))),
                    "daily_limit": self._int(row.get("daily_limit"), 0),
                    "reset_count": self._int(row.get("reset_count"), 0),
                    "is_partner_drop": self._int(row.get("is_partner_drop"), 0),
                }
                cleaned.append(item)
                if item != row:
                    changed = True
            if seed_normal and not cleaned:
                first = next(iter(self._source_mode_ids(1)), 100001)
                cleaned = [self._campaign_row(first, 0)]
                changed = True
            return cleaned

        normal = clean_rows(wm.get("normal"), seed_normal=True)
        super_rows = clean_rows(wm.get("super"), seed_normal=False)
        if wm.get("normal") != normal:
            wm["normal"] = normal
            changed = True
        if wm.get("super") != super_rows:
            wm["super"] = super_rows
            changed = True
        for key in ("challenge", "chapter_events"):
            if not isinstance(wm.get(key), dict):
                wm[key] = {}
                changed = True

        chapter = wm.get("chapter_info")
        if not isinstance(chapter, dict):
            chapter = {}
            changed = True
        normal_frontier = self._frontier_campaign(normal) or self._mode_frontier(1) or 100001
        normal_meta = self.meta(normal_frontier) or {}
        normal_chapter = self._int(normal_meta.get("chapter"), 1) or 1
        super_frontier = self._mode_frontier(2)
        super_meta = self.meta(super_frontier) or {}
        super_chapter = self._int(super_meta.get("chapter"), 0) if super_frontier else 0
        normalized_chapter = {
            **chapter,
            "normal_chapter_id": normal_chapter,
            "normal_campaign_id": normal_frontier,
            "normal_stars": self._chapter_star_sum(normal, normal_chapter),
            "normal_bonus_id": self._int(chapter.get("normal_bonus_id"), 0),
            "super_chapter_id": super_chapter,
            "super_campaign_id": super_frontier,
            "super_stars": self._chapter_star_sum(super_rows, super_chapter) if super_chapter else 0,
            "super_bonus_id": self._int(chapter.get("super_bonus_id"), 0),
        }
        if normalized_chapter != chapter:
            wm["chapter_info"] = normalized_chapter
            changed = True
        if not isinstance(self.player.active_campaign_battle, dict):
            self.player.active_campaign_battle = {}
            changed = True
        return changed

    def _normal_rows(self) -> list[dict[str, Any]]:
        self.normalize()
        return self.player.world_map["normal"]

    def _find_row(self, campaign_id: int, campaign_type: Any | None = None) -> dict[str, Any] | None:
        if campaign_type is not None:
            return self._find_mode_row(campaign_id, campaign_type)
        for wire_type in (1, 2):
            row = self._find_mode_row(campaign_id, wire_type)
            if row is not None:
                return row
        return None

    def _highest_unlocked(self, rows: list[dict[str, Any]]) -> int:
        return max((self._int(row.get("campaign_id"), 0) for row in rows if isinstance(row, dict)), default=0)

    def _frontier_campaign(self, rows: list[dict[str, Any]]) -> int:
        """Return the source-chain frontier among currently unlocked rows.

        Campaign IDs are not contiguous (the opening chain is
        100001 -> 100002 -> 100004), so progression must never use ``id + 1``.
        Prefer the persisted chapter cursor when it still names an unlocked
        row; otherwise find the row whose source-derived next campaign has not
        been unlocked yet.  The numeric fallback exists only for malformed
        legacy/hand-edited data with multiple disconnected frontiers.
        """
        ids = {
            self._int(row.get("campaign_id"), 0)
            for row in rows
            if isinstance(row, dict) and self._int(row.get("campaign_id"), 0) > 0
        }
        chapter = self.player.world_map.get("chapter_info") if isinstance(self.player.world_map, dict) else {}
        persisted = self._int((chapter or {}).get("normal_campaign_id"), 0)
        if persisted in ids:
            persisted_row = next(
                (row for row in rows if self._int(row.get("campaign_id"), 0) == persisted),
                None,
            )
            persisted_meta = self.meta(persisted) or {}
            persisted_next = self._int(persisted_meta.get("next_campaign_id"), 0)
            # A star-0 cursor is the currently playable unbeaten node. A
            # cleared terminal/no-next cursor is also valid. If its source next
            # node is already in the unlocked set, however, the cursor is stale
            # and we intentionally fall through to locate the real frontier.
            if (
                self._int((persisted_row or {}).get("star"), 0) == 0
                or persisted_next <= 0
                or persisted_next not in ids
            ):
                return persisted

        frontiers: list[int] = []
        for cid in ids:
            meta = self.meta(cid) or {}
            next_id = self._int(meta.get("next_campaign_id"), 0)
            if next_id <= 0 or next_id not in ids:
                frontiers.append(cid)
        if len(frontiers) == 1:
            return frontiers[0]
        return self._highest_unlocked(rows)

    def _chapter_star_sum(self, rows: list[dict[str, Any]], chapter: int) -> int:
        total = 0
        for row in rows:
            cid = self._int(row.get("campaign_id"), 0)
            meta = self.meta(cid) or {}
            if self._int(meta.get("chapter"), 0) == chapter:
                total += max(0, min(3, self._int(row.get("star"), 0)))
        return total

    def payload(self) -> dict[str, Any]:
        self.normalize()
        return self.player.world_map

    def _campaign_reward_plan(self, campaign_id: int) -> dict[str, int]:
        """Source-certain scalar/progression reward plan for NORMAL/SUPER Campaign.

        General item RNG is intentionally absent. The deterministic scalar
        fields come from campaign.lua + SelfPlayer:getExpMulti().
        """
        meta = self.economy.campaign_meta(campaign_id)
        energy_cost = max(0, self._int(meta.get("energy_cost"), 0))
        multiplier = max(0, self.economy.player_exp_multiplier())
        return {
            "mana_gain": max(0, self._int(meta.get("mana_gain"), 0)),
            "star_gift": max(0, self._int(meta.get("star_gift"), 0)),
            "partner_exp": max(0, self._int(meta.get("partner_exp"), 0)),
            "player_exp_gain": energy_cost * multiplier,
        }

    def _campaign_result_energy_cost(self, campaign_id: int, star: int) -> int:
        meta = self.ownership_meta(campaign_id) or self.economy.campaign_meta(campaign_id)
        field = "energy_cost" if int(star) > 0 else "defeat_cost"
        return max(0, self._int((meta or {}).get(field), 0))

    def _campaign_entry_energy_cost(self, campaign_id: int) -> int:
        meta = self.ownership_meta(campaign_id) or self.economy.campaign_meta(campaign_id)
        return max(0, self._int((meta or {}).get("energy_cost"), 0))

    def _settle_campaign_energy(self, campaign_id: int, star: int) -> dict[str, int]:
        cost = self._campaign_result_energy_cost(campaign_id, star)
        if cost <= 0:
            return {}
        if self.settlement is None or self.uow is None:
            raise RuntimeError("Campaign Energy settlement requires Pass71 MutationSettlementService")
        plan = MutationPlan(
            schema_version=1,
            plan_id=f"campaign-energy:{campaign_id}:{self.uow.current_state_version}",
            origin=MutationOrigin(
                domain="campaign", operation="fight_result_energy", protocol_mid=114,
                source_table="data/tables/campaign.lua", source_id=int(campaign_id),
                field_path="energy_cost" if int(star) > 0 else "defeat_cost",
            ),
            actor=ActorRef(
                player_id=str(self.player.player_id),
                account_uid=str(getattr(self.player, "account_uid", "") or "") or None,
            ),
            expected_state_version=self.uow.current_state_version,
            idempotency=IdempotencySpec(mode="NONE"),
            preconditions=(),
            operations=(TemporalTransition("energy", "DEBIT", cost),),
            semantic_events=(),
            metadata={"pass":"75.0","campaign_id":int(campaign_id),"result":"win" if int(star)>0 else "defeat"},
        )
        draft = self.settlement.apply(plan)
        return dict(draft.projection.economy)

    @staticmethod
    def _same_formation(left: Any, right: Any) -> bool:
        return str(left or "") == str(right or "")

    def _active_campaign_session_matches(self, req: dict[str, Any]) -> bool:
        pending = self.player.active_campaign_battle
        if not isinstance(pending, dict) or self._int(pending.get("committed"), 0) != 0:
            return False
        return (
            self._int(pending.get("campaign_id"), 0) == self._int(req.get("campaign_id"), 0)
            and self._int(pending.get("campaign_type"), 1) == self._int(req.get("campaign_type"), 1)
            and self._same_formation(pending.get("formation"), req.get("formation"))
        )

    def _campaign_session_reject(self, message: str) -> dict[str, Any]:
        # Backend.lua treats HTTP 200 as nominal transport success before the
        # application error body is interpreted. Keep rejected FIGHT_RESULT
        # responses source-shaped enough that a nominal callback cannot nil-
        # dereference while still applying no Campaign mutation or reward.
        self.normalize()
        return {
            "error_code": 1,
            "msg": str(message),
            "is_win": 0,
            "result": 0,
            "chapter_info": dict(self.player.world_map.get("chapter_info") or {}),
            "campaigns": [],
            "items": [],
        }

    def _committed_retry_response(self, req: dict[str, Any]) -> dict[str, Any] | None:
        pending = self.player.active_campaign_battle
        if not isinstance(pending, dict) or self._int(pending.get("committed"), 0) != 1:
            return None
        if self._int(pending.get("campaign_id"), 0) != self._int(req.get("campaign_id"), 0):
            return None
        if self._int(pending.get("campaign_type"), 1) != self._int(req.get("campaign_type"), 1):
            return None
        if not self._same_formation(pending.get("formation"), req.get("formation")):
            return None
        if self._int(pending.get("star"), 0) != max(0, min(3, self._int(req.get("star"), 0))):
            return None
        response = pending.get("response")
        if not isinstance(response, dict):
            return None
        # JSON round-trip gives the caller a detached copy without importing a
        # second serialization helper into this small repository.
        return json.loads(json.dumps(response))

    def begin_fight(self, req: dict[str, Any]) -> dict[str, Any]:
        if self.uow is None:
            return self._begin_fight_mutation(req)
        context = OperationContext(
            actor_player_id=str(self.player.player_id),
            protocol_mid=113,
            domain="campaign",
            operation_name="begin_fight",
            idempotency_key=f"fight:{self._int(req.get('campaign_id'), 0)}",
        )
        with self.uow.transaction(context):
            return self._begin_fight_mutation(req)

    def _begin_fight_mutation(self, req: dict[str, Any]) -> dict[str, Any]:
        self.normalize()
        campaign_id = self._int(req.get("campaign_id"), 0)
        campaign_type = self._int(req.get("campaign_type"), 1)
        current = self._find_row(campaign_id, campaign_type) if campaign_type in (1, 2) else self._find_row(campaign_id)
        if campaign_type in (1, 2):
            if campaign_id not in self._source_mode_set(campaign_type):
                return {"error_code": 1, "msg": "campaign_mode_mismatch", "items": []}
            if current is None:
                return {"error_code": 1, "msg": "campaign_locked", "items": []}
            # NewMapDetailWindow blocks Super entry when its server-sourced
            # remaining ``dailyLimit`` is exhausted.  Mirror that UI guard at
            # the authority boundary so direct/modified clients cannot stage a
            # battle after the daily allowance reaches zero.
            if campaign_type == 2 and self._int(current.get("daily_limit"), 0) <= 0:
                return {"error_code": 1, "msg": "campaign_daily_limit_exhausted", "items": []}
            # Client MapDetailWindow performs this same full-cost entry check.
            # Actual settlement waits for MID114 so defeats can use defeat_cost.
            temporal = getattr(self.settlement, "temporal", None) if self.settlement is not None else None
            if temporal is not None:
                try:
                    temporal.preview("energy", "DEBIT", self._campaign_entry_energy_cost(campaign_id))
                except Exception:
                    return {"error_code": 1, "msg": "energy_insufficient", "items": []}
        first_clear_candidate = current is not None and self._int(current.get("star"), 0) <= 0
        if self.drop_planner is None:
            raise RuntimeError("Campaign MID113 requires Pass40.1 CampaignDropPlanner")
        drop_plan = self.drop_planner.plan(
            campaign_id=campaign_id,
            wire_campaign_type=campaign_type,
            first_clear=first_clear_candidate,
        )
        staged_items = drop_plan.battle_items()
        reward_plan = self._campaign_reward_plan(campaign_id) if campaign_type in (1, 2) else {
            "mana_gain": 0,
            "star_gift": 0,
            "partner_exp": 0,
            "player_exp_gain": 0,
        }
        self.player.active_campaign_battle = {
            "campaign_id": campaign_id,
            "campaign_type": campaign_type,
            "formation": str(req.get("formation") or ""),
            "started_at": self.player.now(),
            # ``items`` remains the exact battle-visible MID113 occurrence
            # projection. ``drop_plan.canonical_awards`` is the frozen aggregate
            # committed by MID114; the planner is never invoked at result time.
            "items": staged_items,
            "drop_plan": drop_plan.persisted(),
            **reward_plan,
            "committed": 0,
        }
        self._save()
        # SelectTeamWindow consumes ``items`` before building the local battle;
        # the same staged rows are committed to Backpack only after MID114 wins.
        # Scalar economy/Hero EXP rewards stay server-side until the result.
        return {"battle_id": 1, "report": {}, "seed": 1, "enemy_info": {}, "items": staged_items}

    def commit_fight_result(self, req: dict[str, Any]) -> dict[str, Any]:
        # Idempotent committed-receipt retries are read-only and should not
        # create another durability transaction.
        retry = self._committed_retry_response(req)
        if retry is not None:
            return retry
        campaign_type = self._int(req.get("campaign_type"), 1)
        # Pass75 authority boundary: Normal/Super Campaign state and rewards may
        # only be committed from the exact currently staged MID113 session.
        # Reject before opening a UoW so a spoofed/orphan MID114 cannot advance
        # stars/unlocks or even consume a state_version.
        if campaign_type in (1, 2) and not self._active_campaign_session_matches(req):
            return self._campaign_session_reject("campaign_session_mismatch")
        # Pass81 Super ownership: successful settlement consumes a server-owned
        # remaining attempt. Reject before opening a UoW when no attempt remains
        # so a stale/direct client cannot progress or consume a state version.
        if campaign_type == 2 and max(0, min(3, self._int(req.get("star"), 0))) > 0:
            current = self._find_row(self._int(req.get("campaign_id"), 0), 2)
            if current is None or self._int(current.get("daily_limit"), 0) <= 0:
                return self._campaign_session_reject("campaign_daily_limit_exhausted")
        if self.uow is None:
            return self._commit_fight_result_mutation(req)
        context = OperationContext(
            actor_player_id=str(self.player.player_id),
            protocol_mid=114,
            domain="campaign",
            operation_name="commit_fight_result",
            idempotency_key=f"result:{self._int(req.get('campaign_id'), 0)}:{self._int(req.get('star'), 0)}",
        )
        with self.uow.transaction(context):
            return self._commit_fight_result_mutation(req)

    def _commit_fight_result_mutation(self, req: dict[str, Any]) -> dict[str, Any]:
        self.normalize()

        retry = self._committed_retry_response(req)
        if retry is not None:
            return retry

        cid = self._int(req.get("campaign_id"), 0)
        star = max(0, min(3, self._int(req.get("star"), 0)))
        campaign_type = self._int(req.get("campaign_type"), 1)
        current = self._find_row(cid, campaign_type) if campaign_type in (1, 2) else self._find_row(cid)
        previous_star = self._int(current.get("star"), 0) if current is not None else 0
        was_cleared = current is not None and previous_star > 0
        first_three_star = previous_star < 3 and star >= 3
        pending = self.player.active_campaign_battle if isinstance(self.player.active_campaign_battle, dict) else {}
        has_pending = self._active_campaign_session_matches(req)
        staged_items: list[dict[str, int]] = []
        if has_pending:
            pending_drop_plan = pending.get("drop_plan")
            if isinstance(pending_drop_plan, dict) and isinstance(
                pending_drop_plan.get("canonical_awards"), list
            ):
                staged_items = pending_drop_plan.get("canonical_awards") or []
            elif isinstance(pending.get("items"), list):
                # Upgrade compatibility for an in-flight pre-Pass40.1 MID113
                # session: reuse the already-frozen battle items; never reroll.
                staged_items = pending.get("items") or []

        if current is None:
            # NORMAL/SUPER results require an actually unlocked source row and
            # matching MID113 session; an arbitrary MID114 cannot create map state.
            if campaign_type in (1, 2):
                self.player.active_campaign_battle = {}
                self._save()
                return {"error_code": 1, "msg": "campaign_not_unlocked", "items": []}
            if self.meta(cid) is None:
                self.player.active_campaign_battle = {}
                self._save()
                return {"is_win": 1 if star > 0 else 0, "result": 1 if star > 0 else 0, "items": []}
            current = self._campaign_row(cid, 0)
            self._normal_rows().append(current)
        if campaign_type == 2 and star > 0 and has_pending and self._int(current.get("daily_limit"), 0) <= 0:
            # Defensive mirror of commit_fight_result()'s pre-UoW gate for
            # direct repository callers. No Campaign/reward mutation has
            # occurred yet, so returning here is fail-closed.
            return self._campaign_session_reject("campaign_daily_limit_exhausted")

        if star > 0:
            current["star"] = max(self._int(current.get("star"), 0), star)
            if campaign_type == 2 and has_pending:
                # src_64 treats response.daily_limit as the mutable remaining
                # attempts and never decrements it locally after MID114. The
                # source table's daily_limit remains the reset baseline owned
                # by DailyResetCoordinator. Defeat consumption stays deferred
                # until source/runtime evidence resolves star=0 semantics.
                current["daily_limit"] = max(0, self._int(current.get("daily_limit"), 0) - 1)

        touched = [current]
        meta = self.meta(cid) or {}
        mode_rows = self._mode_rows(campaign_type) if campaign_type in (1, 2) else self._normal_rows()
        next_id = self._next_mode_campaign(cid, campaign_type) if campaign_type in (1, 2) else self._int(meta.get("next_campaign_id"), 0)
        if star > 0 and next_id > 0 and self.meta(next_id) is not None:
            nxt = self._find_row(next_id, campaign_type) if campaign_type in (1, 2) else self._find_row(next_id)
            if nxt is None:
                source_daily = self._int((self.ownership_meta(next_id) or {}).get("daily_limit"), 0)
                nxt = self._campaign_row(next_id, 0)
                nxt["daily_limit"] = max(0, source_daily)
                mode_rows.append(nxt)
                # BattleCreate treats a different returned campaign with star=0
                # as a newly opened node. Replays never synthesize it again.
                touched.append(nxt)

        chapter_info = dict(self.player.world_map.get("chapter_info") or {})
        normal_rows = self._mode_rows(1)
        super_rows = self._mode_rows(2)
        normal_frontier = self._frontier_campaign(normal_rows) or self._mode_frontier(1) or cid
        normal_meta = self.meta(normal_frontier) or meta
        normal_chapter = self._int(normal_meta.get("chapter"), 1) or 1
        super_frontier = self._mode_frontier(2)
        super_meta = self.meta(super_frontier) or {}
        super_chapter = self._int(super_meta.get("chapter"), 0) if super_frontier else 0
        chapter_info.update({
            "normal_chapter_id": normal_chapter,
            "normal_campaign_id": normal_frontier,
            "normal_stars": self._chapter_star_sum(normal_rows, normal_chapter),
            "normal_bonus_id": self._int(chapter_info.get("normal_bonus_id"), 0),
            "super_chapter_id": super_chapter,
            "super_campaign_id": super_frontier,
            "super_stars": self._chapter_star_sum(super_rows, super_chapter) if super_chapter else 0,
            "super_bonus_id": self._int(chapter_info.get("super_bonus_id"), 0),
        })
        self.player.world_map["chapter_info"] = chapter_info

        # Pass36.1 response-channel split:
        # - committed_drop_items are the pending MID113 DropPlan rows whose
        #   canonical Inventory mutation is committed by RewardTransactionService;
        # - result_only_items belong exclusively to MID114's independent
        #   result-award wire channel. No distinct result-only item award is
        #   source-proven for the currently mapped early Campaign slice, so the
        #   shape-preserving wire value remains an empty list.
        committed_drop_items: list[dict[str, int]] = []
        result_only_items: list[dict[str, int]] = []
        economy_projection: dict[str, int] = {}
        if has_pending and campaign_type in (1, 2):
            economy_projection.update(self._settle_campaign_energy(cid, star))
        hero_exps: list[dict[str, int]] = []
        story_mission_delta: list[dict[str, int]] = []
        tutorial_new_funcs: list[int] = []
        star_crystal = 0

        # v0.8.2 commits source-certain rewards only when there is a matching
        # MID113 session. This prevents an arbitrary/retried MID114 from minting
        # Mana/EXP without a battle. General repeat item RNG remains deferred.
        if star > 0 and not was_cleared and has_pending:
            committed_drop_items = staged_items if isinstance(staged_items, list) else []

        if star > 0 and has_pending and campaign_type in (1, 2):
            star_crystal = max(0, self._int(pending.get("star_gift"), 0)) if first_three_star else 0
            if self.rewards is None or self.catalog is None:
                raise RuntimeError("Campaign reward commit requires Pass32.6 reward/catalog services")
            economy_grants: list[EconomyGrant] = []
            for field, raw in (
                ("mana", pending.get("mana_gain", 0)),
                ("crystal", star_crystal),
                ("player_exp", pending.get("player_exp_gain", 0)),
            ):
                amount = max(0, self._int(raw, 0))
                if amount > 0:
                    economy_grants.append(EconomyGrant(field, amount))
            inventory_grants = tuple(
                InventoryGrant(
                    ContentRef(CatalogNamespace.ITEM, self._int(award.get("item_id"), 0)),
                    self._int(award.get("item_num"), 0),
                )
                for award in committed_drop_items
                if isinstance(award, dict)
                and self._int(award.get("item_id"), 0) > 0
                and self._int(award.get("item_num"), 0) > 0
            )
            reward_result = self.rewards.apply(
                RewardPlan(
                    origin=RewardOrigin("campaign", "fight_result", protocol_mid=114, source_table="data/tables/campaign.lua", source_id=cid, field_path="fight_result"),
                    economy=tuple(economy_grants),
                    inventory=inventory_grants,
                )
            )
            economy_projection.update(reward_result.economy)
            # The canonical grant result is intentionally not reused as MID114
            # ``items``. Those rows already belong to the MID113 battle-drop
            # delivery channel and are credited client-side by BattleWinWindow.
            committed_drop_items = reward_result.inventory_awards
            # Economy first: BattleWinWindow observes the post-battle player
            # level when applying Hero EXP and therefore the resulting Hero cap.
            hero_exps = self.hero_progression.grant_battle_exp(
                pending.get("formation", ""),
                pending.get("partner_exp", 0),
                persist=False,
            )
        elif committed_drop_items:
            # Preserve the pre-Pass32.6 non-normal behavior: deterministic
            # first-clear items can still persist without scalar economy grants.
            if self.rewards is None or self.catalog is None:
                raise RuntimeError("Campaign item commit requires Pass32.6 reward/catalog services")
            reward_result = self.rewards.apply(
                RewardPlan(
                    origin=RewardOrigin("campaign", "first_clear_items", protocol_mid=114),
                    inventory=tuple(
                        InventoryGrant(
                            ContentRef(CatalogNamespace.ITEM, self._int(award.get("item_id"), 0)),
                            self._int(award.get("item_num"), 0),
                        )
                        for award in committed_drop_items
                        if isinstance(award, dict)
                        and self._int(award.get("item_id"), 0) > 0
                        and self._int(award.get("item_num"), 0) > 0
                    ),
                )
            )
            # Preserve the committed DropPlan identity without projecting it
            # through MID114's independent result-only item channel.
            committed_drop_items = reward_result.inventory_awards

        if star > 0 and has_pending and campaign_type == 1 and self.missions is not None:
            story_mission_delta = self.missions.record_campaign_clear(cid)

        # Pass33.1 trust boundary: authoritative tutorial milestones are emitted
        # from the successful canonical Campaign transaction, never from MID26's
        # client-attested guide/story cursor.  The policy service owns the
        # Function33 release decision; Campaign supplies only its committed fact.
        if self.tutorial is not None:
            tutorial_new_funcs = self.tutorial.record_campaign_clear(
                cid,
                campaign_type,
                star,
                canonical_session=has_pending,
                persist=False,
            )

        awake_delta: dict[str, Any] = {}
        if self.awakening_missions is not None:
            awake_delta = self.awakening_missions.record_campaign_result(req)

        response: dict[str, Any] = {
            "is_win": 1 if star > 0 else 0,
            "result": 1 if star > 0 else 0,
            "chapter_info": chapter_info,
            "campaigns": touched,
            "items": result_only_items,
        }
        if economy_projection:
            response["economy_"] = economy_projection
        if hero_exps:
            response["exps"] = hero_exps
        if star_crystal > 0:
            # BattleCreate/BattleWin consume the per-result scalar while the
            # global projector/economy_ carries the canonical cumulative total.
            response["star_crystal"] = star_crystal
        if story_mission_delta:
            response["story_mission_"] = story_mission_delta
        if awake_delta:
            response.update(awake_delta)
        if tutorial_new_funcs:
            # Keep the semantic transition in the committed MID114 receipt as
            # well as the UoW semantic bus so a result retry cannot lose it.
            response["new_funcs_"] = sorted({int(value) for value in tutorial_new_funcs if int(value) > 0})

        if has_pending:
            # Keep the committed response as a one-request receipt until the
            # next MID113 overwrites it. A duplicate MID114 therefore returns
            # the same response-shaped receipt without applying rewards twice.
            self.player.active_campaign_battle = {
                "campaign_id": cid,
                "campaign_type": campaign_type,
                "formation": str(pending.get("formation") or ""),
                "star": star,
                "committed": 1,
                "committed_at": self.player.now(),
                "response": json.loads(json.dumps(response)),
            }
        else:
            self.player.active_campaign_battle = {}

        self._save()
        return response

    def reset_campaign(self, req: dict[str, Any]) -> dict[str, Any]:
        """MID116: buy one new Super Campaign attempt block atomically.

        Effective src_64 exposes the button only when ``dailyLimit <= 0`` and
        prices ordinal ``reset_count + 1``.  A repeated request received after
        a committed reset but before those refreshed attempts are consumed is
        treated as a read-only postcondition replay: this reconciles a lost HTTP
        response without inventing a request nonce or charging twice.
        """
        campaign_id = self._int(req.get("campaign_id"), 0)
        campaign_type = self._int(req.get("campaign_type"), 0)
        if campaign_type != 2:
            return {"error_code": 1, "msg": "campaign_reset_super_only"}
        if campaign_id not in self._source_mode_set(2):
            return {"error_code": 1, "msg": "campaign_mode_mismatch"}
        current = self._find_row(campaign_id, 2)
        if current is None:
            return {"error_code": 1, "msg": "campaign_locked"}

        # Natural source-state reconciliation for a lost successful response.
        # The UI cannot legitimately request a paid reset while attempts remain;
        # returning the already-committed row is therefore mutation-free and
        # restores the client's dailyLimit/resetCount view. Initial/non-reset
        # state (reset_count==0) still fails closed.
        if self._int(current.get("daily_limit"), 0) > 0:
            if self._int(current.get("reset_count"), 0) > 0:
                return self._reset_campaign_response(current)
            return {"error_code": 1, "msg": "campaign_daily_limit_not_exhausted"}

        if self.campaign_reset_policy is None:
            return {"error_code": 1, "msg": "campaign_reset_policy_unavailable"}
        reset_count = max(0, self._int(current.get("reset_count"), 0))
        allowance = max(0, self.campaign_reset_policy.total_allowance())
        if reset_count >= allowance:
            return {"error_code": 1, "msg": "campaign_reset_limit_exhausted"}
        try:
            cost = max(0, self.campaign_reset_policy.next_cost(reset_count))
        except Exception as exc:
            return {"error_code": 1, "msg": f"campaign_reset_cost_unavailable:{exc}"}

        if self.uow is None:
            try:
                return self._reset_campaign_mutation(current, cost)
            except InsufficientScalarBalance:
                return {"error_code": 1, "msg": "crystal_insufficient"}
        context = OperationContext(
            actor_player_id=str(self.player.player_id),
            protocol_mid=116,
            domain="campaign",
            operation_name="reset_super_campaign",
            idempotency_key=None,
        )
        try:
            with self.uow.transaction(context):
                # Re-resolve inside the rollback snapshot in case a direct test
                # mutates state between preflight and transaction entry.
                row = self._find_row(campaign_id, 2)
                if row is None:
                    return {"error_code": 1, "msg": "campaign_locked"}
                if self._int(row.get("daily_limit"), 0) > 0:
                    if self._int(row.get("reset_count"), 0) > 0:
                        return self._reset_campaign_response(row)
                    return {"error_code": 1, "msg": "campaign_daily_limit_not_exhausted"}
                current_count = max(0, self._int(row.get("reset_count"), 0))
                current_allowance = max(0, self.campaign_reset_policy.total_allowance())
                if current_count >= current_allowance:
                    return {"error_code": 1, "msg": "campaign_reset_limit_exhausted"}
                current_cost = max(0, self.campaign_reset_policy.next_cost(current_count))
                return self._reset_campaign_mutation(row, current_cost)
        except InsufficientScalarBalance:
            return {"error_code": 1, "msg": "crystal_insufficient"}

    def _reset_campaign_mutation(self, row: dict[str, Any], cost: int) -> dict[str, Any]:
        ownership = self.ownership_meta(row.get("campaign_id")) or {}
        source_limit = max(0, self._int(ownership.get("daily_limit"), 0))
        if source_limit <= 0:
            return {"error_code": 1, "msg": "campaign_source_daily_limit_unavailable"}
        ledger = getattr(self.economy, "ledger", None)
        if ledger is None:
            return {"error_code": 1, "msg": "campaign_crystal_ledger_unavailable"}
        # ``EconomyLedger.debit`` intentionally returns None on insufficient
        # balance; use apply_deltas so the typed exception reaches the UoW and
        # no campaign field is staged first.
        ledger.apply_deltas({"crystal": -max(0, int(cost))}, persist=False)
        row["daily_limit"] = source_limit
        row["reset_count"] = max(0, self._int(row.get("reset_count"), 0)) + 1
        # ``star`` and ``is_partner_drop`` are deliberately untouched.
        self._save()
        return self._reset_campaign_response(row)

    @staticmethod
    def _reset_campaign_response(row: dict[str, Any]) -> dict[str, int]:
        def as_int(value: Any, default: int = 0) -> int:
            try:
                return int(value)
            except (TypeError, ValueError):
                return default
        return {
            "campaign_id": as_int(row.get("campaign_id"), 0),
            "star": max(0, min(3, as_int(row.get("star"), 0))),
            "daily_limit": max(0, as_int(row.get("daily_limit"), 0)),
            "reset_count": max(0, as_int(row.get("reset_count"), 0)),
        }

    def sweep(self, req: dict[str, Any]) -> dict[str, Any]:
        # Historical repository-only tests construct WorldRepository without the
        # request-scoped settlement graph. Preserve that non-runtime seam; live
        # RequestServices always supplies both UoW and MutationSettlementService.
        if self.uow is None or self.settlement is None:
            return self._sweep_compatibility_read_model(req)
        context = OperationContext(
            actor_player_id=str(self.player.player_id),
            protocol_mid=117,
            domain="campaign",
            operation_name="sweep_campaign",
            idempotency_key=None,
        )
        with self.uow.transaction(context):
            return self._sweep_mutation(req)

    def _sweep_compatibility_read_model(self, req: dict[str, Any]) -> dict[str, Any]:
        self.normalize()
        cid = self._int(req.get("campaign_id"), 0)
        count = max(1, min(100, self._int(req.get("sweep_num"), 1)))
        if count > 1 and self.vip_privileges is not None and not self.vip_privileges.campaign_multi_sweep_enabled():
            return {"error_code": 1, "msg": "campaign_multi_sweep_privilege_required"}
        row = self._find_row(cid) or self._campaign_row(cid, 0)
        return {
            "items": [[] for _ in range(count)],
            "economys": [{"exp": 0, "mana": 0} for _ in range(count)],
            "additional": [],
            "campaign": row,
        }

    def _sweep_mutation(self, req: dict[str, Any]) -> dict[str, Any]:
        self.normalize()
        cid = self._int(req.get("campaign_id"), 0)
        count = max(1, min(100, self._int(req.get("sweep_num"), 1)))
        sweep_type = self._int(req.get("sweep_type"), 0)
        # src_64 enums.lua: ITEM_SWEEP=1, CRYSTAL_SWEEP=2. The client checks
        # campaign.energyCost * sweep_num before opening SweepWindow, then
        # removes one Raid Ticket (50001013) per successful ITEM_SWEEP locally.
        # CRYSTAL_SWEEP instead costs one Crystal per sweep. The server must
        # durably own the same debits or reloads resurrect spent resources.
        if sweep_type not in (1, 2):
            return {"error_code": 1, "msg": "campaign_sweep_type_invalid"}
        # Source MapDetail/NewMapDetail behavior: ordinary single sweep remains
        # available, while a multi-sweep requires VIP quick_sweep OR an active
        # Monthly Privilege card. Monthly Privilege lifecycle itself is not
        # implemented here; this path only reads the existing entitlement.
        if count > 1 and self.vip_privileges is not None and not self.vip_privileges.campaign_multi_sweep_enabled():
            return {"error_code": 1, "msg": "campaign_multi_sweep_privilege_required"}
        row = self._find_row(cid) or self._campaign_row(cid, 0)
        reward_meta = self._campaign_rewards.get(str(cid)) or {}
        source_sweep = reward_meta.get("sweep_rewards") or []

        # campaign.lua explicitly pairs sweep_reward + sweep_reward_num. Only
        # those rows are granted here; normal/first-clear dropbox RNG remains a
        # separate contract. SweepWindow consumes one list of item_id/item_num
        # rows per sweep and adds them to its local Backpack.
        per_sweep: list[dict[str, int]] = []
        if self._int(row.get("star"), 0) > 0:
            for award in source_sweep:
                if not isinstance(award, dict):
                    continue
                item_id = self._int(award.get("item_id"), 0)
                item_num = self._int(award.get("item_num"), 0)
                if item_id > 0 and item_num > 0:
                    per_sweep.append({"item_id": item_id, "item_num": item_num})

        item_rows = [[dict(award) for award in per_sweep] for _ in range(count)]
        if self.settlement is None or self.uow is None:
            raise RuntimeError("Campaign MID117 sweep settlement requires PlayerUnitOfWork")

        energy_cost = self._campaign_entry_energy_cost(cid)
        if energy_cost <= 0:
            return {"error_code": 1, "msg": "campaign_energy_cost_unavailable"}
        operations = [
            TemporalTransition("energy", "DEBIT", energy_cost * count),
        ]
        if sweep_type == 1:
            operations.append(StackMutation(50001013, "DEBIT", count))
        else:
            operations.append(ResourceMutation("crystal", "DEBIT", count))
        for award in per_sweep:
            operations.append(StackMutation(award["item_id"], "CREDIT", award["item_num"] * count))

        plan = MutationPlan(
            schema_version=1,
            plan_id=f"campaign-sweep:{cid}:{self.uow.current_state_version}",
            origin=MutationOrigin(
                domain="campaign", operation="sweep_campaign", protocol_mid=117,
                source_table="data/tables/campaign.lua", source_id=cid, field_path="energy_cost",
            ),
            actor=ActorRef(
                player_id=str(self.player.player_id),
                account_uid=str(getattr(self.player, "account_uid", "") or "") or None,
            ),
            expected_state_version=self.uow.current_state_version,
            idempotency=IdempotencySpec(mode="NONE"),
            preconditions=(),
            operations=tuple(operations),
            semantic_events=(),
            metadata={
                "pass": "99.0",
                "campaign_id": cid,
                "sweep_num": count,
                "sweep_type": sweep_type,
                "raid_ticket_item_id": 50001013,
            },
        )
        try:
            self.settlement.apply(plan)
        except (MutationSettlementError, StackInventoryError, InsufficientScalarBalance) as exc:
            return {"error_code": 1, "msg": str(exc)}

        return {
            "items": item_rows,
            # SweepWindow defaults a missing economy.exp to 12 client-side.
            # Explicit zeroes prevent us from fabricating player EXP/mana until
            # those economy mutation semantics are reconstructed and persisted.
            "economys": [{"exp": 0, "mana": 0} for _ in range(count)],
            "additional": [],
            "campaign": row,
        }

    def _save(self) -> None:
        if self._save_callback:
            self._save_callback()
