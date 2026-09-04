"""SQLAlchemy Core repositories for the Pass342 relational identity plane.

These repositories own only identity/session/context/region-directory rows.  They
never read or write mature PlayerState gameplay payloads; that remains Wave I4.
"""

from __future__ import annotations

from datetime import datetime, timedelta
from typing import Any, Mapping
from uuid import UUID

from sqlalchemy import and_, func, select, update
from sqlalchemy.engine import Connection

from .errors import CredentialInvalid, RegionFull, RegionUnavailable, SessionExpired, SessionRevoked
from .models import (
    AccountPrincipal,
    AccountSessionSnapshot,
    CredentialKind,
    GameplayContextSnapshot,
    IdentityPolicy,
    PlayerDirectorySnapshot,
    RegionSnapshot,
    ResolvedAccountCredential,
)
from .schema import (
    account_credentials,
    account_sessions,
    account_uid_seq,
    accounts,
    gameplay_contexts,
    players,
    regions,
    session_credentials,
)


def _row_mapping(row: Any) -> Mapping[str, Any] | None:
    if row is None:
        return None
    mapping = getattr(row, "_mapping", None)
    if mapping is not None:
        return mapping
    if isinstance(row, Mapping):
        return row
    return None


def _one_mapping(result: Any) -> Mapping[str, Any] | None:
    mappings = getattr(result, "mappings", None)
    if callable(mappings):
        mapped = mappings()
        first = getattr(mapped, "first", None)
        if callable(first):
            return _row_mapping(first())
    first = getattr(result, "first", None)
    if callable(first):
        return _row_mapping(first())
    return None


def _all_mappings(result: Any) -> tuple[Mapping[str, Any], ...]:
    mappings = getattr(result, "mappings", None)
    if callable(mappings):
        mapped = mappings()
        all_rows = getattr(mapped, "all", None)
        if callable(all_rows):
            return tuple(row for item in all_rows() if (row := _row_mapping(item)) is not None)
    all_rows = getattr(result, "all", None)
    if callable(all_rows):
        return tuple(row for item in all_rows() if (row := _row_mapping(item)) is not None)
    return ()


def _session_from_row(row: Mapping[str, Any]) -> AccountSessionSnapshot:
    return AccountSessionSnapshot(
        session_id=row["session_id"],
        account_uid=str(row["account_uid"]),
        issued_at=row["issued_at"],
        last_activity_at=row["last_activity_at"],
        absolute_expires_at=row.get("absolute_expires_at"),
        revoked_at=row.get("revoked_at"),
        revocation_reason=row.get("revocation_reason"),
        device_metadata=row.get("device_metadata"),
    )


def _context_from_row(row: Mapping[str, Any]) -> GameplayContextSnapshot:
    return GameplayContextSnapshot(
        context_id=row["context_id"],
        session_id=row.get("context_session_id", row["session_id"]),
        account_uid=str(row.get("context_account_uid", row["account_uid"])),
        region_id=int(row["region_id"]),
        player_id=int(row["player_id"]),
        created_at=row["created_at"],
        ended_at=row.get("ended_at"),
        end_reason=row.get("end_reason"),
        superseded_by_context_id=row.get("superseded_by_context_id"),
    )


