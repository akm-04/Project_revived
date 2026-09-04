from __future__ import annotations

from contextlib import contextmanager

import pytest

from gxb_backend.foundation.contracts import RequestRuntimeAdapter
from gxb_backend.foundation.legacy_adapter import LegacyRequestRuntimeAdapter


class RepositoryStub:
    def __init__(self) -> None:
        self.requests: list[dict[str, object] | None] = []

    @contextmanager
    def request_scope(self, request: dict[str, object] | None):
        self.requests.append(request)
        yield


def test_legacy_adapter_is_explicit_and_does_not_mutate_input() -> None:
    repository = RepositoryStub()
    adapter = LegacyRequestRuntimeAdapter(repository)
    request = {"mid": 55}
    assert isinstance(adapter, RequestRuntimeAdapter)
    assert adapter.mode == "legacy_json_global_rlock"
    with adapter.request_scope(request):
        request["mid"] = 99
    assert repository.requests == [{"mid": 55}]


def test_adapter_requires_existing_request_scope() -> None:
    with pytest.raises(TypeError):
        LegacyRequestRuntimeAdapter(object())

