"""Credential-safe structured logging primitives for later ingress wiring."""

from __future__ import annotations

import json
import re
import sys
from datetime import datetime, timezone
from typing import Any, Mapping, TextIO


REDACTED = "[REDACTED]"
SENSITIVE_FIELDS = frozenset(
    {
        "authorization",
        "cookie",
        "cookies",
        "credential",
        "credential_hash",
        "database_url",
        "dsn",
        "login_token",
        "passwd",
        "password",
        "password_hash",
        "secret",
        "secret_record",
        "set_cookie",
        "sid",
        "token",
    }
)
_BEARER = re.compile(r"(?i)\bbearer\s+[A-Za-z0-9._~+/=-]+")
_DATABASE_PASSWORD = re.compile(
    r"(?i)(postgres(?:ql)?(?:\+psycopg)?://[^\s:/@]+:)([^\s/@]+)(@)"
)


def _field_name(value: object) -> str:
    return str(value).strip().lower().replace("-", "_")


def redact_text(value: str) -> str:
    text = _BEARER.sub("Bearer [REDACTED]", str(value))
    return _DATABASE_PASSWORD.sub(r"\1[REDACTED]\3", text)


def redact(value: Any, *, _seen: set[int] | None = None) -> Any:
    """Return a recursively sanitized, JSON-compatible copy."""

    if isinstance(value, str):
        return redact_text(value)
    if value is None or isinstance(value, (bool, int, float)):
        return value

    seen = set() if _seen is None else _seen
    marker = id(value)
    if marker in seen:
        return "[RECURSIVE]"

    if isinstance(value, Mapping):
        seen.add(marker)
        try:
            return {
                str(key): REDACTED if _field_name(key) in SENSITIVE_FIELDS else redact(item, _seen=seen)
                for key, item in value.items()
            }
        finally:
            seen.remove(marker)
    if isinstance(value, (list, tuple, set, frozenset)):
        seen.add(marker)
        try:
            return [redact(item, _seen=seen) for item in value]
        finally:
            seen.remove(marker)
    return redact_text(repr(value))


class SafeStructuredLogger:
    """Minimal JSON-lines signal contract with centralized redaction."""

    def __init__(self, stream: TextIO | None = None, *, component: str) -> None:
        self._stream = stream or sys.stdout
        self._component = str(component)

    def emit(self, event: str, **fields: Any) -> dict[str, Any]:
        record = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "component": self._component,
            "event": str(event),
            **fields,
        }
        safe = redact(record)
        self._stream.write(json.dumps(safe, ensure_ascii=False, separators=(",", ":")) + "\n")
        self._stream.flush()
        return safe
