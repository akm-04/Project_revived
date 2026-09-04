"""Pure P0 compatibility planner for ordinary Hero Fumo restoration."""
from __future__ import annotations

from dataclasses import dataclass
from fractions import Fraction
from typing import Iterable

from gxb_backend.content.fumo_restoration_source_catalog import FumoRestorationSourceCatalog


class FumoRestorationPolicyError(ValueError):
    pass


@dataclass(frozen=True)
class FumoEquippedSlot:
    item_id: int
    item_quality: int
    fumo_value: int


@dataclass(frozen=True)
class FumoRestorationAward:
    item_id: int
    item_num: int


@dataclass(frozen=True)
class FumoRestorationPlan:
    refundable_value: int
    discarded_residual: int
    awards: tuple[FumoRestorationAward, ...]

    def wire_rows(self) -> list[dict[str, int]]:
        return [{"table_id": row.item_id, "item_num": row.item_num} for row in self.awards]


class FumoRestorationPlanner:
    """Convert lost Fumo to returned enchantment books.

    SOURCE_FACT supplies the per-quality coefficients and 200/60/10 materials.
    COMPATIBILITY_POLICY V1 aggregates exact rational refundable value across all
    lost slots, floors once, then greedily decomposes in source material order.
    Any remainder smaller than the smallest denomination is intentionally lost.
    """

    POLICY_ID = "P0_FUMO_RESTORE_V1_AGGREGATE_FLOOR_GREEDY_SOURCE_ORDER"

    def __init__(self, source: FumoRestorationSourceCatalog) -> None:
        self.source = source

    def plan(self, slots: Iterable[FumoEquippedSlot], *, multiplier: int = 1) -> FumoRestorationPlan:
        if isinstance(multiplier, bool) or int(multiplier) <= 0:
            raise FumoRestorationPolicyError("restoration multiplier must be positive")
        total = Fraction(0, 1)
        for slot in slots:
            fumo = int(slot.fumo_value)
            if fumo < 0:
                raise FumoRestorationPolicyError("Fumo value cannot be negative")
            if fumo == 0:
                continue
            coefficient = self.source.fraction_for_quality(slot.item_quality)
            if coefficient is None:
                raise FumoRestorationPolicyError(
                    f"no source restoration coefficient for equipment quality {slot.item_quality}"
                )
            if int(slot.item_id) <= 0:
                raise FumoRestorationPolicyError("restored Fumo slot lacks equipment item")
            total += fumo * coefficient
        refundable = (total.numerator // total.denominator) * int(multiplier)
        remaining = refundable
        awards: list[FumoRestorationAward] = []
        for material in sorted(self.source.materials, key=lambda row: row.ordinal):
            count, remaining = divmod(remaining, material.enchant_value)
            if count > 0:
                awards.append(FumoRestorationAward(material.item_id, count))
        return FumoRestorationPlan(
            refundable_value=refundable,
            discarded_residual=remaining,
            awards=tuple(awards),
        )
