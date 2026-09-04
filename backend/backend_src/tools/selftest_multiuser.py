#!/usr/bin/env python3
"""Offline v0.8.0 identity/player-isolation smoke test.

Does not start Flask, open sockets, or touch the real data/server_state tree.
"""

from __future__ import annotations

from pathlib import Path
from tempfile import TemporaryDirectory
import sys

PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from gxb_backend.state.repository import StateRepository


def main() -> int:
    project = PROJECT_ROOT
    legacy = project / "data/player_db.json"
    with TemporaryDirectory(prefix="gxb-v080-selftest-") as td:
        root = Path(td)
        repo = StateRepository(
            legacy,
            profile="established",
            multiuser_root=root / "server_state",
        )

        a, a_status = repo.sdk_register("selftest01", "pass1234")
        b, b_status = repo.sdk_register("selftest02", "pass5678")
        assert a and b and a_status == b_status == "created"
        assert a["uid"] != b["uid"]

        ia = repo.sdk_login("selftest01", "pass1234")
        ib = repo.sdk_login("selftest02", "pass5678")
        assert ia and ib
        assert ia.uid != ib.uid and ia.sid != ib.sid and ia.token != ib.token

        with repo.request_scope({"mid": 1, "sid": ia.sid, "login_token": ia.token, "region": 197}):
            pa, is_new = repo.resolve_or_create_player(197)
            assert is_new and pa.lev == 1 and pa.player_name == ""
            pa.mana = 123
            repo.save()
            pa_id = pa.player_id

        with repo.request_scope({"mid": 1, "sid": ib.sid, "login_token": ib.token, "region": 197}):
            pb, is_new = repo.resolve_or_create_player(197)
            assert is_new and pb.player_id != pa_id and pb.mana == 0
            pb_id = pb.player_id

        with repo.request_scope({"mid": 1, "sid": ia.sid, "login_token": ia.token, "region": 197}):
            pa2, is_new = repo.resolve_or_create_player(197)
            assert not is_new and pa2.player_id == pa_id and pa2.mana == 123

        with repo.request_scope({"mid": 18, "sid": ia.sid, "login_token": ia.token}):
            assert [p.player_id for p in repo.list_account_players()] == [pa_id]
        with repo.request_scope({"mid": 18, "sid": ib.sid, "login_token": ib.token}):
            assert [p.player_id for p in repo.list_account_players()] == [pb_id]

        anon = repo.sdk_anonymous_identity()
        with repo.request_scope({"mid": 1, "sid": anon.sid, "login_token": anon.token, "region": 197}):
            sandbox, is_new = repo.resolve_or_create_player(197)
            assert not is_new
            assert sandbox.mana == 999999 and sandbox.crystal == 999999

        print("PASS v0.8.0 multi-user isolation self-test")
        print(f" account A uid={ia.uid} player={pa_id}")
        print(f" account B uid={ib.uid} player={pb_id}")
        print(f" sandbox uid={anon.uid} player={sandbox.player_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
