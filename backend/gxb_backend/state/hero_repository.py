"""Canonical owned-hero state and persistence helpers.

Stage 4A makes hero ownership a first-class state owner instead of treating
MID49 as an isolated response blob.  Future summon/reward/battle code should
add or mutate heroes through this repository so MID17, MID49, collection state,
representative hero state, and the JSON database stay coherent.

This module deliberately does *not* validate arbitrary table IDs against copied
client data.  Callers must still use source-confirmed table IDs.  It only
normalizes fields whose shapes are directly consumed by the supplied Lua.
"""

from __future__ import annotations

from collections.abc import Callable
from pathlib import Path
from typing import Any

from .player_state import PlayerState
from .skill_point_policy import SkillPointPolicy


class HeroRepository:
    """Own and normalize ``PlayerState`` hero-related fields."""

    _SIX_ONES = (1, 1, 1, 1, 1, 1)
    _SIX_ZEROES = (0, 0, 0, 0, 0, 0)

    def __init__(
        self,
        player: PlayerState,
        save_callback: Callable[[], None] | None = None,
        data_dir: Path | None = None,
    ) -> None:
        self.player = player
        self._save_callback = save_callback
        self._data_dir = Path(data_dir or "data")

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    @classmethod
    def _fixed_six(cls, value: Any, default: tuple[int, ...]) -> list[int]:
        if not isinstance(value, (list, tuple)):
            value = list(default)
        result = [cls._int(item, default[idx] if idx < len(default) else 0) for idx, item in enumerate(value[:6])]
        while len(result) < 6:
            result.append(default[len(result)])
        return result

    @staticmethod
    def _string_or_empty(value: Any) -> str:
        # SelfPlayer:getSaveTeams() passes these fields directly to xyd.split /
        # string.split.  Legacy Stage 3 JSON used {}, which crashes that path.
        return value if isinstance(value, str) else ""

    def normalize(self) -> bool:
        """Normalize persisted state to the Lua-facing shapes used by Stage 4A.

        Returns ``True`` when state changed.  StateRepository uses this during
        database load to migrate legacy Stage 3 values atomically.
        """
        changed = False
        player = self.player

        for attr in ("save_team", "save_team_name", "save_pet"):
            old = getattr(player, attr)
            new = self._string_or_empty(old)
            if old != new:
                setattr(player, attr, new)
                changed = True

        old_pieces = player.hero_pieces
        if isinstance(old_pieces, list):
            # Old Stage 3 kept a list-shaped compatibility field.  Source
            # SelfPlayer:heroPiecesEvent_ consumes the response itself as an
            # id->count map.  Preserve recognized rows; empty lists become {}.
            converted: dict[str, int] = {}
            for row in old_pieces:
                if not isinstance(row, dict):
                    continue
                key = row.get("table_id") or row.get("id") or row.get("hero_id")
                count = row.get("num") if "num" in row else row.get("count")
                if key is not None and count is not None:
                    converted[str(key)] = self._int(count)
            player.hero_pieces = converted
            changed = True
        elif not isinstance(old_pieces, dict):
            player.hero_pieces = {}
            changed = True

        if not isinstance(player.collected_heros, dict):
            player.collected_heros = {}
            changed = True

        heroes = player.heroes
        if isinstance(heroes, dict) and isinstance(heroes.get("heroes"), dict):
            heroes = heroes["heroes"]
            player.heroes = heroes
            changed = True
        if not isinstance(heroes, dict):
            heroes = {}
            player.heroes = heroes
            changed = True

        normalized: dict[str, dict[str, Any]] = {}
        max_partner_id = 10000
        for raw_key, raw_hero in heroes.items():
            if not isinstance(raw_hero, dict):
                continue
            hero = dict(raw_hero)
            partner_id = self._int(hero.get("partner_id", raw_key), 0)
            table_id = self._int(hero.get("table_id"), 0)
            star = self._int(hero.get("star"), 0)
            if partner_id <= 0 or table_id <= 0 or star <= 0:
                # Do not invent source identifiers or star values.  Invalid
                # hand-edited records stay out of MID49 until corrected.
                continue

            max_partner_id = max(max_partner_id, partner_id)
            hero["player_id"] = str(player.player_id)
            hero["partner_id"] = partner_id
            hero["table_id"] = table_id
            hero["star"] = star
            hero["lev"] = max(1, self._int(hero.get("lev"), 1))
            hero["exp"] = max(0, self._int(hero.get("exp"), 0))
            hero["color"] = max(1, self._int(hero.get("color"), 1))
            hero["skills"] = self._fixed_six(hero.get("skills"), self._SIX_ONES)
            hero["equips"] = self._fixed_six(hero.get("equips"), self._SIX_ZEROES)
            hero["fumos"] = self._fixed_six(hero.get("fumos"), self._SIX_ZEROES)
            hero.setdefault("skin_ids", [])
            hero.setdefault("current_skin_id", 0)
            # HeroMainWindow's Skin tab treats illusionSkinId_ <= 1 as a
            # 1-based selector by adding one.  The old compatibility fallback -1
            # therefore produces selector 0 and then dereferences skinDatas[0].
            # For an ordinary/non-awakened hero, 0 is the source-defined normal
            # appearance selector.  Normalize absent/negative compatibility values
            # to 0 instead of explicitly emitting -1.
            illusion_skin_id = self._int(hero.get("illusion_skin_id"), 0)
            hero["illusion_skin_id"] = max(0, illusion_skin_id)
            # HeroMainWindow:updateElementEquip() loops four element slots even
            # for a normal hero (the source guard is written as ``not color ==``).
            # An empty Lua table makes ``element_equips[i] ~= 0`` true for nil,
            # then tonumber(nil) is passed into element-equipment tables. Use the
            # source constant MAX_ELEMENT_ITEM_NUM=4 with explicit zero slots.
            element_equips = hero.get("element_equips")
            if not isinstance(element_equips, (list, tuple)) or len(element_equips) < 4:
                hero["element_equips"] = [0, 0, 0, 0]
            else:
                hero["element_equips"] = [self._int(v) for v in element_equips[:4]]
            element_levels = hero.get("element_levels")
            if not isinstance(element_levels, (list, tuple)) or len(element_levels) < 4:
                hero["element_levels"] = [0, 0, 0, 0]
            else:
                hero["element_levels"] = [self._int(v) for v in element_levels[:4]]
            hero.setdefault("element_bak_equips", [])
            hero.setdefault("element_bak_levels", [])
            hero.setdefault("spirit_equip", {})
            hero.setdefault("spirit_item", [])
            hero.setdefault("practice_attr", [0, 0, 0])
            hero.setdefault("skill_book_info", {})
            hero.setdefault("inscript_items", {})
            hero.setdefault("feed_attrs", {})
            hero.setdefault("evo_attr_points", {})
            hero.setdefault("evo_stage", 1)
            hero.setdefault("is_like", 0)
            hero.setdefault("force", 0)
            hero.setdefault("favor_degree", 0)
            hero.setdefault("is_married", 0)
            hero.setdefault("twice_awake_stage", 0)
            hero.setdefault("region_arena_times", 0)
            hero.setdefault("book_shelf_lev", 0)
            hero.setdefault("conquer_lev", 0)
            hero.setdefault("conquer_loop_id", 1)
            # HeroMainWindow:updateFuncBtn() compares house_id > 0.  NormalHero
            # leaves omitted house fields as nil, so these must be explicit
            # zero/empty values for a non-dorm resident hero.
            hero.setdefault("house_id", 0)
            hero.setdefault("house_table_id", 0)
            hero.setdefault("house_comfort", 0)
            hero.setdefault("house_equips", {})
            hero.setdefault("house_expand_lev", 0)
            hero.setdefault("unlocked_dynamic_card", "")
            hero.setdefault("dynamic_card_state", "")
            hero.setdefault("collect_quality_stage", 0)
            hero.setdefault("collect_star_stage", 0)
            hero.setdefault("buffs", {})
            hero.setdefault("board_model_id", 0)
            hero.setdefault("skill_ids", [0, 0, 0, 0, 0, 0])
            hero.setdefault("courses", [])
            hero.setdefault("courses_progress", [])
            hero.setdefault("courses_skill", [])
            hero.setdefault("courses_quality", [])
            hero.setdefault("courses_exp", [])
            hero.setdefault("is_board", 0)
            hero.setdefault("board_card", 1)
            normalized[str(partner_id)] = hero

            # Owning a hero necessarily means it has been collected.  Keep the
            # richer internal map; MID65 serializes only its table IDs.
            collection_key = str(table_id)
            if collection_key not in player.collected_heros:
                player.collected_heros[collection_key] = {
                    "table_id": table_id,
                    "star": star,
                    "is_collected": 1,
                }
                changed = True

        if normalized != player.heroes:
            player.heroes = normalized
            changed = True

        next_id = max(max_partner_id + 1, self._int(player.hero_next_partner_id, 10001))
        if player.hero_next_partner_id != next_id:
            player.hero_next_partner_id = next_id
            changed = True

        if player.heroes:
            rep_id = self._int((player.formation or {}).get("rep_partner_id"), 0)
            if str(rep_id) not in player.heroes:
                first_id = min(int(key) for key in player.heroes if key.isdigit())
                player.formation = dict(player.formation or {})
                player.formation["rep_partner_id"] = first_id
                changed = True

        return changed

    def payload(self) -> dict[str, Any]:
        self.normalize()
        return {"sort_type": self._int(self.player.hero_sort_type), "heros": self.player.heroes}

    def collected_payload(self) -> dict[str, Any]:
        self.normalize()
        result: list[int | str] = []
        for key in sorted(self.player.collected_heros.keys(), key=lambda value: str(value)):
            result.append(int(key) if str(key).isdigit() else key)
        return {"list": result}

    def pieces_payload(self) -> dict[str, int]:
        self.normalize()
        return {str(key): self._int(value) for key, value in self.player.hero_pieces.items()}

    def get(self, partner_id: Any) -> dict[str, Any] | None:
        self.normalize()
        return self.player.heroes.get(str(self._int(partner_id, -1)))

    @staticmethod
    def _pipe_ints(value: Any) -> list[int]:
        """Parse Lua pipe-merged integer lists used by hero skill commands."""
        if value is None:
            return []
        if isinstance(value, (list, tuple)):
            raw = value
        else:
            raw = str(value).split("|")
        result: list[int] = []
        for item in raw:
            try:
                result.append(int(item))
            except (TypeError, ValueError):
                return []
        return result

    def recover_skill_points(self, *, persist: bool = False) -> bool:
        """Mirror the client timed skill-point recovery against canonical state."""
        return SkillPointPolicy(self.player, self._data_dir, self._save_callback).recover(persist=persist)

    def buy_skill_points(self) -> dict[str, int]:
        """Persist MID99 BUY_SKILL_POINT's source-observed player fields.

        The client translation for SKILL_POINT_BUY explicitly states that one
        purchase grants 10 skill points.  Crystal charging is intentionally left
        for the later full Hero/Economy progression pass because this narrow pass
        has no proven economy-sync response path for MID99.
        """
        player = self.player
        SkillPointPolicy(player, self._data_dir, self._save_callback).recover()
        player.buy_skill_times = max(0, self._int(player.buy_skill_times)) + 1
        player.skill_point = max(0, self._int(player.skill_point)) + 10
        if self._int(player.skill_time) <= 0:
            player.skill_time = player.now()
        self._save()
        return {
            "buy_skill_times": player.buy_skill_times,
            "skill_point": player.skill_point,
            "skill_time": player.skill_time,
        }

    def upgrade_skills(self, partner_id: Any, skill_colors: Any, skill_counts: Any) -> dict[str, Any]:
        """Persist MID39 SET_ALL_SKILL_LEVEL against the canonical hero record.

        HeroMainWindow batches changed skill indexes in ``skill_colors`` and the
        per-index increment counts in ``skill_counts``.  Its callback consumes a
        pipe-serialized full ``skills`` vector plus player ``skill_point`` and
        ``skill_time``.
        """
        self.normalize()
        hero = self.get(partner_id)
        if hero is None:
            return {
                "skills": "",
                "skill_point": max(0, self._int(self.player.skill_point)),
                "skill_time": self._int(self.player.skill_time) or self.player.now(),
            }

        indexes = self._pipe_ints(skill_colors)
        counts = self._pipe_ints(skill_counts)
        skills = self._fixed_six(hero.get("skills"), self._SIX_ONES)

        requested: list[tuple[int, int]] = []
        if len(indexes) == len(counts):
            for index, count in zip(indexes, counts):
                if 1 <= index <= 6 and count > 0:
                    requested.append((index, count))

        total_requested = sum(count for _, count in requested)
        policy = SkillPointPolicy(self.player, self._data_dir, self._save_callback)
        policy.recover(persist=True)
        available = max(0, self._int(self.player.skill_point))
        before_time = max(0, self._int(self.player.skill_time))

        # The client performs the same timed recovery before each local click.
        # After mirroring that recovery, the batch can be validated against the
        # same point pool the player actually saw.
        if requested and total_requested <= available:
            for index, count in requested:
                skills[index - 1] += count
            hero["skills"] = skills
            self.player.skill_point = available - total_requested
            policy.begin_recovery_if_full_spent(available, before_time)
            self._save()

        return {
            "skills": "|".join(str(value) for value in skills),
            "skill_point": max(0, self._int(self.player.skill_point)),
            "skill_time": self._int(self.player.skill_time) or self.player.now(),
        }

    def upgrade_single_skill(self, partner_id: Any, skill_index: Any) -> dict[str, int]:
        """Persist the older MID53 single-skill path using the same state owner."""
        result = self.upgrade_skills(partner_id, skill_index, 1)
        return {
            "skill_point": self._int(result.get("skill_point")),
            "skill_time": self._int(result.get("skill_time")),
        }

    def set_sort_type(self, sort_type: Any) -> None:
        self.player.hero_sort_type = self._int(sort_type)
        self._save()

    def save_presets(self, team_str: Any, team_name_str: Any, pet_str: Any) -> dict[str, str]:
        self.player.save_team = self._string_or_empty(team_str)
        self.player.save_team_name = self._string_or_empty(team_name_str)
        self.player.save_pet = self._string_or_empty(pet_str)
        self._save()
        return {
            "save_team": self.player.save_team,
            "save_team_name": self.player.save_team_name,
            "save_pet": self.player.save_pet,
        }


    def set_board_hero(self, partner_id: Any, card_status: Any, board_model_id: Any) -> dict[str, int]:
        """Persist the library/poster-board hero selection (MID 835).

        ``board_partner``, ``board_card`` and ``board_model_id`` are the exact
        callback fields consumed by ``TuJianHeroDetailWindow``.  Board/poster
        selection is intentionally kept separate from ``formation.rep_partner_id``:
        the client models those as different concepts.
        """
        self.normalize()
        key = str(self._int(partner_id, -1))
        selected = self.player.heroes.get(key)
        if selected is None:
            # UI-originated requests should always reference an owned partner.
            # Returning board_partner=0 lets the source callback avoid marking an
            # unknown hero as board hero without inventing another identifier.
            return {
                "board_partner": 0,
                "board_card": self._int(card_status, 0),
                "board_model_id": self._int(board_model_id, 0),
            }

        card = self._int(card_status, 0)
        model_id = self._int(board_model_id, 0)

        # TuJianHeroDetailWindow uses the same request for set and reset. If the
        # selected hero/card/model is already the board configuration, its
        # confirmation text changes to "reset" and the callback treats a
        # non-positive board_partner as cleared. Mirror that client contract
        # rather than inventing a server-only reset flag.
        if (
            self._int(selected.get("is_board"), 0) == 1
            and self._int(selected.get("board_card"), 1) == card
            and self._int(selected.get("board_model_id"), 0) == model_id
        ):
            selected["is_board"] = 0
            selected["board_card"] = card
            selected["board_model_id"] = model_id
            self._save()
            return {
                "board_partner": 0,
                "board_card": card,
                "board_model_id": model_id,
            }

        for hero in self.player.heroes.values():
            if isinstance(hero, dict):
                hero["is_board"] = 0
        selected["is_board"] = 1
        selected["board_card"] = card
        selected["board_model_id"] = model_id
        self._save()
        return {
            "board_partner": self._int(selected.get("partner_id"), 0),
            "board_card": card,
            "board_model_id": model_id,
        }

    def add_owned_hero(
        self, hero: dict[str, Any], *, persist: bool = True
    ) -> dict[str, Any]:
        """Persist one source-valid owned hero and return its normalized record.

        Callers must provide at least ``table_id`` and ``star``.  A local
        partner_id is allocated when absent.  This is the sync primitive future
        summon/reward flows should use; it intentionally does not invent a
        table ID or initial star.
        """
        self.normalize()
        table_id = self._int(hero.get("table_id"), 0)
        star = self._int(hero.get("star"), 0)
        if table_id <= 0 or star <= 0:
            raise ValueError("add_owned_hero requires source-valid table_id and star")

        partner_id = self._int(hero.get("partner_id"), 0)
        if partner_id <= 0:
            partner_id = max(10001, self._int(self.player.hero_next_partner_id, 10001))
            while str(partner_id) in self.player.heroes:
                partner_id += 1
            self.player.hero_next_partner_id = partner_id + 1
        elif str(partner_id) in self.player.heroes:
            raise ValueError(
                f"partner_id {partner_id} already exists; use update_owned_hero for mutations"
            )

        record = dict(hero)
        record["partner_id"] = partner_id
        record["player_id"] = str(self.player.player_id)
        self.player.heroes[str(partner_id)] = record
        self.normalize()
        if persist:
            self._save()
        return dict(self.player.heroes[str(partner_id)])

    def update_owned_hero(self, partner_id: Any, changes: dict[str, Any]) -> dict[str, Any] | None:
        self.normalize()
        key = str(self._int(partner_id, -1))
        if key not in self.player.heroes:
            return None
        self.player.heroes[key].update(changes)
        self.normalize()
        self._save()
        return dict(self.player.heroes[key])

    def remove_owned_hero(self, partner_id: Any) -> bool:
        self.normalize()
        key = str(self._int(partner_id, -1))
        hero = self.player.heroes.pop(key, None)
        if hero is None:
            return False
        self.normalize()
        self._save()
        return True

    def _save(self) -> None:
        if self._save_callback:
            self._save_callback()
