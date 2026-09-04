#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
import socket
import struct
import tempfile
import time

from gxb_backend.realtime import (
    FrameTooLarge,
    RealtimeFrameEncoder,
    RealtimeFrameStreamDecoder,
    RealtimeRole,
    RealtimeRoomAdmissionPolicy,
    RealtimeServer,
    UnsupportedAmf3,
    XinyoudiAmf3Codec,
)
from gxb_backend.state.repository import StateRepository

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
LOGIN_HEX = "000000388003000000000a0b010b746f6b656e06176c6f63616c5f746f6b656e0d726567696f6e0540684000000000000f726f6f6d5f696405406840000000000001"
ENTERED_HEX = "00000015800b000000000a0b010f726f6f6d5f696405406840000000000001"
HEARTBEAT_HEX = "00000004801d000000000a0b0101"


def req(value, message):
    if not value:
        raise AssertionError(message)


def receive_frame(sock: socket.socket, timeout: float = 2.0):
    decoder = RealtimeFrameStreamDecoder()
    end = time.monotonic() + timeout
    sock.settimeout(0.25)
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


def wait_until(predicate, timeout: float = 2.0):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        if predicate():
            return True
        time.sleep(0.01)
    return bool(predicate())


def test_codec_vectors():
    raw = bytes.fromhex(LOGIN_HEX)
    frame = RealtimeFrameStreamDecoder().feed(raw)[0]
    req(frame.mid == 32771 and frame.sequence == 0, "login frame header drift")
    req(frame.params == {"token": "local_token", "region": 194.0, "room_id": 194.0}, "login decode drift")
    encoded = RealtimeFrameEncoder().encode(32771, {"token": "local_token", "region": 194, "room_id": 194}, sequence=0)
    req(encoded == raw and len(encoded) == 66, "known 66-byte login vector mismatch")
    req(RealtimeFrameEncoder().encode(32779, {"room_id": 194}, sequence=0).hex() == ENTERED_HEX, "entered vector drift")
    req(RealtimeFrameEncoder().encode(32797, {}, sequence=0).hex() == HEARTBEAT_HEX, "heartbeat vector drift")

    fragmented = RealtimeFrameStreamDecoder()
    out = []
    for byte in raw:
        out.extend(fragmented.feed(bytes((byte,))))
    req(len(out) == 1 and out[0].params["token"] == "local_token", "1-byte fragmented decode failed")
    coalesced = RealtimeFrameStreamDecoder().feed(raw + bytes.fromhex(HEARTBEAT_HEX))
    req([f.mid for f in coalesced] == [32771, 32797], "coalesced frame decode failed")

    maximum = RealtimeFrameEncoder().encode(32783, "a" * 65532, sequence=0)
    req(struct.unpack(">I", maximum[:4])[0] == 65536, "65536 payload not accepted")
    try:
        RealtimeFrameEncoder().encode(32783, "a" * 65533, sequence=0)
    except FrameTooLarge:
        pass
    else:
        raise AssertionError("65537 payload was not rejected")
    try:
        RealtimeFrameStreamDecoder().feed(struct.pack(">IHI", 65537, 32771, 0))
    except FrameTooLarge:
        pass
    else:
        raise AssertionError("oversize incoming frame not rejected before payload")
    try:
        RealtimeFrameStreamDecoder().feed(struct.pack(">IHI", 1, 32771, 0) + b"\x07")
    except UnsupportedAmf3:
        pass
    else:
        raise AssertionError("unsupported AMF3 marker did not fail closed")

    # Decoder accepts the recovered integer marker in addition to doubles.
    req(XinyoudiAmf3Codec.decode(b"\x04\x7f") == 127, "AMF3 integer decode unsupported")


def make_repo(root: Path):
    repo = StateRepository(DATA / "player_db.json", multiuser_root=root / "server_state")
    record, status = repo.sdk_register("wave-d-user", "wave-d-pass")
    req(status == "created" and record, "test account creation failed")
    account = repo.sdk_login("wave-d-user", "wave-d-pass")
    req(account is not None, "test account login failed")
    with repo.request_scope({"mid": 1, "sid": account.sid, "region": 194}):
        player, created = repo.resolve_or_create_player(194)
        req(created, "test player was not created")
        player.guild_id = 777
        repo.save()
        player_id = str(player.player_id)
    return repo, account, player_id


def test_identity_and_admission():
    with tempfile.TemporaryDirectory(prefix="gxb-wave-d-") as tmp:
        repo, account, player_id = make_repo(Path(tmp))
        binding_before = repo.current_player_or_none()
        identity = repo.resolve_realtime_identity(account.token, 194)
        req(identity is not None, "canonical realtime identity did not resolve")
        req(identity.uid == account.uid and identity.sid == account.sid and identity.player_id == player_id, "identity mismatch")
        req(identity.region == 194 and identity.guild_id == 777, "identity admission facts mismatch")
        req(repo.resolve_realtime_identity("bad-token", 194) is None, "bad token admitted")
        req(repo.resolve_realtime_identity(account.token, 195) is None, "wrong region admitted")
        policy = RealtimeRoomAdmissionPolicy()
        req(policy.classify(identity, 194).role is RealtimeRole.WORLD, "world admission drift")
        req(policy.classify(identity, 99999).role is RealtimeRole.SERVICE, "service admission drift")
        req(policy.classify(identity, 777).role is RealtimeRole.GUILD, "guild admission drift")
        req(policy.classify(identity, 778) is None, "invalid room admitted")
        req(repo.current_player_or_none() is binding_before, "realtime identity polluted request-local binding")


