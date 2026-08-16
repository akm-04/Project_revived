"""Small JSON-backed repository used by Stage 1 handlers.

The default remains deterministic and in-memory. The JSON file is optional and
intended for future stateful gameplay work; Stage 1 avoids complex database
requirements.
"""

from __future__ import annotations

import json
from dataclasses import asdict
from pathlib import Path
from typing import Any

from .account import AccountIdentity
from .defaults import default_account, default_player
from .player_state import PlayerState


class StateRepository:
    def __init__(self, path: Path | None = None) -> None:
        self.path = path
        self.account = default_account()
        self.player = default_player()
        if path:
            self._try_load(path)

    def _try_load(self, path: Path) -> None:
        try:
            if not path.exists():
                return
            data = json.loads(path.read_text(encoding="utf-8"))
            account_data = data.get("account") or {}
            player_data = data.get("player") or {}
            self.account = AccountIdentity(**{**asdict(self.account), **account_data})
            self.player = PlayerState(**{**asdict(self.player), **player_data})
        except Exception as exc:
            print(f"[STATE] could not load {path}: {exc}")

    def save(self) -> None:
        if not self.path:
            return
        try:
            self.path.parent.mkdir(parents=True, exist_ok=True)
            payload: dict[str, Any] = {
                "account": asdict(self.account),
                "player": asdict(self.player),
            }
            self.path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")
        except Exception as exc:
            print(f"[STATE] could not save {self.path}: {exc}")

    def get_account(self) -> AccountIdentity:
        return self.account

    def get_player(self) -> PlayerState:
        return self.player

    def set_region(self, region: int) -> None:
        self.player.set_region(int(region))
        self.save()
