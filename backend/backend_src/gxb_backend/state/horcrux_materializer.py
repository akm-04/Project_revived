"""Horcrux generated-instance materialization and Gift/MID241 compatibility adapter.

Pass168 H3.  RandomOutcomeService owns entropy mechanics only; this module owns
Horcrux-specific candidate interpretation, materialization, and the bounded
9199043 compatibility overlay.  Gift/dropbox *template selection* remains in
GiftOpeningPlanner under ``gift.open``; Horcrux generation begins only after a
source-authorized type-24 template intent exists.
"""
from __future__ import annotations

from typing import Any, Sequence

from gxb_backend.content import CatalogNamespace, ContentRef
from gxb_backend.content.gift_opening_source_catalog import (
    GiftOpeningDropCandidate,
    GiftOpeningDropOccurrence,
    GiftOpeningOperation,
)
from gxb_backend.content.horcrux_source_catalog import HorcruxSourceCatalog

from .horcrux_policy import HorcruxPolicyRegistry
from .horcrux_repository import HorcruxRepository
from .random_outcome_service import RandomOutcomeService
from .reward_transaction_service import SpecializedGrant


class HorcruxMaterializationError(ValueError):
    pass


class HorcruxRandomOutcomeAdapter:
    """Thin namespace binding for the frozen Pass164 Horcrux RNG topology."""

    MAIN = "horcrux.generate.main"
    SUB_COUNT = "horcrux.generate.sub_count"
    SUB_SELECTOR = "horcrux.generate.sub_selector"
    ENHANCE_ACTION = "horcrux.enhance.action"
    ENHANCE_NEW_SUB = "horcrux.enhance.new_sub"
    ENHANCE_IMPROVE_TARGET = "horcrux.enhance.improve_target"

    def __init__(self, service: RandomOutcomeService) -> None:
        if not isinstance(service, RandomOutcomeService):
            raise TypeError("service must be a RandomOutcomeService")
        self._service = service

    def choose_main(self, size: int) -> int:
        return self._service.choose_index(self.MAIN, size)

    def choose_sub_count(self, weights: Sequence[int]) -> int:
        return self._service.weighted_index(self.SUB_COUNT, weights)

    def choose_sub_selector(self, size: int) -> int:
        return self._service.choose_index(self.SUB_SELECTOR, size)

    def choose_enhance_action(self) -> int:
        return self._service.randbelow(self.ENHANCE_ACTION, 2)

    def choose_new_sub(self, size: int) -> int:
        return self._service.choose_index(self.ENHANCE_NEW_SUB, size)

    def choose_improve_target(self, size: int) -> int:
        return self._service.choose_index(self.ENHANCE_IMPROVE_TARGET, size)


