"""Relational semantic receipt primitive for operations with explicit replay identity."""

from __future__ import annotations

import hashlib
import json
from typing import Any, Mapping
from uuid import UUID, uuid4

from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.engine import Connection

from .errors import ReceiptReplayConflict
from .models import ReceiptKey, ReceiptRecord
from .schema import operation_receipts


def canonical_request_fingerprint(value: Mapping[str, Any]) -> bytes:
    encoded = json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    return hashlib.sha256(encoded).digest()


class ReceiptRepository:
    table = operation_receipts

    def get(self, connection: Connection, key: ReceiptKey) -> ReceiptRecord | None:
        statement = select(self.table).where(
            self.table.c.resource_kind == key.resource_kind,
            self.table.c.resource_key == key.resource_key,
            self.table.c.domain == key.domain,
            self.table.c.operation == key.operation,
            self.table.c.idempotency_key == key.idempotency_key,
        )
        row = connection.execute(statement).mappings().first()
        return None if row is None else self._record(row)

    def record_or_replay(
        self,
        connection: Connection,
        *,
        key: ReceiptKey,
        request_fingerprint: bytes,
        result: Mapping[str, Any],
        actor_account_uid: str | None = None,
        context_id: UUID | None = None,
        retention_policy: str = "STANDARD",
        receipt_id: UUID | None = None,
    ) -> tuple[ReceiptRecord, bool]:
        if len(request_fingerprint) != 32:
            raise ValueError("request_fingerprint must be a SHA-256 digest")
        identifier = receipt_id or uuid4()
        values = {
            "receipt_id": identifier,
            "resource_kind": key.resource_kind,
            "resource_key": key.resource_key,
            "domain": key.domain,
            "operation": key.operation,
            "idempotency_key": key.idempotency_key,
            "request_fingerprint": bytes(request_fingerprint),
            "actor_account_uid": actor_account_uid,
            "context_id": context_id,
            "result": dict(result),
            "retention_policy": retention_policy,
        }
        statement = (
            insert(self.table)
            .values(**values)
            .on_conflict_do_nothing(constraint="uq_operation_receipt_semantic_key")
            .returning(*self.table.c)
        )
        inserted = connection.execute(statement).mappings().first()
        if inserted is not None:
            return self._record(inserted), False

        existing = self.get(connection, key)
        if existing is None:
            raise RuntimeError("receipt conflict occurred but committed receipt is not visible")
        if existing.request_fingerprint != request_fingerprint.hex():
            raise ReceiptReplayConflict(key.scope)
        return existing, True

    @staticmethod
    def _record(row: Mapping[str, Any]) -> ReceiptRecord:
        raw_fingerprint = row["request_fingerprint"]
        if isinstance(raw_fingerprint, memoryview):
            raw_fingerprint = raw_fingerprint.tobytes()
        if isinstance(raw_fingerprint, bytes):
            fingerprint = raw_fingerprint.hex()
        else:
            fingerprint = str(raw_fingerprint)
        key = ReceiptKey(
            resource_kind=str(row["resource_kind"]),
            resource_key=str(row["resource_key"]),
            domain=str(row["domain"]),
            operation=str(row["operation"]),
            idempotency_key=str(row["idempotency_key"]),
        )
        return ReceiptRecord(
            receipt_id=row["receipt_id"],
            key=key,
            request_fingerprint=fingerprint,
            result=dict(row["result"]),
            committed_at=row.get("committed_at"),
        )
