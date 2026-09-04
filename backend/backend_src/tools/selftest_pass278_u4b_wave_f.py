#!/usr/bin/env python3
"""Pass278 U4B Wave F whole synchronization-foundation integration test.

This is deliberately cross-plane: one normal multi-user character exercises
bootstrap hydration, deferred status, durable MessagePush preference state,
derived generic redmarks, shared HTTP/TCP room admission, and post-commit
realtime publication through the actual EngineDispatcher lifecycle.
"""
from __future__ import annotations

from dataclasses import replace
import json
from pathlib import Path
import socket
import sys
import tempfile
import time
import types

if "flask" not in sys.modules:
    fake = types.ModuleType("flask")
    fake.Request = object
    fake.jsonify = lambda data=None, **kwargs: data
    fake.make_response = lambda data=None, status=200, **kwargs: data
    fake.send_file = lambda *args, **kwargs: None
    sys.modules["flask"] = fake

from gxb_backend.config import SETTINGS
from gxb_backend.dispatch.engine_dispatcher import EngineDispatcher
from gxb_backend.protocol.mids import MID
from gxb_backend.realtime import (
    PlayerAudience, RealtimeEventIntent, RealtimeFrameStreamDecoder,
    RealtimeRole, RealtimeRuntime, RealtimeSession,
)
from gxb_backend.state.repository import StateRepository
from gxb_backend.state.unit_of_work import OperationContext

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
EXPECTED_STAGE3 = {
    17,49,56,81,112,115,176,229,289,336,352,368,384,612,624,780,836,
    2137,2416,2485,2560,2984,
}
DEFERRED = {124,530,816,822,1152}


def require(value, message):
    if not value:
        raise AssertionError(message)


def recv_frame(sock: socket.socket, timeout: float = 2.0):
    dec = RealtimeFrameStreamDecoder(); end = time.monotonic() + timeout
    sock.settimeout(0.2)
    while time.monotonic() < end:
        try: chunk = sock.recv(4096)
        except socket.timeout: continue
        if not chunk: raise AssertionError("socket closed before frame")
        rows = dec.feed(chunk)
        if rows: return rows[0]
    raise AssertionError("realtime frame timeout")


def make_session(runtime, identity):
    server, peer = socket.socketpair()
    session = RealtimeSession(
        connection_id="pass278-world", identity=identity,
        role=RealtimeRole.WORLD, room_id=int(identity.region), sock=server,
        connected_at=time.monotonic(), last_received_at=time.monotonic(),
    )
    runtime.session_registry.register(session); session.start_writer()
    return session, peer


def force_reload(player_id: str):
    return RealtimeEventIntent(
        mid=36855, params={}, audience=PlayerAudience(player_id),
        owner_domain="TRANSPORT_OPERATIONS",
        delivery_class="TRANSIENT_PRESENTATION", schema_key="force_reload",
    )


