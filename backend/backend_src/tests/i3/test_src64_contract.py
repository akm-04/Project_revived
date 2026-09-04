from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC64 = ROOT / "local_assets" / "src_64"
PASS340_RUNTIME = ROOT / "docs/json/PASS340_RUNTIME_DELTA_MANIFEST.json"
PASS349_RECON = ROOT / "docs/json/PASS349_I10_PRELOGIN_MID2864_RECONCILIATION.json"
PASS352_RECON = ROOT / "docs/json/PASS352_I10_STOCK_RUNTIME_RECONCILIATION.json"


def _text(relative: str) -> str:
    return (SRC64 / relative).read_text(encoding="utf-8")


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _pass340_expected_runtime() -> dict[str, str]:
    data = json.loads(PASS340_RUNTIME.read_text(encoding="utf-8"))
    expected = dict(data["baseline_sha256_by_path"])
    expected.update(data["allowed_modified_sha256"])
    expected.update(data["allowed_added_sha256"])
    return expected


def test_loading_scene_mid1_wire_shape_and_single_flight_remain_source_grounded() -> None:
    text = _text("app/scenes/LoadingScene.lua")
    assert "if arg_29_0.isLoggingIn_ then" in text
    assert "arg_29_0.isLoggingIn_ = true" in text
    assert "arg_29_0.isLoggingIn_ = false" in text
    assert "sid = arg_29_1.sid" in text
    assert "login_token = arg_29_0.token" in text
    assert "region = arg_29_1.region.region_id" in text


def test_login_window_mid18_supports_sdk_pair_and_manual_sid_only() -> None:
    text = _text("app/windows/LoginWindow.lua")
    assert "var_1_1.sid = arg_1_0.sid" in text
    assert "var_1_1.login_token = arg_1_0.token" in text
    assert "xyd.Backend.get():request(xyd.mid.LOAD_USER_REGIONS" in text
    # Stock/manual compatibility path: SID alone is sufficient for MID18.
    assert 'sid = arg_1_0:nodeByName("sid_txt"):getString()' in text


def test_backend_mid1_response_token_becomes_context_bound_gameplay_token() -> None:
    text = _text("app/common/network/Backend.lua")
    # I1 helper admits account/context bootstrap calls while context is not ready.
    assert "xyd.mid.RETRIEVE_TOKEN" in text
    assert "xyd.mid.LOAD_USER_REGIONS" in text
    # MID1 response installs the returned token into the ordinary request bearer slot.
    marker = "if arg_23_1 == xyd.mid.RETRIEVE_TOKEN then"
    start = text.index(marker)
    window = text[start : start + 1200]
    assert "arg_23_0.token_ = arg_27_0.token" in window


def test_epoch_fence_still_precedes_global_response_processing() -> None:
    text = _text("app/common/network/Backend.lua")
    stale = text.index("if var_23_epoch ~= (arg_23_0.contextEpoch_ or 0) then")
    global_check = text.index("arg_23_0:extraWebResponseCheck_", stale)
    assert stale < global_check


def test_i3_does_not_modify_current_src64() -> None:
    """Every authoritative src_64 file must remain byte-identical to sealed Pass341."""
    current = ROOT / "local_assets" / "src_64"
    prefix = "local_assets/src_64/"
    expected = {
        rel[len(prefix):]: digest
        for rel, digest in _pass340_expected_runtime().items()
        if rel.startswith(prefix)
    }
    # Pass349 explicitly authorizes the stock compatibility delta in Backend.lua;
    # historical Pass340 hashes remain immutable provenance for every other file.
    p349 = json.loads(PASS349_RECON.read_text(encoding="utf-8"))
    expected["app/common/network/Backend.lua"] = p349["candidate_hashes"]["local_assets/src_64/app/common/network/Backend.lua"]
    # Pass352 authorizes account-scoped MID18 reconciliation in LoginWindow.
    p352 = json.loads(PASS352_RECON.read_text(encoding="utf-8"))
    expected["app/windows/LoginWindow.lua"] = p352["candidate_hashes"]["local_assets/src_64/app/windows/LoginWindow.lua"]
    current_files = sorted(p.relative_to(current).as_posix() for p in current.rglob("*") if p.is_file())
    assert current_files == sorted(expected)
    mismatches = [
        rel
        for rel in current_files
        if _sha256(current / rel) != expected[rel]
    ]
    assert mismatches == []


def test_i1_perimeter_mid_scopes_are_unchanged_by_i3() -> None:
    current = ROOT / "gxb_backend" / "auth" / "perimeter.py"
    p349 = json.loads(PASS349_RECON.read_text(encoding="utf-8"))
    expected = p349["candidate_hashes"]["gxb_backend/auth/perimeter.py"]
    assert _sha256(current) == expected
    text = current.read_text(encoding="utf-8")
    # Keep these deliberately lexical: this is a compatibility tripwire, not a
    # duplicate implementation of the classifier.
    assert "18" in text and "ACCOUNT_SESSION" in text
    assert "1" in text and "CONTEXT_SELECTION" in text
    assert "20_480" in text and "PUBLIC_BOOTSTRAP" in text
