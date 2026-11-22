#!/usr/bin/env python3
"""Asset front for the v2 playtest harness: serves /res/<basename>.<md5> and forwards the rest to gxb-api."""

import hashlib
import http.client
import json
import os
import re
import secrets
import sys
import threading
import time
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

PLAYTEST_HOME = Path(os.environ.get("PLAYTEST_HOME", Path(__file__).resolve().parent / "runtime"))
ASSET_TREE = Path(os.environ.get("PLAYTEST_ASSET_TREE", Path(__file__).resolve().parents[1] / "tmp" / "virtualclient" / "update-tree"))
BIND_ADDRESS = os.environ.get("PLAYTEST_BIND", "127.0.0.1")
ENGINE_ORIGIN = os.environ.get("PLAYTEST_ENGINE_ORIGIN", "https://gxbv2engine.shares.zrok.io").rstrip("/")
# Cloudflare Tunnel zone: clients that reach api.<domain> are handed api.<domain> and assets.<domain> URLs instead of ENGINE_ORIGIN.
PUBLIC_DOMAIN = os.environ.get("PLAYTEST_PUBLIC_DOMAIN", "gxbengine.dpdns.org")
# Asset names carry their md5, so a cached copy never goes stale; a 404 must never be cached because asset recovery adds files later.
IMMUTABLE_CACHE_CONTROL = "public, max-age=31536000, immutable"
LISTEN_PORT = int(os.environ.get("PLAYTEST_FRONT_PORT", "18956"))
API_HOST = "127.0.0.1"
API_PORT = int(os.environ.get("PLAYTEST_API_PORT", "18953"))
REALTIME_HTTP_HOST = os.environ.get("PLAYTEST_REALTIME_HTTP_HOST", "127.0.0.1")
REALTIME_HTTP_PORT = int(os.environ.get("PLAYTEST_REALTIME_HTTP_PORT", "18958"))
REALTIME_HTTP_PATH = "/realtime/poll"
FORWARD_TIMEOUT_SECONDS = 60
RESOURCE_PREFIX = "/res/"
# One id per game launch, handed out in the MID 20480 reply and carried in every later URL of that launch.
SESSION_PATTERN = r"\d{4}-\d{6}-[0-9a-f]{4}"
SESSION_PATH = re.compile(rf"/s/({SESSION_PATTERN})(/.*)")
SESSION_RESOURCE = re.compile(rf"/res/({SESSION_PATTERN})/([^/]+)")
REFUSED_STATUS = 400
REFUSAL_REPLY_BYTES = 300
SESSION_LOG_DIRECTORY = Path(__file__).resolve().parent / "logs" / "sessions"

STATE_DIRECTORY = PLAYTEST_HOME / "state"
ASSET_INDEX_PATH = STATE_DIRECTORY / "asset_index.json"
MISSING_ASSETS_PATH = STATE_DIRECTORY / "missing_assets.txt"
# Temporary playtest OTA built by ota.py: release.json, the raw volume and the recovered files it makes acceptable.
OTA_DIRECTORY = PLAYTEST_HOME / "ota"
UPDATES_PREFIX = "/updates/"
VERSION_CHECK_MID = 2

HOP_BY_HOP_HEADERS = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
}
REQUEST_DROP_HEADERS = HOP_BY_HOP_HEADERS | {"host", "content-length"}


def log(message):
    print(message, file=sys.stderr, flush=True)


def walk_asset_tree():
    files = []
    total_size = 0
    for directory, _, names in [*os.walk(ASSET_TREE), *os.walk(OTA_DIRECTORY / "assets")]:
        for name in sorted(names):
            path = Path(directory) / name
            try:
                total_size += path.stat().st_size
            except OSError:
                continue
            files.append(path)
    return files, total_size


