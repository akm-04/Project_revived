#!/usr/bin/env python3
"""Build a representative Pass299-format server_state through current backend APIs."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from gxb_backend.state.multiuser_database import MultiUserDatabase
from gxb_backend.state.player_database import JsonPlayerDatabase


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination")
    parser.add_argument("--oversized-receipt-key", action="store_true", help="build an import-rollback failure fixture")
    args = parser.parse_args()
    destination = Path(args.destination).resolve()
    if destination.exists():
        raise SystemExit(f"destination already exists: {destination}")
    database = MultiUserDatabase(destination, ROOT / "data")
    sandbox = database.import_legacy_sandbox(ROOT / "data/player_db.json", profile="established")

    alpha, alpha_status = database.register_account("Alpha.Example", "alpha-test-password")
    beta, beta_status = database.register_account("Beta.Example", "beta-test-password")
    if alpha_status != "created" or beta_status != "created" or alpha is None or beta is None:
        raise RuntimeError("fixture accounts were not created")
    alpha_session = database.issue_session(alpha, sid="a" * 32, token="alpha-legacy-bearer", device={"fixture": True})
    database.issue_session(beta, sid="b" * 32, token="beta-legacy-bearer")

    alpha_player = database.create_fresh_player(uid=str(alpha["uid"]), region=2, region_name="Local-2")
    beta_player = database.create_fresh_player(uid=str(beta["uid"]), region=2, region_name="Local-2")
    alpha_second = database.create_fresh_player(uid=str(alpha["uid"]), region=125, region_name="Deep Valley")
    database.bind_session_context(alpha_session, player_id=str(alpha_player.player_id), region=2)

    receipt_key = "x" * 260 if args.oversized_receipt_key else "logical-op-1"
    alpha_player.persistence_state = {
        "state_version": 7,
        "receipts": {
            "summon": {
                receipt_key: {
                    "request_fingerprint": "fixture-request",
                    "result": {"heroes": [10001001], "unknown_receipt_extension": {"kept": True}},
                    "committed_at": 1700000000,
                }
            }
        },
        "claims": {"opaque-unowned-claim": {"must_survive": [1, 2, 3]}},
    }
    alpha_player.mails = [
        {"id": 41, "is_region": 0, "title": "first", "is_read": 1, "is_awarded": 0, "attachments": [{"item_id": 1, "num": 2}], "unknown_mail_extension": {"a": 1}},
        {"id": 41, "is_region": 0, "title": "collision", "is_read": 0, "is_awarded": 1, "unknown_mail_extension": {"b": 2}},
        {"title": "missing-id", "is_region": 1, "is_read": 0, "is_awarded": 0},
    ]
    database.save_player(alpha_player)

    player_path = database.player_path(str(alpha_player.player_id))
    player_document = json.loads(player_path.read_text(encoding="utf-8"))
    player_document["player"]["future_private_extension"] = {"nested": ["preserve", {"exact": True}]}
    JsonPlayerDatabase.atomic_write_json(player_path, player_document)

    # Exercise the only permitted allocator repair: cursors may be behind durable IDs.
    JsonPlayerDatabase.atomic_write_json(database.region_counter_path, {"2": 1, "125": 1})
    JsonPlayerDatabase.atomic_write_json(database.counters_path, {"next_uid": 20_000_001})

    summary = {
        "root": str(destination),
        "accounts": 3,
        "players": 4,
        "sessions": 3,
        "failure_fixture": bool(args.oversized_receipt_key),
        "fixture_player_ids": [int(sandbox.player_id), int(alpha_player.player_id), int(beta_player.player_id), int(alpha_second.player_id)],
    }
    print(json.dumps(summary, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
