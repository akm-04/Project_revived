"""Relational writes for an offline, disposable I7 candidate database."""
from __future__ import annotations

import hashlib
from datetime import datetime, timezone
from typing import Any
from uuid import UUID, uuid5

from alembic.config import Config
from alembic.script import ScriptDirectory
from sqlalchemy import func, insert, select, text, update
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.engine import Connection

from gxb_backend.identity.credentials import PasswordCredentialService
from gxb_backend.identity.schema import account_credentials, accounts, account_sessions, gameplay_contexts, regions, session_credentials
from gxb_backend.mail.schema import mail_items
from gxb_backend.persistence.schema import account_global_state, players
from gxb_backend.projections.schema import rank_projection_live, rank_snapshots
from gxb_backend.transactions.schema import operation_receipts, outbox_events, scheduled_jobs

from .models import SourceInventory
from .schema import migration_runs


MIGRATION_NAMESPACE = UUID("76c3d094-7ef2-4b53-91c0-cbe4ff2a0b5a")


def alembic_head(config_path: str = "alembic.ini") -> str:
    head = ScriptDirectory.from_config(Config(config_path)).get_current_head()
    if not head:
        raise RuntimeError("Alembic has no current head")
    return head


def _utc_epoch(value: Any, fallback: datetime) -> datetime:
    try:
        parsed = int(value)
        if parsed > 0:
            return datetime.fromtimestamp(parsed, tz=timezone.utc)
    except (TypeError, ValueError, OverflowError, OSError):
        pass
    return fallback


def _legacy_password(account: Any) -> tuple[str, str] | None:
    record = account.password_record
    if record is None:
        return None
    encoded = PasswordCredentialService.encode_legacy_pbkdf2(
        iterations=int(record["iterations"]),
        salt_hex=str(record["salt"]),
        hash_hex=str(record["hash"]),
    )
    return PasswordCredentialService.LEGACY_ALGORITHM, encoded


def assert_fresh_candidate(connection: Connection) -> None:
    """Refuse any target that is not an empty, explicitly disposable candidate."""
    database = str(connection.scalar(text("SELECT current_database()")) or "")
    if not database.endswith("_test"):
        raise RuntimeError("I7 rehearsal target database name must end with _test")
    tables = (
        accounts, account_sessions, gameplay_contexts, session_credentials, players,
        account_global_state, operation_receipts, outbox_events, scheduled_jobs,
        mail_items, rank_projection_live, rank_snapshots, migration_runs,
    )
    nonempty = [table.name for table in tables if int(connection.scalar(select(func.count()).select_from(table)) or 0)]
    if nonempty:
        raise RuntimeError("I7 candidate must be fresh; non-empty tables: " + ", ".join(sorted(nonempty)))


def create_run(connection: Connection, run_id: UUID, inventory: SourceInventory, started_at: datetime) -> None:
    connection.execute(insert(migration_runs).values(
        migration_run_id=run_id,
        source_content_root=inventory.content_root,
        source_manifest_digest=inventory.manifest_digest,
        target_alembic_revision=alembic_head(),
        status="DISCOVERED",
        started_at=started_at,
        report={"pass": "346.0", "wave": "I7", "mode": "OFFLINE_REHEARSAL", "traffic_open": False},
    ))


def update_run(connection: Connection, run_id: UUID, status: str, report: dict[str, Any] | None = None) -> None:
    values: dict[str, Any] = {"status": status}
    if report is not None:
        values["report"] = report
    if status == "VALIDATED":
        values["validated_at"] = func.now()
    # I7 deliberately has no code path that writes TRAFFIC_OPEN.
    connection.execute(update(migration_runs).where(migration_runs.c.migration_run_id == run_id).values(**values))


