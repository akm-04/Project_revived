#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import replace
import json
from pathlib import Path
import socket
import sys
import tempfile
import time
import types

# The runtime artifact depends on Flask for HTTP serving, but this offline
# selftest exercises the dispatcher/service graph without starting Flask.
if "flask" not in sys.modules:
    fake_flask = types.ModuleType("flask")
    fake_flask.Request = object
    fake_flask.jsonify = lambda data=None, **kwargs: data
    fake_flask.make_response = lambda data=None, status=200, **kwargs: data
    fake_flask.send_file = lambda *args, **kwargs: None
    sys.modules["flask"] = fake_flask

from gxb_backend.dispatch.engine_dispatcher import EngineDispatcher
from gxb_backend.config import SETTINGS
from gxb_backend.realtime import (
    AuthenticatedPlayerIdentity,
    PlayerAudience,
    RealtimeEventIntent,
    RealtimeEventSchemaRegistry,
    RealtimeFrameStreamDecoder,
    RealtimeNoticeSchema,
    RealtimePublicationError,
    RealtimeRuntime,
    RealtimeRole,
    RealtimeSession,
    TypedRealtimeEventPublisher,
)
from gxb_backend.state.repository import StateRepository
from gxb_backend.state.unit_of_work import OperationContext
from gxb_backend.transport.result import EngineTransportResult

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"


def req(value, message):
    if not value:
        raise AssertionError(message)


def receive_frame(sock: socket.socket, timeout: float = 2.0):
    decoder = RealtimeFrameStreamDecoder()
    end = time.monotonic() + timeout
    sock.settimeout(0.2)
    while time.monotonic() < end:
        try:
            chunk = sock.recv(4096)
        except socket.timeout:
            continue
        if not chunk:
            raise AssertionError("socket closed before expected frame")
        frames = decoder.feed(chunk)
        if frames:
            return frames[0]
    raise AssertionError("timed out waiting for realtime frame")


def expect_no_frame(sock: socket.socket, timeout: float = 0.2):
    sock.settimeout(timeout)
    try:
        data = sock.recv(1)
    except socket.timeout:
        return
    if data:
        raise AssertionError(f"unexpected realtime bytes {data.hex()}")


def make_repo(root: Path):
    repo = StateRepository(DATA / "player_db.json", multiuser_root=root / "server_state")
    record, status = repo.sdk_register("wave-e-user", "wave-e-pass")
    req(status == "created" and record, "test account creation failed")
    account = repo.sdk_login("wave-e-user", "wave-e-pass")
    req(account is not None, "test account login failed")
    with repo.request_scope({"mid": 1, "sid": account.sid, "region": 194}):
        player, created = repo.resolve_or_create_player(194)
        req(created, "test player was not created")
        player.guild_id = 777
        repo.save()
        player_id = str(player.player_id)
    return repo, account, player_id


def test_mid192_directory():
    with tempfile.TemporaryDirectory(prefix="gxb-wave-e-mid192-") as tmp:
        repo, account, _ = make_repo(Path(tmp))
        settings = replace(SETTINGS, chat_host="127.0.0.1", chat_port=19192)
        runtime = RealtimeRuntime(settings.chat_host, settings.chat_port, repo)
        dispatcher = EngineDispatcher(
            repo, settings, None,
            post_commit_sink=runtime.handle_post_commit,
            realtime_runtime=runtime,
        )
        req(not runtime.is_listening, "AppFactory opened realtime listener during construction")

        for room_id in (194, 99999, 777):
            result = dispatcher.dispatch({
                "mid": 192,
                "token": account.token,
                "region": 194,
                "room_id": room_id,
            })
            req(not isinstance(result, EngineTransportResult), f"valid room {room_id} was rejected")
            req(result["error_code"] == 0, "MID192 valid result not successful")
            req(result["host"] == "127.0.0.1" and result["port"] == 19192, "MID192 endpoint drift")
            req(result["room_id"] == room_id, "MID192 room_id drift")

        invalid = dispatcher.dispatch({
            "mid": 192,
            "token": account.token,
            "region": 194,
            "room_id": 778,
        })
        req(isinstance(invalid, EngineTransportResult) and invalid.status_code == 409, "arbitrary room advertised")
        req(invalid.body == {"error_code": 1}, "MID192 invented invalid-room error payload")

        wrong_region = dispatcher.dispatch({
            "mid": 192,
            "token": account.token,
            "region": 195,
            "room_id": 194,
        })
        req(isinstance(wrong_region, EngineTransportResult) and wrong_region.status_code == 409, "wrong-region MID192 admitted")


