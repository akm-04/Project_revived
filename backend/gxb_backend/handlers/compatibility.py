"""Mutation-safe compatibility boundary for unmapped engine MIDs.

Pass 29 removes the old "unknown means empty success" behavior. Unknown MIDs
may receive an empty acknowledgement only when their numeric MID is explicitly
allow-listed from retained audit/ownership evidence. Everything else is blocked
with a local unsupported response so an optimistic Lua callback cannot create
client-only durable state.
"""

from __future__ import annotations

import json
from typing import Any, Callable

from gxb_backend.config import Settings
from gxb_backend.protocol.mids import mid_name
from gxb_backend.protocol.routing import RouteClass, classify_mid


class CompatibilityHandlers:
    def __init__(self, settings: Settings, name_lookup: Callable[[int], str] | None = None) -> None:
        self.settings = settings
        self._name_lookup = name_lookup or mid_name
        self._safe_mids = self._load_safe_mids()

    def _load_safe_mids(self) -> set[int]:
        path = self.settings.compatibility_safe_mids_path
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
            rows = payload.get("safe_empty_ack_mids") or {}
            if not isinstance(rows, dict):
                raise ValueError("safe_empty_ack_mids must be an object")
            return {int(key) for key in rows.keys()}
        except Exception as exc:
            # Fail closed: a missing/corrupt allow-list must never silently
            # restore the old acknowledge-everything mutation hazard.
            print(f"[COMPAT] safe-MID allow-list unavailable at {path}: {exc}; fail-closed")
            return set()

    def is_safe_fallback_mid(self, mid: int) -> bool:
        return int(mid) in self._safe_mids

    def fallback(self, req: dict[str, Any]) -> dict[str, Any]:
        """Acknowledge an explicitly audited safe-empty-response MID."""
        try:
            mid = int(req.get("mid", 0))
        except Exception:
            mid = 0
        route_class = classify_mid(mid)
        name = self._name_lookup(mid) if mid else "UNKNOWN"
        if mid not in self._safe_mids:
            return self.blocked(req)
        if self.settings.log_unknown_mids:
            print(
                f"[COMPAT SAFE] audited empty acknowledgement for {name} ({mid}), "
                f"route={route_class.value}; request={json.dumps(req, ensure_ascii=False, default=str)}"
            )
        if route_class == RouteClass.CHAT_TCP:
            return {"warning": "chat_mid_received_over_http"}
        if route_class == RouteClass.GM:
            return {"warning": "gm_mid_received_over_http"}
        return {}

    def blocked(self, req: dict[str, Any]) -> dict[str, Any]:
        """Block an unaudited unknown MID without guessing whether it mutates."""
        try:
            mid = int(req.get("mid", 0))
        except Exception:
            mid = 0
        route_class = classify_mid(mid)
        name = self._name_lookup(mid) if mid else "UNKNOWN"
        if self.settings.log_unknown_mids:
            print(
                f"[COMPAT BLOCK] no semantic handler and MID is not on the audited safe allow-list: "
                f"{name} ({mid}), route={route_class.value}; "
                f"request={json.dumps(req, ensure_ascii=False, default=str)}"
            )
        # error_code=1 is a private-server policy sentinel, not a claim about an
        # official GXB error-code assignment. The goal is to prevent a false OK.
        return {
            "error_code": 1,
            "msg": "unsupported_mid_not_allowlisted",
        }