class HorcruxMaterializer:
    """Materialize one fresh unique Horcrux from one type-24 template intent."""

    def __init__(
        self,
        source: HorcruxSourceCatalog,
        policy: HorcruxPolicyRegistry,
        random_outcomes: HorcruxRandomOutcomeAdapter,
    ) -> None:
        self.source = source
        self.policy = policy
        self.random_outcomes = random_outcomes

    @staticmethod
    def _as_int(value: Any, label: str) -> int:
        if isinstance(value, bool):
            raise HorcruxMaterializationError(f"{label} must be an integer")
        try:
            return int(value)
        except (TypeError, ValueError) as exc:
            raise HorcruxMaterializationError(f"{label} must be an integer") from exc

    def validate_template(self, table_id: Any) -> int:
        table_id = self._as_int(table_id, "table_id")
        template = self.source.template(table_id)
        if template is None:
            raise HorcruxMaterializationError(f"unknown Horcrux template {table_id}")
        model_id = self._as_int(template.get("model_id"), "model_id")
        if self.source.model(model_id) is None:
            raise HorcruxMaterializationError(f"Horcrux template {table_id} references unknown model {model_id}")
        return table_id

    @staticmethod
    def _aligned(model: dict[str, Any] | Any, key: str) -> tuple[Any, ...]:
        value = model.get(key) if hasattr(model, "get") else None
        if not isinstance(value, (list, tuple)):
            raise HorcruxMaterializationError(f"Horcrux model lacks {key}")
        return tuple(value)

    def materialize(self, table_id: Any) -> dict[str, Any]:
        table_id = self.validate_template(table_id)
        template = self.source.template(table_id)
        assert template is not None
        model_id = self._as_int(template.get("model_id"), "model_id")
        model = self.source.model(model_id)
        assert model is not None

        main_attrs = self._aligned(model, "main")
        main_values = self._aligned(model, "main_value")
        if not main_attrs or len(main_attrs) != len(main_values):
            raise HorcruxMaterializationError("Horcrux main candidate/value alignment drift")
        main_zero = 0 if len(main_attrs) == 1 else self.random_outcomes.choose_main(len(main_attrs))
        main_selector = main_zero + 1  # source SpiritTable selectors are 1-based.

        sub_attrs = self._aligned(model, "sub")
        sub_values = self._aligned(model, "sub_value")
        sub_rates = tuple(self._as_int(v, "sub_num_rate") for v in self._aligned(model, "sub_num_rate"))
        sub_num = self._as_int(model.get("sub_num"), "sub_num")
        if len(sub_rates) != sub_num + 1 or not sub_attrs or len(sub_attrs) != len(sub_values):
            raise HorcruxMaterializationError("Horcrux secondary source alignment drift")

        # Frozen Pass164 compatibility policy: weighted positional support
        # 0..sub_num.  A source-forced count consumes no entropy.
        positive_counts = [index for index, weight in enumerate(sub_rates) if weight > 0]
        if not positive_counts:
            raise HorcruxMaterializationError("Horcrux secondary-count weights are all zero")
        sub_count = (
            positive_counts[0]
            if len(positive_counts) == 1
            else self.random_outcomes.choose_sub_count(sub_rates)
        )
        if sub_count < 0 or sub_count > sub_num or sub_count > len(sub_attrs):
            raise HorcruxMaterializationError("Horcrux secondary-count selection outside source bounds")

        eligible = list(range(len(sub_attrs)))
        selectors: list[int] = []
        materialized_sub_attrs: list[int] = []
        materialized_sub_values: list[Any] = []
        for _ in range(sub_count):
            local = 0 if len(eligible) == 1 else self.random_outcomes.choose_sub_selector(len(eligible))
            source_zero = eligible.pop(local)
            selectors.append(source_zero + 1)  # source SpiritTable selectors are 1-based.
            materialized_sub_attrs.append(self._as_int(sub_attrs[source_zero], "sub_attr"))
            materialized_sub_values.append(sub_values[source_zero])

        return {
            "table_id": table_id,
            "star": self._as_int(model.get("star"), "star"),
            "lev": 0,
            "exp": 0,
            "main": main_selector,
            "main_attr": self._as_int(main_attrs[main_zero], "main_attr"),
            "main_attr_value": main_values[main_zero],
            "sub": selectors,
            "sub_attr": materialized_sub_attrs,
            "sub_attr_value": materialized_sub_values,
            "is_equip": 0,
            "is_lock": 0,
            "collo_count": 0,
        }


class HorcruxGeneratedRewardOwner:
    """RewardTransactionService specialized owner for generated ``SPIRIT`` grants."""

    OWNER = "SPIRIT"

    def __init__(self, materializer: HorcruxMaterializer, repository: HorcruxRepository) -> None:
        self.materializer = materializer
        self.repository = repository

    def validate_grant(self, grant: SpecializedGrant) -> None:
        if str(grant.owner) != self.OWNER:
            raise HorcruxMaterializationError("wrong specialized owner for Horcrux grant")
        if CatalogNamespace(grant.content.namespace) is not CatalogNamespace.ITEM:
            raise HorcruxMaterializationError("Horcrux generated grant must use ITEM namespace")
        self.materializer.validate_template(grant.content.table_id)
        if isinstance(grant.amount, bool) or int(grant.amount) <= 0:
            raise HorcruxMaterializationError("Horcrux generated grant amount must be positive")

    def apply_grant(self, grant: SpecializedGrant) -> list[dict[str, Any]]:
        self.validate_grant(grant)
        rows: list[dict[str, Any]] = []
        for _ in range(int(grant.amount)):
            rows.append(self.repository.add_instance(self.materializer.materialize(grant.content.table_id)))
        return rows


