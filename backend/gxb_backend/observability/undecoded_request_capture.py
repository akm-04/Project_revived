"""Capture otherwise invisible engine requests that fail payload decoding."""

from __future__ import annotations

import base64
import json
import time
from pathlib import Path
from typing import Any

from flask import Request

from gxb_backend.config import Settings


class UndecodedRequestCapture:
    def __init__(self, settings: Settings) -> None:
        self.root: Path = settings.runtime_log_dir
        self.root.mkdir(parents=True, exist_ok=True)

    @staticmethod
    def _safe_headers(req: Request) -> dict[str, str]:
        keep = {
            "content-type",
            "content-length",
            "user-agent",
            "accept",
            "accept-encoding",
            "connection",
        }
        return {
            key: value
            for key, value in req.headers.items()
            if key.lower() in keep
        }

    def capture(self, req: Request, *, label: str, source: str, decode_method: str) -> None:
        try:
            raw = req.get_data(cache=True) or b""
            record: dict[str, Any] = {
                "ts": int(time.time()),
                "label": label,
                "path": req.path,
                "method": req.method,
                "remote_addr": req.remote_addr or "",
                "content_type": req.content_type or "",
                "content_length": req.content_length,
                "source": source,
                "decode_method": decode_method,
                "headers": self._safe_headers(req),
                "query": {k: req.args.getlist(k) for k in req.args.keys()},
                "form_keys": sorted(req.form.keys()),
                "file_keys": sorted(req.files.keys()),
                "raw_body_len": len(raw),
                "raw_body_hex_prefix": raw[:256].hex(),
                "raw_body_b64_prefix": base64.b64encode(raw[:4096]).decode("ascii"),
            }
            with (self.root / "undecoded_engine_requests.jsonl").open("a", encoding="utf-8") as fh:
                fh.write(json.dumps(record, ensure_ascii=False, separators=(",", ":")) + "\n")
        except Exception as exc:
            print(f"[UNDECODED] capture failed: {type(exc).__name__}: {exc}")
