"""Canonical player repository backed by a human-editable JSON text file."""

from __future__ import annotations

import json
import threading
from contextlib import contextmanager
from dataclasses import asdict
from pathlib import Path

from .account import AccountIdentity
from .defaults import default_account, default_player
from .player_database import JsonPlayerDatabase
from .hero_repository import HeroRepository
from .hero_progression_repository import HeroProgressionRepository
from .inventory_repository import InventoryRepository
from .world_repository import WorldRepository
from .player_state import PlayerState
from .profiles import apply_profile


class StateRepository:
    """Own the single canonical account/player record.

    The project deliberately favors a text database over SQLite while gameplay
    contracts are still moving. Stage 4A adds request-scoped locking around the
    existing atomic saves; Stage 4A.2 applies that same transaction boundary to
    Campaign world/session commits as well as Hero state.
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
        HeroRepository(self.player).normalize()
        InventoryRepository(self.player).normalize()
        WorldRepository(self.player, self._data_dir()).normalize()
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
            # Stage 4A schema migration/normalization: keep local entity IDs,
            # collection state, hero payload shapes, and preset-team strings coherent.
            hero_changed = HeroRepository(self.player).normalize()
            inventory_changed = InventoryRepository(self.player).normalize()
            guide_changed = self._normalize_guide_function_ids()
            world_changed = WorldRepository(self.player, self._data_dir(), inventory=InventoryRepository(self.player)).normalize()
            if hero_changed or inventory_changed or guide_changed or world_changed:
                self.database.save(self.account, self.player)
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
            HeroRepository(self.player).normalize()
            InventoryRepository(self.player).normalize()
            self._normalize_guide_function_ids()
            WorldRepository(self.player, self._data_dir(), inventory=InventoryRepository(self.player)).normalize()
            print(f"[PLAYER DB] migrated legacy state from {path} -> {self.path}")
            return True
        except Exception as exc:
            print(f"[PLAYER DB] could not migrate legacy state {path}: {exc}")
            return False


    def _normalize_guide_function_ids(self) -> bool:
        """Migrate legacy list-shaped guide completions to Lua's string-key map."""
        raw = self.player.guide_function_ids
        normalized: dict[str, int] = {}
        if isinstance(raw, dict):
            for key, value in raw.items():
                try:
                    guide_id = int(key)
                    state = int(value)
                except (TypeError, ValueError):
                    continue
                if guide_id > 0 and state != 0:
                    normalized[str(guide_id)] = state
        elif isinstance(raw, list):
            for value in raw:
                try:
                    guide_id = int(value)
                except (TypeError, ValueError):
                    continue
                if guide_id > 0:
                    normalized[str(guide_id)] = 1
        changed = raw != normalized
        if changed:
            self.player.guide_function_ids = normalized
        return changed


    def _data_dir(self) -> Path:
        # campaign_meta.json ships beside player_db.json in the package data dir.
        if self.path:
            return self.path.parent
        return Path("data")

    @contextmanager
    def request_scope(self):
        """Serialize one stateful request from refresh through response building.

        Flask may execute HTTP requests concurrently.  Stage 3.1 already used
        atomic file replacement, but an interleaved refresh could still replace
        ``self.player`` between a handler mutation and its save.  For this local
        restoration server, serializing stateful requests is simpler and safer
        than introducing a transactional database.  The RLock keeps nested
        ``save()`` calls from handlers safe.
        """
        with self._lock:
            if self.database and self.database.exists():
                self._load_database()
            yield

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

    def get_hero_repository(self) -> HeroRepository:
        """Return the canonical hero state owner for this player.

        A lightweight wrapper is created on demand so every handler operates on
        the current PlayerState after refresh(), while mutations reuse the
        repository's atomic save path.
        """
        return HeroRepository(self.player, self.save, self._data_dir())

    def get_inventory_repository(self) -> InventoryRepository:
        """Return the canonical ordinary Backpack item state owner."""
        return InventoryRepository(self.player, self.save)

    def get_hero_progression_repository(self) -> HeroProgressionRepository:
        """Return the canonical source-backed Hero consumable progression owner."""
        return HeroProgressionRepository(self.player, self._data_dir(), self.save)

    def get_world_repository(self) -> WorldRepository:
        """Return the canonical Campaign/world state owner for this player."""
        return WorldRepository(
            self.player,
            self._data_dir(),
            self.save,
            inventory=InventoryRepository(self.player),
        )

    def get_player(self) -> PlayerState:
        return self.player

    def set_region(self, region: int) -> None:
        self.player.set_region(int(region))
        self.save()
