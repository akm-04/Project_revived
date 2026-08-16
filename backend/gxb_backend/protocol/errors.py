"""Backend-local exception types."""

from __future__ import annotations


class BackendProtocolError(Exception):
    """Raised when a request cannot be represented safely."""

    def __init__(self, message: str, *, mid: int | None = None) -> None:
        super().__init__(message)
        self.mid = mid