class AccountRepository:
    LOCAL_PROVIDER = "LOCAL_PASSWORD"

    def next_account_uid(self, connection: Connection) -> str:
        value = connection.execute(select(account_uid_seq.next_value())).scalar_one()
        return str(int(value))

    def get_principal(self, connection: Connection, account_uid: str) -> AccountPrincipal | None:
        row = _one_mapping(
            connection.execute(
                select(accounts.c.account_uid, accounts.c.account_type, accounts.c.username).where(
                    accounts.c.account_uid == str(account_uid)
                )
            )
        )
        if row is None:
            return None
        return AccountPrincipal(
            account_uid=str(row["account_uid"]),
            account_type=str(row["account_type"]),
            username=str(row["username"]),
        )

    def get_local_credential(
        self,
        connection: Connection,
        subject_normalized: str,
        *,
        for_update: bool = False,
    ) -> Mapping[str, Any] | None:
        statement = (
            select(
                account_credentials.c.credential_id,
                account_credentials.c.account_uid,
                account_credentials.c.provider,
                account_credentials.c.subject_normalized,
                account_credentials.c.password_hash,
                account_credentials.c.password_algorithm,
                account_credentials.c.password_version,
                account_credentials.c.enabled,
                accounts.c.account_type,
                accounts.c.username,
            )
            .select_from(
                account_credentials.join(
                    accounts, account_credentials.c.account_uid == accounts.c.account_uid
                )
            )
            .where(
                account_credentials.c.provider == self.LOCAL_PROVIDER,
                account_credentials.c.subject_normalized == str(subject_normalized),
            )
        )
        if for_update:
            statement = statement.with_for_update(of=account_credentials)
        return _one_mapping(connection.execute(statement))

    def create_local_account(
        self,
        connection: Connection,
        *,
        credential_id: UUID,
        account_uid: str,
        username: str,
        subject_normalized: str,
        password_hash: str,
        password_algorithm: str,
        created_at: datetime,
        account_type: str = "normal",
        metadata_value: Mapping[str, Any] | None = None,
    ) -> AccountPrincipal:
        connection.execute(
            accounts.insert().values(
                account_uid=str(account_uid),
                account_type=str(account_type),
                username=str(username),
                created_at=created_at,
                metadata=dict(metadata_value or {}),
            )
        )
        connection.execute(
            account_credentials.insert().values(
                credential_id=credential_id,
                account_uid=str(account_uid),
                provider=self.LOCAL_PROVIDER,
                subject_normalized=str(subject_normalized),
                password_hash=str(password_hash),
                password_algorithm=str(password_algorithm),
                password_version=1,
                enabled=True,
                created_at=created_at,
                updated_at=created_at,
            )
        )
        return AccountPrincipal(str(account_uid), str(account_type), str(username))

    def upgrade_password(
        self,
        connection: Connection,
        *,
        credential_id: UUID,
        password_hash: str,
        password_algorithm: str,
        updated_at: datetime,
    ) -> bool:
        statement = (
            update(account_credentials)
            .where(account_credentials.c.credential_id == credential_id)
            .values(
                password_hash=str(password_hash),
                password_algorithm=str(password_algorithm),
                password_version=account_credentials.c.password_version + 1,
                updated_at=updated_at,
            )
        )
        return connection.execute(statement).rowcount == 1


