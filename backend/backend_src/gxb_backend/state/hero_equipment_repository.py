"""Source-backed normal-Hero equipment and one-click promotion transactions.

Pass182 reconciles the source-backed ordinary NormalHero equipment path:
MID54 SET_HERO_EQUIP, MID62 ONE_CLICK_EQUIP, MID57 ONE_CLICK_JINJIE and
MID51 ordinary color promotion with bounded Fumo restoration. MID57 now
honors the server-projected max_color split: below it one-click promotes; at
or above it one-click equips the current tier only and MID51 performs the
actual promotion.
The client sends only partner/slot identifiers while independently calculating
recursive composition, EXP-juice and Mana costs.  This repository mirrors those
source calculations against canonical Hero/Backpack/Economy state so relog does
not undo the visible client mutation.

Pass207 Stage C extends the same owner for source-special Awakening/Blood gear.
Special slots/Fumo survive promotion exactly as NormalHero.powerUp/oneKeyPowerUp do;
ordinary slots retain the existing restoration/reset semantics.
"""
from __future__ import annotations

import json
import math
from collections.abc import Callable
from pathlib import Path
from typing import Any

from .economy_repository import EconomyRepository
from .fumo_restoration_planner import FumoEquippedSlot, FumoRestorationPlanner, FumoRestorationPolicyError
from .hero_progression_repository import HeroProgressionRepository
from .hero_repository import HeroRepository
from .inventory_repository import InventoryRepository
from .mutation_plan import (
    ActorRef,
    EntityMutation,
    IdempotencySpec,
    MutationOrigin,
    MutationPlan,
    ResourceMutation,
    StackMutation,
)
from .mutation_settlement_service import MutationSettlementError, MutationSettlementService
from .player_state import PlayerState
from .unit_of_work import OperationContext, UnitOfWork


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
        uow: UnitOfWork | None = None,
        settlement: MutationSettlementService | None = None,
        fumo_restoration: FumoRestorationPlanner | None = None,
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
        self._uow = uow
        self._settlement = settlement
        self._fumo_restoration = fumo_restoration
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
        return True

    def _is_normal_equipment(self, item_id: int) -> bool:
        row = self._item(item_id)
        return bool(row) and self._int(row.get("is_awaken_item"), 0) == 0 and self._int(row.get("is_bloodline_item"), 0) == 0

    def promotion_uses_special_equipment(self, hero: dict[str, Any]) -> bool:
        """True when the current source tier contains persistent Awake/Blood gear."""
        return any(item_id > 0 and not self._is_normal_equipment(item_id) for item_id in self._equip_ids(hero))

    def special_equipment_slots(self, hero: dict[str, Any]) -> tuple[int, ...]:
        """Return source-special slot indexes for selective promotion preservation."""
        return tuple(
            index for index, item_id in enumerate(self._equip_ids(hero), start=1)
            if item_id > 0 and not self._is_normal_equipment(item_id)
        )

    def plan_equip_operations(
        self, partner_id: Any, equip_index: Any, *, authorized_special_item: Any | None = None,
        authorized_blood_lineage: bool = False
    ) -> tuple[int, tuple[Any, ...]] | None:
        """Plan one canonical MID54 equipment mutation without opening a UoW.

        Normal callers leave ``authorized_special_item`` unset.  The Stage-C
        Awakening coordinator may authorize exactly the active mission's source
        exclusive gear.  Blood stage1 intentionally reuses the already-collected
        ordinary Awakening slot bit: source client display substitutes the Blood
        item while durable identity changes only when stage2 is claimed.
        """
        hero=self.heroes.get(partner_id); pid=self._int(partner_id,0); index=self._int(equip_index,0)
        if hero is None or not self._normal_early_boundary(hero) or not (1<=index<=6): return None
        equip_ids=self._equip_ids(hero)
        if len(equip_ids)<index: return None
        canonical_item=self._int(equip_ids[index-1],0)
        equips=(list(hero.get("equips") or [])+[0]*6)[:6]
        special=self._int(authorized_special_item,0) if authorized_special_item is not None else 0
        if special>0:
            # The source slot itself must be the persistent ordinary-Awake slot.
            # Ordinary Awakening consumes that canonical item. Blood consumes the
            # active mission's authorized display substitute while preserving the
            # already-collected lineage bit. Do not infer Blood identity solely
            # from item flags: Reo mission 2166001 / gear 21001080 is a recovered
            # source anomaly whose item row lacks is_bloodline_item.
            if canonical_item<=0 or self._is_normal_equipment(canonical_item): return None
            smeta=self._item(special)
            if not smeta: return None
            if authorized_blood_lineage:
                if self._int(equips[index-1],0)!=1: return None
            else:
                if self._is_normal_equipment(special) or canonical_item!=special: return None
            ops:list[Any]=[StackMutation(special,"DEBIT",1)]
            if not authorized_blood_lineage and self._int(equips[index-1],0)==0:
                ops.append(EntityMutation("HERO",pid,"SET_EQUIP_SLOTS",indices=(index,)))
            return special,tuple(ops)
        if canonical_item<=0 or not self._is_normal_equipment(canonical_item) or self._int(equips[index-1],0)==1: return None
        return canonical_item,(StackMutation(canonical_item,"DEBIT",1),EntityMutation("HERO",pid,"SET_EQUIP_SLOTS",indices=(index,)))

    def ordinary_required_slots_complete(self, hero: dict[str, Any]) -> bool:
        """Read-only source predicate used by the Normal-Girl Common gate.

        HeroMainWindow.CheckOneClickJinjie() ignores Awakening/Blood-Awakening
        special items when deciding whether Element Equipment may open at color16.
        Every ordinary required slot whose source item is nonzero must already be
        collected in the Hero's six-slot ``equips`` vector.
        """
        required=self._equip_ids(hero)
        if len(required)!=6:
            return False
        collected=(list(hero.get("equips") or [])+[0]*6)[:6]
        for index,item_id in enumerate(required):
            if item_id>0 and self._is_normal_equipment(item_id) and self._int(collected[index],0)==0:
                return False
        return True

    def _fumo_restoration_plan(self, hero: dict[str, Any]):
        fumos=list(hero.get("fumos") or [])[:6]
        while len(fumos)<6: fumos.append(0)
        if not any(self._int(v,0)>0 for v in fumos):
            return None
        if self._fumo_restoration is None:
            raise FumoRestorationPolicyError("Fumo restoration planner is unavailable")
        equip_ids=self._equip_ids(hero)
        if len(equip_ids)!=6:
            raise FumoRestorationPolicyError("Hero equipment source is incomplete")
        slots=[]
        for item_id,fumo in zip(equip_ids,fumos):
            value=max(0,self._int(fumo,0))
            if value<=0: continue
            row=self._item(item_id); quality=self._int(row.get("quality"),0)
            if item_id<=0:
                raise FumoRestorationPolicyError("Hero equipment source is incomplete")
            if not self._is_normal_equipment(item_id):
                # Stock NormalHero promotion preserves special gear and Fumo;
                # only ordinary slots are restored/reset.
                continue
            slots.append(FumoEquippedSlot(item_id=item_id,item_quality=quality,fumo_value=value))
        return self._fumo_restoration.plan(slots)

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

    def _apply_typed_plan(
        self,
        *,
        mid: int,
        operation: str,
        partner_id: int,
        operations: tuple[Any, ...],
    ) -> bool:
        """Settle one Hero aggregate command inside the request-scoped UoW."""
        if self._uow is None or self._settlement is None:
            return False
        context = OperationContext(
            actor_player_id=str(self.player.player_id),
            protocol_mid=int(mid),
            domain="hero",
            operation_name=str(operation),
            idempotency_key=f"hero:{int(partner_id)}:{operation}",
        )
        try:
            with self._uow.transaction(context):
                plan = MutationPlan(
                    schema_version=1,
                    plan_id=f"hero-equip:{int(mid)}:{int(partner_id)}:{self._uow.current_state_version}",
                    origin=MutationOrigin(domain="hero", operation=str(operation), protocol_mid=int(mid)),
                    actor=ActorRef(player_id=str(self.player.player_id)),
                    expected_state_version=None,
                    idempotency=IdempotencySpec(),
                    preconditions=(),
                    operations=operations,
                )
                self._settlement.apply(plan)
            return True
        except MutationSettlementError:
            return False

    def set_hero_equip(self, partner_id: Any, equip_index: Any) -> dict[str, Any]:
        pid=self._int(partner_id,0)
        planned=self.plan_equip_operations(partner_id,equip_index)
        if planned is None: return {"error_code":1}
        _item_id,ops=planned
        if self._uow is not None and self._settlement is not None:
            ok=self._apply_typed_plan(mid=54,operation="set_hero_equip",partner_id=pid,operations=ops)
            return {} if ok else {"error_code":1}
        # Compatibility-only construction outside RequestServices.
        item_id=self._int(planned[0]); index=self._int(equip_index,0); hero=self.heroes.get(pid)
        if hero is None or self.inventory.consume_item(item_id,1,persist=False) is None: return {"error_code":1}
        equips=(list(hero.get("equips") or [])+[0]*6)[:6]; equips[index-1]=1; hero["equips"]=equips; self._save(); return {}


    def one_click_equip(self, partner_id: Any) -> dict[str, Any]:
        hero = self.heroes.get(partner_id)
        pid = self._int(partner_id, 0)
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

        if self._uow is not None and self._settlement is not None:
            combined = self._merge_counts(reserved, potion_items)
            ops: list[Any] = [
                StackMutation(item_id, "DEBIT", count)
                for item_id, count in sorted(combined.items()) if count > 0
            ]
            if total_mana > 0:
                ops.append(ResourceMutation("mana", "DEBIT", total_mana))
            if potion_exp > 0:
                ops.append(EntityMutation("HERO", pid, "ADD_EXP", amount=potion_exp))
            ops.append(EntityMutation("HERO", pid, "SET_EQUIP_SLOTS", indices=tuple(indexes)))
            if not self._apply_typed_plan(
                mid=62,
                operation="one_click_equip",
                partner_id=pid,
                operations=tuple(ops),
            ):
                return {"error_code": 1}
            refreshed = self.heroes.get(pid) or hero
            return {"equips": list(refreshed.get("equips") or [0] * 6)[:6]}

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
        pid = self._int(partner_id, 0)
        if hero is None or not self._normal_early_boundary(hero):
            return {"error_code": 1}
        color = self._int(hero.get("color"), 1)
        if color >= self.MAX_COLOR:
            return {"error_code": 1}
        # Effective NormalHero.oneKeyPowerUp has two successful MID57 state
        # transitions.  max_color is a server-projected one-click promotion
        # boundary, not the absolute Hero color ceiling: below it MID57 really
        # promotes; at/above it MID57 only collects the current ordinary gear
        # and leaves MID51 to perform the promotion.  Preserve the inherited
        # numeric max_color compatibility value until source evidence recovers
        # the original-server policy.
        promote_now = color < max(0, self._int(self.player.max_color, 0))
        restore_plan = None
        if promote_now:
            try:
                restore_plan = self._fumo_restoration_plan(hero)
            except FumoRestorationPolicyError:
                return {"error_code": 1}
        equip_ids = self._equip_ids(hero)
        if len(equip_ids) != 6:
            return {"error_code": 1}
        equips = list(hero.get("equips") or [0] * 6)[:6]
        while len(equips) < 6:
            equips.append(0)

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

        if self._uow is not None and self._settlement is not None:
            combined = self._merge_counts(reserved, potion_items)
            ops: list[Any] = [
                StackMutation(item_id, "DEBIT", count)
                for item_id, count in sorted(combined.items()) if count > 0
            ]
            if total_mana > 0:
                ops.append(ResourceMutation("mana", "DEBIT", total_mana))
            if potion_exp > 0:
                ops.append(EntityMutation("HERO", pid, "ADD_EXP", amount=potion_exp))
            if promote_now:
                if restore_plan is not None:
                    ops.extend(StackMutation(row.item_id, "CREDIT", row.item_num) for row in restore_plan.awards)
                special_slots=self.special_equipment_slots(hero)
                action="PROMOTE_COLOR_PRESERVE_SPECIAL" if special_slots else "PROMOTE_COLOR"
                ops.append(EntityMutation("HERO", pid, action, amount=1, indices=special_slots))
            else:
                ops.append(EntityMutation("HERO", pid, "SET_EQUIP_SLOTS", indices=tuple(slot for slot, _item_id in missing)))
            if not self._apply_typed_plan(
                mid=57,
                operation="one_click_promote" if promote_now else "one_click_collect_at_max_color",
                partner_id=pid,
                operations=tuple(ops),
            ):
                return {"error_code": 1}
            return {"restore_items": restore_plan.wire_rows() if restore_plan is not None else []}

        if not self._consume_plan(reserved, potion_items, total_mana, hero, potion_exp):
            return {"error_code": 1}
        if promote_now:
            if restore_plan is not None and restore_plan.awards:
                self.inventory.add_items([{"item_id":row.item_id,"item_num":row.item_num} for row in restore_plan.awards],persist=False)
            special_slots=set(self.special_equipment_slots(hero))
            equips0=(list(hero.get("equips") or [])+[0]*6)[:6]; fumos0=(list(hero.get("fumos") or [])+[0]*6)[:6]; levels0=(list(hero.get("fumo_levels") or [])+[0]*6)[:6]
            for i in range(6):
                if i+1 not in special_slots: equips0[i]=0; fumos0[i]=0; levels0[i]=0
            hero["color"] = color + 1; hero["equips"]=equips0; hero["fumos"]=fumos0; hero["fumo_levels"]=levels0
        else:
            for slot, _item_id in missing:
                equips[slot - 1] = 1
            hero["equips"] = equips
        self._save()
        result: dict[str, Any] = {"restore_items": restore_plan.wire_rows() if restore_plan is not None else []}
        if total_mana > 0:
            result["economy_"] = {"mana": max(0, self._int(self.player.mana, 0))}
        return result

    def powerup_hero(self, partner_id: Any) -> dict[str, Any]:
        """MID51 ordinary color promotion after all six gear slots are owned.

        Gear was already consumed by MID54/MID62. NormalHero:powerUp performs
        only the aggregate color transition here; SuperHero's corresponding
        source methods are no-ops and are excluded by the normal boundary.
        """
        hero = self.heroes.get(partner_id)
        pid = self._int(partner_id, 0)
        if hero is None or not self._normal_early_boundary(hero):
            return {"error_code": 1}
        color = self._int(hero.get("color"), 1)
        if color >= self.MAX_COLOR:
            return {"error_code": 1}
        try:
            restore_plan = self._fumo_restoration_plan(hero)
        except FumoRestorationPolicyError:
            return {"error_code": 1}
        equip_ids = self._equip_ids(hero)
        equips = list(hero.get("equips") or [0] * 6)[:6]
        while len(equips) < 6:
            equips.append(0)
        required_slots = [idx for idx, item_id in enumerate(equip_ids, start=1) if item_id > 0]
        if not required_slots or any(self._int(equips[idx - 1], 0) != 1 for idx in required_slots):
            return {"error_code": 1}

        if self._uow is not None and self._settlement is not None:
            ops: list[Any] = []
            if restore_plan is not None:
                ops.extend(StackMutation(row.item_id, "CREDIT", row.item_num) for row in restore_plan.awards)
            special_slots=self.special_equipment_slots(hero)
            action="PROMOTE_COLOR_PRESERVE_SPECIAL" if special_slots else "PROMOTE_COLOR"
            ops.append(EntityMutation("HERO", pid, action, amount=1, indices=special_slots))
            ok = self._apply_typed_plan(
                mid=51,
                operation="powerup_hero",
                partner_id=pid,
                operations=tuple(ops),
            )
            if not ok:
                return {"error_code": 1}
            return {"restore_items": restore_plan.wire_rows()} if restore_plan is not None else {}

        if restore_plan is not None and restore_plan.awards:
            self.inventory.add_items([{"item_id":row.item_id,"item_num":row.item_num} for row in restore_plan.awards],persist=False)
        special_slots=set(self.special_equipment_slots(hero))
        equips0=(list(hero.get("equips") or [])+[0]*6)[:6]; fumos0=(list(hero.get("fumos") or [])+[0]*6)[:6]; levels0=(list(hero.get("fumo_levels") or [])+[0]*6)[:6]
        for i in range(6):
            if i+1 not in special_slots: equips0[i]=0; fumos0[i]=0; levels0[i]=0
        hero["color"] = color + 1; hero["equips"]=equips0; hero["fumos"]=fumos0; hero["fumo_levels"]=levels0
        self._save()
        return {"restore_items": restore_plan.wire_rows()} if restore_plan is not None else {}


    def _save(self) -> None:
        if self._save_callback:
            self._save_callback()
