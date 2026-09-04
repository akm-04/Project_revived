from __future__ import annotations

from datetime import datetime, timedelta, timezone
from uuid import uuid4

import pytest

from gxb_backend.identity.errors import SessionExpired, SessionRevoked
from gxb_backend.identity.models import AccountSessionSnapshot, IdentityPolicy, RegionSnapshot
from gxb_backend.identity.repositories import SessionRepository


NOW = datetime(2026, 9, 2, 12, 0, tzinfo=timezone.utc)


def policy() -> IdentityPolicy:
    return IdentityPolicy(
        absolute_session_ttl=timedelta(days=7),
        idle_session_ttl=timedelta(hours=24),
        activity_write_interval=timedelta(minutes=10),
    )


def snapshot(**changes) -> AccountSessionSnapshot:
    values = dict(
        session_id=uuid4(),
        account_uid="20000001",
        issued_at=NOW - timedelta(hours=1),
        last_activity_at=NOW - timedelta(minutes=5),
        absolute_expires_at=NOW + timedelta(days=1),
        revoked_at=None,
        revocation_reason=None,
    )
    values.update(changes)
    return AccountSessionSnapshot(**values)


def test_identity_policy_rejects_activity_interval_not_smaller_than_idle_ttl() -> None:
    with pytest.raises(ValueError):
        IdentityPolicy(None, timedelta(minutes=5), timedelta(minutes=5))


def test_session_liveness_accepts_live_and_rejects_revoked_absolute_and_idle_expiry() -> None:
    SessionRepository.validate_liveness(snapshot(), policy=policy(), now=NOW)
    with pytest.raises(SessionRevoked):
        SessionRepository.validate_liveness(
            snapshot(revoked_at=NOW - timedelta(seconds=1), revocation_reason="manual"),
            policy=policy(),
            now=NOW,
        )
    with pytest.raises(SessionExpired):
        SessionRepository.validate_liveness(
            snapshot(absolute_expires_at=NOW), policy=policy(), now=NOW
        )
    with pytest.raises(SessionExpired):
        SessionRepository.validate_liveness(
            snapshot(last_activity_at=NOW - timedelta(hours=24)), policy=policy(), now=NOW
        )


def test_region_full_semantics_allow_existing_login_but_block_new_allocation_decision() -> None:
    open_region = RegionSnapshot(5, "Local-5", 500_001, 599_999, True)
    full_region = RegionSnapshot(5, "Local-5", 600_000, 599_999, True)
    closed_region = RegionSnapshot(5, "Local-5", 500_001, 599_999, False)
    assert not open_region.is_full_for_new_players
    assert full_region.is_full_for_new_players
    assert closed_region.is_full_for_new_players
