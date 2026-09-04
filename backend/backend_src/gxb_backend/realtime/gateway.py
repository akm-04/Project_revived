"""Dedicated-process RealtimeGateway composition for Pass344 I5.

The gateway owns sockets, transient registry, outbox consumption and liveness
checks. It never owns durable gameplay mutation authority.
"""
from __future__ import annotations

from dataclasses import dataclass
import threading
import time
from typing import Callable

from .durable import RealtimeOutboxDispatcher
from .liveness import RealtimeLivenessSweeper
from .server import RealtimeServer
from .wakeup import OutboxWakeupSource


@dataclass(frozen=True, slots=True)
class RealtimeGatewaySettings:
    poll_interval_seconds: float = 1.0
    liveness_interval_seconds: float = 10.0
    stale_claim_seconds: int = 30

    def __post_init__(self) -> None:
        if self.poll_interval_seconds <= 0:
            raise ValueError("poll_interval_seconds must be > 0")
        if self.liveness_interval_seconds <= 0:
            raise ValueError("liveness_interval_seconds must be > 0")
        if self.stale_claim_seconds <= 0:
            raise ValueError("stale_claim_seconds must be > 0")


class RealtimeGateway:
    """One physical gateway process adapter; no horizontal fanout assumption."""

    def __init__(
        self,
        server: RealtimeServer,
        dispatcher: RealtimeOutboxDispatcher,
        sweeper: RealtimeLivenessSweeper,
        *,
        wakeup: OutboxWakeupSource | None = None,
        settings: RealtimeGatewaySettings | None = None,
        paused: Callable[[], bool] | None = None,
    ) -> None:
        self.server = server
        self.dispatcher = dispatcher
        self.sweeper = sweeper
        self.wakeup = wakeup
        self.settings = settings or RealtimeGatewaySettings()
        self.paused = paused or (lambda: False)
        self._stop = threading.Event()
        self._dispatch_thread: threading.Thread | None = None
        self._sweep_thread: threading.Thread | None = None
        self._wakeup_open = False
        self._dispatch_ready = False

    def _activate_dispatch(self) -> None:
        if self.wakeup is not None and not self._wakeup_open:
            try: self.wakeup.open(); self._wakeup_open=True
            except Exception: self._wakeup_open=False
        self.dispatcher.recover_stale_claims(stale_after_seconds=self.settings.stale_claim_seconds)
        self.dispatcher.poll_once(); self._dispatch_ready=True

    def start(self) -> None:
        if self._dispatch_thread and self._dispatch_thread.is_alive():
            return
        self._stop.clear()
        self._wakeup_open = False
        self._dispatch_ready = False
        if not self.paused(): self._activate_dispatch()
        self.server.start()
        self._dispatch_thread = threading.Thread(target=self._dispatch_loop, name="gxb-realtime-outbox", daemon=True)
        self._sweep_thread = threading.Thread(target=self._sweep_loop, name="gxb-realtime-liveness", daemon=True)
        self._dispatch_thread.start()
        self._sweep_thread.start()

    def _dispatch_loop(self) -> None:
        wakeup_open = self._wakeup_open
        while not self._stop.is_set():
            if self.paused(): self._stop.wait(self.settings.poll_interval_seconds); continue
            if not self._dispatch_ready:
                try: self._activate_dispatch(); wakeup_open=self._wakeup_open
                except Exception: self._stop.wait(self.settings.poll_interval_seconds); continue
            if self.wakeup is not None and not wakeup_open:
                try:
                    self.wakeup.open()
                    wakeup_open = True
                except Exception:
                    wakeup_open = False
            try:
                if wakeup_open and self.wakeup is not None:
                    self.wakeup.wait(self.settings.poll_interval_seconds)
                else:
                    self._stop.wait(self.settings.poll_interval_seconds)
            except Exception:
                wakeup_open = False
                if self.wakeup is not None:
                    try:
                        self.wakeup.close()
                    except Exception:
                        pass
            if self._stop.is_set():
                break
            try:
                self.dispatcher.poll_once()
            except Exception:
                # Durable rows remain authoritative/recoverable. A process-level
                # supervisor may restart a persistently unhealthy gateway.
                pass
        if self.wakeup is not None:
            try:
                self.wakeup.close()
            except Exception:
                pass
        self._wakeup_open = False
        self._dispatch_ready = False

    def _sweep_loop(self) -> None:
        while not self._stop.wait(self.settings.liveness_interval_seconds):
            if self.paused(): continue
            try:
                self.sweeper.sweep_once()
            except Exception:
                # The sweeper itself contains fail-closed DB-outage grace logic;
                # unexpected implementation errors must not mutate durable state.
                pass

    def stop(self) -> None:
        self._stop.set()
        if self.wakeup is not None:
            try:
                self.wakeup.close()
            except Exception:
                pass
        self.server.stop()
        for thread in (self._dispatch_thread, self._sweep_thread):
            if thread and thread.is_alive() and thread is not threading.current_thread():
                thread.join(timeout=2.0)
