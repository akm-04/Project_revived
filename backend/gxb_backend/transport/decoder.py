"""Payload decoding for the Lua client.

Normal Backend.lua traffic posts a form field named ``payload``. Selected
paths use zlib-deflated JSON in that field and some builds submit the bytes as
URL-encoded form data. Flask's form parser may decode binary payloads into a
Unicode string before we see them, so Stage 4A.9 first inspects the cached raw
request body and extracts the form value losslessly when possible.
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


def _zlib_json(blob: bytes, wbits: int, label: str) -> DecodeResult:
    try:
        value = _json_loads_text(zlib.decompress(blob, wbits).decode("utf-8"))
        if value is not None:
            return value, label
    except Exception:
        pass
    return None, ""


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

    byte_candidates: list[tuple[bytes, str]] = [(raw_bytes, "binary")]
    try:
        byte_candidates.append((urllib.parse.unquote_to_bytes(raw_text.replace("+", " ")), "url-decoded-binary"))
    except Exception:
        pass

    # Accept zlib wrapper, raw DEFLATE and gzip wrapper. The transport matrix
    # still decides which semantic MIDs should normally use these encodings.
    for blob, prefix in byte_candidates:
        for wbits, suffix in (
            (zlib.MAX_WBITS, "zlib-json"),
            (-zlib.MAX_WBITS, "raw-deflate-json"),
            (zlib.MAX_WBITS | 16, "gzip-json"),
        ):
            value, method = _zlib_json(blob, wbits, f"{prefix}-{suffix}")
            if value is not None:
                return value, method

    return None, "undecoded"


def _extract_urlencoded_payload_bytes(raw_body: bytes) -> bytes | None:
    """Extract payload= from urlencoded bytes without Unicode loss."""
    if not raw_body:
        return None
    for part in raw_body.split(b"&"):
        key, sep, value = part.partition(b"=")
        if not sep:
            continue
        try:
            decoded_key = urllib.parse.unquote_to_bytes(key.replace(b"+", b" ")).decode("utf-8", "replace")
        except Exception:
            continue
        if decoded_key != "payload":
            continue
        try:
            return urllib.parse.unquote_to_bytes(value.replace(b"+", b" "))
        except Exception:
            return value
    return None


def extract_engine_payload(request: Request) -> tuple[bytes | str | None, str]:
    # Cache the body before touching request.form. This preserves binary zlib
    # form payloads which Flask can otherwise coerce to text.
    raw_body = request.get_data(cache=True) or b""
    content_type = (request.content_type or "").lower()

    if "application/x-www-form-urlencoded" in content_type:
        raw_payload = _extract_urlencoded_payload_bytes(raw_body)
        if raw_payload is not None:
            return raw_payload, "raw-urlencoded-payload"

    if "payload" in request.files:
        return request.files["payload"].read(), "multipart-payload"
    if "payload" in request.form:
        return request.form.get("payload"), "form-payload"
    if raw_body:
        return raw_body, "raw-body"
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
