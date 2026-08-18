"""Canonical normal-Campaign progression and commit helpers.

The supplied client simulates normal Campaign combat locally.  The backend owns
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

from .economy_repository import EconomyRepository
from .hero_progression_repository import HeroProgressionRepository
from .inventory_repository import InventoryRepository
from .mission_repository import MissionRepository
from .player_state import PlayerState
from .reward_transaction_service import (
    EconomyGrant, InventoryGrant, RewardOrigin, RewardPlan, RewardTransactionService,
)
from .tutorial_milestone_repository import TutorialMilestoneRepository
from .unit_of_work import OperationContext, UnitOfWork


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
        catalog: GameDataCatalog | None = None,
        rewards: RewardTransactionService | None = None,
        tutorial: TutorialMilestoneRepository | None = None,
        uow: UnitOfWork | None = None,
    ) -> None:
        self.player = player
        self.data_dir = Path(data_dir)
        self._save_callback = save_callback
        self.inventory = inventory
        self.economy = economy or EconomyRepository(player, self.data_dir)
        self.hero_progression = hero_progression or HeroProgressionRepository(player, self.data_dir)
        self.missions = missions
        self.catalog = catalog
        self.rewards = rewards
        self.tutorial = tutorial
        self.uow = uow
        self._campaigns = self._load_campaign_meta()
        self._campaign_rewards = self._load_campaign_reward_meta()
        self._story_drop_campaigns, self._story_drop_partners = self._load_story_drop_meta()

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

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

    def _guaranteed_first_awards(self, campaign_id: int) -> list[dict[str, int]]:
        """Return the conservative source-derived first-clear award subset.

        campaign_dropbox.lua has no quantity column. A selected drop row maps to
        one item in MID114. Stage 4A.5 only enables rows whose increase_rate is
        exactly 10000; lower-rate rows are retained in metadata but are not
        rolled until their RNG semantics are verified.
        """
        meta = self._campaign_rewards.get(str(campaign_id)) or {}
        rows = meta.get("init_dropbox_rows") or []
        awards: list[dict[str, int]] = []
        for row in rows:
            if not isinstance(row, dict) or self._int(row.get("increase_rate"), 0) != 10000:
                continue
            item_id = self._int(row.get("item_id"), 0)
            if item_id > 0:
                awards.append({"item_id": item_id, "item_num": 1})
        return awards

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
        """Migrate old hard-coded map defaults into explicit JSON state."""
        changed = False
        if not isinstance(self.player.world_map, dict):
            self.player.world_map = {}
            changed = True
        wm = self.player.world_map
        normal = wm.get("normal")
        if not isinstance(normal, list) or not normal:
            # Accessible but unbeaten.  Stage 3 incorrectly seeded star=3,
            # which exposed Raid before the first real clear.
            normal = [self._campaign_row(100001, 0)]
            wm["normal"] = normal
            changed = True
        else:
            cleaned = []
            for row in normal:
                if not isinstance(row, dict):
                    continue
                cid = self._int(row.get("campaign_id"), 0)
                if cid <= 0:
                    continue
                cleaned.append({
                    "campaign_id": cid,
                    "star": max(0, min(3, self._int(row.get("star"), 0))),
                    "daily_limit": self._int(row.get("daily_limit"), 0),
                    "reset_count": self._int(row.get("reset_count"), 0),
                    "is_partner_drop": self._int(row.get("is_partner_drop"), 0),
                })
            if cleaned != normal:
                wm["normal"] = cleaned
                normal = cleaned
                changed = True
        for key, default in (("super", {}), ("challenge", {}), ("chapter_events", {})):
            if not isinstance(wm.get(key), type(default)):
                wm[key] = default
                changed = True
        chapter = wm.get("chapter_info")
        if not isinstance(chapter, dict):
            chapter = {}
            wm["chapter_info"] = chapter
            changed = True
        highest = self._frontier_campaign(normal) or 100001
        meta = self.meta(highest) or {}
        chapter_id = self._int(meta.get("chapter"), 1) or 1
        normalized_chapter = {
            **chapter,
            "normal_chapter_id": chapter_id,
            "normal_campaign_id": highest,
            "normal_stars": self._chapter_star_sum(normal, chapter_id),
            "normal_bonus_id": self._int(chapter.get("normal_bonus_id"), 0),
            "super_chapter_id": self._int(chapter.get("super_chapter_id"), 0),
            "super_campaign_id": self._int(chapter.get("super_campaign_id"), 0),
            "super_stars": self._int(chapter.get("super_stars"), 0),
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

    def _find_row(self, campaign_id: int) -> dict[str, Any] | None:
        for row in self._normal_rows():
            if self._int(row.get("campaign_id"), 0) == campaign_id:
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

    def _normal_campaign_reward_plan(self, campaign_id: int) -> dict[str, int]:
        """Source-certain v0.8.2 reward plan for ordinary normal Campaign.

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

    @staticmethod
    def _same_formation(left: Any, right: Any) -> bool:
        return str(left or "") == str(right or "")

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
        current = self._find_row(campaign_id)
        first_clear_candidate = current is not None and self._int(current.get("star"), 0) <= 0
        staged_items = self._guaranteed_first_awards(campaign_id) if first_clear_candidate else []
        reward_plan = self._normal_campaign_reward_plan(campaign_id) if campaign_type == 1 else {
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
            "items": staged_items,
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
        current = self._find_row(cid)
        previous_star = self._int(current.get("star"), 0) if current is not None else 0
        was_cleared = current is not None and previous_star > 0
        first_three_star = previous_star < 3 and star >= 3
        pending = self.player.active_campaign_battle if isinstance(self.player.active_campaign_battle, dict) else {}
        has_pending = (
            self._int(pending.get("committed"), 0) == 0
            and self._int(pending.get("campaign_id"), 0) == cid
            and self._int(pending.get("campaign_type"), 1) == campaign_type
            and self._same_formation(pending.get("formation"), req.get("formation"))
        )
        staged_items = pending.get("items") if has_pending else None

        if current is None:
            if self.meta(cid) is None:
                self.player.active_campaign_battle = {}
                self._save()
                return {"is_win": 1 if star > 0 else 0, "result": 1 if star > 0 else 0, "items": []}
            current = self._campaign_row(cid, 0)
            self._normal_rows().append(current)
        if star > 0:
            current["star"] = max(self._int(current.get("star"), 0), star)

        touched = [current]
        meta = self.meta(cid) or {}
        next_id = self._int(meta.get("next_campaign_id"), 0)
        if star > 0 and next_id > 0 and self.meta(next_id) is not None:
            nxt = self._find_row(next_id)
            if nxt is None:
                nxt = self._campaign_row(next_id, 0)
                self._normal_rows().append(nxt)
                # BattleCreate treats a *different* returned campaign with
                # star=0 as a newly opened node. Only return that row when it
                # was actually unlocked by this result; replaying an older
                # stage must not repeatedly trigger the unlock animation.
                touched.append(nxt)

        highest = self._frontier_campaign(self._normal_rows()) or cid
        highest_meta = self.meta(highest) or meta
        chapter_id = self._int(highest_meta.get("chapter"), 1) or 1
        chapter_info = dict(self.player.world_map.get("chapter_info") or {})
        chapter_info.update({
            "normal_chapter_id": chapter_id,
            "normal_campaign_id": highest,
            "normal_stars": self._chapter_star_sum(self._normal_rows(), chapter_id),
            "normal_bonus_id": self._int(chapter_info.get("normal_bonus_id"), 0),
            "super_chapter_id": self._int(chapter_info.get("super_chapter_id"), 0),
            "super_campaign_id": self._int(chapter_info.get("super_campaign_id"), 0),
            "super_stars": self._int(chapter_info.get("super_stars"), 0),
            "super_bonus_id": self._int(chapter_info.get("super_bonus_id"), 0),
        })
        self.player.world_map["chapter_info"] = chapter_info

        awarded_items: list[dict[str, int]] = []
        economy_projection: dict[str, int] = {}
        hero_exps: list[dict[str, int]] = []
        story_mission_delta: list[dict[str, int]] = []
        tutorial_new_funcs: list[int] = []
        star_crystal = 0

        # v0.8.2 commits source-certain rewards only when there is a matching
        # MID113 session. This prevents an arbitrary/retried MID114 from minting
        # Mana/EXP without a battle. General repeat item RNG remains deferred.
        candidate_awards: list[dict[str, int]] = []
        if star > 0 and not was_cleared and has_pending:
            candidate_awards = staged_items if isinstance(staged_items, list) else self._guaranteed_first_awards(cid)

        if star > 0 and has_pending and campaign_type == 1:
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
                for award in candidate_awards
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
            economy_projection = reward_result.economy
            awarded_items = reward_result.inventory_awards
            # Economy first: BattleWinWindow observes the post-battle player
            # level when applying Hero EXP and therefore the resulting Hero cap.
            hero_exps = self.hero_progression.grant_battle_exp(
                pending.get("formation", ""),
                pending.get("partner_exp", 0),
                persist=False,
            )
        elif candidate_awards:
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
                        for award in candidate_awards
                        if isinstance(award, dict)
                        and self._int(award.get("item_id"), 0) > 0
                        and self._int(award.get("item_num"), 0) > 0
                    ),
                )
            )
            awarded_items = reward_result.inventory_awards

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

        response: dict[str, Any] = {
            "is_win": 1 if star > 0 else 0,
            "result": 1 if star > 0 else 0,
            "chapter_info": chapter_info,
            "campaigns": touched,
            "items": awarded_items,
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
        if tutorial_new_funcs:
            # Keep the semantic transition in the committed MID114 receipt as
            # well as the UoW semantic bus so a result retry cannot lose it.
            response["new_funcs_"] = sorted({int(value) for value in tutorial_new_funcs if int(value) > 0})

        if has_pending:
            # Keep the committed response as a one-request receipt until the
            # next MID113 overwrites it. A duplicate MID114 therefore returns
            # the same cumulative values/items without applying rewards twice.
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

    def sweep(self, req: dict[str, Any]) -> dict[str, Any]:
        self.normalize()
        cid = self._int(req.get("campaign_id"), 0)
        count = max(1, min(100, self._int(req.get("sweep_num"), 1)))
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
        if per_sweep and self.inventory is not None:
            aggregate = [
                {"item_id": award["item_id"], "item_num": award["item_num"] * count}
                for award in per_sweep
            ]
            self.inventory.add_items(aggregate, persist=False)
            self._save()

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
