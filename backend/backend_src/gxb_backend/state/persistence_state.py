"""Phase 3 persistence-control envelope helpers (Pass68 foundation)."""
from __future__ import annotations

import copy
from typing import Any

from .player_state import PlayerState

CONTRACT_VERSION = 1


def default_persistence_state() -> dict[str, Any]:
    return {
        "contract_version": CONTRACT_VERSION,
        "state_version": 0,
        "slice_revisions": {},
        "slice_schema_versions": {},
        "receipts": {},
        "claims": {},
        "migration": {},
        "last_commit": None,
    }


def normalize_persistence_state(value: Any) -> dict[str, Any]:
    """Return a valid envelope while preserving extension keys verbatim."""
    out = copy.deepcopy(value) if isinstance(value, dict) else {}
    defaults = default_persistence_state()
    for key, default in defaults.items():
        if key not in out:
            out[key] = copy.deepcopy(default)

    try:
        out["contract_version"] = max(1, int(out.get("contract_version", CONTRACT_VERSION)))
    except (TypeError, ValueError):
        out["contract_version"] = CONTRACT_VERSION
    try:
        out["state_version"] = max(0, int(out.get("state_version", 0)))
    except (TypeError, ValueError):
        out["state_version"] = 0

    for key in ("slice_revisions", "slice_schema_versions", "receipts", "claims", "migration"):
        if not isinstance(out.get(key), dict):
            out[key] = {}
    if out.get("last_commit") is not None and not isinstance(out.get("last_commit"), dict):
        out["last_commit"] = None
    return out


def ensure_persistence_state(player: PlayerState) -> dict[str, Any]:
    normalized = normalize_persistence_state(getattr(player, "persistence_state", None))
    player.persistence_state = normalized
    return normalized


def state_version(player: PlayerState) -> int:
    return int(ensure_persistence_state(player)["state_version"])
