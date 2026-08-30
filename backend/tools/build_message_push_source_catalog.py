#!/usr/bin/env python3
"""Build the current-src64 MessagePush source catalog deterministically.

Usage:
  python tools/build_message_push_source_catalog.py --src64-root /path/to/src_64 \
      [--output data/message_push_source_catalog.json]

This tool intentionally reads only current source files and does not infer any
server-side behavior beyond the client's numeric message type/title/tip table.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

_TABLE_REL = Path("data/tables/message_push.lua")
_MODEL_REL = Path("app/model/MessagePush.lua")
_ROW_RE = re.compile(
    r'\{\s*"(\d+)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*\}',
    re.S,
)


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _lua_string(value: str) -> str:
    # Current table contains ordinary UTF-8 strings; decode simple Lua-style
    # escapes deterministically without evaluating Lua.
    return bytes(value, "utf-8").decode("unicode_escape")


def build(src64_root: Path) -> dict:
    src64_root = Path(src64_root)
    table_path = src64_root / _TABLE_REL
    model_path = src64_root / _MODEL_REL
    table_bytes = table_path.read_bytes()
    model_bytes = model_path.read_bytes()
    text = table_bytes.decode("utf-8-sig")
    rows = [
        {
            "message_type": int(message_type),
            "title": _lua_string(title),
            "tip": _lua_string(tip),
        }
        for message_type, title, tip in _ROW_RE.findall(text)
    ]
    ids = [row["message_type"] for row in rows]
    if ids != list(range(1, 13)):
        raise ValueError(f"current MessagePush source census drift: {ids}")
    return {
        "schema_version": 1,
        "classification": "CURRENT_SRC64_GENERATED_SOURCE_CATALOG",
        "source_metadata": {
            "src64_root": str(src64_root),
            "table_path": str(_TABLE_REL).replace("\\", "/"),
            "table_sha256": _sha256(table_bytes),
            "model_path": str(_MODEL_REL).replace("\\", "/"),
            "model_sha256": _sha256(model_bytes),
            "consumer_fact": (
                "MessagePush.update iterates enabled message type IDs with ipairs; "
                "setState uses MID1025/1026 and message_type."
            ),
        },
        "message_types": rows,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--src64-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("data/message_push_source_catalog.json"))
    args = parser.parse_args()
    payload = build(args.src64_root)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({
        "status": "PASS",
        "output": str(args.output),
        "message_type_count": len(payload["message_types"]),
        "table_sha256": payload["source_metadata"]["table_sha256"],
        "model_sha256": payload["source_metadata"]["model_sha256"],
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
