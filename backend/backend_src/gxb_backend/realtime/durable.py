"""Durable realtime outbox staging and dispatch for Pass344 I5."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Any, Mapping

from gxb_backend.transactions.models import DeliveryClass, OutboxIntent
from gxb_backend.transactions.outbox import OutboxRepository

from .contracts import PlayerAudience, RealtimeEventIntent, RealtimeRole, RoomAudience, SessionAudience
from .control import PrivateControlKind, RealtimeControlPublisher
from .publisher import RealtimeEventSchemaRegistry, RealtimePublishReport, TypedRealtimeEventPublisher


REALTIME_EVENT_TOPIC = "realtime.event"
REALTIME_DELIVERY_CLASSES = (
    DeliveryClass.TRANSIENT_REALTIME_NOTICE,
    DeliveryClass.IDEMPOTENT_REALTIME_CONTROL,
)


def _audience_payload(audience) -> tuple[dict[str, object], str, str]:
    if isinstance(audience, PlayerAudience):
        roles = [RealtimeRole(role).value for role in audience.roles]
        return {"kind": "PLAYER", "player_id": str(audience.player_id), "roles": roles}, "player", str(audience.player_id)
    if isinstance(audience, RoomAudience):
        role = RealtimeRole(audience.role).value
        return {"kind": "ROOM", "role": role, "room_id": int(audience.room_id)}, "room", f"{role}:{int(audience.room_id)}"
    if isinstance(audience, SessionAudience):
        return {"kind": "CONNECTION", "connection_id": str(audience.connection_id)}, "connection", str(audience.connection_id)
    raise TypeError(f"unsupported realtime audience {type(audience).__name__}")


def _decode_audience(raw: Mapping[str, Any]):
    kind = str(raw.get("kind", ""))
    if kind == "PLAYER":
        roles_raw = raw.get("roles")
        roles = () if roles_raw in (None, []) else tuple(RealtimeRole(str(v)) for v in roles_raw)
        return PlayerAudience(str(raw["player_id"]), roles=roles)
    if kind == "ROOM":
        return RoomAudience(RealtimeRole(str(raw["role"])), int(raw["room_id"]))
    if kind == "CONNECTION":
        return SessionAudience(str(raw["connection_id"]))
    raise ValueError("invalid durable realtime audience")


class DurableRealtimeIntentStager:
    """Translate validated domain realtime intents into the durable I2 outbox."""

    def __init__(self, schemas: RealtimeEventSchemaRegistry) -> None:
        self.schemas = schemas

    def stage(
        self,
        transaction,
        intent: RealtimeEventIntent,
        *,
        expires_at: datetime,
        context_id=None,
        priority: int = 100,
    ) -> None:
        self.schemas.validate(intent)
        audience, resource_kind, resource_key = _audience_payload(intent.audience)
        transaction.stage_outbox(
            OutboxIntent(
                topic=REALTIME_EVENT_TOPIC,
                resource_kind=resource_kind,
                resource_key=resource_key,
                context_id=context_id,
                payload={
                    "mid": int(intent.mid),
                    "params": dict(intent.params),
                    "audience": audience,
                    "owner_domain": str(intent.owner_domain),
                    "wire_delivery_class": str(intent.delivery_class),
                    "schema_key": intent.schema_key,
                },
                delivery_class=DeliveryClass.TRANSIENT_REALTIME_NOTICE,
                priority=int(priority),
                expires_at=expires_at,
            )
        )


@dataclass(frozen=True, slots=True)
class RealtimeDispatchReport:
    claimed: int = 0
    transient_attempted: int = 0
    controls_applied: int = 0
    done: int = 0
    released: int = 0


class RealtimeControlEventHandler:
    """Apply idempotent identity/room invalidation events to transient sockets."""

    def __init__(self, controls: RealtimeControlPublisher) -> None:
        self.controls = controls

    def handle(self, row: Mapping[str, Any]) -> int:
        topic = str(row.get("topic", ""))
        payload = row.get("payload")
        if not isinstance(payload, Mapping):
            raise ValueError("control outbox payload must be a mapping")
        if topic == "identity.context_superseded":
            context_id = str(payload.get("old_context_id") or row.get("context_id") or "")
            if not context_id:
                raise ValueError("context_superseded missing old context")
            return self.controls.close_context(context_id, reason=str(payload.get("reason") or "CONTEXT_SUPERSEDED"))
        if topic == "identity.session_invalidated":
            session_id = str(payload.get("session_id") or "")
            if not session_id:
                raise ValueError("session_invalidated missing session")
            return self.controls.close_account_session(session_id, reason=str(payload.get("reason") or "SESSION_INVALIDATED"))
        if topic == "identity.context_selected":
            # Durable selection is already authoritative. The superseded-context
            # event and periodic sweep perform any required socket invalidation.
            return 0
        if topic == "realtime.room_invalidated":
            context_id = str(payload.get("context_id") or row.get("context_id") or "")
            role_raw = str(payload.get("role") or "")
            try:
                role = RealtimeRole(role_raw)
                room_id = int(payload.get("room_id"))
            except (TypeError, ValueError) as exc:
                raise ValueError("room invalidation requires context_id, role and room_id") from exc
            if not context_id or room_id <= 0:
                raise ValueError("room invalidation requires context_id, role and room_id")
            return self.controls.close_context_room(
                context_id,
                role=role,
                room_id=room_id,
                reason=str(payload.get("reason") or "ROOM_INVALIDATED"),
            )
        raise ValueError(f"unsupported realtime control topic {topic!r}")


class RealtimeOutboxDispatcher:
    """Poll durable realtime rows; socket I/O always happens outside DB txns."""

    def __init__(
        self,
        engine_provider,
        publisher: TypedRealtimeEventPublisher,
        control_handler: RealtimeControlEventHandler,
        *,
        repository: OutboxRepository | None = None,
        worker_id: str = "gxb-realtime",
        batch_size: int = 100,
    ) -> None:
        self._engine_provider = engine_provider
        self.publisher = publisher
        self.controls = control_handler
        self.repository = repository or OutboxRepository()
        self.worker_id = str(worker_id)
        self.batch_size = int(batch_size)
        if not self.worker_id.strip() or self.batch_size <= 0:
            raise ValueError("invalid realtime outbox worker configuration")

    def _engine(self):
        provider = self._engine_provider
        return provider() if callable(provider) else provider.engine()

    @staticmethod
    def decode_intent(row: Mapping[str, Any]) -> RealtimeEventIntent:
        if str(row.get("topic")) != REALTIME_EVENT_TOPIC:
            raise ValueError("not a durable realtime event row")
        payload = row.get("payload")
        if not isinstance(payload, Mapping):
            raise ValueError("realtime outbox payload must be a mapping")
        audience = payload.get("audience")
        if not isinstance(audience, Mapping):
            raise ValueError("realtime outbox audience must be a mapping")
        params = payload.get("params")
        if not isinstance(params, Mapping):
            raise ValueError("realtime params must be a mapping")
        return RealtimeEventIntent(
            mid=int(payload["mid"]),
            params=dict(params),
            audience=_decode_audience(audience),
            owner_domain=str(payload["owner_domain"]),
            delivery_class=str(payload["wire_delivery_class"]),
            schema_key=payload.get("schema_key"),
        )

    def recover_stale_claims(self, *, stale_after_seconds: int) -> int:
        engine = self._engine()
        with engine.begin() as connection:
            return self.repository.requeue_stale_claims(connection, stale_after_seconds=stale_after_seconds)

    def poll_once(self) -> RealtimeDispatchReport:
        engine = self._engine()
        with engine.begin() as connection:
            rows = self.repository.claim_available(
                connection,
                worker_id=self.worker_id,
                limit=self.batch_size,
                delivery_classes=REALTIME_DELIVERY_CLASSES,
            )
            # Transient at-most-once rows become terminal-before-I/O in the same
            # short claim transaction. A crash after commit may lose the notice,
            # but can never duplicate a durable business effect.
            for row in rows:
                if DeliveryClass(str(row["delivery_class"])) is DeliveryClass.TRANSIENT_REALTIME_NOTICE:
                    if not self.repository.mark_dispatched(connection, int(row["event_id"]), worker_id=self.worker_id):
                        raise RuntimeError("lost transient outbox claim before dispatch fence")

        transient_attempted = controls_applied = done = released = 0
        for row in rows:
            event_id = int(row["event_id"])
            delivery_class = DeliveryClass(str(row["delivery_class"]))
            if delivery_class is DeliveryClass.TRANSIENT_REALTIME_NOTICE:
                transient_attempted += 1
                error: str | None = None
                try:
                    self.publisher.publish(self.decode_intent(row))
                except Exception as exc:
                    error = f"transient publish failed: {type(exc).__name__}: {exc}"
                with engine.begin() as connection:
                    if self.repository.mark_done(connection, event_id, worker_id=self.worker_id, error=error):
                        done += 1
                continue
            try:
                controls_applied += self.controls.handle(row)
            except Exception as exc:
                with engine.begin() as connection:
                    if self.repository.release_for_retry(connection, event_id, worker_id=self.worker_id, error=f"{type(exc).__name__}: {exc}"):
                        released += 1
                continue
            with engine.begin() as connection:
                if self.repository.mark_done(connection, event_id, worker_id=self.worker_id):
                    done += 1
        return RealtimeDispatchReport(
            claimed=len(rows),
            transient_attempted=transient_attempted,
            controls_applied=controls_applied,
            done=done,
            released=released,
        )