class HorcruxGiftRewardAdapter:
    """Bounded MID241 adapter for source-authorized type-24 gift intents.

    This object does not draw from ``gift.open``.  It only tells GiftOpeningPlanner
    which type-24 template intents are source/policy valid and supplies the
    Pass164 compatibility overlay for malformed dropbox 9199043.
    """

    OWNER = HorcruxGeneratedRewardOwner.OWNER
    GENERATED_CAPABILITY = "GENERATED_HUNQI_DEPENDENCY"
    OVERLAY_CAPABILITY = "HUNQI_WITH_MISSING_ITEM_DEFS"
    SUPPORTED_CAPABILITIES = frozenset({GENERATED_CAPABILITY, OVERLAY_CAPABILITY})
    CORRUPT_DROPBOX = 9199043

    def __init__(self, source: HorcruxSourceCatalog, policy: HorcruxPolicyRegistry) -> None:
        self.source = source
        self.policy = policy

    def supports(self, operation: GiftOpeningOperation) -> bool:
        return str(operation.capability) in self.SUPPORTED_CAPABILITIES

    def validate_template(self, item_id: Any) -> int:
        try:
            item_id = int(item_id)
        except (TypeError, ValueError) as exc:
            raise HorcruxMaterializationError("generated Gift template id must be an integer") from exc
        if self.source.template(item_id) is None:
            raise HorcruxMaterializationError(f"generated Gift references unknown Horcrux template {item_id}")
        return item_id

    def deterministic_templates(self, operation: GiftOpeningOperation) -> tuple[int, ...]:
        if operation.status != "DETERMINISTIC" or operation.drop_occurrences:
            raise HorcruxMaterializationError("generated deterministic Gift source shape drift")
        # Type-24 gift rows use item=<template> and item_num=0/absent because the
        # output is a unique instance rather than a stack.  Each listed template
        # therefore means one instance per consumed gift copy.
        items = tuple(self.validate_template(v) for v in operation.raw_items if int(v) > 0)
        if not items:
            raise HorcruxMaterializationError("generated deterministic Gift has no Horcrux template intent")
        if operation.raw_item_nums and any(int(v) not in (0, 1) for v in operation.raw_item_nums):
            raise HorcruxMaterializationError("unexpected stack quantity on generated Horcrux Gift")
        return items

    def effective_candidates(self, occurrence: GiftOpeningDropOccurrence) -> tuple[GiftOpeningDropCandidate, ...]:
        if int(occurrence.dropbox_id) != self.CORRUPT_DROPBOX:
            candidates = tuple(occurrence.candidates)
        else:
            overlay = self.policy.anomaly_overlay("dropbox_9199043")
            if overlay is None:
                raise HorcruxMaterializationError("9199043 compatibility overlay missing")
            ids = tuple(int(v) for v in overlay.get("effective_candidates") or ())
            weights = tuple(int(v) for v in overlay.get("effective_weights") or ())
            if len(ids) != 12 or len(weights) != 12 or sum(weights) != 1000:
                raise HorcruxMaterializationError("9199043 compatibility overlay drift")
            candidates = tuple(
                GiftOpeningDropCandidate(
                    source_ordinal=index,
                    row_id=int(occurrence.dropbox_id) * 100 + index,
                    item_id=item_id,
                    item_num=1,
                    drop_rate=weights[index],
                    roll_type=1,
                    item_type=24,
                )
                for index, item_id in enumerate(ids)
            )
        for candidate in candidates:
            self.validate_template(candidate.item_id)
            if int(candidate.item_num) <= 0 or int(candidate.drop_rate) < 0 or int(candidate.roll_type) != 1:
                raise HorcruxMaterializationError("generated random Gift candidate source shape drift")
            if int(candidate.item_type or 0) != 24:
                raise HorcruxMaterializationError("generated random Gift candidate is not source-confirmed type24")
        return candidates

    def grant(self, item_id: int, amount: int) -> SpecializedGrant:
        self.validate_template(item_id)
        return SpecializedGrant(
            owner=self.OWNER,
            content=ContentRef(CatalogNamespace.ITEM, int(item_id)),
            amount=int(amount),
        )
