"""Custom Private Server SX/Soul Box policy and pure planner for Pass42.6."""
from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path

from gxb_backend.content.sx_soul_box_source_catalog import (
    SXSoulBoxItemRow,
    SXSoulBoxSoulCasketRow,
    SXSoulBoxSourceCatalog,
    SXSoulBoxSXCandidate,
)
from .summon_private_policy import SummonRandomSource, SystemSummonRandomSource


SX_CLASS_FULL = "sx_full_hero"
NORMAL_3_FRAGMENT_CLASS = "normal_three_star_fragments"
NORMAL_2_FRAGMENT_CLASS = "normal_two_star_fragments"
ORDINARY_FULL_CLASS = "ordinary_full_hero"
_ALLOWED_CLASSES = (
    SX_CLASS_FULL,
    NORMAL_3_FRAGMENT_CLASS,
    NORMAL_2_FRAGMENT_CLASS,
    ORDINARY_FULL_CLASS,
)


@dataclass(frozen=True)
class SXDynamicSelection:
    outcome_class: str
    hero_table_id: int
    item_num: int | None
    selected_hotspot: bool
    guaranteed: bool
    counter_before: int
    counter_after: int
    source_row_id: int | None = None
    soul_casket_type: int | None = None

    @property
    def full_hero(self) -> bool:
        return self.outcome_class in {SX_CLASS_FULL, ORDINARY_FULL_CLASS}

    @property
    def fragment_item(self) -> bool:
        return self.outcome_class in {NORMAL_3_FRAGMENT_CLASS, NORMAL_2_FRAGMENT_CLASS}


