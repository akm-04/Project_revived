"""App-scoped, non-persistent composition facade for realtime infrastructure."""

from __future__ import annotations

from gxb_backend.synchronization import SynchronizationCatalogs

from .admission import RealtimeRoomAdmissionPolicy, RealtimeRoomDirectory
from .contracts import RealtimeEventIntent, RealtimeIdentityResolver
from .publisher import (
    POST_COMMIT_TOPIC,
    RealtimeEventSchemaRegistry,
    RealtimeNoticeSchema,
    RealtimePublishReport,
    TypedRealtimeEventPublisher,
)
from .server import RealtimeServer
from .session import AuthenticatedRealtimeSessionRegistry


class RealtimeRuntime:
    """Compose transport infrastructure without acquiring canonical state.

    AppFactory constructs this object after StateRepository startup validation.
    Construction never opens a socket. ``run.main`` starts the listener only
    after the entire Flask/dispatcher graph has been built successfully.
    """

    def __init__(
        self,
        host: str,
        port: int,
        identity_resolver: RealtimeIdentityResolver,
        catalogs: SynchronizationCatalogs | None = None,
        *,
        notice_schemas: tuple[RealtimeNoticeSchema, ...] = (),
    ) -> None:
        self.identity_resolver = identity_resolver
        if catalogs is None:
            catalogs = getattr(identity_resolver, "synchronization_catalogs", None)
        if not isinstance(catalogs, SynchronizationCatalogs):
            raise ValueError("RealtimeRuntime requires validated SynchronizationCatalogs")
        self.admission_policy = RealtimeRoomAdmissionPolicy()
        self.room_directory = RealtimeRoomDirectory(str(host), int(port), self.admission_policy)
        self.session_registry = AuthenticatedRealtimeSessionRegistry()
        self.event_schemas = RealtimeEventSchemaRegistry(
            catalogs,
            notice_schemas=notice_schemas,
        )
        self.publisher = TypedRealtimeEventPublisher(
            self.event_schemas,
            self.session_registry,
        )
        self.server = RealtimeServer(
            host,
            port,
            identity_resolver,
            admission_policy=self.admission_policy,
            registry=self.session_registry,
        )

    @property
    def is_listening(self) -> bool:
        return self.server.bound_port is not None

    def publish(self, intent: RealtimeEventIntent) -> RealtimePublishReport:
        return self.publisher.publish(intent)

    def handle_post_commit(self, topic: str, values: tuple[object, ...]) -> None:
        """Best-effort dispatcher sink; called only after repository scope exit."""
        if str(topic) != POST_COMMIT_TOPIC:
            print(f"[REALTIME] ignored unknown post-commit topic {topic!r}")
            return
        for value in values:
            if not isinstance(value, RealtimeEventIntent):
                print(f"[REALTIME] dropped non-intent post-commit value {type(value).__name__}")
                continue
            try:
                report = self.publisher.publish(value)
                if report.selected and report.enqueued != report.selected:
                    print(
                        f"[REALTIME] partial publish mid={report.mid} "
                        f"selected={report.selected} enqueued={report.enqueued} "
                        f"disconnected={report.disconnected}"
                    )
            except Exception as exc:
                # Durable gameplay commit has already succeeded. Publication is
                # deliberately isolated from HTTP success/failure semantics.
                print(f"[REALTIME] post-commit publish rejected/failed: {exc}")

    def start(self) -> None:
        self.server.start()

    def stop(self) -> None:
        self.server.stop()
