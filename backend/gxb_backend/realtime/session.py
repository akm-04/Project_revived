"""Transient authenticated realtime session registry and outbound serialization."""

from __future__ import annotations

from dataclasses import dataclass, field
import queue
import socket
import threading
import time
from typing import Callable

from .contracts import AuthenticatedPlayerIdentity, RealtimeRole


MAX_OUTBOUND_FRAMES = 256
MAX_OUTBOUND_BYTES = 4 * 1024 * 1024


@dataclass(slots=True)
class RealtimeSession:
    connection_id: str
    identity: AuthenticatedPlayerIdentity
    role: RealtimeRole
    room_id: int
    sock: socket.socket
    connected_at: float
    last_received_at: float
    _on_writer_failure: Callable[["RealtimeSession"], None] | None = None
    _queue: queue.Queue[bytes | None] = field(default_factory=lambda: queue.Queue(maxsize=MAX_OUTBOUND_FRAMES))
    _queue_bytes: int = 0
    _queue_lock: threading.RLock = field(default_factory=threading.RLock)
    _closed: threading.Event = field(default_factory=threading.Event)
    _writer_thread: threading.Thread | None = None

    @property
    def uid(self) -> str:
        return self.identity.uid

    @property
    def sid(self) -> str:
        return self.identity.sid

    @property
    def player_id(self) -> str:
        return self.identity.player_id

    def mark_received(self, now: float | None = None) -> None:
        self.last_received_at = float(time.monotonic() if now is None else now)

    def start_writer(self) -> None:
        if self._writer_thread and self._writer_thread.is_alive():
            return
        self._writer_thread = threading.Thread(
            target=self._writer_loop,
            name=f"gxb-realtime-writer-{self.connection_id[:8]}",
            daemon=True,
        )
        self._writer_thread.start()

    def enqueue(self, frame: bytes) -> bool:
        payload = bytes(frame)
        if self._closed.is_set():
            return False
        with self._queue_lock:
            if self._queue_bytes + len(payload) > MAX_OUTBOUND_BYTES:
                return False
            try:
                self._queue.put_nowait(payload)
            except queue.Full:
                return False
            self._queue_bytes += len(payload)
            return True

    def _writer_loop(self) -> None:
        failed = False
        while not self._closed.is_set():
            try:
                item = self._queue.get(timeout=0.5)
            except queue.Empty:
                continue
            if item is None:
                break
            try:
                self.sock.sendall(item)
            except OSError:
                failed = True
                break
            finally:
                with self._queue_lock:
                    self._queue_bytes = max(0, self._queue_bytes - len(item))
        if failed and self._on_writer_failure is not None:
            try:
                self._on_writer_failure(self)
            except Exception:
                pass

    def close(self) -> None:
        if self._closed.is_set():
            return
        self._closed.set()
        try:
            self._queue.put_nowait(None)
        except queue.Full:
            pass
        try:
            self.sock.shutdown(socket.SHUT_RDWR)
        except OSError:
            pass
        try:
            self.sock.close()
        except OSError:
            pass


class AuthenticatedRealtimeSessionRegistry:
    """Process-transient indexes only; never stores canonical gameplay state."""

    def __init__(self) -> None:
        self._lock = threading.RLock()
        self._by_connection: dict[str, RealtimeSession] = {}
        self._by_player: dict[str, set[str]] = {}
        self._by_uid: dict[str, set[str]] = {}
        self._by_room: dict[tuple[RealtimeRole, int], set[str]] = {}

    def register(self, session: RealtimeSession) -> None:
        with self._lock:
            if session.connection_id in self._by_connection:
                raise ValueError(f"duplicate realtime connection {session.connection_id}")
            self._by_connection[session.connection_id] = session
            self._by_player.setdefault(session.player_id, set()).add(session.connection_id)
            self._by_uid.setdefault(session.uid, set()).add(session.connection_id)
            self._by_room.setdefault((session.role, session.room_id), set()).add(session.connection_id)

    def remove(self, connection_id: str) -> RealtimeSession | None:
        with self._lock:
            session = self._by_connection.pop(str(connection_id), None)
            if session is None:
                return None
            self._discard(self._by_player, session.player_id, session.connection_id)
            self._discard(self._by_uid, session.uid, session.connection_id)
            self._discard(self._by_room, (session.role, session.room_id), session.connection_id)
            return session

    @staticmethod
    def _discard(index: dict, key, connection_id: str) -> None:
        values = index.get(key)
        if values is None:
            return
        values.discard(connection_id)
        if not values:
            index.pop(key, None)

    def get(self, connection_id: str) -> RealtimeSession | None:
        with self._lock:
            return self._by_connection.get(str(connection_id))

    def connections_for_player(self, player_id: str) -> tuple[str, ...]:
        with self._lock:
            return tuple(sorted(self._by_player.get(str(player_id), ())))

    def connections_for_room(self, role: RealtimeRole, room_id: int) -> tuple[str, ...]:
        with self._lock:
            return tuple(sorted(self._by_room.get((role, int(room_id)), ())))

    def snapshot(self) -> tuple[RealtimeSession, ...]:
        with self._lock:
            return tuple(self._by_connection.values())

    def __len__(self) -> int:
        with self._lock:
            return len(self._by_connection)

    def close_all(self) -> None:
        for session in self.snapshot():
            session.close()
            self.remove(session.connection_id)
