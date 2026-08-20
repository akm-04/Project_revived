"""Source-backed Hero consumable progression for Stage 4A.7.

MID90 skill-point packs and MID55/MID63 EXP juices mutate the same canonical
PlayerState/Backpack/Hero graph returned by MID17, MID49 and MID81. Numeric item
values and EXP thresholds come from packaged metadata derived from authoritative
src_64 tables; no consumable IDs or level thresholds are guessed here.
"""
from __future__ import annotations

import json
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

from .global_response_semantics import GlobalResponseSemantics
from .hero_repository import HeroRepository
from .inventory_repository import InventoryRepository
from .player_state import PlayerState
from .skill_point_policy import SkillPointPolicy
from .unit_of_work import OperationContext, UnitOfWork


class HeroProgressionRepository:
    def __init__(
        self,
        player: PlayerState,
        data_dir: Path,
        save_callback: Callable[[], None] | None = None,
        *,
        inventory: InventoryRepository | None = None,
        heroes: HeroRepository | None = None,
        uow: UnitOfWork | None = None,
        response_semantics: GlobalResponseSemantics | None = None,
        catalog: GameDataCatalog | None = None,
    ) -> None:
        self.player = player
        self.data_dir = Path(data_dir)
        self._save_callback = save_callback
        self.inventory = inventory or InventoryRepository(player, save_callback)
        self.heroes = heroes or HeroRepository(player, save_callback, self.data_dir)
        self.uow = uow
        self.response_semantics = response_semantics
        self.catalog = catalog
        self.items = self._load_rows("item_progression_meta.json", "items")
        self.exp_levels = self._load_rows("partner_exp_meta.json", "levels")
        self.player_levels = self._load_rows("player_hero_level_meta.json", "levels")

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _load_rows(self, filename: str, key: str) -> dict[str, dict[str, Any]]:
        path = self.data_dir / filename
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
            rows = payload.get(key) or {}
            return rows if isinstance(rows, dict) else {}
        except Exception as exc:
            print(f"[HERO PROGRESSION] could not load {path}: {exc}")
            return {}

    def _item_meta(self, item_id: Any) -> dict[str, Any]:
        return self.items.get(str(self._int(item_id, 0))) or {}

    def _total_exp(self, level: Any) -> int:
        row = self.exp_levels.get(str(max(0, self._int(level, 0)))) or {}
        return max(0, self._int(row.get("total_exp"), 0))

    def _hero_cap(self) -> int:
        player_level = max(1, self._int(self.player.lev, 1))
        row = self.player_levels.get(str(player_level)) or {}
        cap = self._int(row.get("hero_lev"), 0)
        if cap > 0:
            return cap
        # Source metadata currently covers the supplied player table through
        # level 100. For a hand-edited level outside it, use the highest known
        # source row rather than inventing a new mapping.
        known = [self._int(v.get("hero_lev"), 0) for v in self.player_levels.values() if isinstance(v, dict)]
        return max(known, default=1)

    def _normalized_total_exp(self, hero: dict[str, Any]) -> int:
        """Repair the old Stage-4 compatibility ``lev>1, exp=0`` placeholder.

        NormalHero stores cumulative total EXP. Earlier backend builds seeded
        Aquaris at level 20 with exp=0, which is below the source minimum for
        level 20. On first real EXP mutation, preserve the visible level by
        migrating that legacy value to totalExp(level-1), i.e. zero progress
        inside the current level. This is an explicit compatibility migration,
        not a fabricated reward.
        """
        level = max(1, self._int(hero.get("lev"), 1))
        current = max(0, self._int(hero.get("exp"), 0))
        floor = self._total_exp(level - 1) if level > 1 else 0
        return max(current, floor)

    def _level_for_total_exp(self, total_exp: int, start_level: int, cap: int) -> int:
        level = max(1, min(start_level, cap))
        # Matches NormalHero:setLevel: each threshold totalExp(level) advances
        # to level+1, clamped at the source player hero-level cap.
        for candidate in range(level, cap + 1):
            threshold = self._total_exp(candidate)
            if threshold > 0 and total_exp >= threshold:
                level = min(candidate + 1, cap)
            else:
                break
        return level


    def grant_battle_exp(
        self,
        partner_ids: Any,
        per_hero_exp: Any,
        *,
        persist: bool = False,
    ) -> list[dict[str, int]]:
        """Grant source Campaign EXP to participating owned Heroes.

        MID114 ``exps`` rows carry each Hero's new cumulative EXP, not a delta.
        The player-level economy mutation should run before this method so the
        source Hero-level cap reflects any level gained from the same battle.
        """
        gain = max(0, self._int(per_hero_exp, 0))
        if gain <= 0:
            return []

        if isinstance(partner_ids, str):
            raw_ids = partner_ids.split("|")
        elif isinstance(partner_ids, (list, tuple)):
            raw_ids = list(partner_ids)
        else:
            raw_ids = []

        ordered: list[int] = []
        seen: set[int] = set()
        for value in raw_ids:
            partner_id = self._int(value, 0)
            if partner_id <= 0 or partner_id in seen:
                continue
            seen.add(partner_id)
            ordered.append(partner_id)

        cap = max(1, self._hero_cap())
        cap_exp = self._total_exp(cap)
        result: list[dict[str, int]] = []
        for partner_id in ordered:
            hero = self.heroes.get(partner_id)
            if hero is None:
                continue
            start_level = max(1, self._int(hero.get("lev"), 1))
            new_exp = self._normalized_total_exp(hero) + gain
            if cap_exp > 0:
                new_exp = min(new_exp, cap_exp)
            hero["exp"] = new_exp
            hero["lev"] = self._level_for_total_exp(new_exp, start_level, cap)
            result.append({"partner_id": partner_id, "exp": new_exp})

        if persist and result:
            self._save()
        return result

    def total_exp_for_level(self, level: Any) -> int:
        """Expose the source cumulative Hero EXP threshold to sibling domains."""
        return self._total_exp(level)

    def hero_level_cap(self) -> int:
        """Expose the source player-level-derived Hero cap to sibling domains."""
        return self._hero_cap()

    def normalized_total_exp(self, hero: dict[str, Any]) -> int:
        return self._normalized_total_exp(hero)

    def grant_exp_amount(self, partner_id: Any, amount: Any, *, persist: bool = False) -> int | None:
        """Grant arbitrary source-derived Hero EXP through the canonical owner."""
        hero = self.heroes.get(partner_id)
        gain = max(0, self._int(amount, 0))
        if hero is None or gain <= 0:
            return None
        start_level = max(1, self._int(hero.get("lev"), 1))
        cap = max(1, self._hero_cap())
        new_exp = self._normalized_total_exp(hero) + gain
        cap_exp = self._total_exp(cap)
        if cap_exp > 0:
            new_exp = min(new_exp, cap_exp)
        hero["exp"] = new_exp
        hero["lev"] = self._level_for_total_exp(new_exp, start_level, cap)
        if persist:
            self._save()
        return new_exp

    def use_skill_point_item(self, req: dict[str, Any]) -> dict[str, Any]:
        """Consume a source Skill Point item and explicitly sync the global pool.

        MID90's endpoint-local Lua callback removes the Backpack item but reads
        no Skill Point response field.  The successful web-response path runs
        ``Backend.extraWebResponseCheck_()`` before LoadingProxy cleanup and the
        inline callback; that global path dispatches ``economy_`` and
        ``SelfPlayer.economySyncEvent_()`` consumes ``skill_point``.

        Therefore this operation stages exactly one cumulative
        ``economy_.skill_point`` semantic after the canonical mutation is marked
        for commit.  Skill Point remains excluded from generic diff projection.
        """
        item_id = self._int(req.get("item_id"), 0)
        count = max(0, self._int(req.get("item_num"), 0))
        meta = self._item_meta(item_id)
        per_item = max(0, self._int(meta.get("skill_point"), 0))
        if count <= 0 or per_item <= 0:
            return {"error_code": 1}
        if self.inventory.get_item_num(item_id) < count:
            return {"error_code": 1}

        mutated = False

        def mutate() -> None:
            nonlocal mutated
            policy = SkillPointPolicy(self.player, self.data_dir, self._save_callback)
            policy.recover()
            remaining = self.inventory.consume_item(item_id, count, persist=False)
            if remaining is None:
                return
            self.player.skill_point = max(0, self._int(self.player.skill_point)) + per_item * count
            policy.normalize_timer_after_gain()
            self._save()
            mutated = True
            if self.response_semantics is not None:
                self.response_semantics.stage_skill_point()

        if self.uow is not None:
            with self.uow.transaction(OperationContext(
                actor_player_id=str(self.player.player_id),
                domain="hero_progression",
                operation_name="use_skill_point_item",
                protocol_mid=90,
            )):
                mutate()
        else:
            # Compatibility construction outside RequestServices keeps the old
            # canonical mutation semantics but has no request response bus.
            mutate()

        if not mutated:
            # error.lua defines xyd.error.ERROR = 1.  Returning a non-zero
            # result is essential here: the endpoint-local callback removes the
            # Backpack item only on xyd.error.OK, so a duplicate/insufficient
            # request must never receive fabricated success.
            return {"error_code": 1}

        # Source MID90 callback consumes no endpoint-local resource field.
        return {}

    _NORMAL_HERO_MAX_STAR = 5
    _EVOLUTION_STONE_REQUIRED_BY_NEXT_STAR = {2: 20, 3: 50, 4: 100, 5: 150}

    def evolve_hero(self, req: dict[str, Any]) -> dict[str, Any]:
        """MID52: canonically consume the owned Girl's scrolls and raise star.

        ``SelfPlayer:evolveHero`` sends only the runtime ``partner_id``.  On an
        OK callback the stock client removes ``StarLevelSuipian[next_star]`` of
        that Girl's own ``stone_id`` and ``NormalHero:evolution`` increments the
        visible star locally.  The endpoint consumes no response fields, so the
        server must persist the same mutation and return an empty success object.

        All identity checks are typed/source-backed.  No numeric-prefix rule is
        used: the owned Hero resolves to PARTNER, its explicit ``stone_id`` must
        resolve to an ITEM row of type 3 whose ``partner_id`` points back to the
        same Girl, and only ordinary 1->5 evolution is activated here.
        """
        partner_id = self._int(req.get("partner_id"), 0)
        hero = self.heroes.get(partner_id)
        if hero is None or self.catalog is None:
            return {"error_code": 1}

        table_id = self._int(hero.get("table_id"), 0)
        current_star = self._int(hero.get("star"), 0)
        next_star = current_star + 1
        required = self._EVOLUTION_STONE_REQUIRED_BY_NEXT_STAR.get(next_star)
        if table_id <= 0 or current_star <= 0 or current_star >= self._NORMAL_HERO_MAX_STAR or required is None:
            return {"error_code": 1}

        try:
            partner_ref = self.catalog.resolve(
                ResolveContext.create(
                    field_name="owned_hero.table_id",
                    source_domain="hero_evolution",
                    expected_namespaces=(CatalogNamespace.PARTNER,),
                    protocol_mid=52,
                    source_path="app/model/SelfPlayer.lua",
                ),
                table_id,
            )
            partner_row = self.catalog.get(partner_ref)
            stone_id = self._int(partner_row.get("stone_id"), 0)
            stone_ref = self.catalog.resolve(
                ResolveContext.create(
                    field_name="partner.stone_id",
                    source_domain="hero_evolution",
                    expected_namespaces=(CatalogNamespace.ITEM,),
                    protocol_mid=52,
                    source_path="app/model/SelfPlayer.lua",
                ),
                stone_id,
            )
            stone_row = self.catalog.get(stone_ref)
        except (UnknownContentReference, AmbiguousContentReference):
            return {"error_code": 1}

        if (
            stone_id <= 0
            or self._int(stone_row.get("type"), 0) != 3
            or self._int(stone_row.get("partner_id"), 0) != table_id
            or self.inventory.get_item_num(stone_id) < required
        ):
            return {"error_code": 1}

        def mutate() -> None:
            remaining = self.inventory.consume_item(stone_id, required, persist=False)
            if remaining is None:
                raise RuntimeError("canonical Backpack changed during MID52 transaction")
            hero["star"] = next_star
            collected = self.player.collected_heros.get(str(table_id))
            if isinstance(collected, dict):
                collected["star"] = max(self._int(collected.get("star"), 0), next_star)
                collected["is_collected"] = 1
            self._save()

        if self.uow is not None:
            try:
                with self.uow.transaction(OperationContext(
                    actor_player_id=str(self.player.player_id),
                    domain="hero_progression",
                    operation_name="evolve_hero",
                    protocol_mid=52,
                )):
                    mutate()
            except RuntimeError:
                return {"error_code": 1}
        else:
            try:
                mutate()
            except RuntimeError:
                return {"error_code": 1}
        return {}

    def use_exp_item(self, req: dict[str, Any]) -> dict[str, Any]:
        item_id = self._int(req.get("item_id"), 0)
        count = max(0, self._int(req.get("item_num"), 0))
        partner_id = self._int(req.get("partner_id"), 0)
        hero = self.heroes.get(partner_id)
        meta = self._item_meta(item_id)
        per_item = max(0, self._int(meta.get("exp"), 0))

        if hero is None or count <= 0 or per_item <= 0:
            return {}
        consumed = self.inventory.consume_item(item_id, count, persist=False)
        if consumed is None:
            return {}

        start_level = max(1, self._int(hero.get("lev"), 1))
        cap = max(1, self._hero_cap())
        current_exp = self._normalized_total_exp(hero)
        cap_exp = self._total_exp(cap)
        new_exp = current_exp + per_item * count
        if cap_exp > 0:
            new_exp = min(new_exp, cap_exp)
        hero["exp"] = new_exp
        hero["lev"] = self._level_for_total_exp(new_exp, start_level, cap)
        self._save()

        # AddExpWindow/UseExpWindow directly consume these exact three fields.
        return {"item_id": item_id, "partner_exp": new_exp, "total_num": max(0, consumed)}

    def use_exp_items(self, req: dict[str, Any]) -> dict[str, Any]:
        partner_id = self._int(req.get("partner_id"), 0)
        hero = self.heroes.get(partner_id)
        rows = req.get("items") if isinstance(req.get("items"), list) else []
        if hero is None or not rows:
            return {}

        valid: list[dict[str, int]] = []
        add_exp = 0
        for row in rows:
            if not isinstance(row, dict):
                continue
            item_id = self._int(row.get("item_id"), 0)
            item_num = max(0, self._int(row.get("item_num"), 0))
            per_item = max(0, self._int(self._item_meta(item_id).get("exp"), 0))
            if item_id > 0 and item_num > 0 and per_item > 0:
                valid.append({"item_id": item_id, "item_num": item_num})
                add_exp += per_item * item_num

        if not valid or not self.inventory.consume_items(valid, persist=False):
            return {}

        start_level = max(1, self._int(hero.get("lev"), 1))
        cap = max(1, self._hero_cap())
        new_exp = self._normalized_total_exp(hero) + add_exp
        cap_exp = self._total_exp(cap)
        if cap_exp > 0:
            new_exp = min(new_exp, cap_exp)
        hero["exp"] = new_exp
        hero["lev"] = self._level_for_total_exp(new_exp, start_level, cap)
        self._save()
        # AddExpWindow's MID63 callback updates the hero locally from the exact
        # selected source item values and does not consume response fields.
        return {}

    def _save(self) -> None:
        if self._save_callback:
            self._save_callback()
