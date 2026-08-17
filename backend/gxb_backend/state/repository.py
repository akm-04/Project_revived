"""Request-scoped canonical state repository for the v0.8.0 multi-user backend."""

from __future__ import annotations

import threading
from contextlib import contextmanager
from pathlib import Path
from typing import Any

from .account import AccountIdentity
from .economy_repository import EconomyRepository
from .function_unlock_repository import FunctionUnlockRepository
from .hero_progression_repository import HeroProgressionRepository
from .hero_equipment_repository import HeroEquipmentRepository
from .hero_repository import HeroRepository
from .inventory_repository import InventoryRepository
from .mission_repository import MissionRepository
from .multiuser_database import (
    MultiUserDatabase,
    SANDBOX_SID,
    SANDBOX_TOKEN,
    SANDBOX_UID,
)
from .player_state import PlayerState
from .summon_repository import SummonRepository
from .world_repository import WorldRepository


class _RequestBinding(threading.local):
    account: AccountIdentity | None = None
    session: dict[str, Any] | None = None
    player: PlayerState | None = None
    is_new_player: bool = False


class StateRepository:
    """Own SDK identity + request-selected game player state.

    Existing gameplay handlers keep using ``get_player()`` and the domain
    repositories.  v0.8.0 changes what those calls mean: they resolve against a
    request-local authenticated player instead of one process-wide singleton.
    """

    def __init__(
        self,
        path: Path | None = None,
        profile: str = "established",
        legacy_path: Path | None = None,
        multiuser_root: Path | None = None,
    ) -> None:
        self.path = Path(path) if path else None  # v0.7 singleton migration source
        self.legacy_path = Path(legacy_path) if legacy_path else None
        self.profile = profile
        self._lock = threading.RLock()
        self._local = _RequestBinding()
        root = Path(multiuser_root or ((self.path.parent if self.path else Path("data")) / "server_state"))
        self.store = MultiUserDatabase(root, self._data_dir())

        with self._lock:
            sandbox_player = self.store.import_legacy_sandbox(
                self.path,
                profile=self.profile,
                legacy_state_path=self.legacy_path,
            )
            sandbox_session = self.store.ensure_sandbox_session()
            self._bind_session(sandbox_session)
            self._local.player = sandbox_player
            self._local.is_new_player = False

    # ------------------------------------------------------------------
    # Request binding
    # ------------------------------------------------------------------
    def _data_dir(self) -> Path:
        if self.path:
            return self.path.parent
        return Path("data")

    def _clear_binding(self) -> None:
        self._local.account = None
        self._local.session = None
        self._local.player = None
        self._local.is_new_player = False

    def _bind_session(self, session: dict[str, Any] | None) -> None:
        self._local.session = session
        self._local.account = self.store.identity_from_session(session) if session else None

    def _resolve_engine_session(self, req: dict[str, Any]) -> dict[str, Any] | None:
        sid = req.get("sid")
        token = req.get("login_token") or req.get("token")
        session = self.store.resolve_session(
            sid=str(sid) if sid else None,
            token=str(token) if token else None,
        )
        # Anonymous compatibility fallback: historical game requests use the
        # fixed local token.  Do not silently map arbitrary unknown credentials.
        if session is None and (sid == SANDBOX_SID or token == SANDBOX_TOKEN):
            session = self.store.ensure_sandbox_session()
        return session

    def _bind_engine_request(self, req: dict[str, Any] | None) -> None:
        self._clear_binding()
        if not isinstance(req, dict):
            return
        session = self._resolve_engine_session(req)
        if session is None:
            return
        self._bind_session(session)

        uid = str(session.get("uid", ""))
        try:
            region = int(req.get("region", 0) or 0)
        except (TypeError, ValueError):
            region = 0

        # MID18 and MID1 intentionally run with account/session context before
        # a game player is selected/created. Other authenticated requests carry
        # region and should bind that account's existing character.
        try:
            mid = int(req.get("mid", 0) or 0)
        except (TypeError, ValueError):
            mid = 0
        if mid in {1, 18}:
            return

        player: PlayerState | None = None
        if uid == SANDBOX_UID:
            player = self.store.sandbox_player()
        elif region > 0:
            player_id = self.store.player_id_for_account_region(uid, region)
            if player_id:
                player = self.store.load_player(player_id)
        self._local.player = player

    @contextmanager
    def request_scope(self, req: dict[str, Any] | None = None):
        """Serialize a request and bind the correct authenticated player."""
        with self._lock:
            previous = (
                getattr(self._local, "account", None),
                getattr(self._local, "session", None),
                getattr(self._local, "player", None),
                getattr(self._local, "is_new_player", False),
            )
            self._bind_engine_request(req)
            try:
                yield
            finally:
                self._local.account, self._local.session, self._local.player, self._local.is_new_player = previous

    def refresh(self) -> None:
        """Reload the currently bound player from disk."""
        with self._lock:
            player = getattr(self._local, "player", None)
            if player is not None:
                loaded = self.store.load_player(str(player.player_id))
                if loaded is not None:
                    self._local.player = loaded

    # ------------------------------------------------------------------
    # SDK account/session service
    # ------------------------------------------------------------------
    def sdk_anonymous_identity(self, *, device: dict[str, Any] | None = None) -> AccountIdentity:
        with self._lock:
            self.store.ensure_sandbox_account()
            session = self.store.ensure_sandbox_session()
            return self.store.identity_from_session(session)

    def sdk_identity_from_sid(self, sid: str | None) -> AccountIdentity | None:
        with self._lock:
            if not sid:
                return None
            session = self.store.resolve_session(sid=str(sid))
            return self.store.identity_from_session(session) if session else None

    def sdk_register(self, login: str, password: str) -> tuple[dict[str, Any] | None, str]:
        with self._lock:
            return self.store.register_account(login, password)

    def sdk_login(self, login: str, password: str, *, device: dict[str, Any] | None = None) -> AccountIdentity | None:
        with self._lock:
            account = self.store.verify_credentials(login, password)
            if account is None:
                return None
            session = self.store.issue_session(account, device=device)
            return self.store.identity_from_session(session)

    # ------------------------------------------------------------------
    # Account-region player lifecycle
    # ------------------------------------------------------------------
    def current_session(self) -> dict[str, Any] | None:
        return getattr(self._local, "session", None)

    def has_authenticated_session(self) -> bool:
        return getattr(self._local, "session", None) is not None and getattr(self._local, "account", None) is not None

    def current_uid(self) -> str:
        account = self.get_account()
        return str(account.uid)

    def list_account_players(self) -> list[PlayerState]:
        account = getattr(self._local, "account", None)
        if account is None:
            return []
        players: list[PlayerState] = []
        for player_id in self.store.account_player_ids(str(account.uid)):
            player = self.store.load_player(player_id)
            if player is not None:
                players.append(player)
        return players

    def region_player_count(self, region: int) -> int:
        return self.store.region_player_count(int(region))

    def resolve_or_create_player(self, region: int, region_name: str | None = None) -> tuple[PlayerState, bool]:
        """Resolve `(SDK uid, region)` or atomically create a fresh character."""
        session = getattr(self._local, "session", None)
        account = getattr(self._local, "account", None)
        if session is None or account is None:
            raise RuntimeError("MID1 player resolution requires an authenticated SDK session")

        uid = str(account.uid)
        region = int(region)
        region_name = str(region_name or self.region_name(region))

        if uid == SANDBOX_UID:
            player = self.store.sandbox_player()
            old_region = int(player.region)
            player.set_region(region)
            player.account_uid = SANDBOX_UID
            player.token = str(account.token)
            self.store.save_player(player)
            if old_region != region:
                self.store.move_account_region_player(SANDBOX_UID, old_region, region, str(player.player_id))
            self._local.player = player
            self._local.is_new_player = False
            return player, False

        player_id = self.store.player_id_for_account_region(uid, region)
        if player_id:
            player = self.store.load_player(player_id)
            if player is None:
                raise RuntimeError(f"player index points to missing player {player_id}")
            player.account_uid = uid
            self._local.player = player
            self._local.is_new_player = False
            return player, False

        player = self.store.create_fresh_player(uid=uid, region=region, region_name=region_name)
        self._local.player = player
        self._local.is_new_player = True
        print(
            "[MULTIUSER] created player "
            f"uid={uid} region={region} player_id={player.player_id} name={player.player_name!r}"
        )
        return player, True

    @staticmethod
    def region_name(region: int) -> str:
        return "Deep Valley" if int(region) == 125 else f"Local-{int(region)}"

    # ------------------------------------------------------------------
    # Existing gameplay-facing repository interface
    # ------------------------------------------------------------------
    def get_account(self) -> AccountIdentity:
        account = getattr(self._local, "account", None)
        if account is not None:
            return account
        session = self.store.ensure_sandbox_session()
        return self.store.identity_from_session(session)

    def current_player_or_none(self) -> PlayerState | None:
        """Return only the request-bound player, without sandbox fallback.

        Response projection uses this to avoid diffing bootstrap/account-selection
        requests against the implicit AdminRoot sandbox.
        """
        return getattr(self._local, "player", None)

    def get_player(self) -> PlayerState:
        player = getattr(self._local, "player", None)
        if player is not None:
            return player
        # Public/pre-auth handlers historically assume a player object. Keep the
        # sandbox fallback, but authenticated credential mutations only bind an
        # actual player after MID1 has selected the account-region character.
        return self.store.sandbox_player()

    def get_player_by_id(self, player_id: Any) -> PlayerState | None:
        with self._lock:
            return self.store.load_player(str(player_id))

    def save(self) -> None:
        with self._lock:
            player = getattr(self._local, "player", None)
            if player is None:
                return
            self.store.save_player(player)

    def get_hero_repository(self) -> HeroRepository:
        player = self.get_player()
        functions = FunctionUnlockRepository(player, self._data_dir())
        economy = EconomyRepository(
            player, self._data_dir(), self.save,
            function_unlocks=functions,
        )
        return HeroRepository(
            player, self.save, self._data_dir(),
            economy=economy,
        )

    def get_inventory_repository(self) -> InventoryRepository:
        return InventoryRepository(self.get_player(), self.save)

    def get_summon_repository(self) -> SummonRepository:
        return SummonRepository(self.get_player(), self._data_dir(), self.save)

    def get_hero_progression_repository(self) -> HeroProgressionRepository:
        return HeroProgressionRepository(self.get_player(), self._data_dir(), self.save)

    def get_hero_equipment_repository(self) -> HeroEquipmentRepository:
        return HeroEquipmentRepository(self.get_player(), self._data_dir(), self.save)

    def get_function_unlock_repository(self) -> FunctionUnlockRepository:
        return FunctionUnlockRepository(self.get_player(), self._data_dir(), self.save)

    def get_economy_repository(self) -> EconomyRepository:
        player = self.get_player()
        return EconomyRepository(
            player, self._data_dir(), self.save,
            function_unlocks=FunctionUnlockRepository(player, self._data_dir()),
        )

    def get_mission_repository(self) -> MissionRepository:
        player = self.get_player()
        functions = FunctionUnlockRepository(player, self._data_dir())
        economy = EconomyRepository(player, self._data_dir(), function_unlocks=functions)
        return MissionRepository(
            player, self._data_dir(), self.save,
            economy=economy, inventory=InventoryRepository(player),
        )

    def get_world_repository(self) -> WorldRepository:
        player = self.get_player()
        functions = FunctionUnlockRepository(player, self._data_dir())
        economy = EconomyRepository(player, self._data_dir(), function_unlocks=functions)
        inventory = InventoryRepository(player)
        missions = MissionRepository(
            player, self._data_dir(), economy=economy, inventory=inventory,
        )
        return WorldRepository(
            player,
            self._data_dir(),
            self.save,
            inventory=inventory,
            economy=economy,
            hero_progression=HeroProgressionRepository(player, self._data_dir()),
            missions=missions,
        )

    def set_region(self, region: int) -> None:
        """Compatibility shim.

        Credential-player region is an ownership key and is not freely mutated.
        The sandbox retains the old behavior. If a credential account already
        owns the requested region, bind that player instead.
        """
        with self._lock:
            account = getattr(self._local, "account", None)
            if account is None or str(account.uid) == SANDBOX_UID:
                player = self.get_player()
                old_region = int(player.region)
                player.set_region(int(region))
                self.store.save_player(player)
                if old_region != int(region):
                    self.store.move_account_region_player(SANDBOX_UID, old_region, int(region), str(player.player_id))
                return
            player_id = self.store.player_id_for_account_region(str(account.uid), int(region))
            if player_id:
                player = self.store.load_player(player_id)
                if player is not None:
                    self._local.player = player