class SessionRepository:
    def create_session(
        self,
        connection: Connection,
        *,
        session_id: UUID,
        account_uid: str,
        issued_at: datetime,
        absolute_expires_at: datetime | None,
        device_metadata: Mapping[str, Any] | None,
        sid_credential_id: UUID,
        sid_digest: bytes,
        login_credential_id: UUID,
        login_digest: bytes,
    ) -> AccountSessionSnapshot:
        connection.execute(
            account_sessions.insert().values(
                session_id=session_id,
                account_uid=str(account_uid),
                issued_at=issued_at,
                last_activity_at=issued_at,
                absolute_expires_at=absolute_expires_at,
                revoked_at=None,
                revocation_reason=None,
                device_metadata=dict(device_metadata or {}) if device_metadata is not None else None,
            )
        )
        credential_rows = (
            {
                "credential_id": sid_credential_id,
                "credential_hash": bytes(sid_digest),
                "kind": CredentialKind.SDK_SID_COMPAT.value,
                "session_id": session_id,
                "context_id": None,
                "issued_at": issued_at,
                "expires_at": absolute_expires_at,
                "revoked_at": None,
            },
            {
                "credential_id": login_credential_id,
                "credential_hash": bytes(login_digest),
                "kind": CredentialKind.LOGIN_TOKEN.value,
                "session_id": session_id,
                "context_id": None,
                "issued_at": issued_at,
                "expires_at": absolute_expires_at,
                "revoked_at": None,
            },
        )
        connection.execute(session_credentials.insert(), list(credential_rows))
        return AccountSessionSnapshot(
            session_id=session_id,
            account_uid=str(account_uid),
            issued_at=issued_at,
            last_activity_at=issued_at,
            absolute_expires_at=absolute_expires_at,
            revoked_at=None,
            revocation_reason=None,
            device_metadata=dict(device_metadata or {}) if device_metadata is not None else None,
        )

    def get_session(
        self,
        connection: Connection,
        session_id: UUID,
        *,
        for_update: bool = False,
        for_share: bool = False,
    ) -> AccountSessionSnapshot | None:
        if for_update and for_share:
            raise ValueError("choose at most one lock mode")
        statement = select(account_sessions).where(account_sessions.c.session_id == session_id)
        if for_update:
            statement = statement.with_for_update()
        elif for_share:
            statement = statement.with_for_update(read=True)
        row = _one_mapping(connection.execute(statement))
        return _session_from_row(row) if row is not None else None

    def resolve_credential_digest(
        self,
        connection: Connection,
        *,
        kind: CredentialKind,
        credential_hash: bytes,
    ) -> ResolvedAccountCredential | None:
        statement = (
            select(
                session_credentials.c.kind,
                session_credentials.c.expires_at.label("credential_expires_at"),
                session_credentials.c.revoked_at.label("credential_revoked_at"),
                account_sessions.c.session_id,
                account_sessions.c.account_uid,
                account_sessions.c.issued_at,
                account_sessions.c.last_activity_at,
                account_sessions.c.absolute_expires_at,
                account_sessions.c.revoked_at,
                account_sessions.c.revocation_reason,
                account_sessions.c.device_metadata,
                accounts.c.account_type,
                accounts.c.username,
            )
            .select_from(
                session_credentials.join(
                    account_sessions,
                    session_credentials.c.session_id == account_sessions.c.session_id,
                ).join(accounts, account_sessions.c.account_uid == accounts.c.account_uid)
            )
            .where(
                session_credentials.c.kind == kind.value,
                session_credentials.c.credential_hash == bytes(credential_hash),
            )
        )
        row = _one_mapping(connection.execute(statement))
        if row is None:
            return None
        if row.get("credential_revoked_at") is not None:
            return None
        return ResolvedAccountCredential(
            account=AccountPrincipal(
                account_uid=str(row["account_uid"]),
                account_type=str(row["account_type"]),
                username=str(row["username"]),
            ),
            session=_session_from_row(row),
            credential_expires_at=row.get("credential_expires_at"),
        )

    @staticmethod
    def validate_liveness(
        session: AccountSessionSnapshot,
        *,
        policy: IdentityPolicy,
        now: datetime,
    ) -> None:
        if session.revoked_at is not None:
            raise SessionRevoked(session.revocation_reason or "session revoked")
        if session.absolute_expires_at is not None and now >= session.absolute_expires_at:
            raise SessionExpired("absolute session expiry reached")
        if policy.idle_session_ttl is not None and now >= session.last_activity_at + policy.idle_session_ttl:
            raise SessionExpired("idle session expiry reached")

    def maybe_touch_activity(
        self,
        connection: Connection,
        *,
        session: AccountSessionSnapshot,
        policy: IdentityPolicy,
        now: datetime,
    ) -> bool:
        if now < session.last_activity_at + policy.activity_write_interval:
            return False
        statement = (
            update(account_sessions)
            .where(
                account_sessions.c.session_id == session.session_id,
                account_sessions.c.revoked_at.is_(None),
                account_sessions.c.last_activity_at == session.last_activity_at,
            )
            .values(last_activity_at=now)
        )
        return connection.execute(statement).rowcount == 1

    def revoke_session(
        self,
        connection: Connection,
        *,
        session_id: UUID,
        revoked_at: datetime,
        reason: str,
    ) -> bool:
        updated = connection.execute(
            update(account_sessions)
            .where(account_sessions.c.session_id == session_id, account_sessions.c.revoked_at.is_(None))
            .values(revoked_at=revoked_at, revocation_reason=str(reason)[:96])
        ).rowcount
        connection.execute(
            update(session_credentials)
            .where(
                session_credentials.c.session_id == session_id,
                session_credentials.c.revoked_at.is_(None),
            )
            .values(revoked_at=revoked_at)
        )
        return bool(updated)


