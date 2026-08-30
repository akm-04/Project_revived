"""Typed request-scoped global response semantics.

Domains stage only source-confirmed semantic intents.  Wave B keeps staging
separate from wire assembly: committed semantic channels are validated against
the immutable synchronization registry, profile-gated, and projected from
canonical post-commit owners.  No whole-PlayerState diffing occurs here.
"""
from __future__ import annotations

from typing import Any

from gxb_backend.synchronization import SynchronizationCatalogs

from .player_state import PlayerState
from .unit_of_work import UnitOfWork


class GlobalResponseSemantics:
    """Narrow domain-facing staging facade for global client response buses."""

    def __init__(self, player: PlayerState, uow: UnitOfWork) -> None:
        self.player = player
        self.uow = uow

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def stage_skill_point(self) -> None:
        self.uow.stage_semantic(
            "economy_",
            {"skill_point": max(0, self._int(self.player.skill_point))},
        )

    def mark_redmark_dirty(self, function_id: Any) -> None:
        fid = self._int(function_id)
        if fid > 0:
            self.uow.stage_semantic("redmarks_", fid)


class GlobalSemanticEnvelopeAssembler:
    """Merge committed semantic intents into an HTTP handler payload.

    The immutable channel registry is the allow-list. Unknown channels are
    consumed and dropped fail-closed rather than becoming accidental wire API.
    Explicit handler fields are preserved; only staged additions are profile
    gated.  Derived dirty redmark families replace any explicit stale row.
    """

    def __init__(
        self,
        player: PlayerState,
        uow: UnitOfWork,
        catalogs: SynchronizationCatalogs,
        redmarks: Any,
    ) -> None:
        self.player = player
        self.uow = uow
        self.catalogs = catalogs
        self.redmarks = redmarks

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    @staticmethod
    def _allowed(profile: Any, channel: str) -> bool:
        if profile is None:
            return True
        fields = getattr(profile, "global_fields", frozenset())
        return channel in fields

    def _merge_economy(self, result: dict[str, Any], values: list[object]) -> None:
        if not values:
            return
        merged = dict(result.get("economy_")) if isinstance(result.get("economy_"), dict) else {}
        for row in values:
            if isinstance(row, dict):
                merged.update(row)
        if not merged:
            return
        if "skill_point" in merged:
            merged["skill_point"] = max(0, self._int(self.player.skill_point))
        result["economy_"] = merged

    def _merge_new_funcs(self, result: dict[str, Any], values: list[object]) -> None:
        if not values:
            return
        existing = result.get("new_funcs_") if isinstance(result.get("new_funcs_"), list) else []
        funcs: set[int] = set()
        for raw in [*existing, *values]:
            value = self._int(raw)
            if value > 0:
                funcs.add(value)
        if funcs:
            result["new_funcs_"] = sorted(funcs)

    def _existing_redmarks(self, raw: Any) -> dict[str, dict[str, Any]]:
        out: dict[str, dict[str, Any]] = {}
        rows = raw.values() if isinstance(raw, dict) else raw if isinstance(raw, list) else []
        for value in rows:
            if not isinstance(value, dict):
                continue
            fid = self._int(value.get("function_id"))
            if fid > 0:
                marks = value.get("redmark_list") if isinstance(value.get("redmark_list"), list) else []
                out[str(fid)] = {"function_id": fid, "redmark_list": [self._int(mark) for mark in marks if self._int(mark) > 0]}
        return out

    def _merge_redmarks(self, result: dict[str, Any], values: list[object]) -> None:
        dirty: set[int] = set()
        for raw in values:
            if isinstance(raw, dict):
                fid = self._int(raw.get("function_id"))
            else:
                fid = self._int(raw)
            if fid > 0:
                dirty.add(fid)
        if not dirty:
            return
        merged = self._existing_redmarks(result.get("redmarks_"))
        # Current Backend.lua directly indexes redmarks_[tostring(97)], so the
        # response-wide sideband is deliberately a string-keyed family map.
        merged.update(self.redmarks.sideband(dirty))
        result["redmarks_"] = merged

    def apply(self, payload: Any, *, profile: Any = None) -> Any:
        deltas = self.uow.consume_semantic()
        if not deltas:
            return payload
        known = {row.channel for row in self.catalogs.semantic_channels()}
        unknown = sorted(set(deltas) - known)
        if unknown:
            print(f"[SEMANTIC] dropped unknown committed channel(s): {unknown}")
        if not isinstance(payload, dict):
            # Consume-once semantics must never bleed into a later request even
            # when a legacy scalar handler cannot carry the global envelope.
            return payload
        result = dict(payload)
        if self._allowed(profile, "economy_"):
            self._merge_economy(result, deltas.get("economy_", []))
        if self._allowed(profile, "new_funcs_"):
            self._merge_new_funcs(result, deltas.get("new_funcs_", []))
        if self._allowed(profile, "redmarks_"):
            self._merge_redmarks(result, deltas.get("redmarks_", []))
        return result
