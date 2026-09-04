from __future__ import annotations

import io
import json

from gxb_backend.foundation.observability import REDACTED, SafeStructuredLogger, redact


def test_recursive_redaction_covers_fields_bearer_and_postgres_url() -> None:
    payload: dict[str, object] = {
        "sid": "session-value",
        "nested": {
            "Authorization": "Bearer abc.def-123",
            "note": "postgresql+psycopg://user:password@db.example/game",
        },
    }
    payload["cycle"] = payload
    safe = redact(payload)
    rendered = json.dumps(safe)
    assert safe["sid"] == REDACTED
    assert "session-value" not in rendered
    assert "abc.def-123" not in rendered
    assert ":password@" not in rendered
    assert "[RECURSIVE]" in rendered


def test_structured_logger_emits_one_safe_json_line() -> None:
    stream = io.StringIO()
    logger = SafeStructuredLogger(stream, component="http")
    record = logger.emit("auth_failure", password="do-not-log", player_id=3)
    assert record["password"] == REDACTED
    lines = stream.getvalue().splitlines()
    assert len(lines) == 1
    assert json.loads(lines[0]) == record

