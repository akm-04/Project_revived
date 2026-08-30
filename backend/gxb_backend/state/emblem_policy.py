"""Versioned compatibility-policy registry for Emblem server-owned behavior.

Pass244 I3 activated the internal ``emblem-v1`` fixed-point Scholarship
compatibility policy. Pass246 I4 exposed it through MID1400 Forge; Pass247 I5
opens the same replaceable policy through Reforge MID1401 while MID1405/1406
commit/discard frozen proposals without entropy. Source-owned
weights remain in :mod:`emblem_source_catalog`; this registry owns only the
explicitly classified EOL compatibility decisions.
"""
from __future__ import annotations

import copy
from dataclasses import dataclass
import json
from pathlib import Path
from types import MappingProxyType
from typing import Any, Mapping


@dataclass(frozen=True)
class EmblemScholarshipLanePolicy:
    lane: str
    rate_suit_bp: int
    rate_step_bp: int
    max_num: int

    def chance_for_misses(self, misses_since_special: int) -> tuple[int, int, bool]:
        """Return ``(attempt, chance_bp, hard_special)`` for the next eligible draw.

        ``attempt`` is one-based exactly as sealed in Pass240:
        ``misses_since_special + 1``.  The hard ceiling is deterministic and
        does not require an entropy draw.
        """

        if isinstance(misses_since_special, bool) or not isinstance(misses_since_special, int):
            raise ValueError("misses_since_special must be an integer")
        if misses_since_special < 0:
            raise ValueError("misses_since_special must be nonnegative")
        attempt = misses_since_special + 1
        hard_special = attempt >= self.max_num
        chance_bp = min(10000, self.rate_suit_bp + attempt * self.rate_step_bp)
        if hard_special:
            chance_bp = 10000
        return attempt, chance_bp, hard_special


class EmblemPolicyRegistry:
    SCHEMA_VERSION = 1
    REGISTRY_VERSION = "emblem-v1"
    FIXED_POINT_DENOMINATOR_BP = 10000
    REQUIRED_NAMESPACES = (
        "emblem.forge.ordinary",
        "emblem.forge.scholarship_gate",
        "emblem.forge.scholarship_family",
        "emblem.forge.scholarship_item",
        "emblem.reforge.ordinary",
        "emblem.reforge.scholarship_gate",
        "emblem.reforge.scholarship_family",
        "emblem.reforge.scholarship_item",
    )

    def __init__(self, data_dir: Path) -> None:
        self.path = Path(data_dir) / "emblem_policy_v1.json"
        raw = json.loads(self.path.read_text(encoding="utf-8"))
        if not isinstance(raw, dict) or int(raw.get("schema_version", 0) or 0) != self.SCHEMA_VERSION:
            raise ValueError("invalid Emblem policy schema")
        meta = raw.get("_meta")
        if not isinstance(meta, dict) or meta.get("registry_version") != self.REGISTRY_VERSION:
            raise ValueError("invalid Emblem policy registry version")
        if meta.get("epistemic_class") != "IMPLEMENTATION_COMPATIBILITY_DECISION":
            raise ValueError("Emblem private policy must remain compatibility-classified")
        if meta.get("status") != "I5_FORGE_AND_REFORGE_PUBLIC_ENABLED":
            raise ValueError("Emblem I5 policy activation status drift")
        namespaces = tuple(str(v) for v in raw.get("rng_namespaces") or ())
        if namespaces != self.REQUIRED_NAMESPACES:
            raise ValueError("Emblem RNG namespace topology drift")
        decisions = raw.get("decisions")
        if not isinstance(decisions, dict):
            raise ValueError("Emblem policy decisions missing")
        outer = decisions.get("outer_scholarship")
        reforge = decisions.get("reforge_same_result")
        proposal = decisions.get("pending_proposal")
        if not isinstance(outer, dict) or not isinstance(reforge, dict) or not isinstance(proposal, dict):
            raise ValueError("Emblem policy decision registry incomplete")
        if outer.get("implementation_status") != "I5_FORGE_AND_REFORGE_PUBLIC_ENABLED":
            raise ValueError("I5 Scholarship policy activation drift")
        if outer.get("negative_claim") != "not recovered official server math":
            raise ValueError("Emblem outer policy epistemic guard missing")
        if outer.get("forge") != {"rate_suit_bp": 0, "rate_step_bp": 10, "max_num": 1000}:
            raise ValueError("Emblem Forge compatibility ladder design drift")
        if outer.get("reforge") != {"rate_suit_bp": 0, "rate_step_bp": 100, "max_num": 100}:
            raise ValueError("Emblem Reforge compatibility ladder design drift")
        if reforge.get("exclude_current_item") is not True:
            raise ValueError("Emblem same-result exclusion policy drift")
        required_proposal = {
            "latest_proposal_wins": True,
            "persist_across_restart": True,
            "stale_source_save_clears_pending": True,
            "abandon_without_pending_success": True,
        }
        for key, value in required_proposal.items():
            if proposal.get(key) is not value:
                raise ValueError(f"Emblem proposal policy drift: {key}")
        self._raw = copy.deepcopy(raw)
        self._meta = MappingProxyType(copy.deepcopy(meta))
        self._decisions = MappingProxyType(copy.deepcopy(decisions))
        self._lanes = {
            lane: EmblemScholarshipLanePolicy(lane=lane, **copy.deepcopy(outer[lane]))
            for lane in ("forge", "reforge")
        }
        for lane, config in self._lanes.items():
            if config.rate_suit_bp < 0 or config.rate_step_bp <= 0 or config.max_num <= 0:
                raise ValueError(f"invalid Emblem Scholarship lane policy: {lane}")
            # The sealed v1 ladders must reach certainty no later than max_num.
            if config.rate_suit_bp + config.max_num * config.rate_step_bp < self.FIXED_POINT_DENOMINATOR_BP:
                raise ValueError(f"Emblem Scholarship lane cannot reach hard ceiling: {lane}")

    @property
    def version(self) -> str:
        return self.REGISTRY_VERSION

    @property
    def metadata(self) -> Mapping[str, Any]:
        return self._meta

    @property
    def rng_namespaces(self) -> tuple[str, ...]:
        return self.REQUIRED_NAMESPACES

    def decision(self, name: str) -> Mapping[str, Any]:
        value = self._decisions.get(str(name))
        if not isinstance(value, dict):
            raise KeyError(name)
        return MappingProxyType(copy.deepcopy(value))

    @property
    def outer_scholarship_enabled(self) -> bool:
        # I5 exposes the same versioned compatibility policy through both Forge
        # and Reforge. Save/Abandon are deterministic proposal lifecycle actions.
        return True

    @property
    def exclude_current_reforge_item(self) -> bool:
        return bool(self._decisions["reforge_same_result"]["exclude_current_item"])

    def scholarship_lane(self, lane: str) -> EmblemScholarshipLanePolicy:
        try:
            return self._lanes[str(lane)]
        except KeyError as exc:
            raise ValueError(f"unknown Emblem Scholarship lane {lane!r}") from exc

    def scholarship_chance(self, lane: str, misses_since_special: int) -> tuple[int, int, bool]:
        return self.scholarship_lane(lane).chance_for_misses(misses_since_special)
