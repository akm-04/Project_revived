"""Typed best-effort publication into authenticated transient realtime sessions."""

from __future__ import annotations

from dataclasses import dataclass
from types import MappingProxyType
from typing import Callable, Iterable, Mapping

from gxb_backend.synchronization import SynchronizationCatalogs

from .codec import RealtimeFrameEncoder
from .contracts import (
    PlayerAudience,
    RealtimeAudience,
    RealtimeEventIntent,
    RealtimeRole,
    RoomAudience,
    SessionAudience,
)
from .session import AuthenticatedRealtimeSessionRegistry, RealtimeSession

POST_COMMIT_TOPIC = "realtime.transient"


class RealtimePublicationError(ValueError):
    """Fail-closed schema/audience error before a frame is queued."""


@dataclass(frozen=True, slots=True)
class RealtimeNoticeSchema:
    """Domain-owned validator for one notice_type inside a generic notice MID.

    Wave E intentionally composes no gameplay-domain notice schemas yet.  A
    future Mail/Arena/Guild/etc. owner can provide these descriptors without
    changing the transport publisher itself.
    """

    notice_type: int
    owner_domain: str
    parent_mids: tuple[int, ...]
    allowed_roles: tuple[RealtimeRole, ...]
    validator: Callable[[Mapping[str, object]], bool]


@dataclass(frozen=True, slots=True)
class RealtimePublishReport:
    mid: int
    selected: int
    enqueued: int
    disconnected: int


