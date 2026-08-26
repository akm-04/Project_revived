"""Pure Horcrux strengthening planning for MID3089.

Pass169 H4. Source-derived progression/cost facts come from HorcruxSourceCatalog;
unrecovered ADD/IMPROVE branch policy is the frozen horcrux_policy_v1. This
module never persists player state, debits Mana, or removes fodder.
"""
from __future__ import annotations

import copy
from dataclasses import dataclass
from decimal import Decimal
from typing import Any, Sequence

from gxb_backend.content.horcrux_source_catalog import HorcruxSourceCatalog

from .horcrux_materializer import HorcruxRandomOutcomeAdapter
from .horcrux_policy import HorcruxPolicyRegistry


class HorcruxEnhancementError(ValueError):
    pass


@dataclass(frozen=True)
class HorcruxEnhancementPreview:
    gained_exp: int
    mana_cost: int
    old_exp: int
    stored_exp: int
    old_level: int
    new_level: int
    crossed_milestones: tuple[int, ...]


@dataclass(frozen=True)
class HorcruxEnhancementPlan:
    preview: HorcruxEnhancementPreview
    updated_target: dict[str, Any]


class HorcruxEnhancementPlanner:
    """Deterministic validation + frozen-policy milestone materialization."""

    POLICY_ID = "horcrux_milestone_add_or_improve_balanced_v1"
    OVERFLOW_POLICY_ID = "horcrux_exp_cap_discard_overflow_v1"

    def __init__(
        self,
        source: HorcruxSourceCatalog,
        policy: HorcruxPolicyRegistry,
        random_outcomes: HorcruxRandomOutcomeAdapter,
    ) -> None:
        self.source = source
        self.policy = policy
        self.random_outcomes = random_outcomes
        if self.policy.policy_id("HPD-007") != self.POLICY_ID:
            raise HorcruxEnhancementError("unsupported Horcrux enhancement milestone policy")
        if self.policy.policy_id("HPD-008") != self.OVERFLOW_POLICY_ID:
            raise HorcruxEnhancementError("unsupported Horcrux enhancement overflow policy")

    @staticmethod
    def _int(value: Any, label: str, *, minimum: int | None = None) -> int:
        if isinstance(value, bool):
            raise HorcruxEnhancementError(f"{label} must be an integer")
        try:
            out = int(value)
        except (TypeError, ValueError) as exc:
            raise HorcruxEnhancementError(f"{label} must be an integer") from exc
        if minimum is not None and out < minimum:
            raise HorcruxEnhancementError(f"{label} must be >= {minimum}")
        return out

    @staticmethod
    def _seq(value: Any, label: str) -> list[Any]:
        if not isinstance(value, (list, tuple)):
            raise HorcruxEnhancementError(f"{label} must be a sequence")
        return list(value)

    def _model_for_instance(self, row: dict[str, Any]) -> tuple[dict[str, Any] | Any, int]:
        table_id = self._int(row.get("table_id"), "table_id", minimum=1)
        template = self.source.template(table_id)
        if template is None:
            raise HorcruxEnhancementError(f"unknown Horcrux template {table_id}")
        model_id = self._int(template.get("model_id"), "model_id", minimum=1)
        model = self.source.model(model_id)
        if model is None:
            raise HorcruxEnhancementError(f"unknown Horcrux model {model_id}")
        return model, model_id

    def fodder_exp(self, fodder: dict[str, Any]) -> int:
        model, _ = self._model_for_instance(fodder)
        base = self._int(model.get("exp"), "fodder base EXP", minimum=0)
        stored = self._int(fodder.get("exp", 0), "fodder stored EXP", minimum=0)
        # Source rate is 0.6. Decimal avoids binary-float drift while retaining
        # the client's exact numeric rule. Reachable backend EXP states yield an
        # integer transfer; reject malformed legacy fractions rather than invent
        # rounding policy.
        transferred = Decimal(stored) * Decimal(str(self.source.fodder_exp_rate))
        if transferred != transferred.to_integral_value():
            raise HorcruxEnhancementError("fodder EXP transfer is non-integral")
        return base + int(transferred)

    def preview(self, target: dict[str, Any], fodders: Sequence[dict[str, Any]]) -> HorcruxEnhancementPreview:
        model, _ = self._model_for_instance(target)
        star = self._int(model.get("star"), "target star", minimum=1)
        target_star = self._int(target.get("star", star), "target materialized star", minimum=1)
        if target_star != star:
            raise HorcruxEnhancementError("target star/model mismatch")
        old_exp = self._int(target.get("exp", 0), "target EXP", minimum=0)
        max_exp = self.source.strengthening_max_exp(star)
        if old_exp >= max_exp:
            raise HorcruxEnhancementError("target Horcrux is already at max EXP")
        if not fodders:
            raise HorcruxEnhancementError("at least one fodder Horcrux is required")
        gained_exp = sum(self.fodder_exp(row) for row in fodders)
        if gained_exp <= 0:
            raise HorcruxEnhancementError("fodder grants no strengthening EXP")
        mana_cost = gained_exp * self.source.mana_per_strength_exp
        stored_exp = min(max_exp, old_exp + gained_exp)
        old_level = self.source.strengthening_level_for_exp(star, old_exp)
        new_level = self.source.strengthening_level_for_exp(star, stored_exp)
        crossed = tuple(
            level for level in self.source.strengthening_milestones
            if old_level < level <= new_level
        )
        return HorcruxEnhancementPreview(
            gained_exp=gained_exp,
            mana_cost=mana_cost,
            old_exp=old_exp,
            stored_exp=stored_exp,
            old_level=old_level,
            new_level=new_level,
            crossed_milestones=crossed,
        )

    @staticmethod
    def _aligned(model: Any, key: str) -> list[Any]:
        value = model.get(key) if hasattr(model, "get") else None
        if not isinstance(value, (list, tuple)):
            raise HorcruxEnhancementError(f"Horcrux model lacks {key}")
        return list(value)

    def _validated_secondary_state(self, target: dict[str, Any], model: Any) -> tuple[list[int], list[int], list[Any]]:
        selectors = [self._int(v, "sub selector", minimum=1) for v in self._seq(target.get("sub", []), "sub")]
        attrs = [self._int(v, "sub attr", minimum=1) for v in self._seq(target.get("sub_attr", []), "sub_attr")]
        values = self._seq(target.get("sub_attr_value", []), "sub_attr_value")
        if not (len(selectors) == len(attrs) == len(values)):
            raise HorcruxEnhancementError("target secondary arrays are misaligned")
        source_attrs = self._aligned(model, "sub")
        source_values = self._aligned(model, "sub_value")
        source_strength = self._aligned(model, "sub_strth")
        if not (len(source_attrs) == len(source_values) == len(source_strength)):
            raise HorcruxEnhancementError("source secondary arrays are misaligned")
        for idx, selector in enumerate(selectors):
            if selector > len(source_attrs):
                raise HorcruxEnhancementError("target secondary selector outside source range")
            if attrs[idx] != self._int(source_attrs[selector - 1], "source sub attr", minimum=1):
                raise HorcruxEnhancementError("target secondary attr/selector mismatch")
        return selectors, attrs, copy.deepcopy(values)

    def plan(self, target: dict[str, Any], fodders: Sequence[dict[str, Any]]) -> HorcruxEnhancementPlan:
        preview = self.preview(target, fodders)
        model, _ = self._model_for_instance(target)
        updated = copy.deepcopy(target)

        main_selector = self._int(updated.get("main"), "main selector", minimum=1)
        main_attrs = self._aligned(model, "main")
        main_values = self._aligned(model, "main_value")
        main_strength = self._aligned(model, "main_strth")
        if not (len(main_attrs) == len(main_values) == len(main_strength)) or main_selector > len(main_attrs):
            raise HorcruxEnhancementError("target main selector/source alignment drift")
        source_main_attr = self._int(main_attrs[main_selector - 1], "source main attr", minimum=1)
        materialized_main_attr = self._int(updated.get("main_attr", source_main_attr), "main_attr", minimum=1)
        if materialized_main_attr != source_main_attr:
            raise HorcruxEnhancementError("target main attr/selector mismatch")

        selectors, attrs, values = self._validated_secondary_state(updated, model)
        source_sub_attrs = self._aligned(model, "sub")
        source_sub_values = self._aligned(model, "sub_value")
        source_sub_strength = self._aligned(model, "sub_strth")
        max_subs = self._int(model.get("sub_num"), "sub_num", minimum=0)
        if len(selectors) > max_subs:
            raise HorcruxEnhancementError("target has more secondary entries than source maximum")

        # All structural validation is complete before the first entropy draw.
        for _milestone in preview.crossed_milestones:
            if len(selectors) == 0:
                action = "ADD"
            elif len(selectors) >= max_subs:
                action = "IMPROVE"
            else:
                action = "ADD" if self.random_outcomes.choose_enhance_action() == 0 else "IMPROVE"

            if action == "ADD":
                present = set(selectors)
                absent = [idx for idx in range(1, len(source_sub_attrs) + 1) if idx not in present]
                if not absent:
                    # A malformed legacy row can exhaust selectors before sub_num;
                    # fail rather than invent a replacement policy.
                    raise HorcruxEnhancementError("no absent secondary selector available for ADD")
                pick = 0 if len(absent) == 1 else self.random_outcomes.choose_new_sub(len(absent))
                selector = absent[pick]
                selectors.append(selector)
                attrs.append(self._int(source_sub_attrs[selector - 1], "source sub attr", minimum=1))
                values.append(copy.deepcopy(source_sub_values[selector - 1]))
            else:
                if not selectors:
                    raise HorcruxEnhancementError("IMPROVE selected with no secondary entries")
                pick = 0 if len(selectors) == 1 else self.random_outcomes.choose_improve_target(len(selectors))
                selector = selectors[pick]
                values[pick] = values[pick] + source_sub_strength[selector - 1]

        updated["lev"] = preview.new_level
        updated["exp"] = preview.stored_exp
        updated["star"] = self._int(model.get("star"), "target star", minimum=1)
        updated["main_attr"] = source_main_attr
        updated["main_attr_value"] = main_values[main_selector - 1] + preview.new_level * main_strength[main_selector - 1]
        updated["sub"] = selectors
        updated["sub_attr"] = attrs
        updated["sub_attr_value"] = values
        return HorcruxEnhancementPlan(preview=preview, updated_target=updated)
