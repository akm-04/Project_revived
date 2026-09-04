from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

from gxb_backend.migration.source import MigrationSourceReader
from gxb_backend.state.multiuser_database import MultiUserDatabase, SANDBOX_UID

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data"


def test_legacy_sandbox_region_move_is_remapped_not_relocated(tmp_path: Path) -> None:
    source = tmp_path / "server_state"
    db = MultiUserDatabase(source, DATA)
    # Ensure the full set of legacy indexes exists, including counters.json.
    account, status = db.register_account("fixture@example", "password")
    assert status == "created" and account is not None
    player = db.import_legacy_sandbox(DATA / "player_db.json", profile="established")
    original_crystal = int(player.crystal)
    original_inventory_count = len(player.backpack_items)
    assert str(player.player_id) == "12525385" and int(player.region) == 125

    player.set_region(194)
    db.save_player(player)
    db.move_account_region_player(SANDBOX_UID, 125, 194, str(player.player_id))

    destination = tmp_path / "normalized"
    report = tmp_path / "report.json"
    subprocess.run(
        [
            sys.executable,
            str(ROOT / "tools/dev_legacy_sandbox_normalize.py"),
            "--source-root", str(source),
            "--destination", str(destination),
            "--singleton", str(DATA / "player_db.json"),
            "--report", str(report),
        ],
        check=True,
        capture_output=True,
        text=True,
    )

    payload = json.loads(report.read_text(encoding="utf-8"))
    assert payload["adjustment"] == "LEGACY_SANDBOX_REGION_PLAYER_ID_REMAP"
    assert payload["active_region_preserved"] == 194
    assert payload["source_player_id"] == "12525385"
    assert payload["target_player_id"] == "19425385"
    assert payload["source_untouched"] is True

    inventory = MigrationSourceReader().inventory(destination)
    migrated = next(p for p in inventory.players if p.account_uid == SANDBOX_UID)
    assert migrated.player_id == 19425385
    assert migrated.region_id == 194
    assert migrated.transformed.record.payload["economy"]["crystal"] == original_crystal
    assert len(migrated.transformed.record.payload["inventory"]["backpack_items"]) == original_inventory_count

    encoded = json.dumps(migrated.transformed.record.payload, sort_keys=True)
    assert '"12525385"' not in encoded
    assert '"19425385"' in encoded

    original = json.loads((source / "players/12525385/player.json").read_text(encoding="utf-8"))
    assert original["player"]["identity"]["region"] == 194
    assert original["player"]["identity"]["player_id"] == "12525385"
