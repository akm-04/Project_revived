#!/usr/bin/env python3
"""Front for the v2 playtest harness: forwards to gxb-api and realtime; backend OTA files are streamed, not buffered."""

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

BIND_ADDRESS = os.environ.get("PLAYTEST_BIND", "127.0.0.1")
ENGINE_ORIGIN = os.environ.get("PLAYTEST_ENGINE_ORIGIN", "https://gxbv2engine.shares.zrok.io").rstrip("/")
# Cloudflare Tunnel zone: clients that reach api.<domain> are handed api.<domain> and assets.<domain> URLs instead of ENGINE_ORIGIN.
PUBLIC_DOMAIN = os.environ.get("PLAYTEST_PUBLIC_DOMAIN", "gxbengine.dpdns.org")
LISTEN_PORT = int(os.environ.get("PLAYTEST_FRONT_PORT", "18956"))
API_HOST = "127.0.0.1"
API_PORT = int(os.environ.get("PLAYTEST_API_PORT", "18953"))
REALTIME_HTTP_HOST = os.environ.get("PLAYTEST_REALTIME_HTTP_HOST", "127.0.0.1")
REALTIME_HTTP_PORT = int(os.environ.get("PLAYTEST_REALTIME_HTTP_PORT", "18958"))
REALTIME_HTTP_PATH = "/realtime/poll"
FORWARD_TIMEOUT_SECONDS = 60
# One id per game launch, handed out in the MID 20480 reply and carried in every later URL of that launch.
SESSION_PATTERN = r"\d{4}-\d{6}-[0-9a-f]{4}"
SESSION_PATH = re.compile(rf"/s/({SESSION_PATTERN})(/.*)")
REFUSED_STATUS = 400
REFUSAL_REPLY_BYTES = 300
SESSION_LOG_DIRECTORY = Path(__file__).resolve().parent / "logs" / "sessions"
# Backend OTA (I11A): gxb-api mints <GXB_PUBLIC_ENGINE_URL>/updates/... and /res/..., and serves them at its root.
ENGINE_OTA_PATH = re.compile(r"/engine(/(?:updates|res)/.+)")
STREAM_BLOCK_BYTES = 1024 * 1024

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

SESSION_LOG_LOCK = threading.Lock()


def log(message):
    print(message, file=sys.stderr, flush=True)


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


def public_origins(host):
    """(api origin, asset origin, per-launch asset paths) for the public hostname the client reached."""
    if host.split(":")[0].lower() == f"api.{PUBLIC_DOMAIN}":
        # Plain /res/ paths are identical for every launch, so the CDN can serve them from cache.
        return f"https://api.{PUBLIC_DOMAIN}", f"https://assets.{PUBLIC_DOMAIN}", False
    return ENGINE_ORIGIN, ENGINE_ORIGIN, True


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
        session = None
        target = self.path
        session_path = SESSION_PATH.fullmatch(path)
        if session_path:
            session = session_path[1]
            target = self.path[len("/s/") + len(session):]
            path = session_path[2]
        if ENGINE_OTA_PATH.fullmatch(path):
            self.stream_backend_ota(send_body, target[len("/engine"):], session)
            return
        self.forward_request(send_body, target, session)

    def stream_backend_ota(self, send_body, target, session):
        """Update volumes reach 99 MB: stream them (and /res files) instead of buffering, Range headers included."""
        started = time.monotonic()
        headers = dict(filtered_headers(self.headers.items(), REQUEST_DROP_HEADERS))
        connection = http.client.HTTPConnection(API_HOST, API_PORT, timeout=FORWARD_TIMEOUT_SECONDS)
        try:
            connection.request(self.command, target, headers=headers)
            response = connection.getresponse()
        except (OSError, http.client.HTTPException) as error:
            connection.close()
            log(f"asset front: cannot reach gxb-api for {target}: {error}")
            record_session_event(session, {"event": "asset", "file": target, "status": 502, "bytes": 0, "ms": elapsed_milliseconds(started), "delivered": False})
            self.send_empty(502)
            return
        sent = 0
        delivered = True
        try:
            self.send_response(response.status)
            for name, value in filtered_headers(response.getheaders(), HOP_BY_HOP_HEADERS):
                self.send_header(name, value)
            self.end_headers()
            while send_body:
                block = response.read(STREAM_BLOCK_BYTES)
                if not block:
                    break
                self.wfile.write(block)
                sent += len(block)
        except (OSError, http.client.HTTPException) as error:
            log(f"asset front: backend ota {target} failed: {error}")
            delivered = False
            self.close_connection = True
        finally:
            connection.close()
        record_session_event(
            session,
            {
                "event": "asset",
                "file": target,
                "status": response.status,
                "size": int(response.getheader("Content-Length") or 0),
                "bytes": sent,
                "ms": elapsed_milliseconds(started),
                "delivered": delivered,
            },
        )
        log(f"backend ota {session or '-'} {target} {response.status} {sent} bytes {elapsed_milliseconds(started)} ms")

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
            # gxb-api mints absolute URLs (MID 1 log_url, MID 2 update volumes) from ENGINE_ORIGIN; keep tunnel clients on their own hostname.
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
        # The backend OTA owns res_download_url (empty = lazy fetch off); the front only re-homes its path.
        res_path = urllib.parse.urlsplit(reply["res_download_url"]).path
        if res_path:
            reply["res_download_url"] = f"{api_origin}/s/{session}{res_path}" if per_launch_assets else f"{asset_origin}{res_path}"
        reply["url"] = f"{api_origin}/s/{session}{urllib.parse.urlsplit(reply['url']).path}"
        return json.dumps(reply, separators=(",", ":")).encode("utf-8"), session

    def send_empty(self, status):
        self.send_response(status)
        self.send_header("Content-Length", "0")
        self.end_headers()


class PlaytestFrontServer(ThreadingHTTPServer):
    # Held polls arrive in one burst; socketserver's default backlog of 5 resets
    # most of them, so size the accept queue for a full client population.
    request_queue_size = 4096


def main():
    server = PlaytestFrontServer((BIND_ADDRESS, LISTEN_PORT), PlaytestFrontHandler)
    server.daemon_threads = True
    log(f"asset front listening on {BIND_ADDRESS}:{LISTEN_PORT}")
    server.serve_forever()


if __name__ == "__main__":
    main()
