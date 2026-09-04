"""SQLAlchemy Core MailRepository for Pass345 I6."""
from __future__ import annotations

from typing import Any, Iterable, Mapping

from sqlalchemy import and_, func, select, update
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.engine import Connection

from .models import MailAddress, MailDeliveryIntent, MailRecord
from .schema import mail_items


class MailDeliveryConflict(RuntimeError):
    pass


def _record(row: Mapping[str, Any]) -> MailRecord:
    return MailRecord(
        mail_row_id=int(row["mail_row_id"]),
        player_id=int(row["player_id"]),
        address=MailAddress(bool(row["is_region"]), int(row["protocol_mail_id"])),
        delivery_key=str(row["delivery_key"]),
        protocol_payload=dict(row.get("protocol_payload") or {}),
        attachments=tuple(dict(x) for x in (row.get("attachments") or ())),
        created_at=row["created_at"],
        expires_at=row.get("expires_at"),
        read_at=row.get("read_at"),
        claimed_at=row.get("claimed_at"),
        source_type=str(row["source_type"]),
        source_id=str(row["source_id"]),
        metadata=dict(row.get("metadata") or {}),
    )


class MailRepository:
    table = mail_items

    def deliver(self, connection: Connection, intent: MailDeliveryIntent) -> tuple[MailRecord, bool]:
        values = dict(
            player_id=int(intent.player_id),
            is_region=bool(intent.is_region),
            legacy_mail_id=int(intent.legacy_mail_id) if intent.legacy_mail_id is not None else None,
            delivery_key=str(intent.delivery_key),
            protocol_payload=dict(intent.protocol_payload),
            attachments=[dict(x) for x in intent.attachments],
            expires_at=intent.expires_at,
            source_type=str(intent.source_type),
            source_id=str(intent.source_id),
            metadata=dict(intent.metadata or {}),
        )
        if intent.protocol_mail_id is not None:
            values["protocol_mail_id"] = int(intent.protocol_mail_id)
        stmt = (
            insert(self.table)
            .values(**values)
            # Both uq_mail_items_delivery_key and the player/protocol address
            # are unique.
            # Under concurrent identical inserts PostgreSQL may discover the
            # protocol-address index conflict before the named delivery-key
            # arbiter.  Suppress either uniqueness race, then prove below that
            # the durable winner has this exact semantic delivery identity.
            .on_conflict_do_nothing()
            .returning(*self.table.c)
        )
        row = connection.execute(stmt).mappings().first()
        if row is not None:
            return _record(row), False
        existing = connection.execute(
            select(self.table).where(self.table.c.delivery_key == str(intent.delivery_key))
        ).mappings().first()
        if existing is None and intent.protocol_mail_id is not None:
            existing = connection.execute(
                select(self.table).where(
                    self.table.c.player_id == int(intent.player_id),
                    self.table.c.is_region == bool(intent.is_region),
                    self.table.c.protocol_mail_id == int(intent.protocol_mail_id),
                )
            ).mappings().first()
        if existing is None:
            raise MailDeliveryConflict(
                f"mail uniqueness conflict without visible semantic winner: {intent.delivery_key}"
            )
        record = _record(existing)
        same = (
            record.delivery_key == str(intent.delivery_key)
            and record.player_id == int(intent.player_id)
            and record.address.is_region == bool(intent.is_region)
            and (intent.protocol_mail_id is None or record.address.protocol_mail_id == int(intent.protocol_mail_id))
            and dict(record.protocol_payload) == dict(intent.protocol_payload)
            and tuple(dict(x) for x in record.attachments) == tuple(dict(x) for x in intent.attachments)
            and record.expires_at == intent.expires_at
            and record.source_type == str(intent.source_type)
            and record.source_id == str(intent.source_id)
            and dict(record.metadata) == dict(intent.metadata or {})
        )
        if not same:
            raise MailDeliveryConflict(f"delivery_key semantic collision: {intent.delivery_key}")
        return record, True

    def list_player(self, connection: Connection, player_id: int, *, limit: int | None = None) -> tuple[MailRecord, ...]:
        stmt = (
            select(self.table)
            .where(self.table.c.player_id == int(player_id))
            .order_by(self.table.c.created_at.desc(), self.table.c.mail_row_id.desc())
        )
        if limit is not None:
            if isinstance(limit, bool) or int(limit) <= 0:
                raise ValueError("limit must be positive")
            stmt = stmt.limit(int(limit))
        return tuple(_record(row) for row in connection.execute(stmt).mappings().all())

    def load_locked(self, connection: Connection, player_id: int, address: MailAddress) -> tuple[MailRecord | None, Any]:
        row = connection.execute(
            select(self.table, func.now().label("db_now"))
            .where(
                self.table.c.player_id == int(player_id),
                self.table.c.is_region == bool(address.is_region),
                self.table.c.protocol_mail_id == int(address.protocol_mail_id),
            )
            .with_for_update()
        ).mappings().first()
        if row is None:
            return None, None
        return _record(row), row["db_now"]

    def mark_read(self, connection: Connection, player_id: int, addresses: Iterable[MailAddress]) -> int:
        count = 0
        for address in sorted(set(addresses)):
            result = connection.execute(
                update(self.table)
                .where(
                    self.table.c.player_id == int(player_id),
                    self.table.c.is_region == bool(address.is_region),
                    self.table.c.protocol_mail_id == int(address.protocol_mail_id),
                    self.table.c.read_at.is_(None),
                )
                .values(read_at=func.now())
            )
            count += int(getattr(result, "rowcount", 0) or 0)
        return count

    def mark_claimed(self, connection: Connection, mail_row_id: int) -> bool:
        result = connection.execute(
            update(self.table)
            .where(self.table.c.mail_row_id == int(mail_row_id), self.table.c.claimed_at.is_(None))
            .values(claimed_at=func.now(), read_at=func.coalesce(self.table.c.read_at, func.now()))
        )
        return int(getattr(result, "rowcount", 0) or 0) == 1
