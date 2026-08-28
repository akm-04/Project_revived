"""Filtered console + automatic server.txt tee for operator smoke testing.

Structured runtime_logs/*.jsonl remain authoritative and are never filtered by
this module.  This layer only controls human-facing console text and the
runtime_logs/server.txt transcript, so lowering verbosity cannot destroy
forensic evidence.
"""
from __future__ import annotations

import re
import sys
import threading
from pathlib import Path
from typing import TextIO

CATEGORY_LEVEL = {
    "basic": 1,
    "error": 1,
    "missing": 1,
    "window": 2,
    "http_download": 3,
    "full": 4,
}

_runtime: "ConsoleRuntime | None" = None


def _http_status(line: str) -> int | None:
    m = re.search(r'"\s+(\d{3})(?:\s|$)', line)
    return int(m.group(1)) if m else None


def classify_legacy_line(line: str) -> str:
    """Best-effort category for legacy print()/Werkzeug lines.

    New observability code should prefer ``console_emit(category, message)`` so
    adding a future filter does not require extending this compatibility map.
    """
    text = line.strip()
    lower = text.lower()
    if not text:
        return "basic"
    if text.startswith("[RESOURCE CLIENT PROBE]"):
        return "window"
    if text.startswith("[RESOURCE] served "):
        return "http_download"
    # Werkzeug access lines are intentionally hidden at low levels.  Missing
    # resources remain visible regardless of verbosity.
    if " - - [" in text and 'http/' in lower:
        status = _http_status(text)
        if status is not None and status >= 400:
            return "error"
        if '"get /res/' in lower or '"get /updates/' in lower:
            return "http_download"
        return "full"
    error_markers = (
        "[client error]", "[engine block]", "[engine domain block]",
        "[undecoded]", "traceback (most recent call last)", "fatal ",
        "exception", "md5_mismatch", "catalog miss", "local_file_missing",
        "roots_unconfigured", "[resource][warn]", " failed", " failure",
    )
    if any(marker in lower for marker in error_markers):
        return "error"
    return "basic"


class ConsoleRuntime:
    def __init__(self, *, verbosity: int, log_path: Path, stdout: TextIO, stderr: TextIO) -> None:
        if verbosity not in (1, 2, 3, 4):
            raise ValueError("debug verbosity must be 1..4")
        self.verbosity = int(verbosity)
        self.log_path = Path(log_path)
        self.log_path.parent.mkdir(parents=True, exist_ok=True)
        self._stdout = stdout
        self._stderr = stderr
        self._log = self.log_path.open("w", encoding="utf-8", buffering=1)
        self._lock = threading.RLock()

    def enabled(self, category: str) -> bool:
        return self.verbosity >= CATEGORY_LEVEL.get(category, 4)

    def emit(self, category: str, text: str, *, stream: str = "stdout") -> None:
        if not self.enabled(category):
            return
        target = self._stderr if stream == "stderr" else self._stdout
        if not text.endswith("\n"):
            text += "\n"
        with self._lock:
            target.write(text)
            target.flush()
            self._log.write(text)
            self._log.flush()

    def legacy(self, text: str, *, stream: str = "stdout") -> None:
        category = classify_legacy_line(text)
        self.emit(category, text.rstrip("\n"), stream=stream)

    def close(self) -> None:
        with self._lock:
            try:
                self._log.flush()
                self._log.close()
            except Exception:
                pass


class _ConsoleStream:
    def __init__(self, runtime: ConsoleRuntime, stream_name: str, original: TextIO) -> None:
        self.runtime = runtime
        self.stream_name = stream_name
        self.original = original
        self._buffer = ""
        self._lock = threading.RLock()

    def write(self, data: str) -> int:
        if not data:
            return 0
        with self._lock:
            self._buffer += str(data)
            while "\n" in self._buffer:
                line, self._buffer = self._buffer.split("\n", 1)
                self.runtime.legacy(line, stream=self.stream_name)
        return len(data)

    def flush(self) -> None:
        with self._lock:
            if self._buffer:
                self.runtime.legacy(self._buffer, stream=self.stream_name)
                self._buffer = ""
        try:
            self.original.flush()
        except Exception:
            pass

    def isatty(self):
        return getattr(self.original, "isatty", lambda: False)()

    def fileno(self):
        return self.original.fileno()

    @property
    def encoding(self):
        return getattr(self.original, "encoding", "utf-8")

    def __getattr__(self, name):
        return getattr(self.original, name)


def configure_console(*, runtime_log_dir: Path, verbosity: int) -> ConsoleRuntime:
    global _runtime
    if _runtime is not None:
        return _runtime
    runtime = ConsoleRuntime(
        verbosity=verbosity,
        log_path=Path(runtime_log_dir) / "server.txt",
        stdout=sys.stdout,
        stderr=sys.stderr,
    )
    _runtime = runtime
    sys.stdout = _ConsoleStream(runtime, "stdout", runtime._stdout)  # type: ignore[assignment]
    sys.stderr = _ConsoleStream(runtime, "stderr", runtime._stderr)  # type: ignore[assignment]
    runtime.emit("basic", f"[CONSOLE] DEBUG_VERBOSE={verbosity} auto_log={runtime.log_path}")
    return runtime


def console_emit(category: str, message: str, *, stream: str = "stdout") -> None:
    runtime = _runtime
    if runtime is None:
        target = sys.stderr if stream == "stderr" else sys.stdout
        print(message, file=target)
        return
    runtime.emit(category, message, stream=stream)


def debug_verbosity() -> int:
    return _runtime.verbosity if _runtime is not None else 4
