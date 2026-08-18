"""Read-only protocol labels/planes generated from the canonical Pass34 MID atlas."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .mids import mid_name as mid_lua_name


class ProtocolRegistry:
    """Observability metadata only; numeric MID remains the protocol key."""

    def __init__(self, records: dict[str, dict[str, Any]] | None = None) -> None:
        self._records = records or {}

    @classmethod
    def load(cls, path: Path) -> "ProtocolRegistry":
        try:
            payload = json.loads(Path(path).read_text(encoding="utf-8"))
            records = payload.get("records") if isinstance(payload, dict) else None
            if not isinstance(records, dict):
                raise ValueError("records must be an object")
            return cls(records)
        except Exception as exc:
            # Logging metadata must never prevent the game backend from booting.
            print(f"[PROTOCOL] registry unavailable at {path}: {exc}; falling back to mid.lua labels")
            return cls()

    def record(self, mid: Any) -> dict[str, Any] | None:
        try:
            key = str(int(mid))
        except (TypeError, ValueError):
            return None
        row = self._records.get(key)
        return row if isinstance(row, dict) else None

    def label(self, mid: Any) -> str:
        try:
            value = int(mid)
        except (TypeError, ValueError):
            return f"UNKNOWN_{mid}"
        row = self.record(value)
        label = str((row or {}).get("label") or "").strip()
        return label or mid_lua_name(value)

    def plane(self, mid: Any) -> str | None:
        row = self.record(mid)
        value = str((row or {}).get("plane") or "").strip()
        return value or None
