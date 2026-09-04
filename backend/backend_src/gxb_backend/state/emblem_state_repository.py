"""Canonical server-only Emblem control-state owner.

Pass244 I3 activates durable Scholarship counters and latest-proposal machinery
while public Forge/Reforge protocol routes remain fenced.
"""
from __future__ import annotations

import copy
from typing import Any

from gxb_backend.content.emblem_source_catalog import EmblemSourceCatalog

from .emblem_policy import EmblemPolicyRegistry
from .player_state import PlayerState
from .unit_of_work import UnitOfWork


class EmblemStateError(ValueError):
    pass


class EmblemStateRepository:
    STATE_SCHEMA_VERSION = 1

    def __init__(
        self,
        player: PlayerState,
        source: EmblemSourceCatalog,
        policy: EmblemPolicyRegistry,
        *,
        uow: UnitOfWork | None = None,
    ) -> None:
        self.player = player
        self.source = source
        self.policy = policy
        self.uow = uow

    @classmethod
    def default_state(cls, policy_version: str = "emblem-v1") -> dict[str, Any]:
        return {
            "schema_version": cls.STATE_SCHEMA_VERSION,
            "policy_version": str(policy_version),
            "proposal_generation": 0,
            "pending_rebuild": None,
            "scholarship_rng": {
                "forge": {"misses_since_special": 0},
                "reforge": {"misses_since_special": 0},
            },
        }

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _candidate_valid_for_source(self, item_id: int, source_inscription_id: int) -> bool:
        item = self.source.concrete_item(item_id)
        source_row = self.source.inscription(source_inscription_id)
        if item is None or source_row is None or not self.source.is_generation_candidate(item_id):
            return False
        candidate_inscription_id = self._int(item.get("inscription_id"), 0)
        if candidate_inscription_id == source_inscription_id:
            return True
        # Scholarship outputs are source-valid only for ordinary Lv7 origins.
        if self._int(source_row.get("level"), 0) != self._int(self.source.rules.get("scholarship_level"), 7):
            return False
        candidate_row = self.source.inscription(candidate_inscription_id)
        return bool(candidate_row and self._int(candidate_row.get("special"), 0) == 1)

    def _normalize_pending(self, raw: Any, generation: int) -> dict[str, Any] | None:
        if raw in (None, {}, []):
            return None
        if not isinstance(raw, dict):
            return None
        proposal_generation = max(0, self._int(raw.get("generation"), 0))
        source_item_id = max(0, self._int(raw.get("source_item_id"), 0))
        source_inscription_id = max(0, self._int(raw.get("source_inscription_id"), 0))
        rebuild_num = self._int(raw.get("rebuild_num"), 0)
        cost_type = self._int(raw.get("cost_type"), 0)
        candidates_raw = raw.get("candidates")
        candidates = [self._int(v) for v in candidates_raw] if isinstance(candidates_raw, list) else []
        policy_version = str(raw.get("policy_version") or "").strip()
        item = self.source.concrete_item(source_item_id)
        inscription = self.source.inscription(source_inscription_id)
        if (
            proposal_generation <= 0
            or proposal_generation > generation
            or item is None
            or inscription is None
            or int(item.get("inscription_id", 0) or 0) != source_inscription_id
            or int(inscription.get("special", 0) or 0) != 0
            or rebuild_num not in {1, 10}
            or cost_type not in {1, 2}
            or len(candidates) != rebuild_num
            or not policy_version
        ):
            return None
        if any(not self._candidate_valid_for_source(item_id, source_inscription_id) for item_id in candidates):
            return None
        return {
            "generation": proposal_generation,
            "source_item_id": source_item_id,
            "source_inscription_id": source_inscription_id,
            "rebuild_num": rebuild_num,
            "cost_type": cost_type,
            "candidates": candidates,
            "policy_version": policy_version,
        }

    def normalize(self) -> bool:
        raw = self.player.emblem_state if isinstance(self.player.emblem_state, dict) else {}
        raw_schema = self._int(raw.get("schema_version"), 0)
        if raw_schema > self.STATE_SCHEMA_VERSION:
            raise EmblemStateError(
                f"emblem_state schema {raw_schema} is newer than supported {self.STATE_SCHEMA_VERSION}"
            )
        generation = max(0, self._int(raw.get("proposal_generation"), 0))
        rng_raw = raw.get("scholarship_rng") if isinstance(raw.get("scholarship_rng"), dict) else {}
        normalized = self.default_state(self.policy.version)
        normalized["proposal_generation"] = generation
        normalized["pending_rebuild"] = self._normalize_pending(raw.get("pending_rebuild"), generation)
        normalized["scholarship_rng"] = {
            "forge": {
                "misses_since_special": max(
                    0,
                    self._int(
                        (rng_raw.get("forge") if isinstance(rng_raw.get("forge"), dict) else {}).get("misses_since_special"),
                        0,
                    ),
                )
            },
            "reforge": {
                "misses_since_special": max(
                    0,
                    self._int(
                        (rng_raw.get("reforge") if isinstance(rng_raw.get("reforge"), dict) else {}).get("misses_since_special"),
                        0,
                    ),
                )
            },
        }
        # The aggregate's active policy version is current. A frozen pending
        # proposal keeps its own policy_version so a future policy upgrade can
        # still commit old generated candidates without rerolling.
        normalized["policy_version"] = self.policy.version
        changed = raw != normalized
        self.player.emblem_state = normalized
        return changed

    def state(self) -> dict[str, Any]:
        self.normalize()
        return self.player.emblem_state

    def pending_rebuild(self) -> dict[str, Any] | None:
        pending = self.state().get("pending_rebuild")
        return copy.deepcopy(pending) if isinstance(pending, dict) else None

    def misses_since_special(self, lane: str) -> int:
        lane = str(lane)
        if lane not in {"forge", "reforge"}:
            raise EmblemStateError(f"unknown Emblem RNG lane {lane!r}")
        return int(self.state()["scholarship_rng"][lane]["misses_since_special"])

    def _require_active_uow(self) -> None:
        if self.uow is None or not self.uow.active:
            raise EmblemStateError("Emblem state mutation requires active PlayerUnitOfWork")

    def replace_pending(self, proposal: dict[str, Any]) -> dict[str, Any]:
        self._require_active_uow()
        state = self.state()
        generation = int(state.get("proposal_generation", 0) or 0) + 1
        candidate = copy.deepcopy(dict(proposal))
        candidate["generation"] = generation
        candidate.setdefault("policy_version", self.policy.version)
        normalized = self._normalize_pending(candidate, generation)
        if normalized is None:
            raise EmblemStateError("invalid Emblem pending proposal")
        state["proposal_generation"] = generation
        state["pending_rebuild"] = normalized
        self.player.emblem_state = state
        self.uow.mark_changed("emblem_state")
        return copy.deepcopy(normalized)

    def clear_pending(self) -> bool:
        self._require_active_uow()
        state = self.state()
        if state.get("pending_rebuild") is None:
            return False
        state["pending_rebuild"] = None
        self.player.emblem_state = state
        self.uow.mark_changed("emblem_state")
        return True

    def set_misses_since_special(self, lane: str, misses: Any) -> int:
        self._require_active_uow()
        lane = str(lane)
        if lane not in {"forge", "reforge"}:
            raise EmblemStateError(f"unknown Emblem RNG lane {lane!r}")
        value = max(0, self._int(misses, 0))
        state = self.state()
        state["scholarship_rng"][lane]["misses_since_special"] = value
        self.player.emblem_state = state
        self.uow.mark_changed("emblem_state")
        return value
    def apply_scholarship_result(
        self,
        lane: str,
        *,
        misses_before: Any,
        hit: bool,
    ) -> int:
        """Apply one already-generated eligible Lv7 gate result atomically.

        ``misses_before`` must still match durable state so a caller cannot
        accidentally apply a result planned against stale state.
        """

        self._require_active_uow()
        lane = str(lane)
        current = self.misses_since_special(lane)
        expected = max(0, self._int(misses_before, -1))
        if expected != current:
            raise EmblemStateError(
                f"stale Emblem Scholarship result for {lane}: expected {current}, got {expected}"
            )
        return self.set_misses_since_special(lane, 0 if bool(hit) else current + 1)

