"""Versioned private-server Horcrux compatibility policy registry.

The source catalog is immutable source fact. This registry is explicitly the
accepted private-server policy for unrecovered original-server behavior.
"""
from __future__ import annotations

import copy
import json
from pathlib import Path
from types import MappingProxyType
from typing import Any, Mapping


class HorcruxPolicyRegistry:
    SCHEMA_VERSION = 1
    REGISTRY_VERSION = "horcrux_policy_v1"
    REQUIRED_HPDS = tuple(f"HPD-{idx:03d}" for idx in range(1, 14))
    REQUIRED_RNG_NAMESPACES = (
        "horcrux.generate.main",
        "horcrux.generate.sub_count",
        "horcrux.generate.sub_selector",
        "horcrux.enhance.action",
        "horcrux.enhance.new_sub",
        "horcrux.enhance.improve_target",
        "horcrux.trial.repeat.residual",
    )

    def __init__(self, data_dir: Path) -> None:
        self.path = Path(data_dir) / "horcrux_policy_v1.json"
        raw = json.loads(self.path.read_text(encoding="utf-8"))
        if not isinstance(raw, dict) or int(raw.get("schema_version", 0) or 0) != self.SCHEMA_VERSION:
            raise ValueError("invalid Horcrux policy schema")
        meta = raw.get("_meta")
        if not isinstance(meta, dict) or meta.get("registry_version") != self.REGISTRY_VERSION:
            raise ValueError("invalid Horcrux policy registry version")
        if meta.get("epistemic_class") != "IMPLEMENTATION_COMPATIBILITY_DECISION":
            raise ValueError("Horcrux policy must remain explicitly compatibility-classified")
        policy_ids = raw.get("policy_ids")
        decisions = raw.get("decisions")
        if not isinstance(policy_ids, dict) or not isinstance(decisions, dict):
            raise ValueError("Horcrux HPD registry missing")
        if tuple(sorted(policy_ids)) != self.REQUIRED_HPDS or tuple(sorted(decisions)) != self.REQUIRED_HPDS:
            raise ValueError("Horcrux HPD registry incomplete")
        namespaces = tuple(raw.get("rng_namespaces") or ())
        if namespaces != self.REQUIRED_RNG_NAMESPACES:
            raise ValueError("Horcrux RNG namespace topology drift")
        overlays = raw.get("anomaly_overlays")
        if not isinstance(overlays, dict):
            raise ValueError("Horcrux anomaly overlays missing")
        pool = overlays.get("dropbox_9199043")
        if not isinstance(pool, dict):
            raise ValueError("9199043 compatibility overlay missing")
        candidates = tuple(int(v) for v in pool.get("effective_candidates") or ())
        weights = tuple(int(v) for v in pool.get("effective_weights") or ())
        if len(candidates) != 12 or len(weights) != 12 or sum(weights) != 1000:
            raise ValueError("9199043 compatibility overlay drift")
        if bool(pool.get("raw_source_mutated", True)):
            raise ValueError("9199043 raw source must remain immutable")

        self._raw = copy.deepcopy(raw)
        self._meta = MappingProxyType(copy.deepcopy(meta))
        self._policy_ids = MappingProxyType({str(k): str(v) for k, v in policy_ids.items()})
        self._decisions = MappingProxyType({str(k): str(v) for k, v in decisions.items()})
        self._overlays = MappingProxyType(copy.deepcopy(overlays))

    @property
    def metadata(self) -> Mapping[str, Any]:
        return self._meta

    @property
    def version(self) -> str:
        return self.REGISTRY_VERSION

    @property
    def rng_namespaces(self) -> tuple[str, ...]:
        return self.REQUIRED_RNG_NAMESPACES

    def policy_id(self, hpd: str) -> str:
        return self._policy_ids[str(hpd)]

    def decision(self, hpd: str) -> str:
        return self._decisions[str(hpd)]

    def anomaly_overlay(self, key: str) -> Mapping[str, Any] | None:
        value = self._overlays.get(str(key))
        return MappingProxyType(copy.deepcopy(value)) if isinstance(value, dict) else None

    @property
    def soft_trial_capacity(self) -> int:
        capacity = self._raw.get("capacity") or {}
        return max(0, int(capacity.get("gods_trial_soft_entry_limit", 0) or 0))
