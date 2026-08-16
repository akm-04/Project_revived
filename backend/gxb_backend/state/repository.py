"""Canonical player repository backed by a human-editable JSON text file."""

from __future__ import annotations

import json
import threading
from dataclasses import asdict
from pathlib import Path

from .account import AccountIdentity
from .defaults import default_account, default_player
from .player_database import JsonPlayerDatabase
from .player_state import PlayerState
from .profiles import apply_profile


class StateRepository:
    """Own the single canonical account/player record.

    Stage 3.1 deliberately favors a text database over SQLite. The file is read
    before every request (via ``refresh``), which makes live value tweaking easy
    during APK compatibility work. Handler mutations call ``save`` and are
    written atomically.
    """

    def __init__(
        self,
        path: Path | None = None,
        profile: str = "established",
        legacy_path: Path | None = None,
    ) -> None:
        self.path = Path(path) if path else None
        self.legacy_path = Path(legacy_path) if legacy_path else None
        self.profile = profile
        self._lock = threading.RLock()

        # Profiles are initialization defaults now, not forced overrides. Once a
        # JSON database exists, explicit file values win so the user can test any
        # level/guide/currency/roster combination without editing Python.
        self.account = default_account()
        self.player = apply_profile(default_player(), profile)
        self.database = JsonPlayerDatabase(self.path) if self.path else None

        with self._lock:
            if self.database and self.database.exists():
                self._load_database()
            elif self._migrate_legacy_if_available():
                self.save()
            elif self.database:
                self.save()

    def _load_database(self) -> None:
        if not self.database:
            return
        try:
            base_account = default_account()
            base_player = apply_profile(default_player(), self.profile)
            self.account, self.player = self.database.load(base_account, base_player)
        except Exception as exc:
            # Keep the last known-good in-memory copy when a hand edit is
            # temporarily invalid JSON. This makes iterative editing recoverable.
            print(f"[PLAYER DB] could not load {self.path}: {exc}")

    def _migrate_legacy_if_available(self) -> bool:
        path = self.legacy_path
        if not path or not path.exists() or (self.path and path.resolve() == self.path.resolve()):
            return False
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            account_data = data.get("account") or {}
            player_data = data.get("player") or {}
            account_values = {**asdict(default_account()), **account_data}
            player_values = {**asdict(apply_profile(default_player(), self.profile)), **player_data}
            self.account = AccountIdentity(**account_values)
            self.player = PlayerState(**player_values)
            print(f"[PLAYER DB] migrated legacy state from {path} -> {self.path}")
            return True
        except Exception as exc:
            print(f"[PLAYER DB] could not migrate legacy state {path}: {exc}")
            return False

    def refresh(self) -> None:
        """Re-read the text database before handling a client request."""
        with self._lock:
            if self.database and self.database.exists():
                self._load_database()

    def save(self) -> None:
        with self._lock:
            if not self.database:
                return
            try:
                self.database.save(self.account, self.player)
            except Exception as exc:
                print(f"[PLAYER DB] could not save {self.path}: {exc}")

    def get_account(self) -> AccountIdentity:
        return self.account

    def get_player(self) -> PlayerState:
        return self.player

    def set_region(self, region: int) -> None:
        self.player.set_region(int(region))
        self.save()