class RealtimeEventSchemaRegistry:
    """Read-only event/notice validator over the frozen synchronization catalog."""

    def __init__(
        self,
        catalogs: SynchronizationCatalogs,
        *,
        notice_schemas: Iterable[RealtimeNoticeSchema] = (),
    ) -> None:
        self.catalogs = catalogs
        notices: dict[tuple[int, int], RealtimeNoticeSchema] = {}
        for row in notice_schemas:
            notice_type = self._exact_int(row.notice_type)
            if notice_type is None or notice_type <= 0:
                raise ValueError("notice_type must be a positive integer")
            for parent_mid in row.parent_mids:
                mid = self._exact_int(parent_mid)
                if mid is None or mid <= 0:
                    raise ValueError("notice parent MID must be positive")
                key = (mid, notice_type)
                if key in notices:
                    raise ValueError(f"duplicate realtime notice schema {key}")
                notices[key] = row
        self._notice_schemas = MappingProxyType(notices)

    @staticmethod
    def _exact_int(value: object) -> int | None:
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            return None
        integer = int(value)
        if float(value) != float(integer):
            return None
        return integer

    @staticmethod
    def _role(value: RealtimeRole | str) -> RealtimeRole:
        if isinstance(value, RealtimeRole):
            return value
        try:
            return RealtimeRole(str(value))
        except ValueError as exc:
            raise RealtimePublicationError(f"invalid realtime role {value!r}") from exc

    def descriptor(self, mid: int):
        return self.catalogs.realtime_event(int(mid))

    def validate(self, intent: RealtimeEventIntent) -> tuple[RealtimeRole, ...]:
        descriptor = self.descriptor(intent.mid)
        if descriptor is None:
            raise RealtimePublicationError(f"unregistered realtime MID {intent.mid}")
        if descriptor.direction not in {"server->client", "bidirectional"}:
            raise RealtimePublicationError(f"MID {intent.mid} is not server-publishable")
        if not descriptor.publication_enabled:
            raise RealtimePublicationError(f"MID {intent.mid} publication is deferred/disabled")
        if str(intent.delivery_class) != descriptor.delivery_class:
            raise RealtimePublicationError(
                f"MID {intent.mid} delivery class mismatch: {intent.delivery_class!r}"
            )
        if intent.schema_key is not None and str(intent.schema_key) != descriptor.schema_key:
            raise RealtimePublicationError(f"MID {intent.mid} schema_key mismatch")
        if not isinstance(intent.params, Mapping):
            raise RealtimePublicationError("realtime params must be a mapping")

        allowed = tuple(self._role(v) for v in descriptor.allowed_roles)
        audience_roles = self._audience_roles(intent.audience)
        for role in audience_roles:
            if role not in allowed:
                raise RealtimePublicationError(
                    f"MID {intent.mid} cannot target role {role.value}"
                )

        schema_key = descriptor.schema_key
        if schema_key == "typed_notice":
            self._validate_typed_notice(intent, audience_roles)
        elif schema_key == "force_reload":
            if str(intent.owner_domain) != descriptor.owner_domain:
                raise RealtimePublicationError("FORCE_RELOAD owner mismatch")
        elif schema_key == "chat_room_entered":
            if str(intent.owner_domain) != descriptor.owner_domain:
                raise RealtimePublicationError("CHAT_ROOM_ENTERED owner mismatch")
            room_id = self._exact_int(intent.params.get("room_id"))
            if room_id is None or room_id <= 0:
                raise RealtimePublicationError("CHAT_ROOM_ENTERED requires room_id")
        elif schema_key == "guild_fight_notice":
            if str(intent.owner_domain) != descriptor.owner_domain:
                raise RealtimePublicationError("GUILD_FIGHT_NOTICE owner mismatch")
            required = ("copy_id", "chapter_id", "player_id")
            if any(key not in intent.params for key in required):
                raise RealtimePublicationError("GUILD_FIGHT_NOTICE missing required field")
        elif schema_key == "commerce_recharge":
            if str(intent.owner_domain) != descriptor.owner_domain:
                raise RealtimePublicationError("RECHARGE owner mismatch")
            if not isinstance(intent.params.get("params"), Mapping):
                raise RealtimePublicationError("RECHARGE requires nested params")
        elif schema_key == "empty_params":
            if dict(intent.params):
                raise RealtimePublicationError("empty_params schema requires {}")
        elif schema_key == "tcp_login":
            raise RealtimePublicationError("TCP_LOGIN is client->server session control")
        else:
            raise RealtimePublicationError(f"unimplemented realtime schema {schema_key!r}")
        return audience_roles


    def validate_resolved_role(self, intent: RealtimeEventIntent, role: RealtimeRole) -> None:
        """Validate a live SessionAudience role that was unknown at stage time."""
        descriptor = self.descriptor(intent.mid)
        if descriptor is None:
            raise RealtimePublicationError(f"unregistered realtime MID {intent.mid}")
        role = self._role(role)
        allowed = tuple(self._role(v) for v in descriptor.allowed_roles)
        if role not in allowed:
            raise RealtimePublicationError(f"MID {intent.mid} cannot target role {role.value}")
        if descriptor.schema_key == "typed_notice":
            notice_type = self._exact_int(intent.params.get("notice_type"))
            if notice_type is None or notice_type <= 0:
                raise RealtimePublicationError("typed notice requires numeric notice_type")
            notice = self._notice_schemas.get((int(intent.mid), notice_type))
            if notice is None:
                raise RealtimePublicationError(
                    f"typed notice MID {intent.mid} notice_type {notice_type} has no owning schema"
                )
            if role not in notice.allowed_roles:
                raise RealtimePublicationError(
                    f"notice_type {notice_type} cannot target role {role.value}"
                )

    def _audience_roles(self, audience: RealtimeAudience) -> tuple[RealtimeRole, ...]:
        if isinstance(audience, PlayerAudience):
            roles = audience.roles or (RealtimeRole.WORLD,)
            return tuple(self._role(v) for v in roles)
        if isinstance(audience, RoomAudience):
            return (self._role(audience.role),)
        if isinstance(audience, SessionAudience):
            # Session role is checked against the resolved live session by the publisher.
            return ()
        raise RealtimePublicationError(f"unsupported realtime audience {type(audience).__name__}")

    def _validate_typed_notice(
        self,
        intent: RealtimeEventIntent,
        audience_roles: tuple[RealtimeRole, ...],
    ) -> None:
        notice_type = self._exact_int(intent.params.get("notice_type"))
        if notice_type is None or notice_type <= 0:
            raise RealtimePublicationError("typed notice requires numeric notice_type")
        notice = self._notice_schemas.get((int(intent.mid), notice_type))
        if notice is None:
            raise RealtimePublicationError(
                f"typed notice MID {intent.mid} notice_type {notice_type} has no owning schema"
            )
        if str(intent.owner_domain) != notice.owner_domain:
            raise RealtimePublicationError("typed notice owner mismatch")
        for role in audience_roles:
            if role not in notice.allowed_roles:
                raise RealtimePublicationError(
                    f"notice_type {notice_type} cannot target role {role.value}"
                )
        if not notice.validator(intent.params):
            raise RealtimePublicationError(
                f"typed notice MID {intent.mid} notice_type {notice_type} failed domain schema"
            )