class SXSoulBoxPrivatePolicy:
    DATA_FILE = "sx_soul_box_private_policy.json"

    def __init__(self, data_dir: Path | str, source: SXSoulBoxSourceCatalog) -> None:
        path = Path(data_dir) / self.DATA_FILE
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise RuntimeError(f"cannot load private SX policy {path}: {exc}") from exc
        if not isinstance(raw, dict):
            raise RuntimeError(f"invalid private SX policy: {path}")
        self.meta = dict(raw.get("_meta") or {})
        if int(self.meta.get("schema_version") or 0) != 2:
            raise RuntimeError("Pass42.6 SX private policy must use schema2")
        self.policy_version = str(raw.get("policy_version") or "")
        self._active = frozenset(str(v) for v in self.meta.get("active_semantics") or [])
        op = dict(raw.get("operation") or {})
        if (
            int(op.get("protocol_mid") or 0) != 50
            or int(op.get("summon_type") or 0) != 4
            or tuple(int(v) for v in op.get("selectors") or []) != (1, 2)
            or int(op.get("crystal_cost") or 0) != 388
            or int(op.get("vip_min") or 0) != 9
            or int(op.get("result_count") or 0) != source.configured_result_count
            or int(op.get("static_item_slots") or 0) != len(source.static_pool_ids)
            or int(op.get("dynamic_reward_slots") or 0) != 1
        ):
            raise RuntimeError("private SX operation drifts from recovered client/source contract")
        self.crystal_cost = int(op["crystal_cost"])
        self.vip_min = int(op["vip_min"])
        self.result_count = int(op["result_count"])

        static = dict(raw.get("static_slots") or {})
        self.static_pool_ids = tuple(int(v) for v in static.get("pool_ids") or [])
        if self.static_pool_ids != source.static_pool_ids:
            raise RuntimeError("private SX static pools drift from recovered source")

        dynamic = dict(raw.get("dynamic_reward_slot") or {})
        self.class_weight_total = int(dynamic.get("class_weight_total") or 0)
        configured = dict(dynamic.get("class_weights") or {})
        if set(configured) != set(_ALLOWED_CLASSES):
            raise RuntimeError("SX private dynamic class set drift")
        self.class_weights = {name: int(configured[name]) for name in _ALLOWED_CLASSES}
        if self.class_weight_total <= 0 or any(weight < 0 for weight in self.class_weights.values()):
            raise RuntimeError("SX dynamic class weights are invalid")
        if sum(self.class_weights.values()) != self.class_weight_total:
            raise RuntimeError("SX dynamic class weights must sum to class_weight_total")
        classes = dict(dynamic.get("classes") or {})
        sx_class = dict(classes.get(SX_CLASS_FULL) or {})
        self.sx_fallback_weight = int(sx_class.get("newer_candidate_fallback_weight") or 0)
        if self.sx_fallback_weight <= 0:
            raise RuntimeError("SX current-roster fallback weight must be positive")

        hotspot = dict(raw.get("hotspot_policy") or {})
        self.hotspot_share_per_10000 = int(hotspot.get("selected_hotspot_share_within_sx_class_per_10000") or 0)
        self.guarantee_purchases = int(hotspot.get("guarantee_purchases") or 0)
        self.counter_key = str(hotspot.get("pity_counter_key") or "")
        self.counter_target_key = str(hotspot.get("counter_target_key") or "")
        self.source_max_num = int(hotspot.get("source_max_num") or 0)
        if not (0 <= self.hotspot_share_per_10000 <= 10000):
            raise RuntimeError("SX private hotspot share is outside 0..10000")
        if self.guarantee_purchases <= 0 or self.source_max_num <= 0 or self.guarantee_purchases > self.source_max_num:
            raise RuntimeError("SX private guarantee/source max relationship is invalid")
        if not self.counter_key or not self.counter_target_key or not self.policy_version:
            raise RuntimeError("SX private policy lacks counter/version identity")

        overrides = dict(raw.get("balance_overrides") or {})
        class_overrides = dict(overrides.get("class_weight_overrides") or {})
        for name, weight in class_overrides.items():
            if name not in _ALLOWED_CLASSES or int(weight) < 0:
                raise RuntimeError("SX private class-weight override is invalid")
            self.class_weights[name] = int(weight)
        if sum(self.class_weights.values()) <= 0:
            raise RuntimeError("SX effective class weights have no positive mass")

        self.item_weight_overrides: dict[int, dict[int, int]] = {}
        for raw_pool_id, raw_rows in dict(overrides.get("static_item_row_weight_overrides") or {}).items():
            pool_id = int(raw_pool_id)
            if pool_id not in self.static_pool_ids or not isinstance(raw_rows, dict):
                raise RuntimeError("SX private item-weight override references invalid pool")
            valid_row_ids = {row.row_id for row in source.pool(pool_id).rows}
            parsed: dict[int, int] = {}
            for raw_row_id, raw_weight in raw_rows.items():
                row_id, weight = int(raw_row_id), int(raw_weight)
                if row_id not in valid_row_ids or weight < 0:
                    raise RuntimeError("SX private item-weight override is invalid")
                parsed[row_id] = weight
            self.item_weight_overrides[pool_id] = parsed

        self.sx_candidate_weight_overrides: dict[int, int] = {}
        for raw_hero_id, raw_weight in dict(overrides.get("sx_candidate_weight_overrides") or {}).items():
            hero_id, weight = int(raw_hero_id), int(raw_weight)
            if source.sx_candidate(hero_id) is None or weight < 0:
                raise RuntimeError("SX private current-SX candidate override is invalid")
            self.sx_candidate_weight_overrides[hero_id] = weight

        self.soul_row_weight_overrides: dict[int, dict[int, int]] = {}
        for raw_type, raw_rows in dict(overrides.get("soul_casket_row_weight_overrides") or {}).items():
            type_id = int(raw_type)
            if type_id not in {2, 5, 6} or not isinstance(raw_rows, dict):
                raise RuntimeError("SX Soul-Casket row override references inactive/invalid class")
            valid = {row.source_row_id for row in source.positive_class_rows(type_id)}
            parsed: dict[int, int] = {}
            for raw_row_id, raw_weight in raw_rows.items():
                row_id, weight = int(raw_row_id), int(raw_weight)
                if row_id not in valid or weight < 0:
                    raise RuntimeError("SX Soul-Casket row override is invalid")
                parsed[row_id] = weight
            self.soul_row_weight_overrides[type_id] = parsed

        retry = dict(raw.get("retry_policy") or {})
        self.retry_window_ms = max(0, int(retry.get("window_ms") or 0))

    def active(self, semantic: str) -> bool:
        return str(semantic) in self._active

    def item_weight(self, pool_id: int, row: SXSoulBoxItemRow) -> int:
        return int(self.item_weight_overrides.get(int(pool_id), {}).get(int(row.row_id), row.weight))

    def sx_candidate_weight(self, row: SXSoulBoxSXCandidate) -> int:
        if row.hero_table_id in self.sx_candidate_weight_overrides:
            return int(self.sx_candidate_weight_overrides[row.hero_table_id])
        if row.historical_type1_positive_weight is not None:
            return int(row.historical_type1_positive_weight)
        return int(self.sx_fallback_weight)

    def soul_row_weight(self, row: SXSoulBoxSoulCasketRow) -> int:
        return int(
            self.soul_row_weight_overrides.get(int(row.soul_casket_type), {}).get(
                int(row.source_row_id), row.weight
            )
        )