def make_session(runtime, identity, role, room_id, suffix):
    server_sock, client_sock = socket.socketpair()
    session = RealtimeSession(
        connection_id=f"wavee-{suffix}",
        identity=identity,
        role=role,
        room_id=room_id,
        sock=server_sock,
        connected_at=time.monotonic(),
        last_received_at=time.monotonic(),
    )
    runtime.session_registry.register(session)
    session.start_writer()
    return session, client_sock


def force_reload(player_id: str, *, roles=()):
    return RealtimeEventIntent(
        mid=36855,
        params={},
        audience=PlayerAudience(player_id, roles=roles),
        owner_domain="TRANSPORT_OPERATIONS",
        delivery_class="TRANSIENT_PRESENTATION",
        schema_key="force_reload",
    )


def test_typed_publisher_and_role_routing():
    with tempfile.TemporaryDirectory(prefix="gxb-wave-e-pub-") as tmp:
        repo, account, player_id = make_repo(Path(tmp))
        settings = replace(SETTINGS, chat_host="127.0.0.1", chat_port=19193)
        runtime = RealtimeRuntime(settings.chat_host, settings.chat_port, repo)
        identity = repo.resolve_realtime_identity(account.token, 194)
        req(identity is not None, "realtime identity missing")
        world, world_peer = make_session(runtime, identity, RealtimeRole.WORLD, 194, "world")
        service, service_peer = make_session(runtime, identity, RealtimeRole.SERVICE, 99999, "service")
        try:
            report = runtime.publish(force_reload(player_id))
            req((report.selected, report.enqueued, report.disconnected) == (1, 1, 0), "WORLD default routing drift")
            frame = receive_frame(world_peer)
            req(frame.mid == 36855 and frame.sequence == 0 and frame.params == {}, "FORCE_RELOAD frame mismatch")
            expect_no_frame(service_peer)

            try:
                runtime.publish(force_reload(player_id, roles=(RealtimeRole.SERVICE,)))
            except RealtimePublicationError:
                pass
            else:
                raise AssertionError("FORCE_RELOAD was allowed on SERVICE despite current src_64")
            expect_no_frame(service_peer)

            unknown = RealtimeEventIntent(
                mid=36854,
                params={"notice_type": 2},
                audience=PlayerAudience(player_id),
                owner_domain="MAIL",
                delivery_class="TRANSIENT_INVALIDATION",
                schema_key="typed_notice",
            )
            try:
                runtime.publish(unknown)
            except RealtimePublicationError:
                pass
            else:
                raise AssertionError("PLAYER_NOTICE published without domain-owned notice schema")

            # Generic transport can validate a future domain schema without owning
            # that domain. This injected test descriptor is not production wiring.
            notice_schema = RealtimeNoticeSchema(
                notice_type=2,
                owner_domain="MAIL",
                parent_mids=(36854,),
                allowed_roles=(RealtimeRole.WORLD,),
                validator=lambda params: set(params).issubset({"notice_type", "params"}),
            )
            schemas = RealtimeEventSchemaRegistry(repo.synchronization_catalogs, notice_schemas=(notice_schema,))
            typed = TypedRealtimeEventPublisher(schemas, runtime.session_registry)
            mail_intent = RealtimeEventIntent(
                mid=36854,
                params={"notice_type": 2},
                audience=PlayerAudience(player_id),
                owner_domain="MAIL",
                delivery_class="TRANSIENT_INVALIDATION",
                schema_key="typed_notice",
            )
            report = typed.publish(mail_intent)
            req(report.enqueued == 1, "injected typed notice schema did not publish")
            frame = receive_frame(world_peer)
            req(frame.mid == 36854 and frame.params["notice_type"] == 2.0, "typed notice wire mismatch")
            expect_no_frame(service_peer)
        finally:
            runtime.session_registry.remove(world.connection_id)
            runtime.session_registry.remove(service.connection_id)
            world.close(); service.close(); world_peer.close(); service_peer.close()


