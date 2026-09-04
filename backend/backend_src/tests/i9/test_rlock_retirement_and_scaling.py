from pathlib import Path
from contextlib import contextmanager

import pytest

from gxb_backend.dispatch.engine_dispatcher import EngineDispatcher
from gxb_backend.identity.errors import ContextStale
from gxb_backend.runtime.config import ProductionRuntimeSettings, RuntimeConfigurationError
from gxb_backend.transactions.errors import StateVersionConflict, TransactionRetryExhausted
from gxb_backend.transport.result import EngineTransportResult


ROOT = Path(__file__).resolve().parents[2]
BASE_ENV = {"GXB_DATABASE_URL": "postgresql+psycopg://u:p@localhost/gxb"}


def test_postgresql_runtime_retires_only_the_global_request_lock():
    relational = (ROOT / "gxb_backend/runtime/state_repository.py").read_text()
    legacy = (ROOT / "gxb_backend/state/repository.py").read_text()
    assert "with self._lock" not in relational
    assert "del self._lock" in relational
    assert "threading.RLock()" in legacy and "with self._lock" in legacy
    assert "TransactionBoundPostgresPlayerStateStore" in relational
    assert "def _cache_player" in relational and "return player" in relational


@pytest.mark.parametrize("workers", (1, 2, 4))
def test_runtime_accepts_only_proven_gradual_worker_stages(workers):
    settings = ProductionRuntimeSettings.from_env({**BASE_ENV, "GXB_HTTP_WORKERS": str(workers)})
    assert settings.http_workers == workers


@pytest.mark.parametrize("workers", (-1, 0, 3, 5, 100))
def test_runtime_rejects_unproven_worker_stages(workers):
    with pytest.raises(RuntimeConfigurationError):
        ProductionRuntimeSettings.from_env({**BASE_ENV, "GXB_HTTP_WORKERS": str(workers)})


def test_packaged_scaling_is_explicit_and_rollback_to_one_remains_available():
    gunicorn = (ROOT / "deploy/gunicorn.conf.py").read_text()
    wrapper = (ROOT / "bin/gxb-stack").read_text()
    preflight = (ROOT / "tools/pass348_i9_scale_preflight.py").read_text()
    assert "workers not in (1, 2, 4)" in gunicorn
    assert "scale-preflight" in wrapper
    assert "require_postgresql" in preflight
    assert "maintenance_active" in preflight
    assert "GXB_HTTP_WORKERS=1" in preflight


def _dispatcher_with_failure(error):
    class State:
        @contextmanager
        def request_scope(self, req):
            del req
            raise error
            yield

    dispatcher = object.__new__(EngineDispatcher)
    dispatcher.state = State()
    dispatcher._post_commit_sink = None
    return dispatcher


@pytest.mark.parametrize(
    ("error", "status", "kind"),
    (
        (ContextStale("superseded"), 409, "CONTEXT_STALE"),
        (StateVersionConflict("player:1", 7), 409, "STATE_VERSION_CONFLICT"),
        (
            TransactionRetryExhausted(3, RuntimeError("deadlock")),
            503,
            "TRANSACTION_RETRY_EXHAUSTED",
        ),
    ),
)
def test_dispatcher_maps_expected_concurrency_failures_to_explicit_transport(error, status, kind):
    result = _dispatcher_with_failure(error).dispatch({"mid": 17})
    assert isinstance(result, EngineTransportResult)
    assert result.status_code == status
    assert result.body["error_code"] == 1
    assert result.body["error_kind"] == kind
