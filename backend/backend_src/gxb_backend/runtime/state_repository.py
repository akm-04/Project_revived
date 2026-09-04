"""PostgreSQL authority adapter over the mature PlayerState modular monolith."""
from __future__ import annotations

from contextlib import ExitStack, contextmanager
from datetime import datetime, timedelta, timezone
from typing import Any
from uuid import UUID

from sqlalchemy import func, select

from gxb_backend.auth.perimeter import AuthScope, AuthScopeRegistry
from gxb_backend.content import CatalogNamespace, ContentRef
from gxb_backend.foundation.contracts import TransactionRequest
from gxb_backend.foundation.resource_keys import ResourceClass, ResourceKey
from gxb_backend.identity.errors import IdentityError
from gxb_backend.identity.repositories import AccountRepository, RegionDirectoryRepository
from gxb_backend.identity.schema import players as identity_players
from gxb_backend.identity.service import (
    AccountSessionAuthenticator, ContextSelectionService, GameplayContextAuthenticator,
    IdentityService, RegionDirectoryService,
)
from gxb_backend.mail.models import MailAddress
from gxb_backend.mail.protocol import mailbox_snapshot, onekey_response, parse_onekey_addresses
from gxb_backend.mail.repository import MailRepository
from gxb_backend.persistence.codec import PlayerPayloadCodec
from gxb_backend.persistence.locking import account_global_resource, player_state_resource
from gxb_backend.persistence.repositories import AccountGlobalRepository, PlayerAggregateNotMaterialized, PostgresPlayerAggregateRepository
from gxb_backend.persistence.store import TransactionBoundPostgresPlayerStateStore
from gxb_backend.protocol.mids import MID
from gxb_backend.realtime.contracts import AuthenticatedPlayerIdentity, RealtimeEventIntent
from gxb_backend.realtime.durable import DurableRealtimeIntentStager
from gxb_backend.realtime.publisher import POST_COMMIT_TOPIC, RealtimeEventSchemaRegistry
from gxb_backend.state.account import AccountIdentity
from gxb_backend.state.profiles import make_fresh_player
from gxb_backend.state.skill_point_policy import SkillPointPolicy
from gxb_backend.state.maintenance_services import normalize_player_domain
from gxb_backend.state.repository import StateRepository, _RequestBinding
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.reward_transaction_service import InventoryGrant, RewardOrigin, RewardPlan
from gxb_backend.state.unit_of_work import OperationContext as PlayerOperationContext
from gxb_backend.transactions.coordinator import ResourceTransactionCoordinator
from gxb_backend.transactions.models import ReceiptKey
from gxb_backend.transactions.receipts import ReceiptRepository, canonical_request_fingerprint
from gxb_backend.mail.locking import mail_resource
from .maintenance import MaintenanceGate


