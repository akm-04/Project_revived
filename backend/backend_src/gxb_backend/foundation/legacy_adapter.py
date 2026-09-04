"""Explicit adapter around the unchanged Pass299 request-scope runtime."""

from __future__ import annotations

from contextlib import AbstractContextManager
from typing import Any, Mapping


class LegacyRequestRuntimeAdapter:
    """Delegate to StateRepository without altering its global-lock semantics.

    This adapter makes the strangler boundary visible for later waves.  Pass339
    does not install it into EngineDispatcher and does not narrow the RLock.
    """

    mode = "legacy_json_global_rlock"

    def __init__(self, repository: Any) -> None:
        if not callable(getattr(repository, "request_scope", None)):
            raise TypeError("repository must provide request_scope()")
        self._repository = repository

    def request_scope(
        self,
        request: Mapping[str, Any] | None,
    ) -> AbstractContextManager[None]:
        payload = dict(request) if request is not None else None
        return self._repository.request_scope(payload)