def main():
    with tempfile.TemporaryDirectory(prefix="gxb-wave-f-") as tmp:
        tmp = Path(tmp)
        repo = StateRepository(DATA / "player_db.json", multiuser_root=tmp / "server_state")
        _, status = repo.sdk_register("wave-f-user", "wave-f-pass")
        require(status == "created", "account create failed")
        account = repo.sdk_login("wave-f-user", "wave-f-pass")
        require(account is not None, "account login failed")
        settings = replace(SETTINGS, chat_host="127.0.0.1", chat_port=19278, runtime_log_dir=tmp / "logs")
        runtime = RealtimeRuntime(settings.chat_host, settings.chat_port, repo)
        dispatcher = EngineDispatcher(repo, settings, None, post_commit_sink=runtime.handle_post_commit, realtime_runtime=runtime)
        require(not runtime.is_listening, "runtime listened during graph construction")

        # Wave A/C bootstrap integration: exact accepted Stage3, no adapter widening.
        boot = dispatcher.dispatch({"mid": int(MID.RETRIEVE_TOKEN), "sid": account.sid, "region": 194})
        require(boot.get("error_code") == 0, "MID1 failed")
        token = str(boot["token"]); detail = boot.get("detail") or {}
        require({int(k) for k in detail} == EXPECTED_STAGE3, "Stage3 membership drift")
        require(not ({int(k) for k in detail} & DEFERRED), "deferred adapter leaked into Stage3")
        require(detail["17"].get("message_pushes") == [], "MessagePush bootstrap shape drift")

        # Wave C deferred status direct source-safe contract.
        practice = dispatcher.dispatch({"mid":124,"token":token,"region":194})
        require(practice.get("error_code") == 0, "MID124 failed")
        required = {"last_time","practice_attr","lock","times","base_crystal","base_mana","bless_value"}
        require(required.issubset(practice), "MID124 source-required fields missing")
        require(practice["practice_attr"] == [0,0,0] and practice["lock"] == [], "MID124 baseline drift")

        # Wave C durable MessagePush list semantics and HTTP projection.
        add = dispatcher.dispatch({"mid":1025,"token":token,"region":194,"message_type":3})
        require(add == {"error_code":0}, "MID1025 failed")
        p17 = dispatcher.dispatch({"mid":17,"token":token,"region":194})
        require(p17.get("message_pushes") == [3], "MessagePush durable list not projected")

        # Wave B derived Mission redmark from canonical campaign fact, no legacy badge state.
        with repo.request_scope({"mid":17,"token":token,"region":194}):
            services = repo.get_services(); player = repo.get_player()
            meta = services.missions.story_missions[str(services.missions.FIRST_STORY_MISSION)]
            target = int(str(meta.get("task_num_raw", "0")).split("|")[0])
            rows = player.world_map.setdefault("normal", [])
            found = False
            for row in rows:
                if int(row.get("campaign_id",0)) == target:
                    row["star"] = max(1, int(row.get("star",0))); found = True; break
            if not found: rows.append({"campaign_id":target,"star":1,"daily_limit":0,"reset_count":0,"is_partner_drop":0})
            services.missions.normalize_story_80001(); repo.save()
            # Poison the legacy persisted badge field: MID2560 must ignore it.
            player.redmarks = [{"function_id":999,"redmark_list":[9999]}]; repo.save()
        red = dispatcher.dispatch({"mid":2560,"token":token,"region":194})
        require(red.get("error_code") == 0, "MID2560 failed")
        require(any(r.get("function_id")==27 and 2704 in r.get("redmark_list",[]) for r in red.get("data",[])), "Story redmark not derived")
        require(not any(r.get("function_id")==999 for r in red.get("data",[])), "legacy redmarks regained authority")

        # Wave D/E shared discovery/admission over canonical identity.
        room = dispatcher.dispatch({"mid":192,"token":token,"region":194,"room_id":194})
        require(room.get("error_code") == 0 and room.get("room_id") == 194, "MID192 canonical WORLD discovery failed")
        bad = dispatcher.dispatch({"mid":192,"token":token,"region":194,"room_id":195})
        require(getattr(bad,"status_code",None) == 409, "MID192 arbitrary room admitted")
        identity = repo.resolve_realtime_identity(token,194)
        require(identity is not None and identity.player_id == p17["player_id"], "TCP/HTTP identity split")

        # Wave A+E cross-plane invariant: stage under UoW, deliver only after request scope exits.
        session, peer = make_session(runtime, identity)
        original = dispatcher.handlers[int(MID.LOAD_PLAYER_INFO)]
        def integration_handler(req):
            services = repo.get_services()
            ctx = OperationContext(actor_player_id=str(repo.get_player().player_id), protocol_mid=17, domain="pass278_wave_f", operation_name="postcommit_probe")
            with services.uow.transaction(ctx):
                services.realtime_intents.stage(force_reload(str(repo.get_player().player_id)))
                services.uow.request_save()
            return original(req)
        dispatcher.handlers[int(MID.LOAD_PLAYER_INFO)] = integration_handler
        try:
            out = dispatcher.dispatch({"mid":17,"token":token,"region":194})
            require(out.get("error_code") == 0, "postcommit probe HTTP failed")
            frame = recv_frame(peer)
            require(frame.mid == 36855 and frame.params == {} and frame.sequence == 0, "postcommit realtime delivery mismatch")
            require(repo.current_services_or_none() is None, "request-scoped services survived dispatch")
            require(str(repo.current_player_or_none().player_id) != str(identity.player_id), "authenticated player binding survived dispatch")
        finally:
            dispatcher.handlers[int(MID.LOAD_PLAYER_INFO)] = original
            removed = runtime.session_registry.remove(session.connection_id)
            if removed is not None: removed.close()
            peer.close()

        # Restart reality: durable preference survives; transient realtime session does not.
        repo2 = StateRepository(DATA / "player_db.json", multiuser_root=tmp / "server_state")
        account2 = repo2.sdk_login("wave-f-user", "wave-f-pass")
        require(account2 is not None, "restart login failed")
        settings2 = replace(settings, runtime_log_dir=tmp / "logs2")
        runtime2 = RealtimeRuntime(settings2.chat_host, settings2.chat_port, repo2)
        dispatcher2 = EngineDispatcher(repo2, settings2, None, post_commit_sink=runtime2.handle_post_commit, realtime_runtime=runtime2)
        p17b = dispatcher2.dispatch({"mid":17,"token":account2.token,"region":194})
        require(p17b.get("message_pushes") == [3], "MessagePush lost across restart")
        require(len(runtime2.session_registry) == 0, "transient session persisted across restart")

    print(json.dumps({
        "pass":"278.0","status":"PASS","wave":"F_WHOLE_SYNCHRONIZATION_FOUNDATION_INTEGRATION_REGRESSION",
        "integration":{"stage3_exact":22,"deferred_bootstrap_leak":0,"practice_shape":7,"message_push_restart":True,"derived_story_redmark":2704,"legacy_redmark_ignored":True,"mid192_shared_admission":True,"postcommit_force_reload":True,"request_binding_cleared":True,"realtime_sessions_transient":True}
    },indent=2,sort_keys=True))

if __name__ == "__main__": main()
