"""Source/target accounting and application-read validation for I7."""
from __future__ import annotations

from typing import Any

from sqlalchemy import func, select, text
from sqlalchemy.engine import Connection

from gxb_backend.identity.credentials import PasswordCredentialService
from gxb_backend.identity.schema import account_credentials, accounts, account_sessions, gameplay_contexts, regions, session_credentials
from gxb_backend.mail.schema import mail_items
from gxb_backend.persistence.codec import PlayerPayloadCodec, canonical_json_digest
from gxb_backend.persistence.repositories import PostgresPlayerAggregateRepository
from gxb_backend.persistence.schema import account_global_state, players
from gxb_backend.projections.schema import rank_projection_live, rank_snapshots
from gxb_backend.state.defaults import default_player
from gxb_backend.transactions.schema import operation_receipts, outbox_events, scheduled_jobs

from .models import SourceInventory, TargetAccounting
from .source import MigrationSourceReader


class MigrationValidationError(RuntimeError):
    pass


def _count(connection: Connection, table: Any) -> int:
    return int(connection.scalar(select(func.count()).select_from(table)) or 0)


def _expect(name: str, actual: Any, expected: Any) -> None:
    if actual != expected:
        raise MigrationValidationError(f"{name} mismatch: expected {expected!r}, got {actual!r}")


