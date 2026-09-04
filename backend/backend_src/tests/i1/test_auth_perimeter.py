from __future__ import annotations

from unittest.mock import Mock
from pathlib import Path

from gxb_backend.auth.perimeter import AuthScope, AuthScopeRegistry, LegacyAuthPerimeter
from gxb_backend.state.multiuser_database import SANDBOX_SID, SANDBOX_TOKEN
from gxb_backend.state.repository import StateRepository


def test_scope_registry_is_explicit_and_default_deny() -> None:
    registry = AuthScopeRegistry()
    assert registry.resolve(2, known_engine_mid=True) is AuthScope.PUBLIC_BOOTSTRAP
    assert registry.resolve(7, known_engine_mid=True) is AuthScope.PUBLIC_BOOTSTRAP
    assert registry.resolve(2_864, known_engine_mid=True) is AuthScope.PUBLIC_BOOTSTRAP
    assert registry.resolve(20_480, known_engine_mid=True) is AuthScope.PUBLIC_BOOTSTRAP
    assert registry.resolve(18, known_engine_mid=True) is AuthScope.ACCOUNT_SESSION
    assert registry.resolve(1, known_engine_mid=True) is AuthScope.CONTEXT_SELECTION
    assert registry.resolve(49, known_engine_mid=True) is AuthScope.SELECTED_PLAYER
    assert registry.resolve(12_345, known_engine_mid=False) is None


def test_public_scope_does_not_touch_bound_identity() -> None:
    state = Mock()
    decision = LegacyAuthPerimeter().authorize(AuthScope.PUBLIC_BOOTSTRAP, state)
    assert decision.allowed
    state.has_authenticated_session.assert_not_called()
    state.current_player_or_none.assert_not_called()


def test_account_and_context_scopes_require_account_session() -> None:
    state = Mock()
    state.has_authenticated_session.return_value = False
    perimeter = LegacyAuthPerimeter()
    for scope in (AuthScope.ACCOUNT_SESSION, AuthScope.CONTEXT_SELECTION):
        decision = perimeter.authorize(scope, state)
        assert not decision.allowed
        assert decision.status_code == 401
        assert decision.error_class == "auth"
        assert decision.error_kind == "CREDENTIAL_INVALID"


def test_selected_player_requires_session_and_bound_player() -> None:
    perimeter = LegacyAuthPerimeter()
    state = Mock()
    state.has_authenticated_session.return_value = False
    decision = perimeter.authorize(AuthScope.SELECTED_PLAYER, state)
    assert decision.status_code == 401
    assert decision.error_kind == "CREDENTIAL_INVALID"
    state.current_player_or_none.assert_not_called()

    state.reset_mock()
    state.has_authenticated_session.return_value = True
    state.current_player_or_none.return_value = None
    decision = perimeter.authorize(AuthScope.SELECTED_PLAYER, state)
    assert decision.status_code == 409
    assert decision.error_class == "auth"
    assert decision.error_kind == "CONTEXT_STALE"

    state.current_player_or_none.return_value = object()
    assert perimeter.authorize(AuthScope.SELECTED_PLAYER, state).allowed


def test_unclassified_and_wrong_ingress_fail_closed() -> None:
    state = Mock()
    perimeter = LegacyAuthPerimeter()
    unclassified = perimeter.authorize(None, state)
    assert unclassified.status_code == 403
    assert unclassified.error_class == "authorization"
    assert unclassified.error_kind == "AUTH_SCOPE_UNCLASSIFIED"

    for scope in (AuthScope.REALTIME_ADMISSION, AuthScope.ADMIN_OPERATOR):
        decision = perimeter.authorize(scope, state)
        assert decision.status_code == 403
        assert decision.error_kind == "AUTH_SCOPE_WRONG_INGRESS"


def _bare_repository() -> tuple[StateRepository, Mock]:
    repo = object.__new__(StateRepository)
    store = Mock()
    repo.store = store
    return repo, store


def test_account_scope_uses_only_sid_and_login_token() -> None:
    repo, store = _bare_repository()
    session = {"sid": "sid-A", "token": "login-A", "uid": "u"}
    store.resolve_session.return_value = session

    observed = repo._resolve_engine_session(
        {"mid": 1, "sid": "sid-A", "login_token": "login-A", "token": "generic-gameplay"}
    )
    assert observed is session
    store.resolve_session.assert_called_once_with(sid="sid-A", token="login-A")


def test_account_scope_keeps_sid_only_manual_login_compatibility() -> None:
    repo, store = _bare_repository()
    store.resolve_session.return_value = {"sid": "manual", "uid": "u"}
    repo._resolve_engine_session({"mid": 18, "sid": "manual", "token": "ignored"})
    store.resolve_session.assert_called_once_with(sid="manual", token=None)


