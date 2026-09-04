"""Wave C read-only deferred UI status adapters."""
from __future__ import annotations

import copy
from typing import Any

from .catalogs import SynchronizationCatalogs
from .hydration import HydrationShapeValidator


_OMIT = "OMIT"


def _strip_omit(value: Any) -> Any:
    if isinstance(value, dict):
        return {k: _strip_omit(v) for k, v in value.items() if v != _OMIT}
    if isinstance(value, list):
        return [_strip_omit(v) for v in value]
    return copy.deepcopy(value)


class DeferredUiStatusAdapterService:
    """Project exact registered status shapes without mutating gameplay state."""

    def __init__(self, player, catalogs: SynchronizationCatalogs, server_clock) -> None:
        self.player = player
        self.catalogs = catalogs
        self.server_clock = server_clock

    def response(self, mid: int) -> dict[str, Any]:
        desc = self.catalogs.deferred_adapter(int(mid))
        if desc is None:
            raise KeyError(f"unregistered deferred UI status MID {mid}")
        baseline = _strip_omit(self.catalogs.compatibility.decision(desc.policy_id))
        if desc.mode == "canonical_overlay":
            payload = self._canonical_overlay(int(mid), baseline)
        elif desc.mode == "inactive_baseline":
            payload = baseline
        else:
            raise ValueError(f"unsupported deferred adapter mode {desc.mode!r}")
        HydrationShapeValidator.validate(int(mid), payload)
        return copy.deepcopy(payload)

    def _canonical_overlay(self, mid: int, baseline: dict[str, Any]) -> dict[str, Any]:
        if mid != 124:
            raise ValueError(f"no canonical overlay provider for MID {mid}")
        out = copy.deepcopy(baseline)
        # Policy text records the clock-owned last_time decision; materialize it
        # here without persisting fabricated Practice state.
        out["last_time"] = int(self.server_clock.now())
        info = self.player.practice_info.get("hero") if isinstance(self.player.practice_info, dict) else None
        if isinstance(info, dict):
            for key in ("last_time", "practice_attr", "lock", "times", "base_crystal", "base_mana", "bless_value"):
                if key in info and info[key] is not None:
                    out[key] = copy.deepcopy(info[key])
        # Keep source arithmetic deterministic and fail-safe for legacy hand edits.
        for key in ("last_time", "times", "base_crystal", "base_mana", "bless_value"):
            try: out[key] = int(out[key])
            except (TypeError, ValueError): out[key] = 0 if key != "last_time" else int(self.server_clock.now())
        if not isinstance(out.get("practice_attr"), list): out["practice_attr"] = [0, 0, 0]
        if not isinstance(out.get("lock"), list): out["lock"] = []
        return out


class DeferredStatusMutationFenceValidator:
    """Prove read-only adapters did not silently un-fence adjacent gameplay."""

    @staticmethod
    def validate(catalogs, *, handlers, mutation_contracts, safe_fallback_check, label_lookup) -> None:
        errors = []
        for adapter in catalogs.deferred_adapters():
            for mid in adapter.adjacent_mutation_mids:
                contract = mutation_contracts.contract(mid)
                # Explicit audited blocked/deferred contracts are acceptable.
                if contract is not None and contract.enforcement in {"BLOCK_PHASE1", "BLOCK_PHASE2", "DEFER_TERMINAL"}:
                    continue
                # Otherwise the mutation must be completely absent and must not
                # be admitted by the generic safe-empty compatibility allow-list.
                if mid not in handlers and not safe_fallback_check(mid):
                    continue
                errors.append(f"adapter {adapter.mid} adjacent mutation unexpectedly exposed: {label_lookup(mid)} ({mid})")
        if errors:
            raise RuntimeError("Deferred UI mutation-fence validation failed:\n- " + "\n- ".join(errors))
