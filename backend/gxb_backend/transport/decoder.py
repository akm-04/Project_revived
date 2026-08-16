"""Payload decoding for the Lua client.

Normal Backend.lua traffic posts a form field named `payload`; selected battle
result paths post zlib-deflated JSON in the same field, sometimes as multipart
file data. This decoder is intentionally permissive and logs the decode mode.
"""

from __future__ import annotations

import json
import urllib.parse
import zlib
from typing import Any

from flask import Request


DecodeResult = tuple[dict[str, Any] | None, str]


def _json_loads_text(text: str) -> dict[str, Any] | None:
    value = json.loads(text)
    return value if isinstance(value, dict) else None


def decode_payload(raw: bytes | str | None) -> DecodeResult:
    if raw is None:
        return None, "empty"

    if isinstance(raw, str):
        raw_text = raw
        raw_bytes = raw.encode("latin1", "replace")
    else:
        raw_bytes = bytes(raw)
        raw_text = raw_bytes.decode("utf-8", "replace")

    text_candidates = [
        (raw_text, "plain-json"),
        (urllib.parse.unquote_plus(raw_text), "url-decoded-json"),
        (urllib.parse.unquote(urllib.parse.unquote_plus(raw_text)), "double-url-decoded-json"),
    ]
    for text, method in text_candidates:
        try:
            value = _json_loads_text(text)
            if value is not None:
                return value, method
        except Exception:
            pass

    binary_candidates = [
        (raw_bytes, "zlib-json"),
        (urllib.parse.unquote_to_bytes(raw_text), "url-decoded-zlib-json"),
    ]
    for blob, method in binary_candidates:
        try:
            value = _json_loads_text(zlib.decompress(blob).decode("utf-8"))
            if value is not None:
                return value, method
        except Exception:
            pass

    return None, "undecoded"


def extract_engine_payload(request: Request) -> tuple[bytes | str | None, str]:
    if "payload" in request.form:
        return request.form.get("payload"), "form-payload"
    if "payload" in request.files:
        return request.files["payload"].read(), "multipart-payload"
    if request.data:
        return request.data, "raw-body"
    return None, "empty"


def decode_sdk_body(request: Request) -> dict[str, Any] | None:
    body = request.get_json(silent=True)
    if isinstance(body, dict):
        return body
    raw = request.form.get("payload")
    if raw:
        try:
            value = json.loads(raw)
            if isinstance(value, dict):
                return value
        except Exception:
            return None
    return None