def test_selected_player_scope_does_not_accept_sid_or_login_token() -> None:
    repo, store = _bare_repository()
    store.resolve_session.return_value = None
    repo._resolve_engine_session(
        {"mid": 49, "sid": "sid-A", "login_token": "login-A", "token": "gameplay-A"}
    )
    store.resolve_session.assert_called_once_with(sid=None, token="gameplay-A")
    store.ensure_sandbox_session.assert_not_called()


def test_public_scope_does_not_resolve_opportunistic_actor_credentials() -> None:
    for mid in (2, 7, 2_864, 20_480):
        repo, store = _bare_repository()
        assert repo._resolve_engine_session({"mid": mid, "token": "anything", "sid": "anything"}) is None
        store.resolve_session.assert_not_called()
        store.ensure_sandbox_session.assert_not_called()


def test_only_exact_sandbox_compatibility_credentials_can_materialize_sandbox() -> None:
    repo, store = _bare_repository()
    store.resolve_session.return_value = None
    store.ensure_sandbox_session.return_value = {"sid": SANDBOX_SID, "token": SANDBOX_TOKEN}

    assert repo._resolve_engine_session({"mid": 18, "sid": SANDBOX_SID}) == store.ensure_sandbox_session.return_value
    store.ensure_sandbox_session.assert_called_once()

    repo, store = _bare_repository()
    store.resolve_session.return_value = None
    repo._resolve_engine_session({"mid": 49, "token": "invalid"})
    store.ensure_sandbox_session.assert_not_called()


def test_dispatcher_source_enforces_auth_before_mutation_fallback_and_handlers() -> None:
    source = (Path(__file__).resolve().parents[2] / "gxb_backend/dispatch/engine_dispatcher.py").read_text(encoding="utf-8")
    scoped = source[source.index("    def _dispatch_scoped"): ]
    auth = scoped.index("auth_perimeter.authorize")
    mutation = scoped.index("mutation_firewall.evaluate")
    fallback = scoped.index("self.compat.is_safe_fallback_mid(req_mid)", auth)
    handler = scoped.index("handler = self.handlers.get(req_mid)")
    assert auth < mutation < handler
    assert auth < fallback
    assert 'handler="auth_perimeter"' in scoped[auth:mutation]


def test_legacy_session_context_binding_is_persisted_without_new_credential(tmp_path) -> None:
    from gxb_backend.state.multiuser_database import MultiUserDatabase

    store = MultiUserDatabase(tmp_path / "server_state", tmp_path)
    session = store.ensure_sandbox_session()
    original_token = str(session["token"])
    store.bind_session_context(session, player_id="13371337", region=197)
    observed = store.resolve_session(token=original_token, touch=False)
    assert observed is not None
    assert observed["token"] == original_token
    assert observed["selected_player_id"] == "13371337"
    assert observed["selected_region"] == 197


def test_selected_player_binding_uses_session_context_not_caller_region() -> None:
    import threading
    from types import SimpleNamespace

    repo, store = _bare_repository()
    repo._local = threading.local()
    session = {
        "sid": "sid-A",
        "token": "game-A",
        "uid": "u1",
        "selected_player_id": "p-7",
        "selected_region": 197,
    }
    store.resolve_session.return_value = session
    store.identity_from_session.return_value = SimpleNamespace(uid="u1")
    player = SimpleNamespace(player_id="p-7", region=197, account_uid="u1")
    repo._load_player_canonical = Mock(return_value=player)

    repo._bind_engine_request({"mid": 49, "token": "game-A", "region": 125})
    assert repo.current_player_or_none() is None
    repo._load_player_canonical.assert_not_called()
    store.player_id_for_account_region.assert_not_called()

    repo._bind_engine_request({"mid": 49, "token": "game-A", "region": 197})
    assert repo.current_player_or_none() is player
    repo._load_player_canonical.assert_called_once_with("p-7")
    store.player_id_for_account_region.assert_not_called()


def test_mid1_records_legacy_selected_context_binding() -> None:
    import threading
    from types import SimpleNamespace

    repo, store = _bare_repository()
    repo._local = threading.local()
    session = {"sid": "sid-A", "token": "login-A", "uid": "u1"}
    repo._local.session = session
    repo._local.account = SimpleNamespace(uid="u1")
    repo._local.player = None
    repo._local.services = None
    repo._local.is_new_player = False
    store.player_id_for_account_region.return_value = "p-7"
    player = SimpleNamespace(player_id="p-7", region=197, account_uid="u1")
    repo._load_player_canonical = Mock(return_value=player)

    observed, is_new = repo.resolve_or_create_player(197, "Local-197")
    assert observed is player
    assert is_new is False
    store.bind_session_context.assert_called_once_with(
        session, player_id="p-7", region=197
    )


