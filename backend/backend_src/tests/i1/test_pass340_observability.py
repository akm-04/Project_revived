from __future__ import annotations

import json
from pathlib import Path
from types import SimpleNamespace

from gxb_backend.foundation.observability import REDACTED, redact
from gxb_backend.observability.runtime_logger import RuntimeLogger

ROOT = Path(__file__).resolve().parents[2]


def test_recursive_redaction_covers_ingress_credentials() -> None:
    safe = redact(
        {
            "sid": "SID-SECRET",
            "login_token": "LOGIN-SECRET",
            "token": "GAME-SECRET",
            "nested": {"authorization": "Bearer ABCDEF", "password": "pw"},
            "safe": "keep",
        }
    )
    assert safe["sid"] == REDACTED
    assert safe["login_token"] == REDACTED
    assert safe["token"] == REDACTED
    assert safe["nested"]["authorization"] == REDACTED
    assert safe["nested"]["password"] == REDACTED
    assert safe["safe"] == "keep"


def test_runtime_logger_never_persists_raw_request_credentials(tmp_path) -> None:
    settings = SimpleNamespace(runtime_log_dir=tmp_path, log_all_requests=True)
    logger = RuntimeLogger(settings)
    logger.request(
        mid=49,
        name="LOAD_HEROS",
        route="engine_json",
        req={"sid": "SID-SECRET", "login_token": "LOGIN-SECRET", "token": "GAME-SECRET"},
        handler="test",
        response={},
        fallback=False,
    )
    text = (tmp_path / "all_requests.jsonl").read_text(encoding="utf-8")
    assert "SID-SECRET" not in text
    assert "LOGIN-SECRET" not in text
    assert "GAME-SECRET" not in text
    row = json.loads(text.splitlines()[-1])
    assert row["request"]["sid"] == REDACTED
    assert row["request"]["login_token"] == REDACTED
    assert row["request"]["token"] == REDACTED


def test_undecoded_capture_suppresses_raw_body_and_redacts_query_by_construction() -> None:
    text = (ROOT / "gxb_backend/observability/undecoded_request_capture.py").read_text(encoding="utf-8")
    assert '"query": redact(' in text
    assert '"raw_body_sha256"' in text
    assert '"raw_body_capture": "SUPPRESSED_PASS340_CREDENTIAL_SAFETY"' in text
    assert "raw_body_prefix_hex" not in text
    assert "raw_body_prefix_b64" not in text
    assert "base64" not in text
