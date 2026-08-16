"""Capture the game's built-in ErrorLogPoster uploads.

The Lua client stores engine/Lua/resource failures in ``xyd.db.errorLog`` and,
when RETRIEVE_TOKEN supplies a non-empty ``log_url``, posts them roughly every
30 seconds. Type-0 uploads are zlib-compressed JSON in a multipart field named
``payload``. Type-1 uploads contain a crash dump file plus metadata.

This module deliberately treats the endpoint as observability only: it never
changes player state or fabricates client errors.
"""

from __future__ import annotations

import base64
import json
import re
import time
import zlib
from pathlib import Path
from typing import Any

from flask import Request

from gxb_backend.config import Settings


_BOUNDARY_RE = re.compile(r"boundary=(?:\"([^\"]+)\"|([^;]+))", re.IGNORECASE)
_NAME_RE = re.compile(br'name="([^"]+)"')
_FILENAME_RE = re.compile(br'filename="([^"]*)"')


def _safe_name(value: str, fallback: str = "upload.bin") -> str:
    name = Path(value or fallback).name
    cleaned = re.sub(r"[^A-Za-z0-9._-]+", "_", name)
    return cleaned or fallback


def _multipart_parts(raw: bytes, content_type: str) -> list[tuple[str, str | None, bytes]]:
    """Parse multipart bytes without text-decoding binary form contents.

    Cocos ``addFormContents`` can place deflated bytes directly into a normal
    multipart field. Depending on framework decoding that binary value may be
    lossy if accessed only through ``request.form``, so we inspect the raw body.
    """

    match = _BOUNDARY_RE.search(content_type or "")
    if not match:
        return []
    boundary = (match.group(1) or match.group(2) or "").strip().encode("utf-8")
    if not boundary:
        return []

    marker = b"--" + boundary
    parts: list[tuple[str, str | None, bytes]] = []
    for chunk in raw.split(marker):
        # A multipart boundary is surrounded by CRLF, but the payload itself is
        # arbitrary binary. Remove only the protocol CRLF bytes; never ``strip``
        # or ``rstrip`` the body because compressed data may legitimately end in
        # 0x0a/0x0d.
        if chunk.startswith(b"\r\n"):
            chunk = chunk[2:]
        if not chunk or chunk.startswith(b"--"):
            continue
        if chunk.endswith(b"\r\n"):
            chunk = chunk[:-2]
        header_blob, sep, body = chunk.partition(b"\r\n\r\n")
        if not sep:
            continue
        name_match = _NAME_RE.search(header_blob)
        if not name_match:
            continue
        filename_match = _FILENAME_RE.search(header_blob)
        name = name_match.group(1).decode("utf-8", "replace")
        filename = filename_match.group(1).decode("utf-8", "replace") if filename_match else None
        parts.append((name, filename, body))
    return parts


def _inflate(payload: bytes) -> tuple[bytes | None, str]:
    attempts = (
        (zlib.MAX_WBITS, "zlib"),
        (-zlib.MAX_WBITS, "raw-deflate"),
        (zlib.MAX_WBITS | 16, "gzip"),
    )
    for wbits, label in attempts:
        try:
            return zlib.decompress(payload, wbits), label
        except zlib.error:
            pass
    return None, "failed"