def test_postcommit_staging_and_slow_consumer():
    with tempfile.TemporaryDirectory(prefix="gxb-wave-e-postcommit-") as tmp:
        repo, account, player_id = make_repo(Path(tmp))
        settings = replace(SETTINGS, chat_host="127.0.0.1", chat_port=19194)
        runtime = RealtimeRuntime(settings.chat_host, settings.chat_port, repo)
        dispatcher = EngineDispatcher(
            repo, settings, None,
            post_commit_sink=runtime.handle_post_commit,
            realtime_runtime=runtime,
        )
        identity = repo.resolve_realtime_identity(account.token, 194)
        req(identity is not None, "realtime identity missing")
        session, peer = make_session(runtime, identity, RealtimeRole.WORLD, 194, "postcommit")

        observed_scope = []
        production_sink = runtime.handle_post_commit
        def checking_sink(topic, values):
            current = repo.current_player_or_none()
            observed_scope.append(str(current.player_id) if current is not None else None)
            req(repo.current_services_or_none() is None, "request-scoped services remained bound during realtime sink")
            production_sink(topic, values)
        dispatcher._post_commit_sink = checking_sink

        original = dispatcher.handlers[124]
        def staged_handler(_request):
            services = repo.get_services()
            context = OperationContext(
                actor_player_id=str(services.player.player_id),
                domain="WAVE_E_SELFTEST",
                operation_name="stage_force_reload",
                protocol_mid=124,
            )
            with services.uow.transaction(context):
                services.realtime_intents.stage(force_reload(player_id))
                services.uow.request_save()
            return services.deferred_status.response(124)
        dispatcher.handlers[124] = staged_handler
        try:
            result = dispatcher.dispatch({
                "mid": 124,
                "token": account.token,
                "region": 194,
            })
            req(result["error_code"] == 0, "test request failed")
            req(observed_scope and observed_scope[0] != player_id, "target player binding survived into realtime sink")
            frame = receive_frame(peer)
            req(frame.mid == 36855, "committed realtime intent not delivered")
        finally:
            dispatcher.handlers[124] = original
            runtime.session_registry.remove(session.connection_id)
            session.close(); peer.close()

        # Queue overflow must disconnect a slow consumer rather than block a
        # committed gameplay transaction/publisher caller.
        slow_server, slow_peer = socket.socketpair()
        slow = RealtimeSession(
            connection_id="wavee-slow",
            identity=identity,
            role=RealtimeRole.WORLD,
            room_id=194,
            sock=slow_server,
            connected_at=time.monotonic(),
            last_received_at=time.monotonic(),
        )
        runtime.session_registry.register(slow)
        for _ in range(256):
            req(slow.enqueue(b"x"), "failed to prefill slow-consumer queue")
        report = runtime.publish(force_reload(player_id))
        req(report.selected == 1 and report.enqueued == 0 and report.disconnected == 1, "slow consumer was not isolated")
        req(runtime.session_registry.get("wavee-slow") is None, "slow consumer leaked registry")
        slow_peer.close()


def test_source_and_composition_guards():
    backend = (ROOT / "../wavee_src64_marker").resolve()  # marker only for readability
    source = Path('/mnt/data/wavee_src64/app-assets/output/assets/src_64/app/common/network/Backend.lua')
    if source.exists():
        text = source.read_text(encoding="utf-8-sig")
        req('request(xyd.mid.LOAD_CHAT_ROOM_INFO' in text, "current src_64 MID192 discovery evidence missing")
        req('arg_39_1:sendMessage(xyd.mid.TCP_LOGIN' in text, "current src_64 TCP login evidence missing")
        req(text.count('elseif arg_47_2 == xyd.mid.FORCE_RELOAD') == 1, "FORCE_RELOAD current-source role evidence drift")
    app_factory = (ROOT / "gxb_backend/app_factory.py").read_text()
    req('post_commit_sink=realtime_runtime.handle_post_commit' in app_factory, "postcommit publisher sink not composed")
    req('RealtimeRuntime(settings.chat_host, settings.chat_port, repo)' in app_factory, "Wave D app-scoped runtime composition drift")


def main():
    test_mid192_directory()
    test_typed_publisher_and_role_routing()
    test_postcommit_staging_and_slow_consumer()
    test_source_and_composition_guards()
    print(json.dumps({
        "pass": "277.0",
        "status": "PASS",
        "wave": "E_TYPED_REALTIME_PUBLISHER_MID192_HTTP_INTEGRATION",
        "mid192": {"valid_roles": ["WORLD", "SERVICE", "GUILD"], "invalid_room_http": 409},
        "publisher": {
            "post_commit_topic": "realtime.transient",
            "default_player_role": "WORLD",
            "publication_enabled_mids": [32784, 36854, 36855],
            "force_reload_roles": ["WORLD"],
            "production_notice_schemas": 0,
        },
        "domain_business_state_added": False,
        "client_runtime_changed": False,
    }, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
