"""Compatibility fallback handlers.

Unknown MIDs are logged and acknowledged to maximize client progress. This is
not a semantic-completeness claim; it is a discovery aid for APK testing.
"""

from __future__ import annotations

import json
from typing import Any

from gxb_backend.config import Settings
from gxb_backend.protocol.mids import mid_name
from gxb_backend.protocol.routing import RouteClass, classify_mid


class CompatibilityHandlers:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings

    def fallback(self, req: dict[str, Any]) -> dict[str, Any]:
        try:
            mid = int(req.get("mid", 0))
        except Exception:
            mid = 0
        route_class = classify_mid(mid)
        name = mid_name(mid) if mid else "UNKNOWN"
        if self.settings.log_unknown_mids:
            print(
                f"[COMPAT] no semantic handler for {name} ({mid}), route={route_class}; "
                f"request={json.dumps(req, ensure_ascii=False, default=str)}"
            )
        if route_class == RouteClass.CHAT_TCP:
            return {"warning": "chat_mid_received_over_http"}
        if route_class == RouteClass.GM:
            return {"warning": "gm_mid_received_over_http"}
        return {}