def import_inventory(connection: Connection, inventory: SourceInventory, run_id: UUID, started_at: datetime) -> tuple[dict[str, int], tuple[dict[str, Any], ...]]:
    for account in inventory.accounts:
        connection.execute(insert(accounts).values(
            account_uid=account.account_uid,
            account_type=account.account_type,
            username=account.username,
            created_at=_utc_epoch(account.created_at, started_at),
            metadata={**dict(account.metadata), "legacy_login": account.login, "migration_source": "pass299_json"},
        ))
        credential = _legacy_password(account)
        if credential is not None:
            algorithm, encoded_hash = credential
            credential_id = uuid5(MIGRATION_NAMESPACE, f"credential:{inventory.content_root}:{account.account_uid}:{account.normalized_login}")
            connection.execute(insert(account_credentials).values(
                credential_id=credential_id,
                account_uid=account.account_uid,
                provider="LOCAL_PASSWORD",
                subject_normalized=account.normalized_login,
                password_hash=encoded_hash,
                password_algorithm=algorithm,
                password_version=1,
                enabled=True,
                created_at=_utc_epoch(account.created_at, started_at),
                updated_at=started_at,
            ))
        connection.execute(pg_insert(account_global_state).values(
            account_uid=account.account_uid,
            schema_version=1,
            state_version=0,
            payload={},
            updated_at=started_at,
        ).on_conflict_do_nothing(index_elements=[account_global_state.c.account_uid]))

    for region_id, next_player_id in inventory.region_next_player_ids.items():
        result = connection.execute(
            update(regions).where(regions.c.region_id == region_id).values(next_player_id=next_player_id)
        )
        if int(result.rowcount or 0) != 1:
            raise RuntimeError(f"source region {region_id} does not exist in target catalog")

    connection.execute(text('SELECT setval(\'"gxb"."account_uid_seq"\', :next_uid, false)'), {"next_uid": inventory.next_account_uid})

    for player in inventory.players:
        record = player.transformed.record
        connection.execute(insert(players).values(
            player_id=player.player_id,
            account_uid=player.account_uid,
            region_id=player.region_id,
            created_at=started_at,
            schema_version=record.schema_version,
            state_version=record.state_version,
            payload=dict(record.payload),
            updated_at=started_at,
        ))
        for receipt in player.transformed.receipts:
            migration_key = receipt.migration_key(player.player_id)
            if len(migration_key) > 255 or len(receipt.domain) > 96:
                raise RuntimeError(f"legacy receipt identity exceeds target bound for player {player.player_id}")
            connection.execute(insert(operation_receipts).values(
                receipt_id=uuid5(MIGRATION_NAMESPACE, f"receipt:{inventory.content_root}:{migration_key}"),
                resource_kind="PLAYER",
                resource_key=str(player.player_id),
                domain=receipt.domain,
                operation="LEGACY_IMPORT",
                idempotency_key=migration_key,
                request_fingerprint=bytes.fromhex(receipt.canonical_digest),
                actor_account_uid=player.account_uid,
                context_id=None,
                result=dict(receipt.record),
                retention_policy="MIGRATED_LEGACY",
                committed_at=started_at,
            ))

    mail_remaps = _insert_mail(connection, inventory, started_at)
    return inventory.counts, mail_remaps


def _insert_mail(connection: Connection, inventory: SourceInventory, started_at: datetime) -> tuple[dict[str, Any], ...]:
    rows: list[tuple[Any, Any]] = []
    valid_ids: list[int] = []
    for player in inventory.players:
        for mail in player.transformed.mails:
            rows.append((player, mail))
            raw = mail.legacy_mail_id
            if raw is not None:
                try:
                    value = int(raw)
                except (TypeError, ValueError):
                    continue
                if value > 0:
                    valid_ids.append(value)
    next_remap = max(valid_ids, default=0) + 1
    used: set[tuple[int, bool, int]] = set()
    remaps: list[dict[str, Any]] = []
    for player, mail in rows:
        payload = dict(mail.payload)
        is_region = bool(payload.get("is_region", False))
        raw = mail.legacy_mail_id
        try:
            legacy_id = int(raw) if raw is not None else None
        except (TypeError, ValueError):
            legacy_id = None
        protocol_id = legacy_id if legacy_id is not None and legacy_id > 0 else None
        identity = (player.player_id, is_region, protocol_id or 0)
        if protocol_id is None or identity in used:
            while (player.player_id, is_region, next_remap) in used:
                next_remap += 1
            protocol_id = next_remap
            next_remap += 1
            remaps.append({
                "player_id": player.player_id,
                "source_ordinal": mail.ordinal,
                "legacy_mail_id": raw,
                "protocol_mail_id": protocol_id,
                "reason": "missing_invalid_or_colliding_legacy_id",
            })
        used.add((player.player_id, is_region, protocol_id))
        created = _utc_epoch(payload.get("created_at", payload.get("send_time", payload.get("time"))), started_at)
        expires_raw = payload.get("expires_at", payload.get("expired_time"))
        expires = _utc_epoch(expires_raw, created) if expires_raw else None
        if expires is not None and expires <= created:
            expires = None
        attachments = payload.get("attachments")
        if not isinstance(attachments, list):
            attachments = payload.get("awards") if isinstance(payload.get("awards"), list) else []
        read = bool(payload.get("is_read", payload.get("read", False)))
        claimed = bool(payload.get("is_awarded", payload.get("claimed", False)))
        connection.execute(insert(mail_items).values(
            player_id=player.player_id,
            is_region=is_region,
            protocol_mail_id=protocol_id,
            legacy_mail_id=legacy_id if legacy_id is not None and legacy_id > 0 else None,
            delivery_key=mail.delivery_key(player.player_id),
            protocol_payload=payload,
            attachments=attachments,
            created_at=created,
            expires_at=expires,
            read_at=created if read or claimed else None,
            claimed_at=created if claimed else None,
            source_type="LEGACY_JSON_IMPORT",
            source_id=f"{player.source_path}#mail:{mail.ordinal}",
            metadata={"canonical_row_digest": mail.canonical_digest, "source_ordinal": mail.ordinal},
        ))
    if rows:
        maximum = max(x[2] for x in used)
        connection.execute(text('SELECT setval(\'"gxb"."mail_protocol_id_seq"\', :next_id, false)'), {"next_id": maximum + 1})
    return tuple(remaps)