def validate_candidate(connection: Connection, inventory: SourceInventory) -> TargetAccounting:
    MigrationSourceReader.assert_stable(inventory)
    connection.execute(text("SET CONSTRAINTS ALL IMMEDIATE"))

    counts = {
        "accounts": _count(connection, accounts),
        "credentials": _count(connection, account_credentials),
        "sessions": _count(connection, account_sessions),
        "contexts": _count(connection, gameplay_contexts),
        "session_credentials": _count(connection, session_credentials),
        "players": _count(connection, players),
        "account_global": _count(connection, account_global_state),
        "receipts": _count(connection, operation_receipts),
        "mail": _count(connection, mail_items),
        "outbox": _count(connection, outbox_events),
        "scheduled_jobs": _count(connection, scheduled_jobs),
        "rank_projection_live": _count(connection, rank_projection_live),
        "rank_snapshots": _count(connection, rank_snapshots),
    }
    expected_credentials = sum(1 for x in inventory.accounts if x.password_record is not None)
    expected_account_global = len(inventory.accounts)
    expected = {
        "accounts": len(inventory.accounts), "credentials": expected_credentials,
        "sessions": 0, "contexts": 0, "session_credentials": 0,
        "players": len(inventory.players), "account_global": expected_account_global,
        "receipts": inventory.counts["receipts"], "mail": inventory.counts["mail"],
        "outbox": 0, "scheduled_jobs": 0, "rank_projection_live": 0, "rank_snapshots": 0,
    }
    _expect("target table counts", counts, expected)

    account_rows = connection.execute(select(
        accounts.c.account_uid, accounts.c.account_type, accounts.c.username,
    ).order_by(accounts.c.account_uid)).mappings().all()
    account_view = [{"account_uid": str(x["account_uid"]), "account_type": str(x["account_type"]), "username": str(x["username"])} for x in account_rows]
    expected_account_view = [{"account_uid": x.account_uid, "account_type": x.account_type, "username": x.username} for x in sorted(inventory.accounts, key=lambda a: a.account_uid)]
    _expect("account identity", account_view, expected_account_view)

    credential_rows = {str(x["account_uid"]): x for x in connection.execute(select(account_credentials)).mappings().all()}
    for account in inventory.accounts:
        if account.password_record is None:
            continue
        row = credential_rows.get(account.account_uid)
        if row is None:
            raise MigrationValidationError(f"missing password credential: {account.account_uid}")
        expected_hash = PasswordCredentialService.encode_legacy_pbkdf2(
            iterations=int(account.password_record["iterations"]),
            salt_hex=str(account.password_record["salt"]),
            hash_hex=str(account.password_record["hash"]),
        )
        _expect(f"credential provider {account.account_uid}", row["provider"], "LOCAL_PASSWORD")
        _expect(f"credential subject {account.account_uid}", row["subject_normalized"], account.normalized_login)
        _expect(f"credential algorithm {account.account_uid}", row["password_algorithm"], PasswordCredentialService.LEGACY_ALGORITHM)
        _expect(f"credential verifier {account.account_uid}", row["password_hash"], expected_hash)

    player_rows = connection.execute(select(players).order_by(players.c.player_id)).mappings().all()
    actual_players = [{
        "player_id": int(x["player_id"]), "account_uid": str(x["account_uid"]),
        "region_id": int(x["region_id"]), "schema_version": int(x["schema_version"]),
        "state_version": int(x["state_version"]), "payload": dict(x["payload"]),
    } for x in player_rows]
    expected_players = [{
        "player_id": p.player_id, "account_uid": p.account_uid, "region_id": p.region_id,
        "schema_version": p.transformed.record.schema_version,
        "state_version": p.transformed.record.state_version,
        "payload": dict(p.transformed.record.payload),
    } for p in sorted(inventory.players, key=lambda p: p.player_id)]
    _expect("player aggregate semantics", actual_players, expected_players)

    repository = PostgresPlayerAggregateRepository()
    for source in inventory.players:
        record = repository.load_for_update(connection, source.player_id)
        if record is None:
            raise MigrationValidationError(f"application adapter cannot load player {source.player_id}")
        hydrated = PlayerPayloadCodec.hydrate(
            record, default_player(), receipts=source.transformed.receipts, mails=source.transformed.mails,
        )
        roundtrip = PlayerPayloadCodec.transform(hydrated)
        _expect(f"player roundtrip record {source.player_id}", roundtrip.record, source.transformed.record)
        _expect(f"player roundtrip extraction {source.player_id}", roundtrip.extraction_accounting(), source.transformed.extraction_accounting())

    expected_receipts = []
    for player in inventory.players:
        for receipt in player.transformed.receipts:
            expected_receipts.append({
                "player_id": player.player_id, "account_uid": player.account_uid,
                "domain": receipt.domain, "migration_key": receipt.migration_key(player.player_id),
                "fingerprint": receipt.canonical_digest, "result": dict(receipt.record),
            })
    expected_receipts.sort(key=lambda x: (x["player_id"], x["domain"], x["migration_key"]))
    receipt_rows = connection.execute(select(operation_receipts).order_by(
        operation_receipts.c.resource_key, operation_receipts.c.domain, operation_receipts.c.idempotency_key,
    )).mappings().all()
    actual_receipts = []
    for row in receipt_rows:
        fingerprint = row["request_fingerprint"]
        if isinstance(fingerprint, memoryview):
            fingerprint = fingerprint.tobytes()
        actual_receipts.append({
            "player_id": int(row["resource_key"]), "account_uid": str(row["actor_account_uid"]),
            "domain": str(row["domain"]), "migration_key": str(row["idempotency_key"]),
            "fingerprint": bytes(fingerprint).hex(), "result": dict(row["result"]),
        })
    actual_receipts.sort(key=lambda x: (x["player_id"], x["domain"], x["migration_key"]))
    _expect("receipt extraction", actual_receipts, expected_receipts)

    expected_mail = []
    for player in inventory.players:
        for mail in player.transformed.mails:
            expected_mail.append({"delivery_key": mail.delivery_key(player.player_id), "digest": mail.canonical_digest, "payload": dict(mail.payload)})
    expected_mail.sort(key=lambda x: x["delivery_key"])
    actual_mail = [{
        "delivery_key": str(x["delivery_key"]),
        "digest": str(dict(x["metadata"])["canonical_row_digest"]),
        "payload": dict(x["protocol_payload"]),
    } for x in connection.execute(select(mail_items).order_by(mail_items.c.delivery_key)).mappings().all()]
    _expect("mail extraction", actual_mail, expected_mail)

    allocator_rows = {int(x[0]): int(x[1]) for x in connection.execute(select(regions.c.region_id, regions.c.next_player_id).where(regions.c.region_id.in_(list(inventory.region_next_player_ids))))}
    _expect("region allocators", allocator_rows, dict(inventory.region_next_player_ids))
    sequence = connection.execute(text('SELECT last_value, is_called FROM "gxb"."account_uid_seq"')).one()
    _expect("account sequence value", int(sequence[0]), inventory.next_account_uid)
    _expect("account sequence call state", bool(sequence[1]), False)

    invalid_constraints = int(connection.scalar(text(
        "SELECT count(*) FROM pg_constraint c JOIN pg_namespace n ON n.oid=c.connamespace WHERE n.nspname='gxb' AND NOT c.convalidated"
    )) or 0)
    _expect("unvalidated constraints", invalid_constraints, 0)

    digests = {
        "accounts": canonical_json_digest(account_view),
        "players": canonical_json_digest(actual_players),
        "receipts": canonical_json_digest(actual_receipts),
        "mail": canonical_json_digest(actual_mail),
        "region_allocators": canonical_json_digest(allocator_rows),
    }
    invariants = {
        "source_manifest_stable": True,
        "credentials_preserved_without_bearers": True,
        "ownership_and_region_exact": True,
        "player_codec_roundtrip_exact": True,
        "receipt_accounting_exact": True,
        "mail_accounting_exact": True,
        "allocators_safe": True,
        "database_constraints_validated": True,
        "application_adapter_reads_all_players": True,
        "traffic_open_untouched": True,
    }
    return TargetAccounting(counts=counts, digests=digests, invariant_results=invariants)
