"""Tiny TCP chat stub.

This accepts socket connections advertised by LOAD_CHAT_ROOM_INFO so the client
is not handed a dead host/port during MessageManager startup. It deliberately
implements no real chat-room semantics yet.
"""

from __future__ import annotations

import socket
import threading
import time


class ChatStubServer:
    def __init__(self, host: str, port: int) -> None:
        # Bind to all interfaces when config uses a device-facing host that may
        # not be assigned locally. The advertised host remains configurable via
        # LOAD_CHAT_ROOM_INFO.
        self.host = host
        self.port = int(port)
        self._thread: threading.Thread | None = None
        self._stop = threading.Event()

    def start(self) -> None:
        if self._thread and self._thread.is_alive():
            return
        self._thread = threading.Thread(target=self._serve, name="gxb-chat-stub", daemon=True)
        self._thread.start()

    def _serve(self) -> None:
        bind_host = "0.0.0.0"
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as srv:
                srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
                srv.bind((bind_host, self.port))
                srv.listen(16)
                srv.settimeout(1.0)
                print(f"[CHAT] stub listening on {bind_host}:{self.port}; advertised host={self.host}")
                while not self._stop.is_set():
                    try:
                        conn, addr = srv.accept()
                    except socket.timeout:
                        continue
                    threading.Thread(target=self._handle_client, args=(conn, addr), daemon=True).start()
        except Exception as exc:
            print(f"[CHAT] stub failed to bind/listen on {bind_host}:{self.port}: {exc}")

    def _handle_client(self, conn: socket.socket, addr) -> None:
        print(f"[CHAT] client connected: {addr}")
        with conn:
            conn.settimeout(1.0)
            last_heartbeat = time.time()
            while not self._stop.is_set():
                try:
                    data = conn.recv(4096)
                    if not data:
                        break
                    print(f"[CHAT] recv {len(data)} bytes from {addr}")
                    # Do not echo arbitrary payload; unknown chat framing could
                    # be binary/protobuf-like. Keeping the socket alive is safer.
                    last_heartbeat = time.time()
                except socket.timeout:
                    if time.time() - last_heartbeat > 60:
                        last_heartbeat = time.time()
                    continue
                except Exception:
                    break
        print(f"[CHAT] client disconnected: {addr}")

    def stop(self) -> None:
        self._stop.set()
