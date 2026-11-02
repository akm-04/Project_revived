#!/usr/bin/env python3
"""Asset front for the v2 playtest harness: serves /res/<basename>.<md5> and forwards the rest to gxb-api."""

import hashlib
import http.client
import json
import os
import sys
import threading
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

PLAYTEST_HOME = Path(os.environ.get("PLAYTEST_HOME", Path(__file__).resolve().parent / "runtime"))
ASSET_TREE = Path(os.environ.get("PLAYTEST_ASSET_TREE", Path(__file__).resolve().parents[1] / "tmp" / "virtualclient" / "update-tree"))
BIND_ADDRESS = os.environ.get("PLAYTEST_BIND", "127.0.0.1")
ENGINE_ORIGIN = os.environ.get("PLAYTEST_ENGINE_ORIGIN", "https://gxbv2engine.shares.zrok.io").rstrip("/")
LISTEN_PORT = 18956
API_HOST = "127.0.0.1"
API_PORT = 18953
FORWARD_TIMEOUT_SECONDS = 60
RESOURCE_PREFIX = "/res/"

STATE_DIRECTORY = PLAYTEST_HOME / "state"
ASSET_INDEX_PATH = STATE_DIRECTORY / "asset_index.json"
MISSING_ASSETS_PATH = STATE_DIRECTORY / "missing_assets.txt"

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
    for directory, _, names in os.walk(ASSET_TREE):
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


def filtered_headers(headers, dropped):
    connection_tokens = set()
    for name, value in headers:
        if name.lower() == "connection":
            connection_tokens = {
                token.strip().lower() for token in value.split(",") if token.strip()
            }
    drop = dropped | connection_tokens
    return [(name, value) for name, value in headers if name.lower() not in drop]


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
        if path.startswith(RESOURCE_PREFIX):
            self.serve_asset(path[len(RESOURCE_PREFIX):], send_body)
            return
        self.forward_request(send_body)

    def serve_asset(self, key, send_body):
        if not key or "/" in key or key in (".", ".."):
            self.send_empty(404)
            return
        with INDEX_LOCK:
            path = INDEX.get(key)
        if path is None or not os.path.isfile(path):
            record_missing(key)
            self.send_empty(404)
            return
        size = os.path.getsize(path)
        self.send_response(200)
        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Content-Length", str(size))
        self.end_headers()
        if send_body:
            with open(path, "rb") as handle:
                while True:
                    block = handle.read(1024 * 1024)
                    if not block:
                        break
                    self.wfile.write(block)
        log(f"asset served: {key} {size}")

    def read_body(self):
        length = self.headers.get("Content-Length")
        if not length:
            return b""
        try:
            return self.rfile.read(int(length))
        except (ValueError, OSError):
            return b""

    def forward_request(self, send_body):
        body = self.read_body()
        headers = dict(filtered_headers(self.headers.items(), REQUEST_DROP_HEADERS))
        headers["Content-Length"] = str(len(body))
        connection = http.client.HTTPConnection(API_HOST, API_PORT, timeout=FORWARD_TIMEOUT_SECONDS)
        try:
            connection.request(self.command, self.path, body=body, headers=headers)
            response = connection.getresponse()
            data = response.read()
            response_headers = filtered_headers(response.getheaders(), HOP_BY_HOP_HEADERS)
        except (OSError, http.client.HTTPException) as error:
            log(f"asset front: cannot reach gxb-api: {error}")
            self.send_empty(502)
            return
        finally:
            connection.close()
        data = self.rewrite_download_url(response_headers, data)
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
        if send_body and data:
            self.wfile.write(data)

    def rewrite_download_url(self, headers, data):
        if b'"res_download_url":""' not in data:
            return data
        return data.replace(
            b'"res_download_url":""',
            json.dumps({"res_download_url": f"{ENGINE_ORIGIN}/res/"}, separators=(",", ":"))[1:-1].encode("utf-8"),
            1,
        )

    def send_empty(self, status):
        self.send_response(status)
        self.send_header("Content-Length", "0")
        self.end_headers()


def main():
    server = ThreadingHTTPServer((BIND_ADDRESS, LISTEN_PORT), PlaytestFrontHandler)
    server.daemon_threads = True
    log(f"asset front listening on {BIND_ADDRESS}:{LISTEN_PORT}, {len(INDEX)} assets from {ASSET_TREE}")
    server.serve_forever()


if __name__ == "__main__":
    main()