class PostgresStateRepository(StateRepository):
    """Runtime-active relational identity + JSONB aggregate repository.

    Pass348 retired the inherited process-global request RLock after the live
    pre-retirement race suite passed. Request state is thread-local, player
    objects are transaction-local, and every durable mutation remains beneath
    the ordered PostgreSQL ResourceTransaction boundary. The legacy JSON
    StateRepository keeps its historical RLock unchanged.
    """

    def __init__(
        self,
        *,
        data_path,
        profile: str,
        engine_provider,
        coordinator: ResourceTransactionCoordinator,
        identity: IdentityService,
        account_auth: AccountSessionAuthenticator,
        context_auth: GameplayContextAuthenticator,
        context_selection: ContextSelectionService,
        region_directory: RegionDirectoryService,
        player_repository: PostgresPlayerAggregateRepository | None = None,
        account_global_repository: AccountGlobalRepository | None = None,
        mail_repository: MailRepository | None = None,
        anonymous_account_uid: str = "13371337",
        maintenance_gate: MaintenanceGate | None = None,
        server_clock=None,
    ) -> None:
        self._initialize_common(path=data_path, profile=profile, legacy_path=None, server_clock=server_clock)
        # _initialize_common() serves the unchanged legacy JSON implementation
        # too, so it constructs that adapter's RLock. The PostgreSQL subclass
        # overrides every inherited lock-taking method and must not retain a
        # misleading process-global serialization primitive.
        del self._lock
        self._local = _RequestBinding()
        self._engine_provider = engine_provider
        self._coordinator = coordinator
        self._identity = identity
        self._account_auth = account_auth
        self._context_auth = context_auth
        self._context_selection = context_selection
        self._region_directory = region_directory
        self._accounts = AccountRepository()
        self._directory = RegionDirectoryRepository()
        self._aggregates = player_repository or PostgresPlayerAggregateRepository()
        self._account_global = account_global_repository or AccountGlobalRepository()
        self._mail = mail_repository or MailRepository()
        self._anonymous_account_uid = str(anonymous_account_uid)
        self._maintenance_gate = maintenance_gate
        self._receipts = ReceiptRepository()
        self._player_store = TransactionBoundPostgresPlayerStateStore(self._aggregates, lambda: make_fresh_player(account_uid="0", player_id="1", region=1, region_name="Local-1"))
        self._player_working_set = {}
        self._player_fingerprints = {}
        self._sandbox_player_id = None
        self._realtime_stager = DurableRealtimeIntentStager(RealtimeEventSchemaRegistry(self._synchronization_catalogs))

    def _cache_player(self, player):
        """Keep relational PlayerState transaction-local, never process-cached."""
        return player

    @staticmethod
    def _request_id(req: dict[str, Any]) -> str:
        return str(req.get("request_id") or req.get("client_op_id") or f"mid-{req.get('mid', 0)}")

    def _principal_account(
        self,
        account_uid: str,
        *,
        sid: str = "",
        token: str = "",
        connection=None,
    ) -> AccountIdentity:
        if connection is None:
            with self._engine_provider().connect() as owned_connection:
                principal = self._accounts.get_principal(owned_connection, str(account_uid))
        else:
            principal = self._accounts.get_principal(connection, str(account_uid))
        username = principal.username if principal is not None else str(account_uid)
        return AccountIdentity(uid=str(account_uid), sid=str(sid), token=str(token), username=str(username))

    def _mail_addresses(self, req: dict[str, Any], mid: int) -> tuple[MailAddress, ...]:
        try:
            if mid == int(MID.SET_MAIL_READ):
                raw = req.get("id", req.get("mail_id", req.get("mail_ids")))
                values = raw if isinstance(raw, (list, tuple)) else (raw,)
                return tuple(sorted({MailAddress(bool(int(req.get("is_region", 0) or 0)), int(v)) for v in values if v not in (None, "")}))
            if mid == int(MID.MAIL_ONEKEY):
                return parse_onekey_addresses(req)
        except (TypeError, ValueError):
            return ()
        return ()

    def _bind_selected_context(self, stack: ExitStack, req: dict[str, Any], lease) -> None:
        resources = [
            *self._context_auth.lease_resources(lease),
            account_global_resource(lease.account_uid),
            player_state_resource(lease.player_id),
        ]
        for address in self._mail_addresses(req, int(req.get("mid", 0) or 0)):
            resources.append(mail_resource(lease.player_id, address))
        request = TransactionRequest(
            request_id=self._request_id(req), operation_name="runtime.http_gameplay",
            resources=tuple(resources), client_operation_id=str(req.get("client_op_id") or "") or None,
            retry_safe=False,
        )
        transaction = stack.enter_context(self._coordinator.begin(request))
        self._account_global.ensure_empty(transaction, lease.account_uid)
        context = self._context_auth.validate_lease(
            transaction, lease, supplied_region=req.get("region"),
            request_id=self._request_id(req), auth_scope=AuthScope.SELECTED_PLAYER.value,
        )
        stack.enter_context(self._player_store.bind(transaction))
        player = self._player_store.load(int(context.player_id))
        if player is None:
            raise LookupError(str(context.player_id))
        self._local.outer_transaction = transaction
        self._local.player = player
        self._local.account = self._principal_account(
            context.account_uid or "", connection=transaction.connection
        )
        self._local.session = {
            "uid": context.account_uid,
            "session_id": str(context.session_id),
            "context_id": str(context.context_id),
            "player_id": context.player_id,
            "region": context.region_id,
        }

    @contextmanager
    def request_scope(self, req: dict[str, Any] | None = None):
        request = dict(req or {})
        previous = dict(vars(self._local))
        self._clear_relational_binding()
        self._local.request = request
        try:
            mid = int(request.get("mid", 0) or 0)
        except (TypeError, ValueError):
            mid = 0
        try:
            with ExitStack() as stack:
                auth_failed = False
                try:
                    if mid in {int(MID.LOAD_USER_REGIONS), int(MID.RETRIEVE_TOKEN)}:
                        resolved = self._account_auth.resolve(
                            sid=request.get("sid"), login_token=request.get("login_token"),
                            request_id=self._request_id(request),
                        )
                        self._local.account = self._principal_account(
                            resolved.account.account_uid,
                            sid=str(request.get("sid") or ""), token=str(request.get("login_token") or ""),
                        )
                        self._local.session = {"uid": resolved.account.account_uid, "session_id": str(resolved.session.session_id)}
                    elif mid not in AuthScopeRegistry.PUBLIC_MIDS:
                        lease = self._context_auth.prepare_lease(request.get("token"))
                        self._bind_selected_context(stack, request, lease)
                except IdentityError:
                    auth_failed = True
                if auth_failed:
                    self._clear_binding()
                yield
                # EngineDispatcher drains this before returning. Other
                # authenticated entrypoints (notably the commerce bridge)
                # share the same request scope, so catch any remaining
                # committed intents before the outer transaction commits.
                services = self.current_services_or_none()
                if services is not None:
                    pending = services.uow.drain_post_commit()
                    if pending:
                        self.persist_post_commit(pending)
        finally:
            self._clear_relational_binding()
            vars(self._local).update(previous)

    def resolve_or_create_player(self, region: int, region_name: str | None = None):
        del region_name
        request = dict(getattr(self._local, "request", {}) or {})
        result = self._context_selection.select(
            region_id=int(region), request_id=self._request_id(request),
            sid=request.get("sid"), login_token=request.get("login_token"),
            client_operation_id=str(request.get("client_op_id") or "") or None,
        )
        lease = self._context_auth.prepare_lease(result.gameplay_token)
        stack = ExitStack()
        resources = (*self._context_auth.lease_resources(lease), account_global_resource(result.account_uid), player_state_resource(result.player_id))
        tx_request = TransactionRequest(
            request_id=self._request_id(request), operation_name="runtime.context_bootstrap",
            resources=resources, client_operation_id=str(request.get("client_op_id") or "") or None,
            retry_safe=False,
        )
        try:
            transaction = stack.enter_context(self._coordinator.begin(tx_request))
            self._account_global.ensure_empty(transaction, result.account_uid)
            self._context_auth.validate_lease(transaction, lease, supplied_region=result.region_id, request_id=self._request_id(request), auth_scope=AuthScope.CONTEXT_SELECTION.value)
            stack.enter_context(self._player_store.bind(transaction))
            try:
                player = self._player_store.load(result.player_id)
            except PlayerAggregateNotMaterialized:
                # Context selection and directory allocation are intentionally
                # separate from the mature aggregate layer.  A re-entrant stock
                # MID1 can observe a freshly allocated directory row before the
                # first request materializes JSONB.  We already hold the canonical
                # PLAYER row lock here, so materialize exactly once in-place and
                # make abandoned half-created rows self-healing on the next login.
                fresh = make_fresh_player(
                    account_uid=result.account_uid, player_id=str(result.player_id), region=result.region_id,
                    region_name=self.region_name(result.region_id),
                )
                SkillPointPolicy(fresh, self._data_dir()).initialize_fresh_full_pool()
                normalize_player_domain(
                    fresh, self._data_dir(), featured_rotation=self._featured_rotation
                )
                transformed = PlayerPayloadCodec.transform(fresh)
                self._aggregates.materialize(transaction, transformed.record)
                player = self._player_store.load(result.player_id)
            if player is None:
                raise LookupError(str(result.player_id))

            # Match the mature JSON store's durable load boundary. This also
            # repairs already-materialized Pass351-era fresh aggregates that
            # were created before the shared normalization seam existed (for
            # example a tutorial player whose Aquarius seed is missing).
            if normalize_player_domain(
                player, self._data_dir(), featured_rotation=self._featured_rotation
            ):
                self._player_store.save(player)
        except Exception:
            stack.close()
            raise
        # The stack must remain open through MID1 detail construction and is
        # closed by request_scope after the handler returns.
        old_stack = getattr(self._local, "selection_stack", None)
        if old_stack is not None:
            old_stack.close()
        self._local.selection_stack = stack
        self._local.outer_transaction = transaction
        self._local.player = player
        self._local.is_new_player = bool(result.is_new_player)
        self._local.account = self._principal_account(
            result.account_uid,
            sid=str(request.get("sid") or ""),
            token=result.gameplay_token,
            connection=transaction.connection,
        )
        self._local.session = {"uid": result.account_uid, "session_id": str(result.session_id), "context_id": str(result.context_id), "player_id": result.player_id, "region": result.region_id}
        return player, bool(result.is_new_player)

    def _clear_relational_binding(self) -> None:
        selection_stack = getattr(self._local, "selection_stack", None)
        if selection_stack is not None:
            selection_stack.close()
        self._clear_binding()
        self._local.selection_stack = None
        self._local.outer_transaction = None
        self._local.request = None
        self._local.selection_result = None
        self._local.region_counts = {}

    def get_account(self) -> AccountIdentity:
        account = getattr(self._local, "account", None)
        if account is None:
            raise RuntimeError("request has no relational account binding")
        return account

    def get_player(self):
        player = getattr(self._local, "player", None)
        if player is None:
            raise RuntimeError("request has no relational player binding")
        return player

    def refresh(self) -> None:
        player = getattr(self._local, "player", None)
        if player is not None:
            loaded = self._reload_player_from_disk(str(player.player_id))
            if loaded is not None:
                self._local.player = loaded
                self._local.services = None

    def current_session(self):
        return getattr(self._local, "session", None)

    def has_authenticated_session(self) -> bool:
        return getattr(self._local, "account", None) is not None

    def list_account_players(self):
        account = getattr(self._local, "account", None)
        if account is None:
            return []
        with self._engine_provider().connect() as connection:
            rows = self._directory.list_account_players(connection, account.uid)
            counts = dict(connection.execute(select(identity_players.c.region_id, func.count()).group_by(identity_players.c.region_id)).all())
            self._local.region_counts = {int(k): int(v) for k, v in counts.items()}
            out = []
            for row in rows:
                record = self._aggregates.load(connection, row.player_id)
                if record is not None:
                    out.append(PlayerPayloadCodec.hydrate(record, make_fresh_player(account_uid=row.account_uid, player_id=str(row.player_id), region=row.region_id, region_name=self.region_name(row.region_id))))
            return out

    def region_player_count(self, region: int) -> int:
        return int(getattr(self._local, "region_counts", {}).get(int(region), 0))

    def get_player_by_id(self, player_id: Any):
        with self._engine_provider().connect() as connection:
            record = self._aggregates.load(connection, int(player_id))
        if record is None:
            return None
        return PlayerPayloadCodec.hydrate(record, make_fresh_player(account_uid=record.account_uid, player_id=str(record.player_id), region=record.region_id, region_name=self.region_name(record.region_id)))

    def get_services(self) -> RequestServices:
        services = super().get_services()
        services.hydration_snapshot._providers[int(MID.LOAD_MAIL_LIST)] = lambda: self.relational_mail_list({})
        return services

    def save(self) -> None:
        player = getattr(self._local, "player", None)
        if player is None:
            return
        services = getattr(self._local, "services", None)
        if services is not None and services.player is player:
            services.uow.request_save()
        else:
            self._save_player_canonical(player)

    def set_region(self, region: int) -> None:
        del region
        raise RuntimeError("PostgreSQL region changes require the MID1 context-selection transaction")

    def persist_post_commit(self, pending: dict[str, list[object]]) -> bool:
        if not pending:
            return True
        transaction = getattr(self._local, "outer_transaction", None)
        if transaction is None:
            raise RuntimeError("durable post-commit intents require an outer ResourceTransaction")
        for topic, values in pending.items():
            if topic != POST_COMMIT_TOPIC:
                raise RuntimeError(f"unregistered durable post-commit topic {topic!r}")
            for value in values:
                if not isinstance(value, RealtimeEventIntent):
                    raise TypeError("realtime post-commit value must be RealtimeEventIntent")
                raw_context_id = (getattr(self._local, "session", {}) or {}).get("context_id")
                self._realtime_stager.stage(
                    transaction, value, expires_at=datetime.now(timezone.utc) + timedelta(seconds=30),
                    context_id=UUID(str(raw_context_id)) if raw_context_id else None,
                )
        return True

    def sdk_register(self, login: str, password: str):
        try:
            principal = self._identity.register_local(username=login, password=password, request_id=f"sdk-register:{login}")
        except IdentityError:
            return None, "conflict"
        return {"uid": principal.account_uid, "login": login}, "created"

    @staticmethod
    def _issued_identity(issued) -> AccountIdentity:
        return AccountIdentity(uid=issued.account.account_uid, sid=issued.sid, token=issued.login_token, username=issued.account.username)

    def sdk_login(self, login: str, password: str, *, device=None):
        try:
            return self._issued_identity(self._identity.login_local(username=login, password=password, request_id=f"sdk-login:{login}", device_metadata=device))
        except IdentityError:
            return None

    def sdk_anonymous_identity(self, *, device=None):
        issued = self._identity.issue_fresh_anonymous_session(account_uid=self._anonymous_account_uid, request_id="sdk-anonymous", device_metadata=device)
        return self._issued_identity(issued)

    def sdk_identity_from_sid(self, sid: str | None):
        # Raw login_token cannot be reconstructed from its digest; package-info
        # safely issues a fresh anonymous session instead.
        del sid
        return None

    def resolve_realtime_metadata(self, player_id: int):
        from gxb_backend.realtime.identity import RealtimePlayerMetadata
        player = self.get_player_by_id(player_id)
        return None if player is None else RealtimePlayerMetadata(guild_id=int(player.guild_id or 0))

    def resolve_realtime_identity(self, token: str, region: int):
        if self._maintenance_gate is not None and self._maintenance_gate.active():
            return None
        try:
            context = self._context_auth.resolve(gameplay_token=token, supplied_region=region, request_id="realtime-admission", auth_scope=AuthScope.REALTIME_ADMISSION.value)
        except IdentityError:
            return None
        metadata = self.resolve_realtime_metadata(int(context.player_id))
        if metadata is None:
            return None
        return AuthenticatedPlayerIdentity(uid=str(context.account_uid), sid="", player_id=str(context.player_id), region=int(context.region_id), guild_id=metadata.guild_id, session_id=str(context.session_id), context_id=str(context.context_id))

    def current_realtime_identity(self):
        player = getattr(self._local, "player", None)
        session = getattr(self._local, "session", None)
        account = getattr(self._local, "account", None)
        if player is None or not isinstance(session, dict) or account is None:
            return None
        return AuthenticatedPlayerIdentity(uid=account.uid, sid="", player_id=str(player.player_id), region=int(player.region), guild_id=int(player.guild_id or 0), session_id=session.get("session_id"), context_id=session.get("context_id"))

    def _mail_connection(self):
        transaction = getattr(self._local, "outer_transaction", None)
        if transaction is None:
            raise RuntimeError("relational mail requires outer transaction")
        return transaction.connection

    def relational_mail_list(self, req: dict[str, Any]):
        del req
        rows = self._mail.list_player(self._mail_connection(), int(self.get_player().player_id))
        return mailbox_snapshot(rows)

    def relational_mail_read(self, req: dict[str, Any]):
        raw = req.get("id", req.get("mail_id", req.get("mail_ids")))
        values = raw if isinstance(raw, (list, tuple)) else (raw,)
        addresses = tuple(MailAddress(bool(int(req.get("is_region", 0) or 0)), int(v)) for v in values if v not in (None, ""))
        changed = self._mail.mark_read(self._mail_connection(), int(self.get_player().player_id), addresses)
        return {"changed": bool(changed)}

    def relational_mail_onekey(self, req: dict[str, Any]):
        addresses = parse_onekey_addresses(req)
        player_id = int(self.get_player().player_id)
        request_id = self._request_id(req)
        key = ReceiptKey("player", str(player_id), "mail", "claim", str(req.get("client_op_id") or request_id))
        fingerprint = canonical_request_fingerprint({"player_id": player_id, "addresses": [{"is_region": a.is_region, "id": a.protocol_mail_id} for a in addresses]})
        existing = self._receipts.get(self._mail_connection(), key)
        if existing is not None:
            if existing.request_fingerprint != fingerprint.hex():
                raise RuntimeError("mail receipt replay conflict")
            return dict(existing.result)
        services = self.get_services()
        awards: list[dict[str, Any]] = []
        with services.uow.transaction(PlayerOperationContext(actor_player_id=str(player_id), domain="mail", operation_name="claim", protocol_mid=int(MID.MAIL_ONEKEY), idempotency_key=key.idempotency_key)):
            for address in addresses:
                mail, db_now = self._mail.load_locked(self._mail_connection(), player_id, address)
                if mail is None or mail.claimed_at is not None:
                    continue
                if mail.expires_at is not None and db_now is not None and mail.expires_at <= db_now:
                    continue
                grants = []
                for attachment in mail.attachments:
                    item_id = int(attachment.get("table_id", 0) or 0)
                    amount = int(attachment.get("item_num", 0) or 0)
                    if item_id <= 0 or amount <= 0:
                        raise ValueError("unsupported relational mail attachment shape")
                    grants.append(InventoryGrant(ContentRef(CatalogNamespace.ITEM, item_id), amount))
                if grants:
                    result = services.rewards.apply(RewardPlan(origin=RewardOrigin("mail", "claim", protocol_mid=int(MID.MAIL_ONEKEY)), inventory=tuple(grants)))
                    awards.extend(dict(row) for row in result.inventory_awards)
                if not self._mail.mark_claimed(self._mail_connection(), mail.mail_row_id):
                    raise RuntimeError("mail claim changed concurrently")
                services.uow.request_save()
        response = onekey_response(awards=awards, snapshot=self.relational_mail_list({}))
        receipt, replayed = self._receipts.record_or_replay(self._mail_connection(), key=key, request_fingerprint=fingerprint, result=response, actor_account_uid=self.get_account().uid, retention_policy="MAIL_CLAIM")
        return dict(receipt.result) if replayed else response