class ContextRepository:
    def get_active_for_session(
        self,
        connection: Connection,
        session_id: UUID,
        *,
        for_update: bool = False,
        for_share: bool = False,
    ) -> GameplayContextSnapshot | None:
        if for_update and for_share:
            raise ValueError("choose at most one lock mode")
        statement = select(gameplay_contexts).where(
            gameplay_contexts.c.session_id == session_id,
            gameplay_contexts.c.ended_at.is_(None),
        )
        if for_update:
            statement = statement.with_for_update(of=gameplay_contexts)
        elif for_share:
            statement = statement.with_for_update(read=True, of=gameplay_contexts)
        row = _one_mapping(connection.execute(statement))
        return _context_from_row(row) if row is not None else None

    def get_context(
        self,
        connection: Connection,
        context_id: UUID,
        *,
        for_share: bool = False,
    ) -> GameplayContextSnapshot | None:
        statement = select(gameplay_contexts).where(
            gameplay_contexts.c.context_id == context_id
        )
        if for_share:
            statement = statement.with_for_update(read=True, of=gameplay_contexts)
        row = _one_mapping(connection.execute(statement))
        return _context_from_row(row) if row is not None else None

    def create_context(
        self,
        connection: Connection,
        *,
        context_id: UUID,
        session_id: UUID,
        account_uid: str,
        region_id: int,
        player_id: int,
        created_at: datetime,
    ) -> None:
        connection.execute(
            gameplay_contexts.insert().values(
                context_id=context_id,
                session_id=session_id,
                account_uid=str(account_uid),
                region_id=int(region_id),
                player_id=int(player_id),
                created_at=created_at,
                ended_at=None,
                end_reason=None,
                superseded_by_context_id=None,
            )
        )

    def end_context(
        self,
        connection: Connection,
        *,
        context_id: UUID,
        ended_at: datetime,
        reason: str,
        superseded_by_context_id: UUID | None = None,
    ) -> bool:
        changed = connection.execute(
            update(gameplay_contexts)
            .where(
                gameplay_contexts.c.context_id == context_id,
                gameplay_contexts.c.ended_at.is_(None),
            )
            .values(
                ended_at=ended_at,
                end_reason=str(reason)[:96],
                superseded_by_context_id=superseded_by_context_id,
            )
        ).rowcount
        return bool(changed)

    def set_superseded_by(
        self,
        connection: Connection,
        *,
        context_id: UUID,
        superseded_by_context_id: UUID,
    ) -> bool:
        changed = connection.execute(
            update(gameplay_contexts)
            .where(
                gameplay_contexts.c.context_id == context_id,
                gameplay_contexts.c.ended_at.is_not(None),
            )
            .values(superseded_by_context_id=superseded_by_context_id)
        ).rowcount
        return bool(changed)

    def revoke_gameplay_credentials(
        self,
        connection: Connection,
        *,
        context_id: UUID,
        revoked_at: datetime,
    ) -> int:
        return int(
            connection.execute(
                update(session_credentials)
                .where(
                    session_credentials.c.context_id == context_id,
                    session_credentials.c.kind == CredentialKind.GAMEPLAY_TOKEN.value,
                    session_credentials.c.revoked_at.is_(None),
                )
                .values(revoked_at=revoked_at)
            ).rowcount
            or 0
        )

    def create_gameplay_credential(
        self,
        connection: Connection,
        *,
        credential_id: UUID,
        credential_hash: bytes,
        session_id: UUID,
        context_id: UUID,
        issued_at: datetime,
        expires_at: datetime | None,
    ) -> None:
        connection.execute(
            session_credentials.insert().values(
                credential_id=credential_id,
                credential_hash=bytes(credential_hash),
                kind=CredentialKind.GAMEPLAY_TOKEN.value,
                session_id=session_id,
                context_id=context_id,
                issued_at=issued_at,
                expires_at=expires_at,
                revoked_at=None,
            )
        )

    def resolve_gameplay_digest(
        self,
        connection: Connection,
        *,
        credential_hash: bytes,
    ) -> tuple[AccountSessionSnapshot, GameplayContextSnapshot, datetime | None] | None:
        statement = (
            select(
                session_credentials.c.expires_at.label("credential_expires_at"),
                session_credentials.c.revoked_at.label("credential_revoked_at"),
                account_sessions.c.session_id,
                account_sessions.c.account_uid,
                account_sessions.c.issued_at,
                account_sessions.c.last_activity_at,
                account_sessions.c.absolute_expires_at,
                account_sessions.c.revoked_at,
                account_sessions.c.revocation_reason,
                account_sessions.c.device_metadata,
                gameplay_contexts.c.context_id,
                gameplay_contexts.c.session_id.label("context_session_id"),
                gameplay_contexts.c.account_uid.label("context_account_uid"),
                gameplay_contexts.c.region_id,
                gameplay_contexts.c.player_id,
                gameplay_contexts.c.created_at,
                gameplay_contexts.c.ended_at,
                gameplay_contexts.c.end_reason,
                gameplay_contexts.c.superseded_by_context_id,
            )
            .select_from(
                session_credentials.join(
                    account_sessions,
                    session_credentials.c.session_id == account_sessions.c.session_id,
                ).join(
                    gameplay_contexts,
                    (session_credentials.c.context_id == gameplay_contexts.c.context_id)
                    & (session_credentials.c.session_id == gameplay_contexts.c.session_id),
                )
            )
            .where(
                session_credentials.c.kind == CredentialKind.GAMEPLAY_TOKEN.value,
                session_credentials.c.credential_hash == bytes(credential_hash),
            )
        )
        row = _one_mapping(connection.execute(statement))
        if row is None or row.get("credential_revoked_at") is not None:
            return None
        if (
            row.get("context_session_id") != row.get("session_id")
            or str(row.get("context_account_uid")) != str(row.get("account_uid"))
        ):
            # Database constraints should make this impossible; fail closed if an
            # imported/corrupt row ever violates the credential/context binding.
            return None
        return _session_from_row(row), _context_from_row(row), row.get("credential_expires_at")


