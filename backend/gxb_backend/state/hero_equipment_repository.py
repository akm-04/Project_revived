"""Source-backed normal-Hero equipment and one-click promotion transactions.

v0.8.4 intentionally implements the early ordinary NormalHero path only:
MID54 SET_HERO_EQUIP, MID62 ONE_CLICK_EQUIP and MID57 ONE_CLICK_JINJIE.
The client sends only partner/slot identifiers while independently calculating
recursive composition, EXP-juice and Mana costs.  This repository mirrors those
source calculations against canonical Hero/Backpack/Economy state so relog does
not undo the visible client mutation.

Awakened/bloodline/Fumo restoration semantics remain deferred. Requests that
leave this narrow source-backed boundary fail closed without mutating state.
"""
from __future__ import annotations

import json
import math
from collections.abc import Callable
from pathlib import Path
from typing import Any

from .economy_repository import EconomyRepository
from .hero_progression_repository import HeroProgressionRepository
from .hero_repository import HeroRepository
from .inventory_repository import InventoryRepository
from .player_state import PlayerState


class HeroEquipmentRepository:
    MAX_COLOR = 16

    def __init__(
        self,
        player: PlayerState,
        data_dir: Path,
        save_callback: Callable[[], None] | None = None,
        *,
        inventory: InventoryRepository | None = None,
        heroes: HeroRepository | None = None,
        progression: HeroProgressionRepository | None = None,
        economy: EconomyRepository | None = None,
    ) -> None:
        self.player = player
        self.data_dir = Path(data_dir)
        self._save_callback = save_callback
        self.inventory = inventory or InventoryRepository(player, save_callback)
        self.heroes = heroes or HeroRepository(player, save_callback, self.data_dir)
        self.progression = progression or HeroProgressionRepository(
            player, self.data_dir, save_callback, inventory=self.inventory, heroes=self.heroes
        )
        self.economy = economy or EconomyRepository(player, self.data_dir, save_callback)
        self.meta = self._load_meta()
        self.partners = self.meta.get("partners") or {}
        self.items = self.meta.get("items") or {}
        self.potion_ids = [self._int(value) for value in (self.meta.get("potion_ids") or [])]
        self.partner_table_init_id = self._int(self.meta.get("partner_table_init_id"), 10001000)

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _load_meta(self) -> dict[str, Any]:
        path = self.data_dir / "hero_equipment_meta.json"
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
            return payload if isinstance(payload, dict) else {}
        except Exception as exc:
            print(f"[HERO EQUIP] could not load {path}: {exc}")
            return {}

    def _item(self, item_id: Any) -> dict[str, Any]:
        row = self.items.get(str(self._int(item_id, 0))) if isinstance(self.items, dict) else None
        return row if isinstance(row, dict) else {}

    def _equip_ids(self, hero: dict[str, Any]) -> list[int]:
        row = self.partners.get(str(self._int(hero.get("table_id"), 0))) if isinstance(self.partners, dict) else None
        if not isinstance(row, dict):
            return []
        lists = row.get("equip_lists") or {}
        values = lists.get(str(self._int(hero.get("color"), 1))) if isinstance(lists, dict) else None
        if not isinstance(values, list):
            return []
        result = [self._int(value) for value in values[:6]]
        while len(result) < 6:
            result.append(0)
        return result

    def _normal_early_boundary(self, hero: dict[str, Any]) -> bool:
        table_id = self._int(hero.get("table_id"), 0)
        color = self._int(hero.get("color"), 0)
        if table_id <= self.partner_table_init_id or not (1 <= color < self.MAX_COLOR + 1):
            return False
        # Fumo restoration on one-click promotion is source-visible but its
        # full award semantics have not been reconstructed yet. Fresh tutorial
        # Heroes have no Fumo, so fail closed outside that boundary.
        fumos = hero.get("fumos")
        if isinstance(fumos, (list, tuple)) and any(self._int(value) != 0 for value in fumos):
            return False
        return True

    def _is_normal_equipment(self, item_id: int) -> bool:
        row = self._item(item_id)
        return bool(row) and self._int(row.get("is_awaken_item"), 0) == 0 and self._int(row.get("is_bloodline_item"), 0) == 0

    @staticmethod
    def _merge_counts(base: dict[int, int], extra: dict[int, int]) -> dict[int, int]:
        result = dict(base)
        for item_id, count in extra.items():
            result[item_id] = result.get(item_id, 0) + count
        return result

    def _materials_available(self, counts: dict[int, int]) -> bool:
        return all(self.inventory.get_item_num(item_id) >= count for item_id, count in counts.items())

    def _reserve_item(
        self,
        item_id: int,
        reserved: dict[int, int],
        *,
        base_reserved: dict[int, int] | None = None,
        depth: int = 0,
    ) -> int | None:
        """Mirror HeroMainWindow's recursive compose-or-use-one-item decision.

        Returns the additional compose Mana generated by this reservation, or
        ``None`` when source metadata cannot represent the requested item.
        """
        if item_id <= 0 or depth > 32:
            return None
        meta = self._item(item_id)
        if not meta:
            return None
        base_reserved = base_reserved or {}
        already = base_reserved.get(item_id, 0) + reserved.get(item_id, 0)
        compose = [self._int(value) for value in (meta.get("compose") or [])]
        compose_num = [self._int(value) for value in (meta.get("compose_num") or [])]
        has_recipe = bool(compose and compose[0] != 0)

        # Lua logic composes only when every canonical copy is already reserved;
        # otherwise it consumes one existing target item directly.
        if not has_recipe or self.inventory.get_item_num(item_id) > already:
            reserved[item_id] = reserved.get(item_id, 0) + 1
            return 0

        if len(compose_num) < len(compose):
            return None
        mana = max(0, self._int(meta.get("compose_mana"), 0))
        for component, count in zip(compose, compose_num):
            if component <= 0 or count <= 0:
                return None
            for _ in range(count):
                added = self._reserve_item(
                    component,
                    reserved,
                    base_reserved=base_reserved,
                    depth=depth + 1,
                )
                if added is None:
                    return None
                mana += added
        return mana

    def _hero_cap(self) -> int:
        return max(1, self.progression.hero_level_cap())

    def _normalized_exp(self, hero: dict[str, Any]) -> int:
        return self.progression.normalized_total_exp(hero)

    def _exp_needed_for_level(self, hero: dict[str, Any], target_level: int) -> int:
        current_level = max(1, self._int(hero.get("lev"), 1))
        if target_level <= current_level:
            return 0
        threshold = self.progression.total_exp_for_level(target_level - 1)
        return max(0, threshold - self._normalized_exp(hero))

    def _all_potion_exp(self) -> int:
        total = 0
        for item_id in self.potion_ids:
            meta = self._item(item_id)
            total += self.inventory.get_item_num(item_id) * max(0, self._int(meta.get("exp"), 0))
        return total

    def _potion_plan(self, exp_needed: int) -> tuple[dict[int, int], int] | None:
        remaining = max(0, self._int(exp_needed, 0))
        plan: dict[int, int] = {}
        total_exp = 0
        if remaining <= 0:
            return plan, 0
        for item_id in self.potion_ids:
            per_item = max(0, self._int(self._item(item_id).get("exp"), 0))
            count = self.inventory.get_item_num(item_id)
            if per_item <= 0 or count <= 0:
                continue
            if remaining <= count * per_item:
                use = int(math.ceil(remaining / per_item))
                if use > 0:
                    plan[item_id] = use
                    total_exp += use * per_item
                remaining = 0
                break
            plan[item_id] = count
            total_exp += count * per_item
            remaining -= count * per_item
        if remaining > 0:
            return None
        return plan, total_exp

    def _consume_plan(self, items: dict[int, int], potions: dict[int, int], mana: int, hero: dict[str, Any], potion_exp: int) -> bool:
        combined = self._merge_counts(items, potions)
        if not self._materials_available(combined) or max(0, self._int(self.player.mana, 0)) < mana:
            return False
        rows = [{"item_id": item_id, "item_num": count} for item_id, count in combined.items() if count > 0]
        if rows and not self.inventory.consume_items(rows, persist=False):
            return False
        if mana > 0 and not self.economy.spend_mana(mana, persist=False):
            return False
        if potion_exp > 0:
            self.progression.grant_exp_amount(hero.get("partner_id"), potion_exp, persist=False)
        return True

    def set_hero_equip(self, partner_id: Any, equip_index: Any) -> dict[str, Any]:
        hero = self.heroes.get(partner_id)
        index = self._int(equip_index, 0)
        if hero is None or not self._normal_early_boundary(hero) or not (1 <= index <= 6):
            return {"error_code": 1}
        equip_ids = self._equip_ids(hero)
        item_id = equip_ids[index - 1] if len(equip_ids) >= index else 0
        if item_id <= 0 or not self._is_normal_equipment(item_id):
            return {"error_code": 1}
        equips = list(hero.get("equips") or [0, 0, 0, 0, 0, 0])[:6]
        while len(equips) < 6:
            equips.append(0)
        if self._int(equips[index - 1], 0) == 1:
            # Defensive duplicate acknowledgement. The normal UI does not send
            # MID54 for an already-collected slot.
            return {}
        if self.inventory.consume_item(item_id, 1, persist=False) is None:
            return {"error_code": 1}
        equips[index - 1] = 1
        hero["equips"] = equips
        self._save()
        return {}

    def one_click_equip(self, partner_id: Any) -> dict[str, Any]:
        hero = self.heroes.get(partner_id)
        if hero is None or not self._normal_early_boundary(hero):
            return {"error_code": 1}
        equip_ids = self._equip_ids(hero)
        if len(equip_ids) != 6:
            return {"error_code": 1}
        equips = list(hero.get("equips") or [0] * 6)[:6]
        while len(equips) < 6:
            equips.append(0)

        max_level = self._hero_cap()
        current_level = max(1, self._int(hero.get("lev"), 1))
        all_potion_exp = self._all_potion_exp()
        reserved: dict[int, int] = {}
        total_mana = 0
        indexes: list[int] = []
        max_needed_exp = 0

        for slot, item_id in enumerate(equip_ids, start=1):
            if item_id <= 0 or self._int(equips[slot - 1], 0) == 1:
                continue
            item = self._item(item_id)
            item_level = max(0, self._int(item.get("level"), 0))
            if not self._is_normal_equipment(item_id) or item_level > max_level:
                continue

            candidate: dict[int, int] = {}
            candidate_mana = self._reserve_item(item_id, candidate, base_reserved=reserved)
            if candidate_mana is None:
                continue
            combined = self._merge_counts(reserved, candidate)
            if total_mana + candidate_mana > max(0, self._int(self.player.mana, 0)):
                continue
            if not self._materials_available(combined):
                continue

            needed_exp = self._exp_needed_for_level(hero, item_level) if current_level < item_level else 0
            if needed_exp > all_potion_exp:
                continue
            reserved = combined
            total_mana += candidate_mana
            indexes.append(slot)
            max_needed_exp = max(max_needed_exp, needed_exp)

        if not indexes:
            return {"equips": equips}
        potion = self._potion_plan(max_needed_exp)
        if potion is None:
            return {"error_code": 1}
        potion_items, potion_exp = potion
        if not self._consume_plan(reserved, potion_items, total_mana, hero, potion_exp):
            return {"error_code": 1}

        for slot in indexes:
            equips[slot - 1] = 1
        hero["equips"] = equips
        self._save()
        result: dict[str, Any] = {"equips": equips}
        if total_mana > 0:
            result["economy_"] = {"mana": max(0, self._int(self.player.mana, 0))}
        return result

    def one_click_promote(self, partner_id: Any) -> dict[str, Any]:
        hero = self.heroes.get(partner_id)
        if hero is None or not self._normal_early_boundary(hero):
            return {"error_code": 1}
        color = self._int(hero.get("color"), 1)
        if color >= self.MAX_COLOR:
            return {"error_code": 1}
        equip_ids = self._equip_ids(hero)
        if len(equip_ids) != 6:
            return {"error_code": 1}
        equips = list(hero.get("equips") or [0] * 6)[:6]
        while len(equips) < 6:
            equips.append(0)

        # The UI only exposes ONE_CLICK_JINJIE when at least one ordinary slot
        # is missing; already-equipped slots were consumed by earlier MID54/62.
        missing = [
            (slot, item_id)
            for slot, item_id in enumerate(equip_ids, start=1)
            if item_id > 0 and self._int(equips[slot - 1], 0) == 0 and self._is_normal_equipment(item_id)
        ]
        if not missing:
            return {"error_code": 1}

        max_level = self._hero_cap()
        target_level = max(1, self._int(hero.get("lev"), 1))
        reserved: dict[int, int] = {}
        total_mana = 0
        for _slot, item_id in missing:
            item_level = max(0, self._int(self._item(item_id).get("level"), 0))
            if item_level > max_level:
                return {"error_code": 1}
            target_level = max(target_level, item_level)
            added = self._reserve_item(item_id, reserved)
            if added is None:
                return {"error_code": 1}
            total_mana += added

        if total_mana > max(0, self._int(self.player.mana, 0)) or not self._materials_available(reserved):
            return {"error_code": 1}
        potion = self._potion_plan(self._exp_needed_for_level(hero, target_level))
        if potion is None:
            return {"error_code": 1}
        potion_items, potion_exp = potion
        if not self._consume_plan(reserved, potion_items, total_mana, hero, potion_exp):
            return {"error_code": 1}

        hero["color"] = color + 1
        hero["equips"] = [0, 0, 0, 0, 0, 0]
        hero["fumos"] = [0, 0, 0, 0, 0, 0]
        hero["fumo_levels"] = [0, 0, 0, 0, 0, 0]
        self._save()
        result: dict[str, Any] = {"restore_items": []}
        if total_mana > 0:
            result["economy_"] = {"mana": max(0, self._int(self.player.mana, 0))}
        return result

    def _save(self) -> None:
        if self._save_callback:
            self._save_callback()
