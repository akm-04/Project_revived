"""Typed MID50 dispatch registry.

Pass41.4 keeps operation identity source-derived while allowing only the four
runtime-mapped classic paid button topologies under the explicit Custom Private
Server Policy v1. Deferred operations remain fail closed.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from gxb_backend.content.summon_operation_catalog import (
    SummonOperationCatalog,
    SummonOperationDescriptor,
    SummonOperationKey,
)


@dataclass(frozen=True)
class SummonDispatchDecision:
    key: SummonOperationKey
    descriptor: SummonOperationDescriptor | None
    strategy: str | None

    @property
    def supported(self) -> bool:
        return self.descriptor is not None and self.descriptor.supported and bool(self.strategy)


class SummonOperationRegistry:
    _ACTIVE_STRATEGIES = {
        "tutorial_small_free_first": "_tutorial_mana",
        "tutorial_medium_free_first": "_tutorial_crystal",
        "small_paid_1": "_classic_paid",
        "small_paid_10": "_classic_paid",
        "medium_paid_1": "_classic_paid",
        "medium_paid_10": "_classic_paid",
        "sx_soul_box_selector_1": "_sx_private",
        "sx_soul_box_selector_2": "_sx_private",
    }

    def __init__(self, catalog: SummonOperationCatalog) -> None:
        self.catalog = catalog

    def resolve(self, protocol_mid: Any, summon_type: Any, summon_index: Any) -> SummonDispatchDecision:
        try:
            key = SummonOperationKey.create(protocol_mid, summon_type, summon_index)
        except (TypeError, ValueError):
            key = SummonOperationKey(-1, -1, -1)
            return SummonDispatchDecision(key, None, None)
        descriptor = self.catalog.get(key)
        if descriptor is None:
            return SummonDispatchDecision(key, None, None)
        strategy = self._ACTIVE_STRATEGIES.get(descriptor.semantic) if descriptor.supported else None
        return SummonDispatchDecision(key, descriptor, strategy)
