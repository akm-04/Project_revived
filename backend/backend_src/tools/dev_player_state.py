#!/usr/bin/env python3
"""Development-only export/import of one PostgreSQL player JSONB aggregate.

This tool deliberately refuses non-*_test databases.  It is intended for
operator QA surgery while the HTTP/realtime/scheduler stack is stopped.
Identity columns stay relational and immutable; only the JSONB payload is
editable.  Imports use optimistic state_version matching and bump the version.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

from sqlalchemy import select, update

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from gxb_backend.foundation.database import DatabaseSettings, ProcessEngineProvider
from gxb_backend.persistence.schema import players


def provider() -> ProcessEngineProvider:
    settings = DatabaseSettings.from_env(dict(os.environ))
    if not str(settings.url.database or "").endswith("_test"):
        raise SystemExit("dev player-state surgery requires a database name ending in _test")
    return ProcessEngineProvider(settings)


def document(row) -> dict:
    return {
        "format": "GXB_DEV_PLAYER_JSONB_V1",
        "player_id": int(row["player_id"]),
        "account_uid": str(row["account_uid"]),
        "region_id": int(row["region_id"]),
        "schema_version": int(row["schema_version"]),
        "state_version": int(row["state_version"]),
        "payload": dict(row["payload"] or {}),
    }


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    sub = ap.add_subparsers(dest="command", required=True)
    ex = sub.add_parser("export")
    ex.add_argument("player_id", type=int)
    ex.add_argument("output")
    im = sub.add_parser("import")
    im.add_argument("player_id", type=int)
    im.add_argument("input")
    im.add_argument("--confirmation", required=True)
    args = ap.parse_args()

    db = provider()
    try:
        if args.command == "export":
            with db.engine().connect() as c:
                row = c.execute(select(players).where(players.c.player_id == args.player_id)).mappings().first()
            if row is None:
                raise SystemExit(f"player not found: {args.player_id}")
            out = Path(args.output)
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(json.dumps(document(row), ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
            print(json.dumps({"status":"EXPORTED","player_id":args.player_id,"state_version":int(row["state_version"]),"path":str(out)}, sort_keys=True))
            return

        expected_confirmation = f"IMPORT DEV PLAYER {args.player_id}"
        if args.confirmation != expected_confirmation:
            raise SystemExit(f"exact confirmation required: {expected_confirmation!r}")
        inp = Path(args.input)
        body = json.loads(inp.read_text(encoding="utf-8"))
        if body.get("format") != "GXB_DEV_PLAYER_JSONB_V1":
            raise SystemExit("unsupported dev player document format")
        if int(body.get("player_id", -1)) != args.player_id:
            raise SystemExit("player_id in document does not match command")
        if not isinstance(body.get("payload"), dict):
            raise SystemExit("payload must be a JSON object")
        expected_version = int(body.get("state_version", -1))
        with db.engine().begin() as c:
            current = c.execute(select(players).where(players.c.player_id == args.player_id).with_for_update()).mappings().first()
            if current is None:
                raise SystemExit(f"player not found: {args.player_id}")
            for key in ("account_uid", "region_id", "schema_version"):
                if str(body.get(key)) != str(current[key]):
                    raise SystemExit(f"refusing typed identity/schema change through payload editor: {key}")
            if int(current["state_version"]) != expected_version:
                raise SystemExit(f"stale export: database state_version={current['state_version']} file={expected_version}; re-export before editing")
            new_version = expected_version + 1
            changed = c.execute(
                update(players)
                .where(players.c.player_id == args.player_id, players.c.state_version == expected_version)
                .values(payload=body["payload"], state_version=new_version)
            )
            if int(changed.rowcount or 0) != 1:
                raise SystemExit("optimistic player update failed")
        print(json.dumps({"status":"IMPORTED","player_id":args.player_id,"old_state_version":expected_version,"new_state_version":new_version}, sort_keys=True))
    finally:
        db.dispose()


if __name__ == "__main__":
    main()
