from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
from uuid import UUID

import pytest
from sqlalchemy.dialects import postgresql

from gxb_backend.identity.models import RegionSnapshot
from gxb_backend.identity.repositories import RegionDirectoryRepository, SessionRepository

NOW = datetime(2026, 9, 2, 12, 0, tzinfo=timezone.utc)


class RowcountResult:
    def __init__(self, rowcount=1):
        self.rowcount = rowcount


class RecordingConnection:
    def __init__(self):
        self.calls = []

    def execute(self, statement, params=None):
        self.calls.append((statement, params))
        return RowcountResult(1)


def _sql(statement) -> str:
    return str(statement.compile(dialect=postgresql.dialect())).lower()


def test_session_and_both_account_credentials_use_one_caller_owned_connection() -> None:
    connection = RecordingConnection()
    repo = SessionRepository()
    session_id = UUID("11111111-1111-1111-1111-111111111111")
    repo.create_session(
        connection,
        session_id=session_id,
        account_uid="20000001",
        issued_at=NOW,
        absolute_expires_at=None,
        device_metadata={"platform": "test"},
        sid_credential_id=UUID("22222222-2222-2222-2222-222222222222"),
        sid_digest=b"s" * 32,
        login_credential_id=UUID("33333333-3333-3333-3333-333333333333"),
        login_digest=b"l" * 32,
    )
    assert len(connection.calls) == 2
    assert "insert into gxb.account_sessions" in _sql(connection.calls[0][0])
    assert "insert into gxb.session_credentials" in _sql(connection.calls[1][0])
    rows = connection.calls[1][1]
    assert isinstance(rows, list) and len(rows) == 2
    assert {row["kind"] for row in rows} == {"SDK_SID_COMPAT", "LOGIN_TOKEN"}
    assert {row["session_id"] for row in rows} == {session_id}


class AllocatorConnection:
    def execute(self, statement, params=None):
        text = _sql(statement)
        if text.startswith("update gxb.regions"):
            return RowcountResult(0)
        raise AssertionError(f"unexpected SQL after allocator invariant failure: {text}")


def test_region_allocator_refuses_stale_cursor_instead_of_allocating_from_it(monkeypatch) -> None:
    repo = RegionDirectoryRepository()
    monkeypatch.setattr(repo, "find_player", lambda *a, **k: None)
    monkeypatch.setattr(
        repo,
        "get_region",
        lambda *a, **k: RegionSnapshot(125, "Deep Valley", 12_500_001, 12_599_999, True),
    )
    with pytest.raises(RuntimeError, match="cursor changed"):
        repo.allocate_player(
            AllocatorConnection(), account_uid="20000001", region_id=125, created_at=NOW
        )


def test_new_relational_identity_plane_contains_no_fixed_sandbox_credentials() -> None:
    root = Path(__file__).resolve().parents[2] / "gxb_backend" / "identity"
    combined = "\n".join(
        p.read_text(encoding="utf-8") for p in sorted(root.glob("*.py"))
    )
    assert "SANDBOX_SID" not in combined
    assert "SANDBOX_TOKEN" not in combined
    assert "1993b58bfd1b93499ae19477b236d4a2" not in combined
    assert '"local_token"' not in combined and "'local_token'" not in combined
