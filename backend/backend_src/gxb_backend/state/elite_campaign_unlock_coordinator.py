"""Function31 <-> Super Campaign projection coordination."""
from __future__ import annotations

from typing import Any

from gxb_backend.content.super_campaign_catalog import (
    SUPER_FUNCTION_ID,
    SUPER_FUNCTION_LEVEL,
)

from .function_state_repository import FunctionStateRepository
from .player_state import PlayerState
from .super_campaign_projection_service import SuperCampaignProjectionService
from .unit_of_work import UnitOfWork


class EliteCampaignUnlockCoordinator:
    """Keep Function31 announcement and the first Super frontier coherent."""

    MIGRATION_MARKER = "pass128_elite_campaign_function31_reconcile_v1"

    def __init__(
        self,
        player: PlayerState,
        function_state: FunctionStateRepository,
        projection: SuperCampaignProjectionService,
        uow: UnitOfWork | None = None,
    ) -> None:
        self.player = player
        self.function_state = function_state
        self.projection = projection
        self.uow = uow

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def function_open(self) -> bool:
        return SUPER_FUNCTION_ID in set(self.function_state.announced_ids())

    def on_level_progress(self, before_level: Any, after_level: Any) -> bool:
        before = max(1, self._int(before_level, 1))
        after = max(before, self._int(after_level, before))
        if after < SUPER_FUNCTION_LEVEL:
            return False
        # observe_level_progress() normally made Function31 eligible immediately
        # before this hook; ensure it explicitly as a fail-closed composition guard.
        self.function_state.ensure_level_eligible(SUPER_FUNCTION_ID, after, persist=False)
        changed = self.projection.reconcile(function_open=True, ensure_first=True)
        added = self.function_state.announce([SUPER_FUNCTION_ID], persist=False)
        if added:
            changed = True
        # Recompute after announcement for clarity/idempotency; first projection
        # deliberately existed before the semantic NEW_FUNC_OPEN event was staged.
        if self.projection.recompute_cursors(function_open=self.function_open()):
            changed = True
        return changed

    def reconcile_projection(self) -> bool:
        """LOAD_WORLD_MAP/runtime self-heal without changing Function authority."""
        return self.projection.reconcile(
            function_open=self.function_open(),
            ensure_first=self.function_open(),
        )

    def _migration_bucket(self) -> dict[str, Any]:
        root = self.player.persistence_state
        if not isinstance(root, dict):
            root = {}
            self.player.persistence_state = root
        migrations = root.get("migrations")
        if not isinstance(migrations, dict):
            migrations = {}
            root["migrations"] = migrations
        return migrations

    def maintenance_reconcile(self) -> bool:
        """One-time player-load repair for historical Pass32.6 Function31 gaps.

        Maintenance composition has no semantic callback, so announcing an
        already-eligible historical level>=11 account here cannot emit a
        mid-session function guide popup.
        """
        level = max(1, self._int(self.player.lev, 1))
        changed = False
        if self.function_open():
            return self.projection.reconcile(function_open=True, ensure_first=True)
        if level < SUPER_FUNCTION_LEVEL:
            return self.projection.recompute_cursors(function_open=False)

        migrations = self._migration_bucket()
        self.function_state.ensure_level_eligible(SUPER_FUNCTION_ID, level, persist=False)
        # Ordering is source/UI-sensitive: first row/cursor before announcement.
        if self.projection.reconcile(function_open=True, ensure_first=True):
            changed = True
        if self.function_state.announce([SUPER_FUNCTION_ID], persist=False):
            changed = True
        if self.projection.recompute_cursors(function_open=True):
            changed = True
        if not migrations.get(self.MIGRATION_MARKER):
            migrations[self.MIGRATION_MARKER] = {
                "applied": 1,
                "policy": "legacy_level11_function31_projection_reconcile",
                "level": level,
                "first_super_campaign_id": self.projection.catalog.first_id,
            }
            changed = True
        return changed
