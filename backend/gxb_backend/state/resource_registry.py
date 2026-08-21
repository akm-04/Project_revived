"""Immutable routing metadata for the 47 source-backed economy_ keys.

Pass68 installs the Phase-2 ResourceRegistry contract without yet replacing
legacy storage. It owns no balances; it tells future settlement code which
logical owner/policy is allowed to mutate or project a key.
"""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable


class ResourceRegistryError(ValueError):
    pass


@dataclass(frozen=True)
class ResourceDescriptor:
    ordinal: int
    wire_key: str
    client_attr: str
    legacy_adapter_class: str
    domain_scope: str
    owner_service: str
    semantic_class: str
    storage_locator_v1: str
    mutation_capability: str
    temporal_policy_key: str
    reset_policy_key: str
    cap_policy: str
    projection_strategy: str
    projection_path: str
    insufficient_balance_policy: str
    direct_handler_write_allowed: bool
    evidence_class: str
    migration_readiness: str
    notes: str

    @classmethod
    def from_mapping(cls, row: dict[str, Any]) -> "ResourceDescriptor":
        fields = cls.__dataclass_fields__
        missing = [name for name in fields if name not in row]
        if missing:
            raise ResourceRegistryError(f"descriptor missing fields: {missing}")
        return cls(**{name: row[name] for name in fields})


class ResourceRegistry:
    EXPECTED_COUNT = 47
    REGENERATING_KEYS = frozenset({"energy", "spirit_energy", "skill_point", "invitation"})

    def __init__(self, descriptors: Iterable[ResourceDescriptor]) -> None:
        rows = tuple(sorted(descriptors, key=lambda d: int(d.ordinal)))
        if len(rows) != self.EXPECTED_COUNT:
            raise ResourceRegistryError(f"expected 47 descriptors, got {len(rows)}")
        by_key = {row.wire_key: row for row in rows}
        if len(by_key) != len(rows):
            raise ResourceRegistryError("duplicate wire_key in ResourceRegistry")
        self._rows = rows
        self._by_key = by_key
        regenerating = {k for k, d in by_key.items() if d.legacy_adapter_class == "regenerating_ledger"}
        if regenerating != set(self.REGENERATING_KEYS):
            raise ResourceRegistryError(f"regenerating key drift: {sorted(regenerating)}")

    @classmethod
    def load(cls, path: Path) -> "ResourceRegistry":
        raw = json.loads(Path(path).read_text(encoding="utf-8"))
        if int(raw.get("descriptor_count", 0)) != cls.EXPECTED_COUNT:
            raise ResourceRegistryError("resource registry descriptor_count drift")
        rows = raw.get("descriptors")
        if not isinstance(rows, list):
            raise ResourceRegistryError("resource registry descriptors must be a list")
        return cls(ResourceDescriptor.from_mapping(row) for row in rows if isinstance(row, dict))

    def require(self, wire_key: str) -> ResourceDescriptor:
        try:
            return self._by_key[str(wire_key)]
        except KeyError as exc:
            raise ResourceRegistryError(f"unknown economy resource: {wire_key}") from exc

    def get(self, wire_key: str) -> ResourceDescriptor | None:
        return self._by_key.get(str(wire_key))

    def all(self) -> tuple[ResourceDescriptor, ...]:
        return self._rows

    def keys(self) -> tuple[str, ...]:
        return tuple(row.wire_key for row in self._rows)

    def scalar_keys(self) -> tuple[str, ...]:
        return tuple(row.wire_key for row in self._rows if row.legacy_adapter_class == "scalar_ledger")

    def assert_legacy_economy_field(self, wire_key: str) -> ResourceDescriptor:
        desc = self.require(wire_key)
        if wire_key in {"mana", "crystal"} and desc.owner_service != "EconomyLedger":
            raise ResourceRegistryError(f"legacy field owner drift: {wire_key} -> {desc.owner_service}")
        if wire_key == "energy" and desc.legacy_adapter_class != "regenerating_ledger":
            raise ResourceRegistryError("energy must remain temporal/regenerating")
        if wire_key in {"exp", "lev"} and desc.owner_service != "PlayerProgressionService":
            raise ResourceRegistryError(f"progression owner drift: {wire_key} -> {desc.owner_service}")
        return desc