class RealtimeIntentStager:
    """Request-scoped validator/stager; it never has socket/session access."""

    def __init__(self, uow, schemas: RealtimeEventSchemaRegistry) -> None:
        self.uow = uow
        self.schemas = schemas

    def stage(self, intent: RealtimeEventIntent) -> None:
        self.schemas.validate(intent)
        self.uow.stage_post_commit(POST_COMMIT_TOPIC, intent)


class TypedRealtimeEventPublisher:
    """Process-wide best-effort publisher over transient authenticated sessions."""

    def __init__(
        self,
        schemas: RealtimeEventSchemaRegistry,
        sessions: AuthenticatedRealtimeSessionRegistry,
        *,
        encoder: RealtimeFrameEncoder | None = None,
    ) -> None:
        self.schemas = schemas
        self.sessions = sessions
        self.encoder = encoder or RealtimeFrameEncoder()

    def publish(self, intent: RealtimeEventIntent) -> RealtimePublishReport:
        self.schemas.validate(intent)
        selected = self._select_sessions(intent)
        encoded = self.encoder.encode(int(intent.mid), dict(intent.params), sequence=0)
        enqueued = 0
        disconnected = 0
        for session in selected:
            if session.enqueue(encoded):
                enqueued += 1
                continue
            removed = self.sessions.remove(session.connection_id)
            if removed is not None:
                removed.close()
                disconnected += 1
        return RealtimePublishReport(
            mid=int(intent.mid),
            selected=len(selected),
            enqueued=enqueued,
            disconnected=disconnected,
        )

    def publish_many(self, intents: Iterable[RealtimeEventIntent]) -> tuple[RealtimePublishReport, ...]:
        reports: list[RealtimePublishReport] = []
        for intent in intents:
            reports.append(self.publish(intent))
        return tuple(reports)

    def _select_sessions(self, intent: RealtimeEventIntent) -> tuple[RealtimeSession, ...]:
        audience = intent.audience
        descriptor = self.schemas.descriptor(intent.mid)
        if descriptor is None:
            return ()
        allowed_roles = {RealtimeRole(value) for value in descriptor.allowed_roles}

        ids: set[str] = set()
        if isinstance(audience, PlayerAudience):
            wanted_roles = set(audience.roles or (RealtimeRole.WORLD,))
            for connection_id in self.sessions.connections_for_player(audience.player_id):
                session = self.sessions.get(connection_id)
                if session is not None and session.role in wanted_roles and session.role in allowed_roles:
                    ids.add(connection_id)
        elif isinstance(audience, RoomAudience):
            role = RealtimeRole(audience.role)
            if role in allowed_roles:
                ids.update(self.sessions.connections_for_room(role, int(audience.room_id)))
        elif isinstance(audience, SessionAudience):
            session = self.sessions.get(audience.connection_id)
            if session is not None and session.role in allowed_roles:
                ids.add(session.connection_id)

        out: list[RealtimeSession] = []
        for connection_id in sorted(ids):
            session = self.sessions.get(connection_id)
            if session is not None:
                self.schemas.validate_resolved_role(intent, session.role)
                out.append(session)
        return tuple(out)