def file_md5(path):
    digest = hashlib.md5()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def build_index():
    files, total_size = walk_asset_tree()
    cached = None
    try:
        cached = json.loads(ASSET_INDEX_PATH.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError):
        cached = None
    if (
        cached is not None
        and cached.get("file_count") == len(files)
        and cached.get("total_size") == total_size
        and isinstance(cached.get("entries"), dict)
    ):
        return cached["entries"]
    entries = {}
    for path in files:
        try:
            key = f"{path.name}.{file_md5(path)}"
        except OSError:
            continue
        entries.setdefault(key, str(path))
    STATE_DIRECTORY.mkdir(parents=True, exist_ok=True)
    temporary = ASSET_INDEX_PATH.with_name(f"{ASSET_INDEX_PATH.name}.{os.getpid()}.tmp")
    temporary.write_text(
        json.dumps(
            {"file_count": len(files), "total_size": total_size, "entries": entries},
            sort_keys=True,
        ),
        encoding="utf-8",
    )
    os.replace(temporary, ASSET_INDEX_PATH)
    return entries


INDEX = build_index()
INDEX_LOCK = threading.Lock()
MISSING_LOCK = threading.Lock()
SESSION_LOG_LOCK = threading.Lock()


def load_missing_assets():
    try:
        return set(MISSING_ASSETS_PATH.read_text(encoding="utf-8").splitlines())
    except FileNotFoundError:
        return set()


MISSING_ASSETS = load_missing_assets()


def record_missing(key):
    with MISSING_LOCK:
        if key in MISSING_ASSETS:
            return
        MISSING_ASSETS.add(key)
        STATE_DIRECTORY.mkdir(parents=True, exist_ok=True)
        with open(MISSING_ASSETS_PATH, "a", encoding="utf-8") as handle:
            handle.write(key + "\n")
        log(f"asset missing: {key}")


def new_session():
    return time.strftime("%m%d-%H%M%S", time.gmtime()) + "-" + secrets.token_hex(2)


def record_session_event(session, event):
    if session is None:
        return
    line = json.dumps({"at": round(time.time(), 3), **event}, ensure_ascii=False)
    with SESSION_LOG_LOCK:
        SESSION_LOG_DIRECTORY.mkdir(parents=True, exist_ok=True)
        with open(SESSION_LOG_DIRECTORY / f"{session}.jsonl", "a", encoding="utf-8") as handle:
            handle.write(line + "\n")


def elapsed_milliseconds(started):
    return round((time.monotonic() - started) * 1000, 1)


def filtered_headers(headers, dropped):
    connection_tokens = set()
    for name, value in headers:
        if name.lower() == "connection":
            connection_tokens = {
                token.strip().lower() for token in value.split(",") if token.strip()
            }
    drop = dropped | connection_tokens
    return [(name, value) for name, value in headers if name.lower() not in drop]


def resource_version(value):
    parts = str(value or "").split(".")
    return tuple(int(part) for part in parts) if len(parts) == 3 and all(part.isdigit() for part in parts) else (0, 0, 0)


def public_origins(host):
    """(api origin, asset origin, per-launch asset paths) for the public hostname the client reached."""
    if host.split(":")[0].lower() == f"api.{PUBLIC_DOMAIN}":
        # Plain /res/ paths are identical for every launch, so the CDN can serve them from cache.
        return f"https://api.{PUBLIC_DOMAIN}", f"https://assets.{PUBLIC_DOMAIN}", False
    return ENGINE_ORIGIN, ENGINE_ORIGIN, True


def ota_reply(body, asset_origin):
    """MID 2 while an ota.py release exists: the v1 version-check reply, advertising it to clients below its version."""
    try:
        release = json.loads((OTA_DIRECTORY / "release.json").read_text(encoding="utf-8"))
        payload = json.loads(urllib.parse.parse_qs(body.decode("utf-8")).get("payload", ["{}"])[0])
    except (FileNotFoundError, UnicodeDecodeError, json.JSONDecodeError):
        return None
    if not isinstance(payload, dict) or payload.get("mid") != VERSION_CHECK_MID:
        return None
    reply = {"is_appstore": 0, "is_inapp": 0, "is_review": 0, "need_restart": 0}
    if resource_version(payload.get("v")) >= resource_version(release["version"]):
        return reply
    return {
        **reply, "is_inapp": 1,
        # Source semantics (v1 local_update.py): is_review skips the update prompt and starts the download.
        "is_review": 1 if release["silent"] else 0,
        "res": [{
            "version": release["version"], "volume": release["volume"], "size": release["size"], "md5": release["md5"],
            "resource": f"{asset_origin}{UPDATES_PREFIX}{release['package']}",
        }],
    }


class PlaytestFrontHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, format, *arguments):
        return

    def do_HEAD(self):
        self.handle_request(send_body=False)

    def do_GET(self):
        self.handle_request(send_body=True)

    def do_POST(self):
        self.handle_request(send_body=True)

    def do_PUT(self):
        self.handle_request(send_body=True)

    def do_DELETE(self):
        self.handle_request(send_body=True)

    def do_PATCH(self):
        self.handle_request(send_body=True)

    def handle_request(self, send_body):
        path = urllib.parse.urlsplit(self.path).path
        if path == REALTIME_HTTP_PATH:
            self.forward_request(send_body, self.path, None, REALTIME_HTTP_HOST, REALTIME_HTTP_PORT)
            return
        session_resource = SESSION_RESOURCE.fullmatch(path)
        if session_resource:
            self.serve_asset(session_resource[2], send_body, session_resource[1])
            return
        if path.startswith(UPDATES_PREFIX):
            name = path[len(UPDATES_PREFIX):]
            valid = name and "/" not in name and name not in (".", "..")
            self.serve_asset(name, send_body, None, OTA_DIRECTORY / name if valid else None)
            return
        if path.startswith(RESOURCE_PREFIX):
            self.serve_asset(path[len(RESOURCE_PREFIX):], send_body, None)
            return
        session_path = SESSION_PATH.fullmatch(path)
        if session_path:
            prefix_length = len("/s/") + len(session_path[1])
            self.forward_request(send_body, self.path[prefix_length:], session_path[1])
            return
        self.forward_request(send_body, self.path, None)

    def serve_asset(self, key, send_body, session, path=None):
        started = time.monotonic()
        if not key or "/" in key or key in (".", ".."):
            self.send_empty(404)
            return
        md5_named = path is None
        if md5_named:
            with INDEX_LOCK:
                path = INDEX.get(key)
        if path is None or not os.path.isfile(path):
            record_missing(key)
            record_session_event(session, {"event": "asset", "file": key, "status": 404})
            self.send_empty(404, "no-store")
            return
        size = os.path.getsize(path)
        self.send_response(200)
        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Content-Length", str(size))
        if md5_named:
            self.send_header("Cache-Control", IMMUTABLE_CACHE_CONTROL)
        self.end_headers()
        sent = 0
        delivered = True
        if send_body:
            try:
                with open(path, "rb") as handle:
                    while True:
                        block = handle.read(1024 * 1024)
                        if not block:
                            break
                        self.wfile.write(block)
                        sent += len(block)
            except OSError:
                delivered = False
                self.close_connection = True
        record_session_event(
            session,
            {
                "event": "asset",
                "file": key,
                "status": 200,
                "size": size,
                "bytes": sent,
                "ms": elapsed_milliseconds(started),
                "delivered": delivered,
            },
        )
        log(f"asset {'served' if delivered else 'aborted'}: {session or '-'} {key} {sent}/{size}")

    def read_body(self):
        length = self.headers.get("Content-Length")
        if not length:
            return b""
        try:
            return self.rfile.read(int(length))
        except (ValueError, OSError):
            return b""

    def forward_request(self, send_body, target, session, upstream_host=API_HOST, upstream_port=API_PORT):
        started = time.monotonic()
        body = self.read_body()
        headers = dict(filtered_headers(self.headers.items(), REQUEST_DROP_HEADERS))
        headers["Content-Length"] = str(len(body))
        api_origin, asset_origin, per_launch_assets = public_origins(self.headers.get("Host", ""))
        update = ota_reply(body, asset_origin)
        if update is not None:
            self.send_json(update)
            record_session_event(session, {"event": "version_check", "path": target, "ota": update.get("res", []), "ms": elapsed_milliseconds(started)})
            log(f"version check answered by playtest OTA: {update.get('res') or 'no update'}")
            return
        connection = http.client.HTTPConnection(upstream_host, upstream_port, timeout=FORWARD_TIMEOUT_SECONDS)
        try:
            connection.request(self.command, target, body=body, headers=headers)
            response = connection.getresponse()
            data = response.read()
            response_headers = filtered_headers(response.getheaders(), HOP_BY_HOP_HEADERS)
        except (OSError, http.client.HTTPException) as error:
            log(f"asset front: cannot reach gxb-api: {error}")
            record_session_event(session, {"event": "request", "path": target, "status": 502, "ms": elapsed_milliseconds(started)})
            self.send_empty(502)
            return
        finally:
            connection.close()
        if api_origin != ENGINE_ORIGIN:
            # gxb-api mints absolute URLs (MID 1 log_url) from ENGINE_ORIGIN; keep tunnel clients on their own hostname.
            data = data.replace(ENGINE_ORIGIN.encode(), api_origin.encode())
        data, launch = self.claim_launch(data, api_origin, asset_origin, per_launch_assets)
        if launch:
            session = launch
            record_session_event(
                session,
                {
                    "event": "launch",
                    "user_agent": self.headers.get("User-Agent"),
                    "forwarded_for": self.headers.get("X-Forwarded-For"),
                },
            )
        self.send_response(response.status)
        content_length = str(len(data))
        for name, value in response_headers:
            if name.lower() == "content-length":
                if self.command == "HEAD":
                    content_length = value
                continue
            self.send_header(name, value)
        self.send_header("Content-Length", content_length)
        self.end_headers()
        delivered = True
        if send_body and data:
            try:
                self.wfile.write(data)
            except OSError:
                delivered = False
                self.close_connection = True
        record_session_event(
            session,
            {
                "event": "request",
                "path": target,
                "status": response.status,
                "ms": elapsed_milliseconds(started),
                "bytes_in": len(body),
                "bytes_out": len(data),
                "request_sha256": hashlib.sha256(body).hexdigest(),
                "delivered": delivered,
                **({"reply": data[:REFUSAL_REPLY_BYTES].decode("utf-8", "replace")} if response.status >= REFUSED_STATUS else {}),
            },
        )

    def claim_launch(self, data, api_origin, asset_origin, per_launch_assets):
        if b'"res_download_url"' not in data:
            return data, None
        session = new_session()
        reply = json.loads(data)
        reply["res_download_url"] = f"{asset_origin}/res/{session}/" if per_launch_assets else f"{asset_origin}/res/"
        reply["url"] = f"{api_origin}/s/{session}{urllib.parse.urlsplit(reply['url']).path}"
        return json.dumps(reply, separators=(",", ":")).encode("utf-8"), session

    def send_json(self, payload):
        data = json.dumps(payload, separators=(",", ":")).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def send_empty(self, status, cache_control=None):
        self.send_response(status)
        self.send_header("Content-Length", "0")
        if cache_control:
            self.send_header("Cache-Control", cache_control)
        self.end_headers()


class PlaytestFrontServer(ThreadingHTTPServer):
    # Held polls arrive in one burst; socketserver's default backlog of 5 resets
    # most of them, so size the accept queue for a full client population.
    request_queue_size = 4096


def main():
    server = PlaytestFrontServer((BIND_ADDRESS, LISTEN_PORT), PlaytestFrontHandler)
    server.daemon_threads = True
    log(f"asset front listening on {BIND_ADDRESS}:{LISTEN_PORT}, {len(INDEX)} assets from {ASSET_TREE}")
    server.serve_forever()


if __name__ == "__main__":
    main()
