"""Canonical Function state: eligibility is distinct from announcement/open.

``function.lua`` thresholds establish eligibility.  ``new_funcs_`` is a
separate guide-sensitive semantic event and is emitted only by explicit
announcement methods.  Legacy ``PlayerState.func_ids`` remains a compatibility
projection of announced IDs during the migration.
"""
from __future__ import annotations

from collections.abc import Callable, Iterable
from dataclasses import dataclass
from typing import Any

from gxb_backend.content import CatalogNamespace, ContentRef, GameDataCatalog

from .player_state import PlayerState


@dataclass(frozen=True)
class FunctionStateDelta:
    eligible_ids: tuple[int, ...] = ()
    announced_ids: tuple[int, ...] = ()


class FunctionStateRepository:
    SCHEMA_VERSION = 1
    GUIDE_SENSITIVE_POLICIES = {
        33: {"policy": "tutorial_milestone", "milestone": "normal_pre_skill_terminal_fight_committed"},
        31: {"policy": "guide_sensitive_unresolved"},
    }

    def __init__(
        self,
        player: PlayerState,
        catalog: GameDataCatalog,
        save_callback: Callable[[], None] | None = None,
        semantic_callback: Callable[[str, object], None] | None = None,
    ) -> None:
        self.player = player
        self.catalog = catalog
        self._save_callback = save_callback
        self._semantic_callback = semantic_callback
        self.normalize()

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _root(self) -> dict[str, Any]:
        root = self.player.function_state
        if not isinstance(root, dict):
            root = {}
            self.player.function_state = root
        return root

    @staticmethod
    def _clean_ids(raw: Any) -> list[int]:
        if not isinstance(raw, list):
            return []
        out = {FunctionStateRepository._int(value) for value in raw}
        return sorted(value for value in out if value > 0)

    def normalize(self) -> bool:
        root = self._root()
        changed = False
        if self._int(root.get("schema_version"), 0) != self.SCHEMA_VERSION:
            root["schema_version"] = self.SCHEMA_VERSION
            changed = True

        legacy_announced = self._clean_ids(self.player.func_ids)
        announced = self._clean_ids(root.get("announced_ids"))
        # Pass32.5 migration rule: old func_ids are already-announced state.
        if not announced and legacy_announced:
            announced = legacy_announced
            root["announced_ids"] = announced
            changed = True
        elif root.get("announced_ids") != announced:
            root["announced_ids"] = announced
            changed = True

        eligible = self._clean_ids(root.get("eligible_ids"))
        if root.get("eligible_ids") != eligible:
            root["eligible_ids"] = eligible
            changed = True

        pending = root.get("pending")
        if not isinstance(pending, dict):
            pending = {}
            root["pending"] = pending
            changed = True

        # Pass33.1 trust-boundary migration: an eligible-but-unannounced
        # Function33 must wait on a server-authored tutorial milestone. Replace
        # any persisted Pass32.6 raw-guide checkpoint policy in place.
        if 33 in eligible and 33 not in announced:
            policy = dict(self.GUIDE_SENSITIVE_POLICIES[33])
            if pending.get("33") != policy:
                pending["33"] = policy
                changed = True
        elif "33" in pending and 33 in announced:
            pending.pop("33", None)
            changed = True

        if legacy_announced != announced:
            self.player.func_ids = list(announced)
            changed = True
        return changed

    def eligible_ids(self) -> list[int]:
        self.normalize()
        return list(self._root()["eligible_ids"])

    def announced_ids(self) -> list[int]:
        self.normalize()
        return list(self._root()["announced_ids"])

    def _function_rows(self) -> Iterable[tuple[int, dict[str, Any]]]:
        # GameDataCatalog deliberately has no global numeric classifier.  The
        # function namespace is explicit here because this repository owns
        # function state.
        for ref in self.catalog.iter_namespace(CatalogNamespace.FUNCTION):
            row = self.catalog.get(ref)
            yield ref.table_id, dict(row)

    def observe_level_progress(
        self,
        before_level: Any,
        after_level: Any,
        *,
        persist: bool = False,
    ) -> FunctionStateDelta:
        before = max(1, self._int(before_level, 1))
        after = max(before, self._int(after_level, before))
        if after <= before:
            return FunctionStateDelta()

        root = self._root()
        eligible = set(self.eligible_ids())
        announced = set(self.announced_ids())
        pending = root["pending"]
        newly_eligible: list[int] = []
        newly_announced: list[int] = []

        for function_id, row in self._function_rows():
            required = self._int(row.get("eligibility_value", row.get("player_level")), 0)
            kind = self._int(row.get("eligibility_kind", row.get("level_spec_kind")), 0)
            if kind not in {1, 6, 7} or required <= 0:
                continue
            if not (before < required <= after) or function_id in eligible:
                continue
            eligible.add(function_id)
            newly_eligible.append(function_id)
            policy = self.GUIDE_SENSITIVE_POLICIES.get(function_id)
            if policy:
                pending[str(function_id)] = dict(policy)
            elif function_id not in announced:
                announced.add(function_id)
                newly_announced.append(function_id)

        if newly_eligible or newly_announced:
            root["eligible_ids"] = sorted(eligible)
            root["announced_ids"] = sorted(announced)
            self.player.func_ids = sorted(announced)
            for function_id in sorted(newly_announced):
                if self._semantic_callback:
                    self._semantic_callback("new_funcs_", function_id)
            if persist:
                self._save()
        return FunctionStateDelta(tuple(sorted(newly_eligible)), tuple(sorted(newly_announced)))

    # Compatibility façade for old EconomyRepository callers.
    def unlock_crossed_levels(self, before_level: Any, after_level: Any, *, persist: bool = False) -> list[int]:
        return list(self.observe_level_progress(before_level, after_level, persist=persist).announced_ids)

    def announce(self, function_ids: Iterable[Any], *, persist: bool = False) -> list[int]:
        root = self._root()
        eligible = set(self.eligible_ids())
        announced = set(self.announced_ids())
        pending = root["pending"]
        added: list[int] = []
        for raw in function_ids:
            function_id = self._int(raw, 0)
            if function_id <= 0 or function_id not in eligible or function_id in announced:
                continue
            # Explicit table membership guards typo/phantom IDs.
            if not self.catalog.exists(ContentRef(CatalogNamespace.FUNCTION, function_id)):
                continue
            announced.add(function_id)
            pending.pop(str(function_id), None)
            added.append(function_id)
        if added:
            root["announced_ids"] = sorted(announced)
            self.player.func_ids = sorted(announced)
            for function_id in sorted(added):
                if self._semantic_callback:
                    self._semantic_callback("new_funcs_", function_id)
            if persist:
                self._save()
        return sorted(added)

    def _save(self) -> None:
        if self._save_callback:
            self._save_callback()
