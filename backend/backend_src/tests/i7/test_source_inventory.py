from __future__ import annotations

import json
from pathlib import Path

import pytest

from gxb_backend.migration.source import MigrationSourceReader, SourceConflict
from gxb_backend.state.multiuser_database import MultiUserDatabase
from gxb_backend.state.player_database import JsonPlayerDatabase


def _fixture(root: Path, data: Path) -> Path:
    db = MultiUserDatabase(root, data)
    account, status = db.register_account("Case@Test", "password")
    assert status == "created" and account is not None
    db.issue_session(account, sid="a" * 32, token="retire-me")
    player = db.create_fresh_player(uid=str(account["uid"]), region=2, region_name="Local-2")
    player.persistence_state = {"state_version": 3, "receipts": {"domain": {"key": {"value": 1}}}, "claims": {"opaque": True}}
    player.mails = [{"id": 7, "title": "keep", "unknown": {"x": 1}}]
    db.save_player(player)
    return root


def test_inventory_is_strict_and_extracts_without_source_writes(tmp_path: Path) -> None:
    root = _fixture(tmp_path / "server_state", Path(__file__).resolve().parents[2] / "data")
    before = {p.relative_to(root).as_posix(): p.read_bytes() for p in root.rglob("*") if p.is_file()}
    inventory = MigrationSourceReader().inventory(root)
    after = {p.relative_to(root).as_posix(): p.read_bytes() for p in root.rglob("*") if p.is_file()}
    assert before == after
    assert inventory.counts["accounts"] == 1
    assert inventory.counts["players"] == 1
    assert inventory.counts["sessions_retired"] == 1
    assert inventory.counts["receipts"] == 1
    assert inventory.counts["mail"] == 1
    transformed = inventory.players[0].transformed
    assert transformed.record.state_version == 3
    assert "receipts" not in transformed.record.payload["domains"]["persistence_state"]
    assert transformed.record.payload["domains"]["persistence_state"]["claims"] == {"opaque": True}
    assert "mails" not in transformed.record.payload["lobby"]
    assert transformed.record.payload["identity"].get("token") is None


def test_ownership_contradiction_blocks(tmp_path: Path) -> None:
    root = _fixture(tmp_path / "server_state", Path(__file__).resolve().parents[2] / "data")
    index_path = root / "indexes/player_by_account_region.json"
    index = json.loads(index_path.read_text())
    uid = next(iter(index))
    index[uid]["2"] = "299999"
    JsonPlayerDatabase.atomic_write_json(index_path, index)
    with pytest.raises(SourceConflict, match="ownership|exact set"):
        MigrationSourceReader().inventory(root)


def test_snapshot_is_byte_exact_and_mutation_is_detected(tmp_path: Path) -> None:
    root = _fixture(tmp_path / "server_state", Path(__file__).resolve().parents[2] / "data")
    reader = MigrationSourceReader()
    snapshot = reader.snapshot(root, tmp_path / "snapshot")
    assert snapshot.content_root == reader.inventory(root).content_root
    account_path = next((tmp_path / "snapshot/accounts").glob("*.json"))
    account_path.write_bytes(account_path.read_bytes() + b"\n")
    with pytest.raises(SourceConflict, match="no longer matches"):
        reader.assert_stable(snapshot)


def test_snapshot_refuses_existing_or_nested_destination(tmp_path: Path) -> None:
    root = _fixture(tmp_path / "server_state", Path(__file__).resolve().parents[2] / "data")
    reader = MigrationSourceReader()
    existing = tmp_path / "existing"
    existing.mkdir()
    with pytest.raises(SourceConflict, match="already exists"):
        reader.snapshot(root, existing)
    with pytest.raises(SourceConflict, match="inside"):
        reader.snapshot(root, root / "nested")


def test_malformed_player_json_blocks(tmp_path: Path) -> None:
    root = _fixture(tmp_path / "server_state", Path(__file__).resolve().parents[2] / "data")
    player_path = next((root / "players").glob("*/player.json"))
    player_path.write_text("{", encoding="utf-8")
    with pytest.raises(SourceConflict, match="strict JSON parse"):
        MigrationSourceReader().inventory(root)


def test_duplicate_json_key_blocks(tmp_path: Path) -> None:
    root = _fixture(tmp_path / "server_state", Path(__file__).resolve().parents[2] / "data")
    index_path = root / "indexes/counters.json"
    index_path.write_text('{"next_uid":20000002,"next_uid":20000003}\n', encoding="utf-8")
    with pytest.raises(SourceConflict, match="strict JSON parse"):
        MigrationSourceReader().inventory(root)


def test_account_index_must_be_exact_projection(tmp_path: Path) -> None:
    root = _fixture(tmp_path / "server_state", Path(__file__).resolve().parents[2] / "data")
    index_path = root / "indexes/account_by_login.json"
    index = json.loads(index_path.read_text())
    index["extra-alias"] = next(iter(index.values()))
    JsonPlayerDatabase.atomic_write_json(index_path, index)
    with pytest.raises(SourceConflict, match="exact account-record projection"):
        MigrationSourceReader().inventory(root)