def connect_login(port: int, token: str, room_id: int):
    sock = socket.create_connection(("127.0.0.1", port), timeout=2.0)
    login = RealtimeFrameEncoder().encode(32771, {"token": token, "region": 194, "room_id": room_id}, sequence=0)
    started = time.monotonic()
    sock.sendall(login)
    frame = receive_frame(sock)
    elapsed = time.monotonic() - started
    req(frame.mid == 32779 and frame.params == {"room_id": float(room_id)}, "CHAT_ROOM_ENTERED mismatch")
    req(elapsed < 10.0, "session admission missed stock 10s auth window")
    return sock


def test_authenticated_runtime():
    with tempfile.TemporaryDirectory(prefix="gxb-wave-d-server-") as tmp:
        repo, account, player_id = make_repo(Path(tmp))
        server = RealtimeServer("127.0.0.1", 0, repo)
        server.start()
        req(server.wait_ready(2.0) and server.bound_port, "realtime server failed to bind")
        port = int(server.bound_port)
        try:
            world = connect_login(port, account.token, 194)
            service = connect_login(port, account.token, 99999)
            req(wait_until(lambda: len(server.registry) == 2), "multiple sessions were not registered")
            req(len(server.registry.connections_for_player(player_id)) == 2, "player session index mismatch")
            req(len(server.registry.connections_for_room(RealtimeRole.WORLD, 194)) == 1, "world room index mismatch")
            req(len(server.registry.connections_for_room(RealtimeRole.SERVICE, 99999)) == 1, "service room index mismatch")

            world.sendall(bytes.fromhex(HEARTBEAT_HEX))
            time.sleep(0.05)
            req(len(server.registry) == 2, "heartbeat unexpectedly closed authenticated session")

            world.close()
            req(wait_until(lambda: len(server.registry) == 1), "disconnect did not remove registry exactly once")
            service.close()
            req(wait_until(lambda: len(server.registry) == 0), "service disconnect did not clean registry")

            guild = connect_login(port, account.token, 777)
            req(wait_until(lambda: len(server.registry.connections_for_room(RealtimeRole.GUILD, 777)) == 1), "guild admission failed")
            guild.close()
            req(wait_until(lambda: len(server.registry) == 0), "guild disconnect leaked registry")

            bad = socket.create_connection(("127.0.0.1", port), timeout=2.0)
            bad.sendall(RealtimeFrameEncoder().encode(32771, {"token": "wrong", "region": 194, "room_id": 194}))
            bad.settimeout(2.0)
            req(bad.recv(1) == b"", "invalid login got fabricated response or remained open")
            bad.close()

            preauth = socket.create_connection(("127.0.0.1", port), timeout=2.0)
            preauth.sendall(bytes.fromhex(HEARTBEAT_HEX))
            preauth.settimeout(2.0)
            req(preauth.recv(1) == b"", "heartbeat before login was not rejected")
            preauth.close()

            feature = connect_login(port, account.token, 194)
            feature.sendall(RealtimeFrameEncoder().encode(32782, {"message":"not-implemented"}))
            feature.settimeout(2.0)
            req(feature.recv(1) == b"", "unowned feature MID did not fail closed")
            feature.close()
            req(wait_until(lambda: len(server.registry) == 0), "feature failure leaked session")
        finally:
            server.stop()
            req(wait_until(lambda: len(server.registry) == 0), "server shutdown leaked sessions")


def test_app_composition_non_listening():
    app_factory = (ROOT / "gxb_backend/app_factory.py").read_text()
    run_source = (ROOT / "gxb_backend/run.py").read_text()
    dispatcher = (ROOT / "gxb_backend/dispatch/engine_dispatcher.py").read_text()
    req("RealtimeRuntime(settings.chat_host, settings.chat_port, repo)" in app_factory, "AppFactory does not construct non-listening RealtimeRuntime")
    req("realtime_runtime=realtime_runtime" in app_factory, "AppFactory does not inject runtime into EngineDispatcher")
    req('app.extensions["gxb_realtime_runtime"] = realtime_runtime' in app_factory, "runtime extension missing")
    req('app.extensions.get("gxb_realtime_runtime")' in run_source and "realtime_runtime.start()" in run_source, "run.main lifecycle does not start composed runtime")
    req("self.realtime_runtime = realtime_runtime" in dispatcher, "dispatcher runtime injection missing")


def main():
    test_codec_vectors()
    test_identity_and_admission()
    test_app_composition_non_listening()
    test_authenticated_runtime()
    print(json.dumps({
        "pass":"276.0",
        "status":"PASS",
        "wave":"D_REALTIME_CODEC_IDENTITY_ADMISSION_AUTHENTICATED_SESSION_RUNTIME",
        "native_vectors":{"login_bytes":66,"entered_bytes":31,"heartbeat_bytes":14},
        "roles":["WORLD","SERVICE","GUILD"],
        "mids":{"TCP_LOGIN":32771,"CHAT_ROOM_ENTERED":32779,"SOCKET_HEARTBEAT":32797},
        "max_payload":65536,
        "preauth_timeout_seconds":15,
        "idle_timeout_seconds":1320,
        "typed_domain_publisher":False,
        "mid192_policy_integration":False,
        "client_runtime_changed":False,
    },indent=2,sort_keys=True))

if __name__ == "__main__":
    main()
