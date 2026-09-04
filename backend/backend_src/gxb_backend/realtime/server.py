"""Minimum authenticated Xinyoudi realtime TCP runtime (U4B Wave D)."""

from __future__ import annotations

import socket
import threading
import time
import uuid
from typing import Any

from gxb_backend.protocol.mids import MID

from .admission import RealtimeRoomAdmissionPolicy
from .codec import RealtimeCodecError, RealtimeFrame, RealtimeFrameEncoder, RealtimeFrameStreamDecoder
from .contracts import RealtimeIdentityResolver
from .control import PrivateControlKind, RealtimeControlPublisher
from .session import AuthenticatedRealtimeSessionRegistry, RealtimeSession


TCP_LOGIN = int(MID.TCP_LOGIN)
CHAT_ROOM_ENTERED = int(MID.CHAT_ROOM_ENTERED)
SOCKET_HEARTBEAT = int(MID.SOCKET_HEARTBEAT)

PREAUTH_TIMEOUT_SECONDS = 15.0
IDLE_TIMEOUT_SECONDS = 1320.0


class RealtimeServer:
    """Threaded authenticated transport foundation with no gameplay ownership."""

    def __init__(
        self,
        host: str,
        port: int,
        identity_resolver: RealtimeIdentityResolver,
        *,
        admission_policy: RealtimeRoomAdmissionPolicy | None = None,
        registry: AuthenticatedRealtimeSessionRegistry | None = None,
        control_publisher: RealtimeControlPublisher | None = None,
    ) -> None:
        self.host = str(host)
        self.port = int(port)
        self.identity_resolver = identity_resolver
        self.admission_policy = admission_policy or RealtimeRoomAdmissionPolicy()
        self.registry = registry or AuthenticatedRealtimeSessionRegistry()
        self.control_publisher = control_publisher or RealtimeControlPublisher(self.registry)
        self.encoder = RealtimeFrameEncoder()
        self._thread: threading.Thread | None = None
        self._stop = threading.Event()
        self._ready = threading.Event()
        self._listener: socket.socket | None = None
        self._bound_port: int | None = None
        self._workers_lock = threading.RLock()
        self._workers: set[threading.Thread] = set()

    @property
    def bound_port(self) -> int | None:
        return self._bound_port

    def start(self) -> None:
        if self._thread and self._thread.is_alive():
            return
        self._stop.clear()
        self._ready.clear()
        self._thread = threading.Thread(target=self._serve, name="gxb-realtime-listener", daemon=True)
        self._thread.start()

    def wait_ready(self, timeout: float = 5.0) -> bool:
        return self._ready.wait(timeout)

    def _serve(self) -> None:
        bind_host = "0.0.0.0" if self.host not in {"127.0.0.1", "localhost", "0.0.0.0"} else self.host
        try:
            listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self._listener = listener
            listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            listener.bind((bind_host, self.port))
            self._bound_port = int(listener.getsockname()[1])
            listener.listen(32)
            listener.settimeout(0.5)
            print(
                f"[REALTIME] listening on {bind_host}:{self._bound_port}; "
                f"advertised host={self.host}"
            )
            self._ready.set()
            while not self._stop.is_set():
                try:
                    conn, addr = listener.accept()
                except socket.timeout:
                    continue
                except OSError:
                    if self._stop.is_set():
                        break
                    raise
                worker = threading.Thread(
                    target=self._client_worker,
                    args=(conn, addr),
                    name=f"gxb-realtime-reader-{addr[0]}:{addr[1]}",
                    daemon=True,
                )
                with self._workers_lock:
                    self._workers.add(worker)
                worker.start()
        except Exception as exc:
            self._ready.set()
            if not self._stop.is_set():
                print(f"[REALTIME] failed to bind/listen on {bind_host}:{self.port}: {exc}")
        finally:
            listener = self._listener
            self._listener = None
            if listener is not None:
                try:
                    listener.close()
                except OSError:
                    pass

    def _client_worker(self, conn: socket.socket, addr: Any) -> None:
        try:
            self._handle_client(conn, addr)
        finally:
            current = threading.current_thread()
            with self._workers_lock:
                self._workers.discard(current)

    @staticmethod
    def _number_to_int(value: Any) -> int | None:
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            return None
        integer = int(value)
        if float(value) != float(integer):
            return None
        return integer

    def _parse_login(self, frame: RealtimeFrame):
        if frame.mid != TCP_LOGIN or not isinstance(frame.params, dict):
            return None
        token = frame.params.get("token")
        region = self._number_to_int(frame.params.get("region"))
        room_id = self._number_to_int(frame.params.get("room_id"))
        if not isinstance(token, str) or not token or region is None or room_id is None or region <= 0:
            return None
        try:
            identity = self.identity_resolver.resolve_realtime_identity(token, region)
        except Exception:
            # Admission fails closed on database/provider failure. Raw bearer
            # material is never included in an exception/log message here.
            return None
        if identity is None:
            return None
        admission = self.admission_policy.classify(identity, room_id)
        if admission is None:
            return None
        return identity, admission

    def _handle_client(self, conn: socket.socket, addr: Any) -> None:
        connection_id = uuid.uuid4().hex
        decoder = RealtimeFrameStreamDecoder()
        accepted_at = time.monotonic()
        session: RealtimeSession | None = None
        conn.settimeout(0.5)
        try:
            while not self._stop.is_set():
                now = time.monotonic()
                if session is None:
                    if now - accepted_at > PREAUTH_TIMEOUT_SECONDS:
                        break
                elif now - session.last_received_at > IDLE_TIMEOUT_SECONDS:
                    break
                try:
                    chunk = conn.recv(8192)
                except socket.timeout:
                    continue
                except OSError:
                    break
                if not chunk:
                    break
                try:
                    frames = decoder.feed(chunk)
                except RealtimeCodecError:
                    break
                for frame in frames:
                    now = time.monotonic()
                    if session is None:
                        parsed = self._parse_login(frame)
                        if parsed is None:
                            return
                        identity, admission = parsed
                        # Canonical identity resolution is complete before the
                        # transient registry lock/session lifecycle begins.
                        session = RealtimeSession(
                            connection_id=connection_id,
                            identity=identity,
                            role=admission.role,
                            room_id=admission.room_id,
                            sock=conn,
                            connected_at=now,
                            last_received_at=now,
                            _on_writer_failure=self._writer_failed,
                        )
                        if session.context_id:
                            superseded = self.registry.register_newest(session)
                        else:
                            self.registry.register(session)
                            superseded = None
                        session.start_writer()
                        if superseded is not None:
                            self.control_publisher.close_session(
                                superseded,
                                kind=PrivateControlKind.CONNECTION_SUPERSEDED,
                                reason="NEWEST_CONTEXT_ROLE_WINS",
                            )
                        entered = self.encoder.encode(
                            CHAT_ROOM_ENTERED,
                            {"room_id": admission.room_id},
                            sequence=0,
                        )
                        if not session.enqueue(entered):
                            return
                    else:
                        session.mark_received(now)
                        if frame.mid == SOCKET_HEARTBEAT and frame.params == {}:
                            # Current source requires no heartbeat echo.
                            continue
                        # Wave D has no feature-owned client->server MID
                        # descriptors. Fail closed instead of guessing/echoing.
                        return
        finally:
            if session is not None:
                self.registry.remove(session.connection_id)
                session.close()
            else:
                try:
                    conn.close()
                except OSError:
                    pass

    def _writer_failed(self, session: RealtimeSession) -> None:
        self.registry.remove(session.connection_id)
        session.close()

    def stop(self) -> None:
        self._stop.set()
        listener = self._listener
        if listener is not None:
            try:
                listener.close()
            except OSError:
                pass
        self.registry.close_all()
        thread = self._thread
        if thread and thread.is_alive() and thread is not threading.current_thread():
            thread.join(timeout=2.0)