class RegionDirectoryRepository:
    @staticmethod
    def compatibility_seed_rows() -> tuple[dict[str, Any], ...]:
        """Current backend exposes regions 1..200 and local IDs start at region*100000+1."""
        rows = []
        for region_id in range(1, 201):
            rows.append(
                {
                    "region_id": region_id,
                    "name": "Deep Valley" if region_id == 125 else f"Local-{region_id}",
                    "next_player_id": region_id * 100_000 + 1,
                    "max_player_id": (region_id + 1) * 100_000 - 1,
                    "allow_new_players": True,
                    "metadata": {"source": "pass342-current-backend-compat"},
                }
            )
        return tuple(rows)

    def get_region(
        self,
        connection: Connection,
        region_id: int,
        *,
        for_update: bool = False,
    ) -> RegionSnapshot | None:
        statement = select(regions).where(regions.c.region_id == int(region_id))
        if for_update:
            statement = statement.with_for_update()
        row = _one_mapping(connection.execute(statement))
        if row is None:
            return None
        return RegionSnapshot(
            region_id=int(row["region_id"]),
            name=str(row["name"]),
            next_player_id=int(row["next_player_id"]),
            max_player_id=int(row["max_player_id"]),
            allow_new_players=bool(row["allow_new_players"]),
            metadata=dict(row.get("metadata") or {}),
        )

    def list_regions(self, connection: Connection) -> tuple[RegionSnapshot, ...]:
        rows = _all_mappings(connection.execute(select(regions).order_by(regions.c.region_id.asc())))
        return tuple(
            RegionSnapshot(
                region_id=int(row["region_id"]),
                name=str(row["name"]),
                next_player_id=int(row["next_player_id"]),
                max_player_id=int(row["max_player_id"]),
                allow_new_players=bool(row["allow_new_players"]),
                metadata=dict(row.get("metadata") or {}),
            )
            for row in rows
        )

    def find_player(self, connection: Connection, *, account_uid: str, region_id: int) -> PlayerDirectorySnapshot | None:
        row = _one_mapping(
            connection.execute(
                select(players).where(
                    players.c.account_uid == str(account_uid), players.c.region_id == int(region_id)
                )
            )
        )
        if row is None:
            return None
        return PlayerDirectorySnapshot(
            player_id=int(row["player_id"]),
            account_uid=str(row["account_uid"]),
            region_id=int(row["region_id"]),
            created_at=row["created_at"],
        )

    def get_player(self, connection: Connection, player_id: int, *, for_share: bool = False) -> PlayerDirectorySnapshot | None:
        statement = select(players).where(players.c.player_id == int(player_id))
        if for_share:
            statement = statement.with_for_update(read=True)
        row = _one_mapping(connection.execute(statement))
        if row is None:
            return None
        return PlayerDirectorySnapshot(
            player_id=int(row["player_id"]),
            account_uid=str(row["account_uid"]),
            region_id=int(row["region_id"]),
            created_at=row["created_at"],
        )

    def list_account_players(self, connection: Connection, account_uid: str) -> tuple[PlayerDirectorySnapshot, ...]:
        rows = _all_mappings(
            connection.execute(
                select(players)
                .where(players.c.account_uid == str(account_uid))
                .order_by(players.c.region_id.asc())
            )
        )
        return tuple(
            PlayerDirectorySnapshot(
                player_id=int(row["player_id"]),
                account_uid=str(row["account_uid"]),
                region_id=int(row["region_id"]),
                created_at=row["created_at"],
            )
            for row in rows
        )

    def allocate_player(
        self,
        connection: Connection,
        *,
        account_uid: str,
        region_id: int,
        created_at: datetime,
    ) -> PlayerDirectorySnapshot:
        # Caller must already hold the canonical REGION allocator row lock.
        existing = self.find_player(connection, account_uid=account_uid, region_id=region_id)
        if existing is not None:
            return existing
        region = self.get_region(connection, int(region_id))
        if region is None:
            raise RegionUnavailable(f"unknown region {region_id}")
        if region.is_full_for_new_players:
            raise RegionFull(f"region {region_id} is closed/full")
        player_id = int(region.next_player_id)
        advanced = connection.execute(
            update(regions)
            .where(
                regions.c.region_id == int(region_id),
                regions.c.next_player_id == player_id,
            )
            .values(next_player_id=player_id + 1)
        ).rowcount
        if advanced != 1:
            # The REGION row is required to be locked by ResourceTransaction. A
            # failed compare-and-advance is therefore an invariant violation, not
            # permission to allocate from a stale cursor.
            raise RuntimeError("region allocator cursor changed without canonical REGION lock")
        connection.execute(
            players.insert().values(
                player_id=player_id,
                account_uid=str(account_uid),
                region_id=int(region_id),
                created_at=created_at,
            )
        )
        return PlayerDirectorySnapshot(
            player_id=player_id,
            account_uid=str(account_uid),
            region_id=int(region_id),
            created_at=created_at,
        )
