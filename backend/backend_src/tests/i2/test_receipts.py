from __future__ import annotations

from datetime import datetime, timezone
from uuid import UUID, uuid4
from unittest.mock import Mock

import pytest

from gxb_backend.transactions.errors import ReceiptReplayConflict
from gxb_backend.transactions.models import ReceiptKey
from gxb_backend.transactions.receipts import ReceiptRepository, canonical_request_fingerprint


class MappingResult:
    def __init__(self, first=None):
        self._first = first

    def mappings(self):
        return self

    def first(self):
        return self._first


def row_for(key: ReceiptKey, fingerprint: bytes):
    return {
        "receipt_id": uuid4(),
        "resource_kind": key.resource_kind,
        "resource_key": key.resource_key,
        "domain": key.domain,
        "operation": key.operation,
        "idempotency_key": key.idempotency_key,
        "request_fingerprint": fingerprint,
        "result": {"ok": 1},
        "committed_at": datetime.now(timezone.utc),
    }


def test_canonical_request_fingerprint_ignores_mapping_order() -> None:
    assert canonical_request_fingerprint({"a": 1, "b": [2]}) == canonical_request_fingerprint({"b": [2], "a": 1})
    assert len(canonical_request_fingerprint({"a": 1})) == 32


def test_record_or_replay_returns_new_insert_without_second_query() -> None:
    key = ReceiptKey("player", "7", "summon", "draw", "client-op")
    fp = canonical_request_fingerprint({"cost": 10})
    inserted = row_for(key, fp)
    connection = Mock()
    connection.execute.return_value = MappingResult(inserted)
    record, replay = ReceiptRepository().record_or_replay(
        connection, key=key, request_fingerprint=fp, result={"ok": 1}, receipt_id=inserted["receipt_id"]
    )
    assert replay is False
    assert record.request_fingerprint == fp.hex()
    assert connection.execute.call_count == 1


def test_record_or_replay_returns_existing_identical_fingerprint() -> None:
    key = ReceiptKey("player", "7", "summon", "draw", "client-op")
    fp = canonical_request_fingerprint({"cost": 10})
    existing = row_for(key, fp)
    connection = Mock()
    connection.execute.side_effect = [MappingResult(None), MappingResult(existing)]
    record, replay = ReceiptRepository().record_or_replay(connection, key=key, request_fingerprint=fp, result={"ignored": 1})
    assert replay is True
    assert record.result == {"ok": 1}


def test_record_or_replay_rejects_same_key_different_fingerprint() -> None:
    key = ReceiptKey("player", "7", "summon", "draw", "client-op")
    fp = canonical_request_fingerprint({"cost": 10})
    existing = row_for(key, canonical_request_fingerprint({"cost": 11}))
    connection = Mock()
    connection.execute.side_effect = [MappingResult(None), MappingResult(existing)]
    with pytest.raises(ReceiptReplayConflict):
        ReceiptRepository().record_or_replay(connection, key=key, request_fingerprint=fp, result={"ok": 1})


def test_record_requires_sha256_length() -> None:
    key = ReceiptKey("player", "7", "summon", "draw", "op")
    with pytest.raises(ValueError, match="SHA-256"):
        ReceiptRepository().record_or_replay(Mock(), key=key, request_fingerprint=b"bad", result={})
