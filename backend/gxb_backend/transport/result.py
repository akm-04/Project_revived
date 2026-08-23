"""Transport-aware engine result independent of Flask."""
from __future__ import annotations
from dataclasses import dataclass
from typing import Any

@dataclass(frozen=True)
class EngineTransportResult:
    body: Any
    status_code: int = 200
