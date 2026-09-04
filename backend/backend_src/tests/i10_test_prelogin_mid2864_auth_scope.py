from gxb_backend.auth.perimeter import AuthScope, AuthScopeRegistry


def test_stock_prelogin_abtest_lookup_is_public_before_mid1() -> None:
    """src_64 + Pass251/253 runtime: MID7 -> MID2864 -> MID1.

    MID2864 is SelfPlayer.getAbtestGroupByKey() and the local handler is a
    context-free deterministic compatibility response. It must not require a
    gameplay bearer that MID1 has not issued yet.
    """
    registry = AuthScopeRegistry()
    assert registry.resolve(7, known_engine_mid=True) is AuthScope.PUBLIC_BOOTSTRAP
    assert registry.resolve(2864, known_engine_mid=True) is AuthScope.PUBLIC_BOOTSTRAP
    assert registry.resolve(1, known_engine_mid=True) is AuthScope.CONTEXT_SELECTION
    assert registry.resolve(49, known_engine_mid=True) is AuthScope.SELECTED_PLAYER

from unittest.mock import Mock
from gxb_backend.runtime.state_repository import PostgresStateRepository
from gxb_backend.state.repository import _RequestBinding


def test_postgres_request_scope_does_not_require_gameplay_credential_for_mid2864() -> None:
    repo = object.__new__(PostgresStateRepository)
    repo._local = _RequestBinding()
    repo._account_auth = Mock()
    repo._context_auth = Mock()
    repo._coordinator = Mock()

    with repo.request_scope({"mid": 2864, "unique_key": "mtspy", "token": "", "region": 0}):
        assert repo.has_authenticated_session() is False

    repo._account_auth.resolve.assert_not_called()
    repo._context_auth.prepare_lease.assert_not_called()