class ClientErrorCapture:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self.root = settings.runtime_log_dir
        self.root.mkdir(parents=True, exist_ok=True)

    def _append(self, filename: str, payload: dict[str, Any]) -> None:
        try:
            self.root.mkdir(parents=True, exist_ok=True)
            record = {"ts": int(time.time()), **payload}
            with (self.root / filename).open("a", encoding="utf-8") as fh:
                fh.write(json.dumps(record, ensure_ascii=False, default=str, separators=(",", ":")) + "\n")
        except Exception as exc:
            print(f"[CLIENT LOG] failed writing {filename}: {exc}")

    def capture(self, req: Request) -> dict[str, Any]:
        raw = req.get_data(cache=True) or b""
        content_type = req.headers.get("Content-Type", "")
        parts = _multipart_parts(raw, content_type)

        payload_bytes: bytes | None = None
        crash_parts: list[tuple[str, bytes]] = []
        text_fields: dict[str, str] = {}

        for name, filename, body in parts:
            if name == "payload" and filename is None:
                payload_bytes = body
            elif filename is not None:
                crash_parts.append((filename, body))
            else:
                text_fields[name] = body.decode("utf-8", "replace")

        # Fallbacks for non-multipart test clients or implementations where the
        # form parser retained the value cleanly.
        if payload_bytes is None and "payload" in req.form:
            value = req.form.get("payload", "")
            payload_bytes = value.encode("latin-1", "surrogateescape")

        if payload_bytes is not None:
            return self._capture_error_payload(payload_bytes, content_type, len(raw))

        if crash_parts or req.files:
            if not crash_parts:
                for _field, upload in req.files.items():
                    crash_parts.append((upload.filename or "crash.dmp", upload.read()))
                text_fields.update({key: value for key, value in req.form.items()})
            return self._capture_crash(text_fields, crash_parts, len(raw))

        self._append(
            "client_error_uploads.jsonl",
            {
                "kind": "unrecognized",
                "content_type": content_type,
                "body_bytes": len(raw),
            },
        )
        print(f"[CLIENT LOG] unrecognized upload content_type={content_type!r} bytes={len(raw)}")
        return {"kind": "unrecognized", "count": 0}

    def _capture_error_payload(self, payload: bytes, content_type: str, body_bytes: int) -> dict[str, Any]:
        inflated, encoding = _inflate(payload)
        decoded: Any = None
        decode_error = ""
        if inflated is not None:
            try:
                decoded = json.loads(inflated.decode("utf-8"))
            except Exception as exc:
                decode_error = f"json: {exc}"
        else:
            decode_error = "zlib inflate failed"

        entries: list[Any]
        if isinstance(decoded, list):
            entries = decoded
        elif decoded is not None:
            entries = [decoded]
        else:
            entries = []

        self._append(
            "client_error_uploads.jsonl",
            {
                "kind": "error_log",
                "content_type": content_type,
                "body_bytes": body_bytes,
                "payload_bytes": len(payload),
                "inflate": encoding,
                "entry_count": len(entries),
                "decode_error": decode_error,
            },
        )

        if entries:
            for entry in entries:
                if isinstance(entry, dict):
                    record = {"kind": "client_error", **entry}
                    message = str(entry.get("log", ""))
                else:
                    record = {"kind": "client_error", "log": entry}
                    message = str(entry)
                self._append("client_error_logs.jsonl", record)
                if message:
                    first_line = message.splitlines()[0][:500]
                    print(f"[CLIENT ERROR] {first_line}")
        else:
            # Preserve the exact compressed bytes for later offline decoding;
            # base64 keeps the JSONL text-safe without mutating the upload.
            self._append(
                "client_error_raw.jsonl",
                {
                    "kind": "error_log_raw",
                    "inflate": encoding,
                    "decode_error": decode_error,
                    "payload_b64": base64.b64encode(payload).decode("ascii"),
                },
            )
            print(f"[CLIENT LOG] error-log payload decode failed ({decode_error}); raw payload saved")

        return {"kind": "error_log", "count": len(entries), "inflate": encoding}

    def _capture_crash(self, fields: dict[str, str], files: list[tuple[str, bytes]], body_bytes: int) -> dict[str, Any]:
        crash_dir = self.root / "client_crash_uploads"
        crash_dir.mkdir(parents=True, exist_ok=True)
        saved: list[dict[str, Any]] = []
        stamp = int(time.time())
        for index, (filename, body) in enumerate(files):
            safe = _safe_name(filename, f"crash-{stamp}-{index}.dmp")
            path = crash_dir / f"{stamp}-{index}-{safe}"
            path.write_bytes(body)
            saved.append({"filename": safe, "bytes": len(body), "saved_as": str(path)})

        self._append(
            "client_error_uploads.jsonl",
            {
                "kind": "crash",
                "body_bytes": body_bytes,
                "fields": fields,
                "files": saved,
            },
        )
        print(f"[CLIENT CRASH] captured {len(saved)} file(s)")
        return {"kind": "crash", "count": len(saved)}