def test_realtime_region_is_consistency_fence_not_actor_selector() -> None:
    import threading
    from types import SimpleNamespace

    repo, store = _bare_repository()
    repo._lock = threading.RLock()
    session = {
        "sid": "sid-A",
        "token": "game-A",
        "uid": "u1",
        "selected_player_id": "p-7",
        "selected_region": 197,
    }
    store.resolve_session.return_value = session
    player = SimpleNamespace(player_id="p-7", region=197, account_uid="u1", guild_id=0)
    repo._load_player_canonical = Mock(return_value=player)

    assert repo.resolve_realtime_identity("game-A", 125) is None
    repo._load_player_canonical.assert_not_called()
    store.player_id_for_account_region.assert_not_called()

    identity = repo.resolve_realtime_identity("game-A", 197)
    assert identity is not None
    assert identity.player_id == "p-7"
    assert identity.region == 197
    store.player_id_for_account_region.assert_not_called()


def test_nonnumeric_mid_is_default_denied_before_dispatch() -> None:
    source = (Path(__file__).resolve().parents[2] / "gxb_backend/dispatch/engine_dispatcher.py").read_text(encoding="utf-8")
    scoped = source[source.index("    def _dispatch_scoped"):]
    numeric_try = scoped.index('req_mid = int(req.get("mid", 0))')
    default_deny = scoped.index("self.auth_perimeter.authorize(None, self.state)", numeric_try)
    route_class = scoped.index("route_class = classify_mid(req_mid)", default_deny)
    assert numeric_try < default_deny < route_class


def test_restart_requires_fresh_mid1_before_gameplay_and_then_restores_selected_actor(tmp_path) -> None:
    data_dir = Path(__file__).resolve().parents[2] / "data"
    root = tmp_path / "server_state"

    repo1 = StateRepository(data_dir / "player_db.json", multiuser_root=root)
    _, status = repo1.sdk_register("pass340-restart", "pass340-pass")
    assert status == "created"
    account1 = repo1.sdk_login("pass340-restart", "pass340-pass")
    assert account1 is not None
    with repo1.request_scope({"mid": 1, "sid": account1.sid, "region": 194}):
        player1, _ = repo1.resolve_or_create_player(194, "Local-194")
        player_id = str(player1.player_id)
    with repo1.request_scope({"mid": 17, "token": account1.token, "region": 194}):
        assert str(repo1.current_player_or_none().player_id) == player_id

    # A new SDK login is account-session authority only. It may not immediately
    # reuse request.region to choose a gameplay actor after process restart.
    repo2 = StateRepository(data_dir / "player_db.json", multiuser_root=root)
    account2 = repo2.sdk_login("pass340-restart", "pass340-pass")
    assert account2 is not None
    with repo2.request_scope({"mid": 17, "token": account2.token, "region": 194}):
        assert repo2.current_player_or_none() is None

    # Stock flow performs MID18/MID1. MID1 re-establishes the temporary I1
    # selected-context binding for this fresh account session.
    with repo2.request_scope({"mid": 1, "sid": account2.sid, "region": 194}):
        player2, is_new = repo2.resolve_or_create_player(194, "Local-194")
        assert not is_new
        assert str(player2.player_id) == player_id
    with repo2.request_scope({"mid": 17, "token": account2.token, "region": 194}):
        assert str(repo2.current_player_or_none().player_id) == player_id
    with repo2.request_scope({"mid": 17, "token": account2.token, "region": 195}):
        assert repo2.current_player_or_none() is None


def test_engine_http_ingress_fails_closed_when_payload_is_undecodable(tmp_path) -> None:
    from flask import Flask
    from gxb_backend.transport.routes_engine import _handle_engine_request

    app = Flask(__name__)
    dispatcher = Mock()
    capture = Mock()
    with app.test_request_context('/api/v1', method='POST', data=b'not-a-decodable-engine-payload'):
        response = _handle_engine_request(dispatcher, 'API', capture)
    assert response.status_code == 400
    body = response.get_json()
    assert body['error_class'] == 'protocol'
    assert body['error_kind'] == 'MALFORMED_ENGINE_REQUEST'
    dispatcher.dispatch.assert_not_called()
    capture.capture.assert_called_once()


def test_unmatched_empty_http_ingress_is_not_generic_success() -> None:
    source = (Path(__file__).resolve().parents[2] / 'gxb_backend/transport/routes_engine.py').read_text(encoding='utf-8')
    catch_all = source[source.index('    def catch_all(path="")'):]
    assert '"error_kind": "ROUTE_NOT_FOUND"' in catch_all
    assert 'status_code=404' in catch_all
    assert 'return json_response(engine_ok())' not in catch_all
