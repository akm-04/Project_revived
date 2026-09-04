"""Pass342 I3 relational identity/session/context services.

This module is intentionally candidate-only in I3: it replaces the authority
*model* behind the I1 auth seam, but EngineDispatcher/StateRepository stay on the
sealed Pass340 runtime until the I4/I8 strangler/cutover gates.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Mapping
from uuid import UUID, uuid4

from sqlalchemy.exc import IntegrityError

from gxb_backend.foundation.contracts import TransactionRequest
from gxb_backend.foundation.resource_keys import ResourceClass, ResourceKey
from gxb_backend.transactions.coordinator import ResourceTransactionCoordinator, SqlAlchemyResourceTransaction
from gxb_backend.transactions.models import DeliveryClass, OutboxIntent

from .credentials import BearerIssuer, PasswordCredentialService, credential_digest, normalize_login
from .errors import AccountConflict, CredentialInvalid, CredentialMismatch, ContextStale, RegionUnavailable
from .models import (
    AccountPrincipal,
    AuthenticatedRequestContext,
    ContextSelectionResult,
    ContextLivenessLease,
    CredentialKind,
    IdentityPolicy,
    IssuedSession,
    PlayerDirectorySnapshot,
    RegionSnapshot,
    ResolvedAccountCredential,
)
from .repositories import AccountRepository, ContextRepository, RegionDirectoryRepository, SessionRepository


@dataclass(frozen=True, slots=True)
class AccountRegionDirectory:
    account_uid: str
    regions: tuple[RegionSnapshot, ...]
    players: tuple[PlayerDirectorySnapshot, ...]


class AccountSessionAuthenticator:
    """Resolve account credentials, enforce same-session agreement and liveness."""

    def __init__(
        self,
        engine_provider,
        coordinator: ResourceTransactionCoordinator,
        *,
        sessions: SessionRepository | None = None,
        policy: IdentityPolicy,
        clock=None,
    ) -> None:
        self._engine_provider = engine_provider
        self._coordinator = coordinator
        self.sessions = sessions or SessionRepository()
        self.policy = policy
        self._clock = clock or (lambda: datetime.now(timezone.utc))

    def resolve(
        self,
        *,
        sid: object = None,
        login_token: object = None,
        request_id: str = "auth",
        touch_activity: bool = True,
    ) -> ResolvedAccountCredential:
        sid_value = str(sid or "")
        login_value = str(login_token or "")
        if not sid_value and not login_value:
            raise CredentialInvalid("sid or login_token is required")
        resolutions: list[ResolvedAccountCredential] = []
        engine = self._engine_provider()
        with engine.connect() as connection:
            if sid_value:
                resolved = self.sessions.resolve_credential_digest(
                    connection,
                    kind=CredentialKind.SDK_SID_COMPAT,
                    credential_hash=credential_digest(CredentialKind.SDK_SID_COMPAT, sid_value),
                )
                if resolved is None:
                    raise CredentialInvalid("invalid sid")
                resolutions.append(resolved)
            if login_value:
                resolved = self.sessions.resolve_credential_digest(
                    connection,
                    kind=CredentialKind.LOGIN_TOKEN,
                    credential_hash=credential_digest(CredentialKind.LOGIN_TOKEN, login_value),
                )
                if resolved is None:
                    raise CredentialInvalid("invalid login_token")
                resolutions.append(resolved)
        session_ids = {item.session.session_id for item in resolutions}
        if len(session_ids) != 1:
            raise CredentialMismatch("sid and login_token resolve to different sessions")
        resolved = resolutions[0]
        now = self._clock()
        for item in resolutions:
            if item.credential_expires_at is not None and now >= item.credential_expires_at:
                raise CredentialInvalid("account credential expired")
            self.sessions.validate_liveness(item.session, policy=self.policy, now=now)
        if touch_activity and now >= resolved.session.last_activity_at + self.policy.activity_write_interval:
            self._touch(resolved.session.session_id, request_id=request_id, now=now)
            # The returned immutable snapshot still carries the observed timestamp;
            # actor/session identity is unchanged and liveness was already checked.
        return resolved

    def _touch(self, session_id: UUID, *, request_id: str, now: datetime) -> None:
        request = TransactionRequest(
            request_id=str(request_id),
            operation_name="identity.session_activity_touch",
            resources=(ResourceKey.of(ResourceClass.SESSION, "account_session", session_id),),
            retry_safe=True,
        )

        def operation(transaction: SqlAlchemyResourceTransaction) -> None:
            session = self.sessions.get_session(transaction.connection, session_id)
            if session is None:
                raise CredentialInvalid("session disappeared")
            self.sessions.validate_liveness(session, policy=self.policy, now=now)
            self.sessions.maybe_touch_activity(
                transaction.connection, session=session, policy=self.policy, now=now
            )

        self._coordinator.run(request, operation)


class IdentityService:
    """Local-password account registration/login and fresh session issuance."""

    def __init__(
        self,
        engine_provider,
        coordinator: ResourceTransactionCoordinator,
        *,
        accounts: AccountRepository | None = None,
        sessions: SessionRepository | None = None,
        passwords: PasswordCredentialService | None = None,
        bearer_issuer: BearerIssuer | None = None,
        policy: IdentityPolicy,
        clock=None,
        uuid_factory=uuid4,
    ) -> None:
        self._engine_provider = engine_provider
        self._coordinator = coordinator
        self.accounts = accounts or AccountRepository()
        self.sessions = sessions or SessionRepository()
        self.passwords = passwords or PasswordCredentialService()
        self.bearers = bearer_issuer or BearerIssuer()
        self.policy = policy
        self._clock = clock or (lambda: datetime.now(timezone.utc))
        self._uuid = uuid_factory

    def register_local(
        self,
        *,
        username: str,
        password: str,
        request_id: str,
    ) -> AccountPrincipal:
        """Create a local credential account; exact same-credential retry is idempotent.

        This preserves the current SDK boundary: registration creates identity,
        while the separate login operation issues SID/login-token session material.
        """
        subject = normalize_login(username)
        if not subject:
            raise CredentialInvalid("username must not be empty")
        password_hash = self.passwords.hash_new(password)
        account_uid = self._allocate_account_uid()
        account_credential_id = self._uuid()
        created_at = self._clock()
        request = TransactionRequest(
            request_id=str(request_id),
            operation_name="identity.register_local",
            resources=(ResourceKey.of(ResourceClass.SESSION, "account_credential", subject),),
            retry_safe=True,
        )

        def operation(transaction: SqlAlchemyResourceTransaction) -> AccountPrincipal:
            existing = self.accounts.get_local_credential(transaction.connection, subject)
            if existing is not None:
                verification = self.passwords.verify(
                    algorithm=str(existing.get("password_algorithm") or ""),
                    encoded_hash=str(existing.get("password_hash") or ""),
                    password=str(password),
                )
                if verification.valid:
                    return AccountPrincipal(
                        account_uid=str(existing["account_uid"]),
                        account_type=str(existing["account_type"]),
                        username=str(existing["username"]),
                    )
                raise AccountConflict("local login already exists")
            try:
                return self.accounts.create_local_account(
                    transaction.connection,
                    credential_id=account_credential_id,
                    account_uid=account_uid,
                    username=str(username).strip(),
                    subject_normalized=subject,
                    password_hash=password_hash,
                    password_algorithm=self.passwords.ARGON2_ALGORITHM,
                    created_at=created_at,
                )
            except IntegrityError as exc:
                raise AccountConflict("local login already exists") from exc

        try:
            return self._coordinator.run(request, operation)
        except AccountConflict as exc:
            # A UNIQUE(provider, subject_normalized) race cannot be serialized by
            # SELECT FOR UPDATE when the credential row does not exist yet. After
            # PostgreSQL resolves the unique conflict, re-read the committed winner:
            # an exact same-credential concurrent retry is idempotent, while a
            # different password remains a closed conflict.
            if not isinstance(exc.__cause__, IntegrityError):
                raise
            engine = self._engine_provider()
            with engine.connect() as connection:
                existing = self.accounts.get_local_credential(connection, subject)
            if existing is None:
                raise
            verification = self.passwords.verify(
                algorithm=str(existing.get("password_algorithm") or ""),
                encoded_hash=str(existing.get("password_hash") or ""),
                password=str(password),
            )
            if not verification.valid:
                raise
            return AccountPrincipal(
                account_uid=str(existing["account_uid"]),
                account_type=str(existing["account_type"]),
                username=str(existing["username"]),
            )

    def login_local(
        self,
        *,
        username: str,
        password: str,
        request_id: str,
        device_metadata: Mapping[str, Any] | None = None,
    ) -> IssuedSession:
        subject = normalize_login(username)
        if not subject:
            raise CredentialInvalid("invalid username/password")
        request = TransactionRequest(
            request_id=str(request_id),
            operation_name="identity.login_local",
            resources=(ResourceKey.of(ResourceClass.SESSION, "account_credential", subject),),
            retry_safe=True,
        )
        prepared: dict[str, Any] = {}

        def operation(transaction: SqlAlchemyResourceTransaction) -> IssuedSession:
            row = self.accounts.get_local_credential(transaction.connection, subject)
            if row is None or not bool(row.get("enabled")):
                raise CredentialInvalid("invalid username/password")
            verification_source = (
                row.get("credential_id"),
                str(row.get("password_algorithm") or ""),
                str(row.get("password_hash") or ""),
            )
            if prepared.get("verification_source") == verification_source:
                verification = prepared["verification"]
            else:
                verification = self.passwords.verify(
                    algorithm=verification_source[1],
                    encoded_hash=verification_source[2],
                    password=str(password),
                )
                if verification.valid:
                    # A whole-transaction retry sees the same durable credential
                    # material after rollback. Preserve the already verified result
                    # (including randomized Argon2 upgrade salt) across that retry;
                    # reverify if another transaction changed the stored hash.
                    prepared["verification_source"] = verification_source
                    prepared["verification"] = verification
            if not verification.valid:
                raise CredentialInvalid("invalid username/password")
            if verification.upgraded_hash is not None:
                self.accounts.upgrade_password(
                    transaction.connection,
                    credential_id=row["credential_id"],
                    password_hash=verification.upgraded_hash,
                    password_algorithm=verification.upgraded_algorithm or self.passwords.ARGON2_ALGORITHM,
                    updated_at=prepared.setdefault("issued_at", self._clock()),
                )
            account = AccountPrincipal(
                account_uid=str(row["account_uid"]),
                account_type=str(row["account_type"]),
                username=str(row["username"]),
            )
            if "material" not in prepared:
                prepared["material"] = self._prepare_session_material(account_uid=account.account_uid)
            issued = prepared["material"]
            session = self.sessions.create_session(
                transaction.connection,
                session_id=issued["session_id"],
                account_uid=account.account_uid,
                issued_at=issued["issued_at"],
                absolute_expires_at=issued["absolute_expires_at"],
                device_metadata=device_metadata,
                sid_credential_id=issued["sid_credential_id"],
                sid_digest=issued["sid"].digest,
                login_credential_id=issued["login_credential_id"],
                login_digest=issued["login"].digest,
            )
            return IssuedSession(account, session, issued["sid"].raw, issued["login"].raw)

        return self._coordinator.run(request, operation)

    def issue_fresh_anonymous_session(
        self,
        *,
        account_uid: str,
        request_id: str,
        device_metadata: Mapping[str, Any] | None = None,
    ) -> IssuedSession:
        """Optional cutover-compatible guest path: fresh random session, never fixed sandbox secrets."""
        account_uid = str(account_uid)
        material = self._prepare_session_material(account_uid=account_uid)
        request = TransactionRequest(
            request_id=str(request_id),
            operation_name="identity.issue_fresh_anonymous_session",
            resources=(ResourceKey.of(ResourceClass.SESSION, "account_session", material["session_id"]),),
            retry_safe=True,
        )

        def operation(transaction: SqlAlchemyResourceTransaction) -> IssuedSession:
            account = self.accounts.get_principal(transaction.connection, account_uid)
            if account is None:
                raise CredentialInvalid("anonymous compatibility account does not exist")
            session = self.sessions.create_session(
                transaction.connection,
                session_id=material["session_id"],
                account_uid=account_uid,
                issued_at=material["issued_at"],
                absolute_expires_at=material["absolute_expires_at"],
                device_metadata=device_metadata,
                sid_credential_id=material["sid_credential_id"],
                sid_digest=material["sid"].digest,
                login_credential_id=material["login_credential_id"],
                login_digest=material["login"].digest,
            )
            return IssuedSession(account, session, material["sid"].raw, material["login"].raw)

        return self._coordinator.run(request, operation)

    def _allocate_account_uid(self) -> str:
        engine = self._engine_provider()
        with engine.connect() as connection:
            return self.accounts.next_account_uid(connection)

    def _prepare_session_material(self, *, account_uid: str) -> dict[str, Any]:
        del account_uid  # semantic marker; IDs are deliberately opaque and account-independent
        issued_at = self._clock()
        return {
            "session_id": self._uuid(),
            "sid_credential_id": self._uuid(),
            "login_credential_id": self._uuid(),
            "sid": self.bearers.sid(),
            "login": self.bearers.login_token(),
            "issued_at": issued_at,
            "absolute_expires_at": (
                issued_at + self.policy.absolute_session_ttl
                if self.policy.absolute_session_ttl is not None
                else None
            ),
        }


class RegionDirectoryService:
    """MID18 account/region directory under a short durable session-liveness lease."""

    def __init__(
        self,
        engine_provider,
        coordinator: ResourceTransactionCoordinator,
        authenticator: AccountSessionAuthenticator,
        *,
        directory: RegionDirectoryRepository | None = None,
        sessions: SessionRepository | None = None,
        clock=None,
    ) -> None:
        self._engine_provider = engine_provider
        self._coordinator = coordinator
        self.authenticator = authenticator
        self.directory = directory or RegionDirectoryRepository()
        self.sessions = sessions or authenticator.sessions
        self._clock = clock or (lambda: datetime.now(timezone.utc))

    def load_for_account(
        self,
        *,
        sid: object = None,
        login_token: object = None,
        request_id: str = "mid18",
    ) -> AccountRegionDirectory:
        resolved = self.authenticator.resolve(
            sid=sid, login_token=login_token, request_id=request_id
        )
        session_id = resolved.session.session_id
        account_uid = resolved.account.account_uid
        request = TransactionRequest(
            request_id=str(request_id),
            operation_name="identity.region_directory",
            resources=(
                ResourceKey.of(ResourceClass.SESSION, "account_session_liveness", session_id),
            ),
            retry_safe=True,
        )

        def operation(transaction: SqlAlchemyResourceTransaction) -> AccountRegionDirectory:
            session = self.sessions.get_session(transaction.connection, session_id)
            if session is None or session.account_uid != account_uid:
                raise CredentialInvalid("session identity changed")
            self.sessions.validate_liveness(
                session, policy=self.authenticator.policy, now=self._clock()
            )
            return AccountRegionDirectory(
                account_uid=account_uid,
                regions=self.directory.list_regions(transaction.connection),
                players=self.directory.list_account_players(transaction.connection, account_uid),
            )

        return self._coordinator.run(request, operation)


class ContextSelectionService:
    def __init__(
        self,
        engine_provider,
        coordinator: ResourceTransactionCoordinator,
        authenticator: AccountSessionAuthenticator,
        *,
        sessions: SessionRepository | None = None,
        contexts: ContextRepository | None = None,
        directory: RegionDirectoryRepository | None = None,
        bearer_issuer: BearerIssuer | None = None,
        player_materialized_probe=None,
        clock=None,
        uuid_factory=uuid4,
    ) -> None:
        self._engine_provider = engine_provider
        self._coordinator = coordinator
        self.authenticator = authenticator
        self.sessions = sessions or authenticator.sessions
        self.contexts = contexts or ContextRepository()
        self.directory = directory or RegionDirectoryRepository()
        self.bearers = bearer_issuer or BearerIssuer()
        self._player_materialized_probe = player_materialized_probe
        self._clock = clock or (lambda: datetime.now(timezone.utc))
        self._uuid = uuid_factory

    def select(
        self,
        *,
        region_id: int,
        request_id: str,
        sid: object = None,
        login_token: object = None,
        client_operation_id: str | None = None,
    ) -> ContextSelectionResult:
        region_id = int(region_id)
        if region_id <= 0:
            raise RegionUnavailable("region must be positive")
        resolved = self.authenticator.resolve(
            sid=sid,
            login_token=login_token,
            request_id=request_id,
            touch_activity=False,
        )
        session_id = resolved.session.session_id
        account_uid = resolved.account.account_uid
        engine = self._engine_provider()
        with engine.connect() as connection:
            preexisting = self.directory.find_player(
                connection, account_uid=account_uid, region_id=region_id
            )

        context_id = self._uuid()
        gameplay_credential_id = self._uuid()
        gameplay_token = self.bearers.gameplay_token_for_context(
            context_id=context_id, login_token=login_token, sid=sid
        )
        now = self._clock()
        resources = [
            ResourceKey.of(ResourceClass.SESSION, "account_session", session_id),
            ResourceKey.of(ResourceClass.CONTEXT, "active_context_for_session", session_id),
        ]
        if preexisting is None:
            resources.append(ResourceKey.of(ResourceClass.REGION, "region_allocator", region_id))
        else:
            resources.append(
                ResourceKey.of(ResourceClass.PLAYER, "player_directory", int(preexisting.player_id))
            )
        request = TransactionRequest(
            request_id=str(request_id),
            operation_name="identity.context_select",
            resources=tuple(resources),
            client_operation_id=client_operation_id,
            retry_safe=True,
        )

        def operation(transaction: SqlAlchemyResourceTransaction) -> ContextSelectionResult:
            session = self.sessions.get_session(transaction.connection, session_id)
            if session is None or session.account_uid != account_uid:
                raise CredentialInvalid("session identity changed")
            self.sessions.validate_liveness(
                session, policy=self.authenticator.policy, now=now
            )
            old_context = self.contexts.get_active_for_session(transaction.connection, session_id)
            player = self.directory.find_player(
                transaction.connection, account_uid=account_uid, region_id=region_id
            )
            if player is None:
                # The request declared REGION only when the pre-read was absent.
                # A concurrent creator may have won while we waited; the recheck
                # above handles that without allocating a duplicate.
                player = self.directory.allocate_player(
                    transaction.connection,
                    account_uid=account_uid,
                    region_id=region_id,
                    created_at=now,
                )
                is_new = True
            elif self._player_materialized_probe is not None:
                # A directory row with no aggregate is not a completed character.
                # Stock MID1 can overlap before the first bootstrap materializes
                # JSONB, so preserve first-login semantics for both requests.
                is_new = not bool(
                    self._player_materialized_probe(transaction.connection, player.player_id)
                )
            else:
                is_new = False

            if (
                old_context is not None
                and old_context.region_id == region_id
                and old_context.player_id == player.player_id
            ):
                retry_token = self.bearers.gameplay_token_for_context(
                    context_id=old_context.context_id, login_token=login_token, sid=sid
                )
                resolver = getattr(self.contexts, "resolve_gameplay_digest", None)
                resolved_retry = (
                    resolver(transaction.connection, credential_hash=retry_token.digest)
                    if callable(resolver) else None
                )
                if resolved_retry is not None:
                    retry_session, retry_context, _retry_expires_at = resolved_retry
                    if (
                        retry_session.session_id == session_id
                        and retry_session.account_uid == account_uid
                        and retry_context.context_id == old_context.context_id
                        and retry_context.ended_at is None
                    ):
                        return ContextSelectionResult(
                            account_uid=account_uid,
                            session_id=session_id,
                            context_id=old_context.context_id,
                            region_id=region_id,
                            player_id=int(player.player_id),
                            gameplay_token=retry_token.raw,
                            is_new_player=is_new,
                        )

            if old_context is not None:
                self.contexts.end_context(
                    transaction.connection,
                    context_id=old_context.context_id,
                    ended_at=now,
                    reason="CONTEXT_SUPERSEDED",
                )
                self.contexts.revoke_gameplay_credentials(
                    transaction.connection,
                    context_id=old_context.context_id,
                    revoked_at=now,
                )
                transaction.stage_outbox(
                    OutboxIntent(
                        topic="identity.context_superseded",
                        resource_kind="context",
                        resource_key=str(old_context.context_id),
                        context_id=old_context.context_id,
                        payload={
                            "session_id": str(session_id),
                            "old_context_id": str(old_context.context_id),
                            "new_context_id": str(context_id),
                            "reason": "CONTEXT_SUPERSEDED",
                        },
                        delivery_class=DeliveryClass.IDEMPOTENT_REALTIME_CONTROL,
                        priority=10,
                    )
                )
            self.contexts.create_context(
                transaction.connection,
                context_id=context_id,
                session_id=session_id,
                account_uid=account_uid,
                region_id=region_id,
                player_id=player.player_id,
                created_at=now,
            )
            if old_context is not None:
                if not self.contexts.set_superseded_by(
                    transaction.connection,
                    context_id=old_context.context_id,
                    superseded_by_context_id=context_id,
                ):
                    raise ContextStale("previous active context changed during selection")
            self.contexts.create_gameplay_credential(
                transaction.connection,
                credential_id=gameplay_credential_id,
                credential_hash=gameplay_token.digest,
                session_id=session_id,
                context_id=context_id,
                issued_at=now,
                expires_at=session.absolute_expires_at,
            )
            transaction.stage_outbox(
                OutboxIntent(
                    topic="identity.context_selected",
                    resource_kind="context",
                    resource_key=str(context_id),
                    context_id=context_id,
                    payload={
                        "session_id": str(session_id),
                        "context_id": str(context_id),
                        "region_id": region_id,
                        "player_id": int(player.player_id),
                    },
                    delivery_class=DeliveryClass.IDEMPOTENT_REALTIME_CONTROL,
                    priority=20,
                )
            )
            return ContextSelectionResult(
                account_uid=account_uid,
                session_id=session_id,
                context_id=context_id,
                region_id=region_id,
                player_id=int(player.player_id),
                gameplay_token=gameplay_token.raw,
                is_new_player=is_new,
            )

        return self._coordinator.run(request, operation)


class GameplayContextAuthenticator:
    """Resolve gameplay bearers and provide reusable session/context liveness leases.

    Read-only admission uses a short ResourceTransaction. I4 selected-player
    mutations can call prepare_lease(), lease_resources(), and validate_lease()
    inside their larger outer ResourceTransaction so FOR SHARE liveness locks are
    held through durable settlement.
    """

    def __init__(
        self,
        engine_provider,
        coordinator: ResourceTransactionCoordinator,
        *,
        contexts: ContextRepository | None = None,
        sessions: SessionRepository | None = None,
        policy: IdentityPolicy,
        clock=None,
    ) -> None:
        self._engine_provider = engine_provider
        self._coordinator = coordinator
        self.contexts = contexts or ContextRepository()
        self.sessions = sessions or SessionRepository()
        self.policy = policy
        self._clock = clock or (lambda: datetime.now(timezone.utc))

    def prepare_lease(self, gameplay_token: object) -> ContextLivenessLease:
        raw = str(gameplay_token or "")
        if not raw:
            raise CredentialInvalid("gameplay token required")
        digest = credential_digest(CredentialKind.GAMEPLAY_TOKEN, raw)
        engine = self._engine_provider()
        with engine.connect() as connection:
            resolved = self.contexts.resolve_gameplay_digest(
                connection, credential_hash=digest
            )
        if resolved is None:
            raise CredentialInvalid("invalid gameplay token")
        session, context, credential_expires_at = resolved
        self._validate_snapshots(
            session=session,
            context=context,
            credential_expires_at=credential_expires_at,
            supplied_region=None,
            now=self._clock(),
        )
        return ContextLivenessLease(
            credential_hash=digest,
            session_id=session.session_id,
            context_id=context.context_id,
            account_uid=session.account_uid,
            region_id=context.region_id,
            player_id=context.player_id,
            last_activity_at=session.last_activity_at,
        )

    @staticmethod
    def lease_resources(lease: ContextLivenessLease) -> tuple[ResourceKey, ResourceKey]:
        return (
            ResourceKey.of(ResourceClass.SESSION, "account_session_liveness", lease.session_id),
            ResourceKey.of(ResourceClass.CONTEXT, "gameplay_context_liveness", lease.context_id),
        )

    def validate_lease(
        self,
        transaction: SqlAlchemyResourceTransaction,
        lease: ContextLivenessLease,
        *,
        supplied_region: object = None,
        request_id: str,
        auth_scope: str,
    ) -> AuthenticatedRequestContext:
        resolved = self.contexts.resolve_gameplay_digest(
            transaction.connection, credential_hash=lease.credential_hash
        )
        if resolved is None:
            raise CredentialInvalid("gameplay credential was revoked")
        session, context, credential_expires_at = resolved
        if (
            session.session_id != lease.session_id
            or context.context_id != lease.context_id
            or session.account_uid != lease.account_uid
            or context.account_uid != lease.account_uid
            or context.region_id != lease.region_id
            or context.player_id != lease.player_id
        ):
            raise ContextStale("gameplay credential binding changed")
        self._validate_snapshots(
            session=session,
            context=context,
            credential_expires_at=credential_expires_at,
            supplied_region=supplied_region,
            now=self._clock(),
        )
        return AuthenticatedRequestContext(
            request_id=str(request_id),
            auth_scope=str(auth_scope),
            account_uid=session.account_uid,
            session_id=session.session_id,
            context_id=context.context_id,
            region_id=context.region_id,
            player_id=context.player_id,
        )

    def resolve(
        self,
        *,
        gameplay_token: object,
        supplied_region: object = None,
        request_id: str,
        auth_scope: str,
    ) -> AuthenticatedRequestContext:
        lease = self.prepare_lease(gameplay_token)
        request = TransactionRequest(
            request_id=str(request_id),
            operation_name="identity.gameplay_context_read",
            resources=self.lease_resources(lease),
            retry_safe=True,
        )

        def operation(transaction: SqlAlchemyResourceTransaction) -> AuthenticatedRequestContext:
            return self.validate_lease(
                transaction,
                lease,
                supplied_region=supplied_region,
                request_id=request_id,
                auth_scope=auth_scope,
            )

        result = self._coordinator.run(request, operation)
        self._coalesced_activity_touch(lease, request_id=request_id)
        return result

    def _coalesced_activity_touch(self, lease: ContextLivenessLease, *, request_id: str) -> None:
        now = self._clock()
        if now < lease.last_activity_at + self.policy.activity_write_interval:
            return
        session_id = lease.session_id
        request = TransactionRequest(
            request_id=str(request_id),
            operation_name="identity.gameplay_activity_touch",
            resources=(ResourceKey.of(ResourceClass.SESSION, "account_session", session_id),),
            retry_safe=True,
        )

        def operation(transaction: SqlAlchemyResourceTransaction) -> None:
            session = self.sessions.get_session(transaction.connection, session_id)
            if session is None:
                raise CredentialInvalid("session disappeared")
            self.sessions.validate_liveness(session, policy=self.policy, now=now)
            self.sessions.maybe_touch_activity(
                transaction.connection, session=session, policy=self.policy, now=now
            )

        # The conditional UPDATE itself coalesces activity writes. This extra
        # transaction occurs after a read-only lease is released; I4 mutations
        # will hold their liveness leases in the outer domain transaction.
        self._coordinator.run(request, operation)

    def _validate_snapshots(
        self,
        *,
        session,
        context,
        credential_expires_at: datetime | None,
        supplied_region: object,
        now: datetime,
    ) -> None:
        if credential_expires_at is not None and now >= credential_expires_at:
            raise CredentialInvalid("gameplay credential expired")
        self.sessions.validate_liveness(session, policy=self.policy, now=now)
        if context.ended_at is not None:
            raise ContextStale("gameplay context ended")
        if supplied_region not in (None, ""):
            try:
                region = int(supplied_region)
            except (TypeError, ValueError) as exc:
                raise ContextStale("invalid region consistency value") from exc
            if region != context.region_id:
                raise ContextStale("caller region does not match credential-bound context")


class SessionRevocationService:
    def __init__(
        self,
        coordinator: ResourceTransactionCoordinator,
        authenticator: AccountSessionAuthenticator,
        *,
        sessions: SessionRepository | None = None,
        contexts: ContextRepository | None = None,
        clock=None,
    ) -> None:
        self._coordinator = coordinator
        self.authenticator = authenticator
        self.sessions = sessions or authenticator.sessions
        self.contexts = contexts or ContextRepository()
        self._clock = clock or (lambda: datetime.now(timezone.utc))

    def revoke(
        self,
        *,
        request_id: str,
        reason: str,
        sid: object = None,
        login_token: object = None,
    ) -> bool:
        resolved = self.authenticator.resolve(
            sid=sid,
            login_token=login_token,
            request_id=request_id,
            touch_activity=False,
        )
        session_id = resolved.session.session_id
        now = self._clock()
        request = TransactionRequest(
            request_id=str(request_id),
            operation_name="identity.session_revoke",
            resources=(
                ResourceKey.of(ResourceClass.SESSION, "account_session", session_id),
                ResourceKey.of(ResourceClass.CONTEXT, "active_context_for_session", session_id),
            ),
            retry_safe=True,
        )

        def operation(transaction: SqlAlchemyResourceTransaction) -> bool:
            session = self.sessions.get_session(transaction.connection, session_id)
            if session is None:
                return False
            context = self.contexts.get_active_for_session(transaction.connection, session_id)
            if context is not None:
                self.contexts.end_context(
                    transaction.connection,
                    context_id=context.context_id,
                    ended_at=now,
                    reason="SESSION_REVOKED",
                )
                self.contexts.revoke_gameplay_credentials(
                    transaction.connection, context_id=context.context_id, revoked_at=now
                )
            changed = self.sessions.revoke_session(
                transaction.connection,
                session_id=session_id,
                revoked_at=now,
                reason=reason,
            )
            if changed:
                transaction.stage_outbox(
                    OutboxIntent(
                        topic="identity.session_invalidated",
                        resource_kind="session",
                        resource_key=str(session_id),
                        context_id=context.context_id if context is not None else None,
                        payload={
                            "session_id": str(session_id),
                            "context_id": str(context.context_id) if context is not None else None,
                            "reason": str(reason),
                        },
                        delivery_class=DeliveryClass.IDEMPOTENT_REALTIME_CONTROL,
                        priority=5,
                    )
                )
            return changed

        return self._coordinator.run(request, operation)
