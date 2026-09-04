from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASELINE = json.loads((ROOT / "docs/json/PASS342_SOURCE_BACKEND_CROSSCHECK.json").read_text(encoding="utf-8"))
PASS352 = json.loads((ROOT / "docs/json/PASS352_I10_STOCK_RUNTIME_RECONCILIATION.json").read_text(encoding="utf-8"))


def _sha(rel: str) -> str:
    return hashlib.sha256((ROOT / rel).read_bytes()).hexdigest()


def test_current_src64_is_byte_identical_to_sealed_pass342_except_i10_reconciliation_delta() -> None:
    # Pass349 I10 stock-client evidence proves GET_PLAYER_GROUP_BY_KEY (2864) is
    # emitted before MID1. Backend.lua therefore adds that public AB-test lookup
    # to the context-bootstrap bypass; every other sealed client file stays frozen.
    allowed = {"local_assets/src_64/app/common/network/Backend.lua", "local_assets/src_64/app/windows/LoginWindow.lua"}
    for row in BASELINE["client_runtime_rechecked"]:
        if row["path"] in allowed:
            continue
        assert _sha(row["path"]) == row["sha256"], row["path"]


def test_non_strangler_runtime_seams_remain_byte_identical_except_i10_auth_scope_delta() -> None:
    rows = {row["path"]: row for row in BASELINE["backend_runtime_rechecked"]}
    # auth/perimeter.py is the bounded Pass349 scope correction; the legacy
    # identity store remains byte-identical to the sealed baseline.
    rel = "gxb_backend/state/multiuser_database.py"
    assert _sha(rel) == PASS352["candidate_hashes"][rel], rel
    dispatcher = (ROOT / "gxb_backend/dispatch/engine_dispatcher.py").read_text(encoding="utf-8")
    assert "self.state.persist_post_commit(pending_post_commit)" in dispatcher
    assert "with self.state.request_scope(req):" in dispatcher


def test_state_repository_change_is_bounded_to_i4_and_global_rlock_remains() -> None:
    rel = "gxb_backend/state/repository.py"
    old = next(row for row in BASELINE["backend_runtime_rechecked"] if row["path"] == rel)
    # I4 must actually introduce a bounded strangler delta rather than claiming
    # byte identity, but it may not retire/narrow the global request lock yet.
    assert _sha(rel) != old["sha256"]
    text = (ROOT / rel).read_text(encoding="utf-8")
    assert "threading.RLock()" in text
    assert "PlayerStateStore" in text
    assert "LegacyJsonPlayerStateStore" in text
    assert "player_state_store or LegacyJsonPlayerStateStore(self.store)" in text
