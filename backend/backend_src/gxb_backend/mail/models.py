"""Typed I6 mailbox identities and durable delivery records."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Any, Mapping


@dataclass(frozen=True, order=True)
class MailAddress:
    is_region: bool
    protocol_mail_id: int

    def __post_init__(self) -> None:
        if isinstance(self.protocol_mail_id, bool) or int(self.protocol_mail_id) <= 0:
            raise ValueError("protocol_mail_id must be positive")
        object.__setattr__(self, "protocol_mail_id", int(self.protocol_mail_id))
        object.__setattr__(self, "is_region", bool(self.is_region))


@dataclass(frozen=True)
class MailDeliveryIntent:
    player_id: int
    delivery_key: str
    source_type: str
    source_id: str
    protocol_payload: Mapping[str, Any]
    attachments: tuple[Mapping[str, Any], ...] = ()
    is_region: bool = False
    protocol_mail_id: int | None = None
    legacy_mail_id: int | None = None
    expires_at: datetime | None = None
    metadata: Mapping[str, Any] | None = None

    def __post_init__(self) -> None:
        if isinstance(self.player_id, bool) or int(self.player_id) <= 0:
            raise ValueError("player_id must be positive")
        for field in ("delivery_key", "source_type", "source_id"):
            if not str(getattr(self, field)).strip():
                raise ValueError(f"{field} must not be empty")
        if self.protocol_mail_id is not None and int(self.protocol_mail_id) <= 0:
            raise ValueError("protocol_mail_id must be positive when supplied")


@dataclass(frozen=True)
class MailRecord:
    mail_row_id: int
    player_id: int
    address: MailAddress
    delivery_key: str
    protocol_payload: Mapping[str, Any]
    attachments: tuple[Mapping[str, Any], ...]
    created_at: datetime
    expires_at: datetime | None
    read_at: datetime | None
    claimed_at: datetime | None
    source_type: str
    source_id: str
    metadata: Mapping[str, Any]

    def to_wire(self) -> dict[str, Any]:
        """Preserve unknown row extensions while canonical typed fields win."""
        row = dict(self.protocol_payload)
        row["id"] = int(self.address.protocol_mail_id)
        row["is_region"] = 1 if self.address.is_region else 0
        row["is_read"] = 1 if self.read_at is not None else 0
        row["is_awarded"] = 1 if self.claimed_at is not None else 0
        if self.expires_at is not None:
            row["expired_time"] = int(self.expires_at.timestamp())
        if self.attachments:
            # Do not invent attachment field semantics if a migrated payload
            # already preserves them under another key.
            row.setdefault("attachments", [dict(x) for x in self.attachments])
        return row
