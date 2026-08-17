#!/usr/bin/env python3
"""Print a redacted summary of v0.8.0 accounts/sessions/player ownership."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def load(path: Path, default):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return default


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default="data/server_state")
    args = parser.parse_args()
    root = Path(args.root)
    account_index = load(root / "indexes/account_by_login.json", {})
    player_index = load(root / "indexes/player_by_account_region.json", {})

    print(f"root: {root}")
    print("accounts:")
    for login, uid in sorted(account_index.items()):
        account = load(root / "accounts" / f"{uid}.json", {})
        print(
            f"  uid={uid} login={account.get('login', login)!r} "
            f"type={account.get('account_type', '')} regions={player_index.get(str(uid), {})}"
        )

    print("sessions:")
    for path in sorted((root / "sessions").glob("*.json")) if (root / "sessions").exists() else []:
        row = load(path, {})
        token = str(row.get("token", ""))
        redacted = token[:6] + "..." if token else ""
        print(
            f"  sid={row.get('sid','')} uid={row.get('uid','')} "
            f"token={redacted} revoked={row.get('revoked', False)}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