class SXSoulBoxPrivatePlanner:
    def __init__(
        self,
        source: SXSoulBoxSourceCatalog,
        policy: SXSoulBoxPrivatePolicy,
        random_source: SummonRandomSource | None = None,
    ) -> None:
        self.source = source
        self.policy = policy
        self.random = random_source or SystemSummonRandomSource()

    def _weighted_pick(self, rows, weight_getter, *, error: str):
        rows = tuple(rows)
        total = sum(max(0, int(weight_getter(row))) for row in rows)
        if not rows or total <= 0:
            raise RuntimeError(error)
        roll = self.random.randbelow(total)
        cursor = 0
        for row in rows:
            cursor += max(0, int(weight_getter(row)))
            if roll < cursor:
                return row
        raise RuntimeError(f"{error}: weighted selection overflow")

    def pick_static_item(self, pool_id: int) -> SXSoulBoxItemRow:
        pool = self.source.pool(pool_id)
        return self._weighted_pick(
            pool.rows,
            lambda row: self.policy.item_weight(pool_id, row),
            error=f"SX item pool {pool_id} has no positive weight",
        )

    def _pick_class(self) -> str:
        rows = tuple((name, int(self.policy.class_weights[name])) for name in _ALLOWED_CLASSES)
        total = sum(max(0, weight) for _, weight in rows)
        if total <= 0:
            raise RuntimeError("SX dynamic class policy has no positive weight")
        roll = self.random.randbelow(total)
        cursor = 0
        for name, weight in rows:
            cursor += max(0, weight)
            if roll < cursor:
                return name
        raise RuntimeError("SX dynamic class weighted selection overflow")

    def _pick_sx_candidate(self, *, selected_hotspot_id: int, force_selected: bool) -> SXSoulBoxSXCandidate:
        selected = self.source.sx_candidate(selected_hotspot_id)
        if selected is None:
            raise RuntimeError("selected SX hotspot is not current partner.is_sx")
        if force_selected or self.random.randbelow(10000) < self.policy.hotspot_share_per_10000:
            return selected
        rows = tuple(row for row in self.source.sx_candidates() if row.hero_table_id != selected.hero_table_id)
        return self._weighted_pick(
            rows,
            self.policy.sx_candidate_weight,
            error="SX non-hotspot current-SX population is empty",
        )

    def _pick_soul_row(self, type_id: int) -> SXSoulBoxSoulCasketRow:
        return self._weighted_pick(
            self.source.positive_class_rows(type_id),
            self.policy.soul_row_weight,
            error=f"SX Soul-Casket type{type_id} has no positive active row",
        )

    def _pick_quantity(self, row: SXSoulBoxSoulCasketRow) -> int:
        quantities = row.quantity_choices()
        rates = row.quantity_rates()
        if not quantities:
            raise RuntimeError(f"SX Soul-Casket row {row.source_row_id} has no positive quantity")
        if len(quantities) == 1:
            return int(quantities[0])
        if len(rates) != len(quantities) or sum(rates) <= 0:
            raise RuntimeError(f"SX Soul-Casket row {row.source_row_id} quantity-rate shape is invalid")
        roll = self.random.randbelow(sum(rates))
        cursor = 0
        for quantity, rate in zip(quantities, rates):
            cursor += max(0, int(rate))
            if roll < cursor:
                return int(quantity)
        raise RuntimeError("SX quantity weighted selection overflow")

    def pick_dynamic_reward(self, *, selected_hotspot_id: int, counter_before: int) -> SXDynamicSelection:
        if not self.source.is_current_sx(selected_hotspot_id):
            raise RuntimeError("selected SX hotspot is not current partner.is_sx")
        before = max(0, int(counter_before))
        guaranteed = before + 1 >= self.policy.guarantee_purchases
        outcome_class = SX_CLASS_FULL if guaranteed else self._pick_class()

        if outcome_class == SX_CLASS_FULL:
            candidate = self._pick_sx_candidate(
                selected_hotspot_id=selected_hotspot_id,
                force_selected=guaranteed,
            )
            selected = candidate.hero_table_id == int(selected_hotspot_id)
            after = 0 if selected else before + 1
            return SXDynamicSelection(
                outcome_class=outcome_class,
                hero_table_id=int(candidate.hero_table_id),
                item_num=None,
                selected_hotspot=selected,
                guaranteed=bool(guaranteed),
                counter_before=before,
                counter_after=after,
                source_row_id=candidate.historical_type1_source_row_id,
                soul_casket_type=1,
            )

        if outcome_class == NORMAL_3_FRAGMENT_CLASS:
            row = self._pick_soul_row(2)
            quantity = self._pick_quantity(row)
        elif outcome_class == NORMAL_2_FRAGMENT_CLASS:
            row = self._pick_soul_row(5)
            quantity = self._pick_quantity(row)
        elif outcome_class == ORDINARY_FULL_CLASS:
            row = self._pick_soul_row(6)
            quantity = None
        else:  # pragma: no cover - class set validated at startup
            raise RuntimeError(f"unsupported SX dynamic outcome class {outcome_class}")
        return SXDynamicSelection(
            outcome_class=outcome_class,
            hero_table_id=int(row.hero_table_id),
            item_num=(int(quantity) if quantity is not None else None),
            selected_hotspot=False,
            guaranteed=False,
            counter_before=before,
            counter_after=before + 1,
            source_row_id=int(row.source_row_id),
            soul_casket_type=int(row.soul_casket_type),
        )
