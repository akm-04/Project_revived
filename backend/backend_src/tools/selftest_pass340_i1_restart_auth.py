#!/usr/bin/env python3
"""Pass340 I1 replacement for Pass278's pre-I1 restart-auth assumption.

Pass278 correctly tested persistence/realtime integration for the Pass299 model,
but its final restart probe issued gameplay MID17 immediately after a fresh SDK
login. I1 intentionally removes that account-token + caller-region actor
selection shortcut. This bounded replacement proves the new stock flow:
fresh SDK account session -> MID1 context selection -> gameplay token use, while
caller region is only a consistency fence.
"""
from __future__ import annotations

import json
import tempfile
from pathlib import Path

from gxb_backend.state.repository import StateRepository

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"


def require(value: object, message: str) -> None:
    if not value:
        raise AssertionError(message)


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="gxb-pass340-i1-restart-") as tmp_raw:
        tmp = Path(tmp_raw)
        state_root = tmp / "server_state"

        repo1 = StateRepository(DATA / "player_db.json", multiuser_root=state_root)
        _, status = repo1.sdk_register("pass340-i1-user", "pass340-i1-pass")
        require(status == "created", "account create failed")
        account1 = repo1.sdk_login("pass340-i1-user", "pass340-i1-pass")
        require(account1 is not None, "initial sdk login failed")

        with repo1.request_scope({"mid": 1, "sid": account1.sid, "region": 194}):
            player1, _ = repo1.resolve_or_create_player(194, "Local-194")
            player_id = str(player1.player_id)
        with repo1.request_scope({"mid": 17, "token": account1.token, "region": 194}):
            require(
                repo1.current_player_or_none() is not None
                and str(repo1.current_player_or_none().player_id) == player_id,
                "initial selected-context binding failed",
            )

        # Restart + new login yields account-session authority only. It may not
        # use the request region to select a gameplay actor before MID1.
        repo2 = StateRepository(DATA / "player_db.json", multiuser_root=state_root)
        account2 = repo2.sdk_login("pass340-i1-user", "pass340-i1-pass")
        require(account2 is not None, "restart sdk login failed")
        with repo2.request_scope({"mid": 17, "token": account2.token, "region": 194}):
            require(repo2.current_player_or_none() is None, "fresh account session bypassed MID1")

        # MID1 re-establishes the temporary I1 selected-context binding without
        # minting the future I3 PostgreSQL gameplay credential.
        with repo2.request_scope({"mid": 1, "sid": account2.sid, "region": 194}):
            player2, is_new = repo2.resolve_or_create_player(194, "Local-194")
            require(not is_new, "existing player unexpectedly recreated")
            require(str(player2.player_id) == player_id, "MID1 selected different persisted actor")
        with repo2.request_scope({"mid": 17, "token": account2.token, "region": 194}):
            require(
                repo2.current_player_or_none() is not None
                and str(repo2.current_player_or_none().player_id) == player_id,
                "gameplay did not bind MID1-selected actor",
            )
        with repo2.request_scope({"mid": 17, "token": account2.token, "region": 195}):
            require(repo2.current_player_or_none() is None, "caller region selected or widened actor")

        identity = repo2.resolve_realtime_identity(account2.token, 194)
        require(identity is not None and identity.player_id == player_id, "realtime selected actor mismatch")
        require(repo2.resolve_realtime_identity(account2.token, 195) is None, "realtime region widened actor")

    print(json.dumps({
        "pass": "340.0",
        "wave": "I1",
        "status": "PASS",
        "replacement_for": "Pass278 restart direct-gameplay assertion",
        "facts": {
            "fresh_sdk_session_requires_mid1": True,
            "selected_actor_comes_from_session_context_binding": True,
            "http_region_is_consistency_only": True,
            "realtime_region_is_consistency_only": True,
            "postgresql_required": False,
        },
    }, sort_keys=True, separators=(",", ":")))


if __name__ == "__main__":
    main()
