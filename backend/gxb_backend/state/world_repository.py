"""Canonical Normal/Super Campaign progression and commit helpers.

The supplied client simulates Campaign combat locally. The backend owns
persistent map state around that simulation: the unlocked campaign rows, best
stars, chapter cursor, the pending MID113 -> MID114 session, source-certain
first-clear items, and v0.8.2's canonical Mana/player/Hero EXP transaction. Pass114 activates the
source-bounded private-server MID117 repeat-drop policy behind source-native UUID
receipts; MID113 repeat battle RNG remains disabled. Source-derived campaign links
are packaged in ``data/campaign_meta.json`` and source rows remain policy-separated.
"""
from __future__ import annotations

import copy
import hashlib
import json
from collections.abc import Callable
from pathlib import Path
from typing import Any

from gxb_backend.content import CatalogNamespace, ContentRef, GameDataCatalog
from gxb_backend.content.challenge_campaign_catalog import CHALLENGE_CAMPAIGN_TYPE, ChallengeCampaignCatalog
from gxb_backend.content.super_campaign_catalog import SUPER_CAMPAIGN_TYPE, SUPER_FUNCTION_ID, SuperCampaignCatalog

from .awakening_mission_service import AwakeningMissionService
from .awakening_campaign_overlay_planner import (
    AwakeningCampaignOverlayError, AwakeningCampaignOverlayPlanner,
)
from .awakening_campaign_objective_validator import AwakeningCampaignObjectiveValidator
from .campaign_drop_planner import (
    CAMPAIGN_REPEAT_POLICY_ID,
    CAMPAIGN_REPEAT_POLICY_VERSION,
    CampaignDropPlanner,
    CampaignDropSourceCorruptionError,
    CampaignRepeatPoolUnavailableError,
)
from .campaign_sweep_economy_policy import CampaignSweepEconomyPolicy
from .campaign_reset_policy import CampaignResetPolicy
from .campaign_composition import CampaignComposition
from .challenge_projection_service import ChallengeProjectionService
from .economy_repository import EconomyRepository
from .economy_ledger import InsufficientScalarBalance
from .elite_campaign_unlock_coordinator import EliteCampaignUnlockCoordinator
from .function_state_repository import FunctionStateRepository
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
from .super_campaign_access_policy import SuperCampaignAccessPolicy
from .super_campaign_projection_service import SuperCampaignProjectionService
from .mid117_operation_receipt import (
    RECEIPT_DOMAIN as MID117_RECEIPT_DOMAIN,
    RECEIPT_MODE as MID117_RECEIPT_MODE,
    RETENTION_POLICY as MID117_RETENTION_POLICY,
    Mid117OperationIdentity,
    Mid117OperationIdentityError,
    build_mid117_replay_payload,
    validate_mid117_replay_payload,
)
from .unit_of_work import OperationContext, ReceiptConflict, UnitOfWork
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
        awakening_campaign_overlay: AwakeningCampaignOverlayPlanner | None = None,
        awakening_campaign_objectives: AwakeningCampaignObjectiveValidator | None = None,
        catalog: GameDataCatalog | None = None,
        rewards: RewardTransactionService | None = None,
        tutorial: TutorialMilestoneRepository | None = None,
        drop_planner: CampaignDropPlanner | None = None,
        settlement: MutationSettlementService | None = None,
        uow: UnitOfWork | None = None,
        campaign_reset_policy: CampaignResetPolicy | None = None,
        vip_privileges: VipPrivilegeResolver | None = None,
        challenge_catalog: ChallengeCampaignCatalog | None = None,
        challenge_projection: ChallengeProjectionService | None = None,
        super_catalog: SuperCampaignCatalog | None = None,
        super_access_policy: SuperCampaignAccessPolicy | None = None,
        super_projection: SuperCampaignProjectionService | None = None,
        elite_campaign_unlock: EliteCampaignUnlockCoordinator | None = None,
        strict_campaign_collaborators: bool = False,
    ) -> None:
        self.player = player
        self.data_dir = Path(data_dir)
        self._save_callback = save_callback
        self.inventory = inventory
        self.economy = economy or EconomyRepository(player, self.data_dir)
        self.hero_progression = hero_progression or HeroProgressionRepository(player, self.data_dir)
        self.missions = missions
        self.awakening_missions = awakening_missions
        self.awakening_campaign_overlay = awakening_campaign_overlay
        self.awakening_campaign_objectives = awakening_campaign_objectives
        self.catalog = catalog
        self.rewards = rewards
        self.tutorial = tutorial
        self.drop_planner = drop_planner
        self._campaign_drop_source_sha256 = self._drop_source_sha256(drop_planner)
        self.settlement = settlement
        self.uow = uow
        self.campaign_reset_policy = campaign_reset_policy
        self.vip_privileges = vip_privileges or VipPrivilegeResolver(
            player, VipProgressionPolicy(self.data_dir)
        )
        # Pass129 production composition is strict: RequestServices and
        # PlayerMaintenanceServices must inject one canonical Campaign graph.
        # The fallback branch remains only for legacy direct callers/tools so the
        # WorldRepository facade can be strangled incrementally without a rewrite.
        if strict_campaign_collaborators:
            required = {
                "challenge_catalog": challenge_catalog,
                "challenge_projection": challenge_projection,
                "super_catalog": super_catalog,
                "super_access_policy": super_access_policy,
                "super_projection": super_projection,
                "elite_campaign_unlock": elite_campaign_unlock,
            }
            missing = [name for name, value in required.items() if value is None]
            if missing:
                raise ValueError(
                    "strict Campaign composition missing collaborators: " + ", ".join(missing)
                )
            CampaignComposition(
                challenge_catalog=challenge_catalog,
                challenge_projection=challenge_projection,
                super_catalog=super_catalog,
                super_projection=super_projection,
                super_access=super_access_policy,
                elite_campaign_unlock=elite_campaign_unlock,
            ).validate(player, super_access_policy.function_state, uow=uow)

        self.challenge_catalog = challenge_catalog or ChallengeCampaignCatalog(self.data_dir)
        self.challenge_projection = challenge_projection or ChallengeProjectionService(self.challenge_catalog)
        self.super_catalog = super_catalog or SuperCampaignCatalog(self.data_dir)
        self.super_projection = super_projection or SuperCampaignProjectionService(
            player, self.super_catalog, uow
        )
        if super_access_policy is None:
            if catalog is not None:
                _function_state = FunctionStateRepository(player, catalog)
                super_access_policy = SuperCampaignAccessPolicy(
                    player, self.super_catalog, _function_state
                )
        self.super_access_policy = super_access_policy
        if elite_campaign_unlock is None and self.super_access_policy is not None:
            elite_campaign_unlock = EliteCampaignUnlockCoordinator(
                player, self.super_access_policy.function_state, self.super_projection, uow
            )
        self.elite_campaign_unlock = elite_campaign_unlock
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

    @staticmethod
    def _drop_source_sha256(drop_planner: CampaignDropPlanner | None) -> str:
        if drop_planner is None:
            return "0" * 64
        source_catalog = getattr(drop_planner, "source_catalog", None)
        path = getattr(source_catalog, "path", None)
        try:
            return hashlib.sha256(Path(path).read_bytes()).hexdigest()
        except Exception:
            return "0" * 64


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
        if self._int(campaign_type, 1) == SUPER_CAMPAIGN_TYPE:
            return list(self.super_catalog.ids())
        raw = self._campaign_ownership.get("normal_campaign_ids") if isinstance(self._campaign_ownership, dict) else []
        return [self._int(v) for v in raw if self._int(v) > 0] if isinstance(raw, list) else []

    def _source_mode_set(self, campaign_type: Any) -> set[int]:
        return set(self._source_mode_ids(campaign_type))

    def _super_function_open(self) -> bool:
        if self.super_access_policy is not None:
            return self.super_access_policy.function_open()
        return SUPER_FUNCTION_ID in {
            self._int(value, 0)
            for value in (self.player.func_ids if isinstance(self.player.func_ids, list) else [])
        }

    def _mode_key(self, campaign_type: Any) -> str:
        return "super" if self._int(campaign_type, 1) == 2 else "normal"

    def _mode_rows(self, campaign_type: Any) -> list[dict[str, Any]]:
        key = self._mode_key(campaign_type)
        wm = self.player.world_map if isinstance(self.player.world_map, dict) else {}
        rows = wm.get(key)
        return rows if isinstance(rows, list) else []

    def _challenge_rows(self) -> list[dict[str, Any]]:
        wm = self.player.world_map if isinstance(self.player.world_map, dict) else {}
        rows = wm.get("challenge")
        return rows if isinstance(rows, list) else []

    def _find_challenge_row(self, campaign_id: int) -> dict[str, Any] | None:
        for row in self._challenge_rows():
            if self._int(row.get("campaign_id"), 0) == int(campaign_id):
                return row
        return None

    def _find_projection_row(self, campaign_id: int) -> dict[str, Any] | None:
        for wire_type in (1, 2):
            row = self._find_mode_row(int(campaign_id), wire_type)
            if row is not None:
                return row
        return self._find_challenge_row(int(campaign_id))

    def _challenge_unlock_eligible(self) -> bool:
        normal = self._mode_rows(1)
        terminal = next(
            (row for row in normal if self._int(row.get("campaign_id"), 0) == 1600016),
            None,
        )
        if terminal is not None:
            return self._int(terminal.get("star"), 0) > 0
        chapter = self.player.world_map.get("chapter_info") if isinstance(self.player.world_map, dict) else {}
        return self._int((chapter or {}).get("normal_chapter_id"), 0) > 16

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
        chapter = wm.get("chapter_info")
        if not isinstance(chapter, dict):
            chapter = {}
            changed = True

        terminal = next(
            (row for row in normal if self._int(row.get("campaign_id"), 0) == 1600016),
            None,
        )
        challenge_gate_open = bool(terminal is not None and self._int(terminal.get("star"), 0) > 0)
        # Pass120 compatibility fallback is allowed only when the canonical
        # Normal terminal row is absent from legacy state.
        if terminal is None and self._int(chapter.get("normal_chapter_id"), 0) > 16:
            challenge_gate_open = True
        challenge_rows, _challenge_added, challenge_changed = self.challenge_projection.project(
            wm.get("challenge"), gate_open=challenge_gate_open
        )
        if challenge_changed or wm.get("challenge") != challenge_rows:
            wm["challenge"] = challenge_rows
            changed = True
        if not isinstance(wm.get("chapter_events"), dict):
            wm["chapter_events"] = {}
            changed = True

        normal_frontier = self._frontier_campaign(normal) or self._mode_frontier(1) or 100001
        normal_meta = self.meta(normal_frontier) or {}
        normal_chapter = self._int(normal_meta.get("chapter"), 1) or 1
        normalized_chapter = {
            **chapter,
            "normal_chapter_id": normal_chapter,
            "normal_campaign_id": normal_frontier,
            "normal_stars": self._chapter_star_sum(normal, normal_chapter),
            "normal_bonus_id": self._int(chapter.get("normal_bonus_id"), 0),
            "super_bonus_id": self._int(chapter.get("super_bonus_id"), 0),
        }
        if normalized_chapter != chapter:
            wm["chapter_info"] = normalized_chapter
            changed = True
        # Pass128: Super row visibility/frontier is coordinated with server-issued
        # Function31 authority.  Announced legacy accounts self-heal the first row;
        # malformed/preseed rows remain preserved but cannot expose a Super cursor
        # while Function31 is closed.
        if self.elite_campaign_unlock is not None:
            if self.elite_campaign_unlock.reconcile_projection():
                changed = True
        elif self.super_projection.reconcile(
            function_open=self._super_function_open(),
            ensure_first=self._super_function_open(),
        ):
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
            if self._int(campaign_type, 0) == CHALLENGE_CAMPAIGN_TYPE:
                return self._find_challenge_row(campaign_id)
            return self._find_mode_row(campaign_id, campaign_type)
        for wire_type in (1, 2):
            row = self._find_mode_row(campaign_id, wire_type)
            if row is not None:
                return row
        return self._find_challenge_row(campaign_id)

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
        if self.normalize():
            self._save()
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
        if self.challenge_catalog.contains(campaign_id):
            meta = self.challenge_catalog.row(campaign_id) or {}
        else:
            meta = self.ownership_meta(campaign_id) or self.economy.campaign_meta(campaign_id)
        field = "energy_cost" if int(star) > 0 else "defeat_cost"
        return max(0, self._int((meta or {}).get(field), 0))

    def _campaign_entry_energy_cost(self, campaign_id: int) -> int:
        if self.challenge_catalog.contains(campaign_id):
            meta = self.challenge_catalog.row(campaign_id) or {}
        else:
            meta = self.ownership_meta(campaign_id) or self.economy.campaign_meta(campaign_id)
        return max(0, self._int((meta or {}).get("energy_cost"), 0))

    def _campaign_entry_mana_gain(self, campaign_id: int) -> int:
        if self.challenge_catalog.contains(campaign_id):
            meta = self.challenge_catalog.row(campaign_id) or {}
        else:
            meta = self.ownership_meta(campaign_id) or self.economy.campaign_meta(campaign_id)
        return max(0, self._int((meta or {}).get("mana_gain"), 0))

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

    def _campaign_session_status(self, session: Any) -> str:
        if not isinstance(session, dict):
            return ""
        status = str(session.get("status") or "").strip().upper()
        if status:
            return status
        # Compatibility with the Pass117 convenience marker.
        committed = self._int(session.get("committed"), 0)
        star = self._int(session.get("star"), 0)
        return "SETTLED_WIN" if committed == 1 and star > 0 else (
            "SETTLED_LOSS" if committed == 1 else "STAGED"
        )

    def _active_campaign_session(self) -> dict[str, Any]:
        session = self.player.active_campaign_battle
        return session if isinstance(session, dict) else {}

    def _active_campaign_session_matches(
        self,
        req: dict[str, Any],
        *,
        statuses: tuple[str, ...] = ("STAGED",),
    ) -> bool:
        """Match the source-visible Campaign session boundary.

        Effective src_64 carries only campaign_id/campaign_type across MID113 -> MID114.
        Formation is audit metadata, not correlation authority, and any legacy
        ``campaign_battle_op_id`` from OTA 1.631.7 is intentionally ignored.
        """
        session = self._active_campaign_session()
        if self._campaign_session_status(session) not in {str(v).upper() for v in statuses}:
            return False
        return (
            self._int(session.get("campaign_id"), 0) == self._int(req.get("campaign_id"), 0)
            and self._int(session.get("campaign_type"), 1) == self._int(req.get("campaign_type"), 1)
        )

    @staticmethod
    def _session_formation(session: dict[str, Any]) -> str:
        return str(session.get("formation_snapshot") or session.get("formation") or "")

    def _awakening_active_snapshots(self) -> tuple[dict[str, Any] | None, dict[str, Any] | None]:
        if self.awakening_missions is None:
            return None, None
        return (
            self.awakening_missions.active_snapshot(AwakeningMissionService.HERO),
            self.awakening_missions.active_snapshot(AwakeningMissionService.HERO_TWICE),
        )

    def _resolve_awakening_campaign_overlay(
        self, *, campaign_id: int, campaign_type: int, ordinary_wire_mission: int = 0
    ):
        if self.awakening_campaign_overlay is None or self.awakening_missions is None:
            return None
        ordinary, blood = self._awakening_active_snapshots()
        return self.awakening_campaign_overlay.resolve(
            campaign_id=campaign_id, wire_campaign_type=campaign_type,
            ordinary_active=ordinary, blood_active=blood,
            ordinary_wire_mission=ordinary_wire_mission,
        )

    @staticmethod
    def _session_awakening_overlay_awards(session: dict[str, Any]) -> list[dict[str, int]]:
        overlay = session.get("awakening_overlay") if isinstance(session, dict) else None
        rows = overlay.get("canonical_awards") if isinstance(overlay, dict) else None
        if not isinstance(rows, list):
            return []
        out: list[dict[str, int]] = []
        for row in rows:
            if not isinstance(row, dict):
                continue
            try:
                item_id = int(row.get("item_id", 0) or 0); item_num = int(row.get("item_num", 0) or 0)
            except (TypeError, ValueError):
                continue
            if item_id > 0 and item_num > 0:
                out.append({"item_id": item_id, "item_num": item_num})
        return out

    def _freeze_awakening_campaign_objective(
        self, *, request: dict[str, Any], campaign_id: int, campaign_type: int
    ) -> dict[str, Any] | None:
        if self.awakening_missions is None or self.awakening_campaign_objectives is None:
            return None
        active = self.awakening_missions.active_snapshot(AwakeningMissionService.HERO)
        if not active:
            return None
        row = self.awakening_missions.mission_source_row(
            active.get("mission_id", 0), AwakeningMissionService.HERO
        )
        return self.awakening_campaign_objectives.freeze_context(
            active=active, mission_row=row, campaign_id=campaign_id,
            campaign_type=campaign_type, request=request,
        )

    def _session_reward_value(self, session: dict[str, Any], key: str) -> int:
        reward_plan = session.get("reward_plan")
        if isinstance(reward_plan, dict) and key in reward_plan:
            return max(0, self._int(reward_plan.get(key), 0))
        # Pass117 in-flight compatibility.
        return max(0, self._int(session.get(key), 0))

    def _stage_response_from_session(self, session: dict[str, Any]) -> dict[str, Any]:
        response = session.get("stage_response")
        if isinstance(response, dict):
            return copy.deepcopy(response)
        # Compatibility for a STAGED Pass117 session surviving an upgrade.
        items = session.get("items") if isinstance(session.get("items"), list) else []
        return {
            "battle_id": 1,
            "report": {},
            "seed": 1,
            "enemy_info": {},
            "items": copy.deepcopy(items),
        }

    def _terminal_projection_descriptor(self, response: dict[str, Any]) -> dict[str, Any]:
        campaign_ids: list[int] = []
        for row in response.get("campaigns") or []:
            if isinstance(row, dict):
                cid = self._int(row.get("campaign_id"), 0)
                if cid > 0 and cid not in campaign_ids:
                    campaign_ids.append(cid)
        economy = response.get("economy_")
        economy_keys = sorted(str(key) for key in economy.keys()) if isinstance(economy, dict) else []
        return {
            "chapter_info": isinstance(response.get("chapter_info"), dict),
            "campaign_ids": campaign_ids,
            "economy_keys": economy_keys,
        }

    @staticmethod
    def _terminal_static_response(response: dict[str, Any]) -> dict[str, Any]:
        static = copy.deepcopy(response)
        static.pop("chapter_info", None)
        static.pop("campaigns", None)
        static.pop("economy_", None)
        static.pop("error_code", None)
        static.pop("msg", None)
        return static

    def _render_terminal_campaign_response(
        self,
        session: dict[str, Any],
        *,
        error_code: int = 30005,
    ) -> dict[str, Any]:
        """Render a terminal duplicate without replaying any mutation.

        BattleCreate explicitly accepts 30005 (errorIdFightExist) for Campaign
        FIGHT_RESULT. Static outcome fields are frozen at settlement while
        mutable projections are refreshed from current player state.
        """
        static = session.get("terminal_static_response")
        legacy_response = session.get("response")
        if not isinstance(static, dict):
            static = self._terminal_static_response(legacy_response) if isinstance(legacy_response, dict) else {
                "is_win": 1 if self._campaign_session_status(session) == "SETTLED_WIN" else 0,
                "result": 1 if self._campaign_session_status(session) == "SETTLED_WIN" else 0,
                "items": [],
            }
        response = copy.deepcopy(static)
        projection = session.get("terminal_projection")
        if not isinstance(projection, dict):
            projection = self._terminal_projection_descriptor(legacy_response) if isinstance(legacy_response, dict) else {}

        if bool(projection.get("chapter_info")):
            response["chapter_info"] = copy.deepcopy(self.player.world_map.get("chapter_info") or {})

        rows: list[dict[str, Any]] = []
        for raw_cid in projection.get("campaign_ids") or []:
            cid = self._int(raw_cid, 0)
            row = self._find_projection_row(cid)
            if row is not None:
                rows.append(copy.deepcopy(row))
        response["campaigns"] = rows

        economy_keys = projection.get("economy_keys") or []
        if economy_keys:
            current: dict[str, int] = {}
            for key in economy_keys:
                name = str(key)
                if hasattr(self.player, name):
                    current[name] = max(0, self._int(getattr(self.player, name), 0))
            if current:
                response["economy_"] = current

        response["error_code"] = int(error_code)
        if int(error_code) == 30005:
            response["msg"] = "errorIdFightExist"
        return response

    def _campaign_terminal_drain(self, message: str = "campaign_battle_not_active") -> dict[str, Any]:
        """Source-family terminal drain for an unmatched/stale MID114.

        This intentionally performs no Campaign/reward mutation. The stock
        BattleCreate callback accepts 30005 and can safely consume these
        shape-preserving empty projections.
        """
        self.normalize()
        return {
            "error_code": 30005,
            "msg": str(message),
            "is_win": 0,
            "result": 0,
            "chapter_info": copy.deepcopy(self.player.world_map.get("chapter_info") or {}),
            "campaigns": [],
            "items": [],
        }

    def _campaign_session_reject(self, message: str) -> dict[str, Any]:
        self.normalize()
        return {
            "error_code": 1,
            "msg": str(message),
            "is_win": 0,
            "result": 0,
            "chapter_info": copy.deepcopy(self.player.world_map.get("chapter_info") or {}),
            "campaigns": [],
            "items": [],
        }

    def begin_fight(self, req: dict[str, Any]) -> dict[str, Any]:
        """MID113: create or replay the single server-owned Campaign battle session."""
        self.normalize()
        campaign_id = self._int(req.get("campaign_id"), 0)
        campaign_type = self._int(req.get("campaign_type"), 1)

        active = self._active_campaign_session()
        if self._active_campaign_session_matches(req, statuses=("STAGED",)):
            # Sticky stage: same Campaign/type always replays the exact frozen
            # result, regardless of formation or any legacy operation UUID.
            return self._stage_response_from_session(active)

        if self.uow is None:
            return self._begin_fight_mutation(req)

        context = OperationContext(
            actor_player_id=str(self.player.player_id),
            protocol_mid=113,
            domain="campaign",
            operation_name="begin_fight",
            idempotency_key=f"session:{campaign_type}:{campaign_id}",
        )
        with self.uow.transaction(context):
            # Re-check inside the transaction boundary. A valid different stage
            # may supersede the prior active session only after source guards pass.
            if self._active_campaign_session_matches(req, statuses=("STAGED",)):
                return self._stage_response_from_session(self._active_campaign_session())
            return self._begin_fight_mutation(req)

    def _begin_fight_mutation(
        self,
        req: dict[str, Any],
    ) -> dict[str, Any]:
        self.normalize()
        campaign_id = self._int(req.get("campaign_id"), 0)
        campaign_type = self._int(req.get("campaign_type"), 1)
        current = self._find_row(campaign_id, campaign_type)
        if campaign_type in (1, SUPER_CAMPAIGN_TYPE):
            if campaign_type == SUPER_CAMPAIGN_TYPE and self.super_access_policy is not None:
                # Pass128 source-authentic bouncer.  The stock UI checks the
                # related Normal clear after a materialized Super node is clicked;
                # the server mirrors that rule before attempts/Energy/RNG/session
                # replacement so modified clients cannot bypass it.
                decision = self.super_access_policy.evaluate(campaign_id, campaign_type)
                if not decision.allowed:
                    return {"error_code": 1, "msg": decision.reason, "items": []}
                current = self._find_mode_row(campaign_id, SUPER_CAMPAIGN_TYPE)
            else:
                if campaign_id not in self._source_mode_set(campaign_type):
                    return {"error_code": 1, "msg": "campaign_mode_mismatch", "items": []}
                if current is None:
                    return {"error_code": 1, "msg": "campaign_locked", "items": []}
            if current is None:
                return {"error_code": 1, "msg": "campaign_locked", "items": []}
            # NewMapDetailWindow blocks Super entry when its server-sourced
            # remaining ``dailyLimit`` is exhausted.  Mirror that UI guard at
            # the authority boundary so direct/modified clients cannot stage a
            # battle after the daily allowance reaches zero.
            if campaign_type == SUPER_CAMPAIGN_TYPE and self._int(current.get("daily_limit"), 0) <= 0:
                return {"error_code": 1, "msg": "campaign_daily_limit_exhausted", "items": []}
            # Client MapDetailWindow performs this same full-cost entry check.
            # Actual settlement waits for MID114 so defeats can use defeat_cost.
            temporal = getattr(self.settlement, "temporal", None) if self.settlement is not None else None
            if temporal is not None:
                try:
                    temporal.preview("energy", "DEBIT", self._campaign_entry_energy_cost(campaign_id))
                except Exception:
                    return {"error_code": 1, "msg": "energy_insufficient", "items": []}
        elif campaign_type == CHALLENGE_CAMPAIGN_TYPE:
            if not self.challenge_catalog.contains(campaign_id):
                return {"error_code": 1, "msg": "challenge_campaign_unknown", "items": []}
            if current is None:
                return {"error_code": 1, "msg": "campaign_locked", "items": []}
            temporal = getattr(self.settlement, "temporal", None) if self.settlement is not None else None
            if temporal is not None:
                try:
                    temporal.preview("energy", "DEBIT", self._campaign_entry_energy_cost(campaign_id))
                except Exception:
                    return {"error_code": 1, "msg": "energy_insufficient", "items": []}

        first_clear_candidate = current is not None and self._int(current.get("star"), 0) <= 0
        if campaign_type == CHALLENGE_CAMPAIGN_TYPE:
            # Pass120 frozen policy: Challenge first-clear pools are deterministic.
            # ``increase_rate`` is an exact multiple of 10000 for all recovered
            # rows; no RandomOutcomeService or generic Campaign drop planner is used.
            staged_items = [
                {"item_id": int(award["item_id"]), "item_num": int(award["increase_rate"]) // 10000}
                for award in self.challenge_catalog.awards(campaign_id)
            ] if first_clear_candidate else []
            drop_plan_persisted = {
                "schema_version": 1,
                "policy_id": "challenge_deterministic_first_clear",
                "campaign_id": campaign_id,
                "canonical_awards": json.loads(json.dumps(staged_items)),
            }
            reward_plan = {
                "mana_gain": 0,
                "star_gift": 0,
                "partner_exp": 0,
                "player_exp_gain": 0,
            }
        else:
            if self.drop_planner is None:
                raise RuntimeError("Campaign MID113 requires Pass40.1 CampaignDropPlanner")
            drop_plan = self.drop_planner.plan(
                campaign_id=campaign_id,
                wire_campaign_type=campaign_type,
                first_clear=first_clear_candidate,
            )
            staged_items = drop_plan.battle_items()
            drop_plan_persisted = drop_plan.persisted()
            reward_plan = self._campaign_reward_plan(campaign_id) if campaign_type in (1, 2) else {
                "mana_gain": 0,
                "star_gift": 0,
                "partner_exp": 0,
                "player_exp_gain": 0,
            }
        awakening_overlay: dict[str, Any] = {}
        awakening_objective = None
        if campaign_type in (1, 2):
            resolution = self._resolve_awakening_campaign_overlay(
                campaign_id=campaign_id, campaign_type=campaign_type
            )
            if resolution is not None and self.awakening_campaign_overlay is not None:
                overlay_plan = self.awakening_campaign_overlay.plan(resolution)
                awakening_overlay = overlay_plan.persisted()
                staged_items.extend(overlay_plan.battle_items())
            awakening_objective = self._freeze_awakening_campaign_objective(
                request=req, campaign_id=campaign_id, campaign_type=campaign_type
            )

        stage_response = {
            "battle_id": 1,
            "report": {},
            "seed": 1,
            "enemy_info": {},
            "items": copy.deepcopy(staged_items),
        }
        self.player.active_campaign_battle = {
            "schema_version": 2,
            "campaign_id": campaign_id,
            "campaign_type": campaign_type,
            "formation_snapshot": str(req.get("formation") or ""),
            "started_at": self.player.now(),
            "status": "STAGED",
            # ``items`` remains the exact battle-visible MID113 occurrence
            # projection. ``drop_plan.canonical_awards`` is the frozen aggregate
            # committed by MID114; the planner is never invoked at result time.
            "items": copy.deepcopy(staged_items),
            "drop_plan": copy.deepcopy(drop_plan_persisted),
            "awakening_overlay": copy.deepcopy(awakening_overlay),
            "awakening_objective": copy.deepcopy(awakening_objective),
            "reward_plan": copy.deepcopy(reward_plan),
            "stage_response": copy.deepcopy(stage_response),
        }
        self._save()
        # SelectTeamWindow consumes ``items`` before building the local battle;
        # the same staged rows are committed to Backpack only after MID114 wins.
        # Scalar economy/Hero EXP rewards stay server-side until the result.
        return stage_response

    def commit_fight_result(self, req: dict[str, Any]) -> dict[str, Any]:
        """MID114: consume the current server-owned Campaign battle session once."""
        self.normalize()
        campaign_type = self._int(req.get("campaign_type"), 1)
        campaign_id = self._int(req.get("campaign_id"), 0)
        source_campaign_family = campaign_type in (1, 2, CHALLENGE_CAMPAIGN_TYPE)

        if source_campaign_family:
            active = self._active_campaign_session()
            status = self._campaign_session_status(active)

            if self._active_campaign_session_matches(
                req, statuses=("SETTLED_WIN", "SETTLED_LOSS")
            ):
                return self._render_terminal_campaign_response(active, error_code=30005)

            if not self._active_campaign_session_matches(req, statuses=("STAGED",)):
                return self._campaign_terminal_drain("campaign_battle_not_active")

            # Source membership/unlock is checked again at settlement so stale or
            # hand-edited sessions cannot mint progression.
            if campaign_type in (1, 2):
                if campaign_id not in self._source_mode_set(campaign_type):
                    return self._campaign_terminal_drain("campaign_mode_mismatch")
                current = self._find_row(campaign_id, campaign_type)
                if current is None:
                    return self._campaign_terminal_drain("campaign_locked")
            else:
                if not self.challenge_catalog.contains(campaign_id):
                    return self._campaign_terminal_drain("challenge_campaign_unknown")
                current = self._find_challenge_row(campaign_id)
                if current is None:
                    return self._campaign_terminal_drain("campaign_locked")

            star = max(0, min(3, self._int(req.get("star"), 0)))
            if campaign_type == 2 and star > 0 and self._int(current.get("daily_limit"), 0) <= 0:
                return self._campaign_session_reject("campaign_daily_limit_exhausted")
            if self.uow is None:
                return self._campaign_session_reject("campaign_battle_uow_required")

            context = OperationContext(
                actor_player_id=str(self.player.player_id),
                protocol_mid=114,
                domain="campaign",
                operation_name="commit_fight_result",
                idempotency_key=f"session:{campaign_type}:{campaign_id}",
            )
            with self.uow.transaction(context):
                active = self._active_campaign_session()
                if self._active_campaign_session_matches(
                    req, statuses=("SETTLED_WIN", "SETTLED_LOSS")
                ):
                    return self._render_terminal_campaign_response(active, error_code=30005)
                if not self._active_campaign_session_matches(req, statuses=("STAGED",)):
                    return self._campaign_terminal_drain("campaign_battle_not_active")
                return self._commit_fight_result_mutation(req)

        # Deferred non-Campaign families keep the legacy transaction wrapper.
        if self.uow is None:
            return self._commit_fight_result_mutation(req)
        context = OperationContext(
            actor_player_id=str(self.player.player_id),
            protocol_mid=114,
            domain="campaign",
            operation_name="commit_fight_result",
            idempotency_key=f"result:{campaign_id}:{self._int(req.get('star'), 0)}",
        )
        with self.uow.transaction(context):
            return self._commit_fight_result_mutation(req)

    def _commit_fight_result_mutation(
        self,
        req: dict[str, Any],
    ) -> dict[str, Any]:
        self.normalize()

        cid = self._int(req.get("campaign_id"), 0)
        star = max(0, min(3, self._int(req.get("star"), 0)))
        campaign_type = self._int(req.get("campaign_type"), 1)
        current = self._find_row(cid, campaign_type)
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
            # Normal/Super/Challenge require an actually unlocked source row; an
            # arbitrary MID114 must never manufacture topology or reward state.
            if campaign_type in (1, 2, CHALLENGE_CAMPAIGN_TYPE):
                return self._campaign_terminal_drain("campaign_not_unlocked")
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
        if campaign_type == CHALLENGE_CAMPAIGN_TYPE:
            # Raw source topology is authoritative. Pipe-separated Challenge
            # branches must never pass through campaign_meta.next_campaign_id.
            if star > 0:
                before_ids = {self._int(row.get("campaign_id"), 0) for row in self._challenge_rows()}
                projected, projected_added, _ = self.challenge_projection.project(
                    self._challenge_rows(), gate_open=self._challenge_unlock_eligible()
                )
                self.player.world_map["challenge"] = projected
                current = self._find_challenge_row(cid) or current
                touched = [current]
                for opened_id in projected_added:
                    if opened_id in before_ids:
                        continue
                    opened = self._find_challenge_row(opened_id)
                    if opened is not None:
                        touched.append(opened)
        elif campaign_type == SUPER_CAMPAIGN_TYPE:
            if star > 0:
                # Pass128: visibility is sequential source progression.  The raw
                # next Super row is exposed immediately; its related Normal clear
                # remains an independent MID113/MID117 authorization prerequisite.
                nxt, added = self.super_projection.materialize_next(cid)
                if added and nxt is not None:
                    # BattleCreate treats a different returned campaign with star=0
                    # as a newly opened node. Replays never synthesize it again.
                    touched.append(nxt)
        else:
            mode_rows = self._mode_rows(campaign_type) if campaign_type == 1 else self._normal_rows()
            next_id = self._next_mode_campaign(cid, campaign_type) if campaign_type == 1 else self._int(meta.get("next_campaign_id"), 0)
            if star > 0 and next_id > 0 and self.meta(next_id) is not None:
                nxt = self._find_row(next_id, campaign_type) if campaign_type == 1 else self._find_row(next_id)
                if nxt is None:
                    source_daily = self._int((self.ownership_meta(next_id) or {}).get("daily_limit"), 0)
                    nxt = self._campaign_row(next_id, 0)
                    nxt["daily_limit"] = max(0, source_daily)
                    mode_rows.append(nxt)
                    touched.append(nxt)

        chapter_info = dict(self.player.world_map.get("chapter_info") or {})
        normal_rows = self._mode_rows(1)
        normal_frontier = self._frontier_campaign(normal_rows) or self._mode_frontier(1) or cid
        normal_meta = self.meta(normal_frontier) or meta
        normal_chapter = self._int(normal_meta.get("chapter"), 1) or 1
        chapter_info.update({
            "normal_chapter_id": normal_chapter,
            "normal_campaign_id": normal_frontier,
            "normal_stars": self._chapter_star_sum(normal_rows, normal_chapter),
            "normal_bonus_id": self._int(chapter_info.get("normal_bonus_id"), 0),
            "super_bonus_id": self._int(chapter_info.get("super_bonus_id"), 0),
        })
        self.player.world_map["chapter_info"] = chapter_info
        # Super cursors are a reached/materialized frontier projection, not a
        # battle-authorization proof.  Function31 controls whether that frontier
        # is exposed at all.
        self.super_projection.recompute_cursors(function_open=self._super_function_open())
        chapter_info = dict(self.player.world_map.get("chapter_info") or {})

        # Challenge is a raw branching graph. Re-project after any Normal or
        # Challenge clear so the seven-root gate and every source child are
        # materialized in the same committed response/state transition.
        projected_challenge, projected_added, projected_changed = self.challenge_projection.project(
            self.player.world_map.get("challenge"), gate_open=self._challenge_unlock_eligible()
        )
        if projected_changed:
            self.player.world_map["challenge"] = projected_challenge
        if campaign_type != CHALLENGE_CAMPAIGN_TYPE:
            for opened_id in projected_added:
                opened = self._find_challenge_row(opened_id)
                if opened is not None:
                    touched.append(opened)

        # Pass36.1 response-channel split:
        # - committed_drop_items are the pending MID113 DropPlan rows whose
        #   canonical Inventory mutation is committed by RewardTransactionService;
        # - result_only_items belong exclusively to MID114's independent
        #   result-award wire channel. No distinct result-only item award is
        #   source-proven for the currently mapped early Campaign slice, so the
        #   shape-preserving wire value remains an empty list.
        committed_drop_items: list[dict[str, int]] = []
        awakening_drop_items = self._session_awakening_overlay_awards(pending) if has_pending else []
        result_only_items: list[dict[str, int]] = []
        economy_projection: dict[str, int] = {}
        if has_pending and campaign_type in (1, 2, CHALLENGE_CAMPAIGN_TYPE):
            economy_projection.update(self._settle_campaign_energy(cid, star))
        hero_exps: list[dict[str, int]] = []
        story_mission_delta: list[dict[str, int]] = []
        tutorial_new_funcs: list[int] = []
        star_crystal = 0

        # v0.8.2 commits source-certain rewards only when there is a matching
        # MID113 session. This prevents an arbitrary/retried MID114 from minting
        # Mana/EXP without a battle. General repeat item RNG remains deferred.
        if star > 0 and has_pending:
            # Base MID113 source drops remain first-clear-only.  Stage-D
            # Awakening/Blood acquisition occurrences are a separate frozen
            # overlay and must settle on every successful farming battle.
            if not was_cleared:
                committed_drop_items.extend(staged_items if isinstance(staged_items, list) else [])
            committed_drop_items.extend(awakening_drop_items)

        if star > 0 and has_pending and campaign_type in (1, 2):
            star_crystal = self._session_reward_value(pending, "star_gift") if first_three_star else 0
            if self.rewards is None or self.catalog is None:
                raise RuntimeError("Campaign reward commit requires Pass32.6 reward/catalog services")
            economy_grants: list[EconomyGrant] = []
            for field, raw in (
                ("mana", self._session_reward_value(pending, "mana_gain")),
                ("crystal", star_crystal),
                ("player_exp", self._session_reward_value(pending, "player_exp_gain")),
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
                self._session_formation(pending),
                self._session_reward_value(pending, "partner_exp"),
                persist=False,
            )
        elif committed_drop_items:
            # Preserve the pre-Pass32.6 non-normal behavior: deterministic
            # first-clear items can still persist without scalar economy grants.
            if self.rewards is None or self.catalog is None:
                raise RuntimeError("Campaign item commit requires Pass32.6 reward/catalog services")
            reward_result = self.rewards.apply(
                RewardPlan(
                    origin=RewardOrigin(
                        "campaign", "challenge_first_clear_items", protocol_mid=114,
                        source_table="data/tables/campaign_dropbox.lua", source_id=cid,
                        field_path="init_dropbox_id.increase_rate",
                    ) if campaign_type == CHALLENGE_CAMPAIGN_TYPE else RewardOrigin("campaign", "first_clear_items", protocol_mid=114),
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
        awakening_objective_result: dict[str, Any] = {}
        if (
            star > 0 and has_pending and self.awakening_missions is not None
            and self.awakening_campaign_objectives is not None
        ):
            active_awake = self.awakening_missions.active_snapshot(AwakeningMissionService.HERO)
            source_row = self.awakening_missions.mission_source_row(
                (active_awake or {}).get("mission_id", 0), AwakeningMissionService.HERO
            )
            decision = self.awakening_campaign_objectives.validate(
                request=req, session=pending, active=active_awake, mission_row=source_row
            )
            awakening_objective_result = {
                "allowed": bool(decision.allowed),
                "reason": str(decision.reason),
                "evidence_class": str(decision.evidence_class),
            }
            if decision.allowed and active_awake is not None:
                awake_delta = self.awakening_missions.complete_campaign_objective(
                    mission_id=active_awake.get("mission_id", 0),
                    generation=active_awake.get("generation", 0),
                )

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
            terminal_projection = self._terminal_projection_descriptor(response)
            terminal_static = self._terminal_static_response(response)
            self.player.active_campaign_battle = {
                "schema_version": 2,
                "campaign_id": cid,
                "campaign_type": campaign_type,
                "formation_snapshot": self._session_formation(pending),
                "started_at": self._int(pending.get("started_at"), 0),
                "status": "SETTLED_WIN" if star > 0 else "SETTLED_LOSS",
                "star": star,
                "items": copy.deepcopy(pending.get("items") or []),
                "drop_plan": copy.deepcopy(pending.get("drop_plan") or {}),
                "awakening_overlay": copy.deepcopy(pending.get("awakening_overlay") or {}),
                "awakening_objective": copy.deepcopy(pending.get("awakening_objective")),
                "awakening_objective_result": copy.deepcopy(awakening_objective_result),
                "reward_plan": copy.deepcopy(pending.get("reward_plan") or {
                    "mana_gain": self._session_reward_value(pending, "mana_gain"),
                    "star_gift": self._session_reward_value(pending, "star_gift"),
                    "partner_exp": self._session_reward_value(pending, "partner_exp"),
                    "player_exp_gain": self._session_reward_value(pending, "player_exp_gain"),
                }),
                "stage_response": self._stage_response_from_session(pending),
                "terminal_static_response": terminal_static,
                "terminal_projection": terminal_projection,
                "settled_at": self.player.now(),
            }
        elif campaign_type not in (1, 2, CHALLENGE_CAMPAIGN_TYPE):
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

    @staticmethod
    def _blocked_mid117(
        message: str,
        *,
        sweep_num: int = 1,
        campaign: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        # SweepWindow's Pass114 OTA guard suppresses ordinary-MID117 local
        # Backpack/Ticket mutation when this application error is present.
        count = max(1, min(100, int(sweep_num or 1)))
        response: dict[str, Any] = {
            "error_code": 1,
            "msg": str(message),
            "items": [[] for _ in range(count)],
            "economys": [{"exp": 0, "mana": 0} for _ in range(count)],
            "additional": [],
        }
        if isinstance(campaign, dict):
            response["campaign"] = dict(campaign)
        return response

    def _mid117_identity_from_request(
        self, req: dict[str, Any]
    ) -> Mid117OperationIdentity | None:
        return Mid117OperationIdentity.from_request(req)

    def _mid117_replay(
        self, identity: Mid117OperationIdentity
    ) -> dict[str, Any] | None:
        if self.uow is None:
            raise RuntimeError("MID117 durable replay requires PlayerUnitOfWork")
        receipt = self.uow.get_receipt(MID117_RECEIPT_DOMAIN, identity.operation_id)
        if receipt is None:
            return None
        if str(receipt.get("status") or "") != "COMMITTED":
            raise Mid117OperationIdentityError("MID117 receipt is not committed")
        if str(receipt.get("mode") or "") != MID117_RECEIPT_MODE:
            raise Mid117OperationIdentityError("MID117 receipt mode mismatch")
        old_fp = str(receipt.get("request_fingerprint") or "")
        if old_fp != identity.fingerprint:
            raise Mid117OperationIdentityError("MID117 receipt fingerprint conflict")
        payload = validate_mid117_replay_payload(
            receipt.get("replay_payload"), identity=identity
        )
        response = copy.deepcopy(payload["static_response"])
        projection = payload["projection"]
        economy: dict[str, int] = {}
        ledger = getattr(self.economy, "ledger", None)
        for key in projection.get("economy_keys", []):
            # Refresh from the canonical owner rather than replaying a stale
            # cumulative value. Scalar-ledger resources (Mana/Crystal, etc.)
            # are queried through EconomyLedger; PlayerState-owned progression
            # and temporal fields (EXP/level/Energy) come from PlayerState.
            projected = False
            if ledger is not None:
                try:
                    descriptor = ledger.registry.get(key)
                    if descriptor is not None and descriptor.owner_service == "EconomyLedger":
                        economy[key] = max(0, int(ledger.balance(key)))
                        projected = True
                except Exception:
                    pass
            if not projected and hasattr(self.player, key):
                economy[key] = max(0, self._int(getattr(self.player, key), 0))
        if economy:
            response["economy_"] = economy
        if projection.get("campaign") is True:
            row = self._find_row(identity.campaign_id, identity.campaign_type)
            if row is None:
                row = self._find_row(identity.campaign_id)
            if row is not None:
                response["campaign"] = dict(row)
        return response

    def _mid117_context(self, identity: Mid117OperationIdentity) -> OperationContext:
        return OperationContext(
            actor_player_id=str(self.player.player_id),
            domain="campaign",
            operation_name="sweep_campaign",
            protocol_mid=117,
            idempotency_key=identity.operation_id,
            idempotency_mode=MID117_RECEIPT_MODE,
            request_fingerprint=identity.fingerprint,
        )

    def _stage_mid117_receipt(
        self,
        *,
        identity: Mid117OperationIdentity,
        response: dict[str, Any],
        source_pool_id: int,
        repeat_policy_id: str,
        repeat_policy_version: int,
        awakening_overlay_audit: dict[str, Any] | None = None,
    ) -> None:
        if self.uow is None:
            raise RuntimeError("MID117 receipt staging requires PlayerUnitOfWork")
        self.uow.stage_receipt(
            domain=MID117_RECEIPT_DOMAIN,
            operation="sweep_campaign",
            key=identity.operation_id,
            mode=MID117_RECEIPT_MODE,
            request_fingerprint=identity.fingerprint,
            replay_payload=build_mid117_replay_payload(
                identity=identity,
                response=response,
                source_pool_id=source_pool_id,
                source_catalog_sha256=self._campaign_drop_source_sha256,
                repeat_policy_id=repeat_policy_id,
                repeat_policy_version=repeat_policy_version,
                awakening_overlay_audit=awakening_overlay_audit,
            ),
            retention_policy=MID117_RETENTION_POLICY,
        )

    def _validate_mid117_super_source_membership(
        self, identity: Mid117OperationIdentity
    ) -> dict[str, Any] | None:
        """Fail closed when a Super MID117 campaign id is not source-owned.

        Ordinary MID117 is only patched here for the Pass121 Super-attempt plane.
        Normal Campaign keeps its existing behavior. Mutable unlock/row validation
        stays inside the transaction after normalization.
        """
        if identity.campaign_type != SUPER_CAMPAIGN_TYPE:
            return None
        if not self.super_catalog.contains(identity.campaign_id):
            raise ValueError("campaign_super_source_membership_invalid")
        # Unlock/state validation stays inside the PlayerUnitOfWork after
        # normalize(), so this pre-transaction source gate performs no mutation.
        return None

    def _preflight_mid117_super_attempts(
        self,
        *,
        campaign_id: int,
        campaign_type: int,
        sweep_num: int,
    ) -> tuple[dict[str, Any] | None, int | None]:
        """Return the exact Super row and remaining attempts after this batch.

        The caller runs this inside the existing MID117 PlayerUnitOfWork after
        receipt replay and request/VIP validation, but before cost validation or
        RandomOutcomeService draws. No state is mutated here.
        """
        if int(campaign_type) != SUPER_CAMPAIGN_TYPE:
            return None, None
        if not self.super_catalog.contains(campaign_id):
            raise ValueError("campaign_super_source_membership_invalid")
        row = self._find_mode_row(int(campaign_id), SUPER_CAMPAIGN_TYPE)
        if row is None:
            raise ValueError("campaign_super_not_unlocked")
        remaining = max(0, self._int(row.get("daily_limit"), 0))
        requested = int(sweep_num)
        if requested <= 0 or requested > remaining:
            raise ValueError("campaign_daily_limit_insufficient")
        return row, remaining - requested

    def _apply_mid117_super_attempts(
        self, row: dict[str, Any] | None, remaining_after: int | None
    ) -> None:
        """Apply the already-preflighted Super attempt delta in the active UoW."""
        if row is None or remaining_after is None:
            return
        if self.uow is None or not self.uow.active:
            raise RuntimeError("Super MID117 attempt mutation requires PlayerUnitOfWork")
        row["daily_limit"] = max(0, int(remaining_after))
        self.uow.mark_changed()

    def _preflight_mid117_repeat_pool(self, campaign_id: int) -> int:
        if self.drop_planner is None:
            raise RuntimeError("campaign_repeat_planner_unavailable")
        source_catalog = getattr(self.drop_planner, "source_catalog", None)
        if source_catalog is None:
            raise RuntimeError("campaign_repeat_source_catalog_unavailable")
        pool_id, rows = source_catalog.pool_for(campaign_id, "repeat")
        pool_id = self._int(pool_id, -1)
        if pool_id < 0:
            raise CampaignDropSourceCorruptionError("repeat pool id must be nonnegative")
        if pool_id > 0 and not rows:
            raise CampaignRepeatPoolUnavailableError(
                f"campaign_repeat_pool_unavailable:{pool_id}"
            )
        return pool_id

    def sweep(self, req: dict[str, Any]) -> dict[str, Any]:
        # Historical repository-only tests construct WorldRepository without the
        # request-scoped settlement graph. Preserve that non-runtime seam. Live
        # RequestServices requires source-native MID117 UUID identity.
        if self.uow is None or self.settlement is None:
            return self._sweep_compatibility_read_model(req)

        count = max(1, min(100, self._int(req.get("sweep_num"), 1)))
        if self._int(req.get("campaign_type"), 1) == CHALLENGE_CAMPAIGN_TYPE:
            return self._blocked_mid117("challenge_sweep_not_supported", sweep_num=count)
        try:
            identity = self._mid117_identity_from_request(req)
            if identity is None:
                return self._blocked_mid117(
                    "mid117_operation_identity_required", sweep_num=count
                )
            replay = self._mid117_replay(identity)
            if replay is not None:
                return replay
        except (Mid117OperationIdentityError, RuntimeError, ValueError) as exc:
            return self._blocked_mid117(
                f"mid117_operation_identity_invalid:{exc}", sweep_num=count
            )

        # Pass121 source-mode gate: Super requests must name a source-owned
        # campaign id before repeat-pool lookup. Mutable unlock/row validation
        # follows inside the UoW after normalization.
        try:
            self._validate_mid117_super_source_membership(identity)
        except (RuntimeError, ValueError) as exc:
            row = self._find_mode_row(identity.campaign_id, 2)
            return self._blocked_mid117(str(exc), sweep_num=count, campaign=row)

        # Source availability is checked before opening the transaction, spending,
        # or consuming entropy. A positive-but-empty pool is one of the 24 proven
        # effective-source gaps and must never be substituted.
        try:
            self._preflight_mid117_repeat_pool(identity.campaign_id)
        except CampaignRepeatPoolUnavailableError:
            row = self._find_row(identity.campaign_id, identity.campaign_type)
            return self._blocked_mid117(
                "campaign_repeat_pool_unavailable", sweep_num=count, campaign=row
            )
        except (CampaignDropSourceCorruptionError, RuntimeError, ValueError) as exc:
            return self._blocked_mid117(
                f"campaign_repeat_source_invalid:{exc}", sweep_num=count
            )

        context = self._mid117_context(identity)
        try:
            with self.uow.transaction(context):
                replay = self._mid117_replay(identity)
                if replay is not None:
                    return replay
                return self._sweep_mutation(req, identity=identity)
        except ReceiptConflict:
            return self._blocked_mid117(
                "mid117_receipt_conflict", sweep_num=count
            )
        except (
            CampaignDropSourceCorruptionError,
            CampaignRepeatPoolUnavailableError,
            Mid117OperationIdentityError,
            RuntimeError,
            ValueError,
        ) as exc:
            return self._blocked_mid117(
                f"campaign_sweep_rejected:{exc}", sweep_num=count
            )

    def _sweep_compatibility_read_model(self, req: dict[str, Any]) -> dict[str, Any]:
        self.normalize()
        cid = self._int(req.get("campaign_id"), 0)
        count = max(1, min(100, self._int(req.get("sweep_num"), 1)))
        if self._int(req.get("campaign_type"), 1) == CHALLENGE_CAMPAIGN_TYPE:
            return self._blocked_mid117("challenge_sweep_not_supported", sweep_num=count)
        if count > 1 and self.vip_privileges is not None and not self.vip_privileges.campaign_multi_sweep_enabled():
            return {"error_code": 1, "msg": "campaign_multi_sweep_privilege_required"}
        row = self._find_row(cid) or self._campaign_row(cid, 0)
        return {
            "items": [[] for _ in range(count)],
            "economys": [{"exp": 0, "mana": 0} for _ in range(count)],
            "additional": [],
            "campaign": row,
        }

    @staticmethod
    def _aggregate_sweep_awards(
        item_rows: list[list[dict[str, int]]],
    ) -> list[dict[str, int]]:
        order: list[int] = []
        totals: dict[int, int] = {}
        for sweep_rows in item_rows:
            for award in sweep_rows:
                item_id = int(award.get("item_id") or 0)
                item_num = int(award.get("item_num") or 0)
                if item_id <= 0 or item_num <= 0:
                    continue
                if item_id not in totals:
                    order.append(item_id)
                    totals[item_id] = 0
                totals[item_id] += item_num
        return [
            {"item_id": item_id, "item_num": totals[item_id]}
            for item_id in order
            if totals[item_id] > 0
        ]

    def _sweep_mutation(
        self,
        req: dict[str, Any],
        *,
        identity: Mid117OperationIdentity,
    ) -> dict[str, Any]:
        self.normalize()
        cid = self._int(req.get("campaign_id"), 0)
        count = max(1, min(100, self._int(req.get("sweep_num"), 1)))
        sweep_type = self._int(req.get("sweep_type"), 0)
        campaign_type = self._int(req.get("campaign_type"), 0)
        if (
            cid != identity.campaign_id
            or count != identity.sweep_num
            or sweep_type != identity.sweep_type
            or campaign_type != identity.campaign_type
            or self._int(req.get("awake_mission"), 0) != identity.awake_mission
        ):
            raise Mid117OperationIdentityError("MID117 normalized request tuple drift")
        # src_64 enums.lua: ITEM_SWEEP=1, CRYSTAL_SWEEP=2.
        if sweep_type not in (1, 2):
            return self._blocked_mid117(
                "campaign_sweep_type_invalid", sweep_num=count
            )
        if campaign_type == SUPER_CAMPAIGN_TYPE and self.super_access_policy is not None:
            # Receipt replay and static source identity have already run.  The
            # shared bouncer now executes before attempts, cost validation and
            # RandomOutcomeService draws, preserving Pass121 exactly-once order.
            decision = self.super_access_policy.evaluate(cid, campaign_type)
            if not decision.allowed:
                return self._blocked_mid117(decision.reason, sweep_num=count)
            row = self._find_mode_row(cid, SUPER_CAMPAIGN_TYPE)
            if row is None:
                return self._blocked_mid117(
                    "campaign_super_not_unlocked", sweep_num=count
                )
        elif campaign_type == SUPER_CAMPAIGN_TYPE:
            row = self._find_mode_row(cid, SUPER_CAMPAIGN_TYPE)
            if row is None:
                return self._blocked_mid117(
                    "campaign_super_not_unlocked", sweep_num=count
                )
        else:
            row = self._find_row(cid, campaign_type) or self._find_row(cid) or self._campaign_row(cid, 0)
        if count > 1 and self.vip_privileges is not None and not self.vip_privileges.campaign_multi_sweep_enabled():
            return self._blocked_mid117(
                "campaign_multi_sweep_privilege_required", sweep_num=count
            )

        # Mutable Super attempts share the same persisted world-map row as manual
        # battle settlement and MID116/Daily Reset. Preflight before any cost
        # validation or Campaign entropy; apply only after the reward/cost plan.
        try:
            super_row, super_remaining_after = self._preflight_mid117_super_attempts(
                campaign_id=cid, campaign_type=campaign_type, sweep_num=count
            )
        except ValueError as exc:
            return self._blocked_mid117(str(exc), sweep_num=count, campaign=row)

        reward_meta = self._campaign_rewards.get(str(cid)) or {}
        source_sweep = reward_meta.get("sweep_rewards") or []

        deterministic_per_sweep: list[dict[str, int]] = []
        if self._int(row.get("star"), 0) > 0:
            for award in source_sweep:
                if not isinstance(award, dict):
                    continue
                item_id = self._int(award.get("item_id"), 0)
                item_num = self._int(award.get("item_num"), 0)
                if item_id > 0 and item_num > 0:
                    deterministic_per_sweep.append(
                        {"item_id": item_id, "item_num": item_num}
                    )

        energy_cost = self._campaign_entry_energy_cost(cid)
        if energy_cost <= 0:
            return self._blocked_mid117(
                "campaign_energy_cost_unavailable", sweep_num=count, campaign=row
            )
        mana_gain = self._campaign_entry_mana_gain(cid)
        if mana_gain <= 0:
            return self._blocked_mid117(
                "campaign_mana_gain_unavailable", sweep_num=count, campaign=row
            )
        if self.rewards is None:
            raise RuntimeError("Campaign sweep economy settlement requires RewardTransactionService")

        # Pass131 source-bounded compatibility policy. SweepWindow displays the
        # raw energy_cost as each per-run EXP row, but mirrors a low-level 1x
        # account-EXP curve until its pre-request simulation crosses above 10;
        # later rows use SelfPlayer:getExpMulti() (3 in effective src_64).
        economy_plan = CampaignSweepEconomyPolicy.plan(
            base_exp=energy_cost,
            mana_gain=mana_gain,
            sweep_num=count,
            start_level=self.player.lev,
            start_exp=self.player.exp,
            normal_exp_multiplier=self.economy.player_exp_multiplier(),
            total_exp_threshold=lambda level: self.economy.player_level_meta(level).get("total_exp", 0),
        )
        sweep_reward_plan = RewardPlan(
            origin=RewardOrigin(
                "campaign",
                "sweep_campaign_economy",
                protocol_mid=117,
                source_table="data/tables/campaign.lua",
                source_id=cid,
                field_path="energy_cost+mana_gain",
            ),
            economy=(
                EconomyGrant("mana", economy_plan.total_mana_gain),
                EconomyGrant("player_exp", economy_plan.total_player_exp_gain),
            ),
        )
        # Reward-plan validation is deterministic and must happen before any
        # Campaign entropy is consumed.
        self.rewards.validate(sweep_reward_plan)

        cost_operations = [TemporalTransition("energy", "DEBIT", energy_cost * count)]
        if sweep_type == 1:
            cost_operations.append(StackMutation(50001013, "DEBIT", count))
        else:
            cost_operations.append(ResourceMutation("crystal", "DEBIT", count))

        # Frozen RNG lifecycle: all deterministic eligibility/cost gates are
        # validated before entropy is consumed. This plan is validation-only;
        # the later full plan performs the one actual atomic mutation.
        cost_preflight = MutationPlan(
            schema_version=1,
            plan_id=f"campaign-sweep-preflight:{cid}:{identity.operation_id}",
            origin=MutationOrigin(
                domain="campaign", operation="sweep_campaign_preflight", protocol_mid=117,
                source_table="data/tables/campaign.lua", source_id=cid, field_path="energy_cost",
            ),
            actor=ActorRef(
                player_id=str(self.player.player_id),
                account_uid=str(getattr(self.player, "account_uid", "") or "") or None,
            ),
            expected_state_version=self.uow.current_state_version,
            idempotency=IdempotencySpec(
                mode=MID117_RECEIPT_MODE, key=identity.operation_id
            ),
            preconditions=(),
            operations=tuple(cost_operations),
            semantic_events=(),
            metadata={"pass": "121.0", "validation_only": True},
        )
        try:
            self.settlement.validate(cost_preflight)
        except (MutationSettlementError, StackInventoryError, InsufficientScalarBalance) as exc:
            return self._blocked_mid117(str(exc), sweep_num=count, campaign=row)

        awakening_resolution = self._resolve_awakening_campaign_overlay(
            campaign_id=cid,
            campaign_type=campaign_type,
            ordinary_wire_mission=identity.awake_mission,
        )

        if self.drop_planner is None:
            raise RuntimeError("campaign_repeat_planner_unavailable")
        repeat_plans = [
            self.drop_planner.plan_repeat_sweep(
                campaign_id=cid, wire_campaign_type=campaign_type
            )
            for _ in range(count)
        ]
        if any(plan.status != "planned" for plan in repeat_plans):
            raise RuntimeError("campaign_repeat_policy_unavailable")
        source_pool_ids = {int(plan.source_pool_id) for plan in repeat_plans}
        policy_ids = {str(plan.policy_id) for plan in repeat_plans}
        policy_versions = {int(plan.policy_version) for plan in repeat_plans}
        if len(source_pool_ids) != 1 or len(policy_ids) != 1 or len(policy_versions) != 1:
            raise RuntimeError("campaign_repeat_plan_batch_drift")
        source_pool_id = next(iter(source_pool_ids))
        repeat_policy_id = next(iter(policy_ids))
        repeat_policy_version = next(iter(policy_versions))
        if (
            repeat_policy_id != CAMPAIGN_REPEAT_POLICY_ID
            or repeat_policy_version != CAMPAIGN_REPEAT_POLICY_VERSION
        ):
            raise RuntimeError("campaign_repeat_policy_identity_drift")

        awakening_plans = []
        if (
            awakening_resolution is not None
            and self.awakening_campaign_overlay is not None
            and awakening_resolution.resolved
        ):
            awakening_plans = [
                self.awakening_campaign_overlay.plan(awakening_resolution)
                for _ in range(count)
            ]

        item_rows: list[list[dict[str, int]]] = []
        for index, plan in enumerate(repeat_plans):
            rows = [dict(award) for award in deterministic_per_sweep]
            rows.extend(dict(award) for award in plan.canonical_awards)
            if awakening_plans:
                rows.extend(dict(award) for award in awakening_plans[index].canonical_awards)
            item_rows.append(rows)

        awakening_overlay_audit: dict[str, Any] | None = None
        if awakening_plans and awakening_resolution is not None:
            awakening_overlay_audit = awakening_resolution.audit()
            awakening_overlay_audit["sweeps"] = [
                {
                    "occurrences": [dict(row) for row in plan.occurrences],
                    "canonical_awards": [dict(row) for row in plan.canonical_awards],
                }
                for plan in awakening_plans
            ]

        operations = list(cost_operations)
        for award in self._aggregate_sweep_awards(item_rows):
            operations.append(
                StackMutation(award["item_id"], "CREDIT", award["item_num"])
            )

        plan = MutationPlan(
            schema_version=1,
            plan_id=f"campaign-sweep:{cid}:{identity.operation_id}",
            origin=MutationOrigin(
                domain="campaign", operation="sweep_campaign", protocol_mid=117,
                source_table="data/tables/campaign.lua+campaign_dropbox.lua", source_id=cid,
                field_path="energy_cost+sweep_reward+repeat_dropbox_id+awakening_dropbox",
            ),
            actor=ActorRef(
                player_id=str(self.player.player_id),
                account_uid=str(getattr(self.player, "account_uid", "") or "") or None,
            ),
            expected_state_version=self.uow.current_state_version,
            idempotency=IdempotencySpec(
                mode=MID117_RECEIPT_MODE, key=identity.operation_id
            ),
            preconditions=(),
            operations=tuple(operations),
            semantic_events=(),
            metadata={
                "pass": "131.0",
                "campaign_id": cid,
                "campaign_type": campaign_type,
                "sweep_num": count,
                "sweep_type": sweep_type,
                "raid_ticket_item_id": 50001013,
                "repeat_policy_id": repeat_policy_id,
                "repeat_policy_version": repeat_policy_version,
                "repeat_source_pool_id": source_pool_id,
                "sweep_economy_policy_id": economy_plan.policy_id,
                "sweep_economy_policy_version": economy_plan.policy_version,
                "awakening_campaign_overlay": copy.deepcopy(awakening_overlay_audit),
            },
        )
        try:
            self.settlement.apply(plan)
        except (MutationSettlementError, StackInventoryError, InsufficientScalarBalance) as exc:
            return self._blocked_mid117(
                str(exc), sweep_num=count, campaign=row
            )

        # Reuse the same typed owners as manual MID114: EconomyLedger owns Mana,
        # PlayerProgressionService owns cumulative EXP/level and its level-up
        # Energy/function side effects. The outer PlayerUnitOfWork is the atomic
        # boundary shared with costs, items, RNG-derived awards and receipts.
        reward_result = self.rewards.apply(sweep_reward_plan)

        # The Super attempt decrement is intentionally after canonical cost/reward
        # mutation but before response/receipt staging, all within the same UoW.
        # Any later receipt/commit failure restores the whole PlayerState snapshot.
        self._apply_mid117_super_attempts(super_row, super_remaining_after)

        economy_projection = dict(reward_result.economy)
        economy_projection["energy"] = max(0, self._int(self.player.energy, 0))
        economy_projection["exp"] = max(0, self._int(self.player.exp, 0))
        ledger = getattr(self.economy, "ledger", None)
        if ledger is not None:
            economy_projection["mana"] = max(0, self._int(ledger.balance("mana"), 0))
        else:
            economy_projection["mana"] = max(0, self._int(self.player.mana, 0))
        if sweep_type == 2:
            if ledger is not None:
                economy_projection["crystal"] = max(0, self._int(ledger.balance("crystal"), 0))
            else:
                economy_projection["crystal"] = max(0, self._int(self.player.crystal, 0))
        response: dict[str, Any] = {
            "items": item_rows,
            "economys": economy_plan.wire_economys(),
            "additional": [],
            "campaign": row,
            "economy_": economy_projection,
        }
        self._stage_mid117_receipt(
            identity=identity,
            response=response,
            source_pool_id=source_pool_id,
            repeat_policy_id=repeat_policy_id,
            repeat_policy_version=repeat_policy_version,
            awakening_overlay_audit=awakening_overlay_audit,
        )
        self.uow.mark_changed()
        return response

    def _save(self) -> None:
        if self._save_callback:
            self._save_callback()
