"""Canonical level-driven FunctionID ownership.

Pass 30 implements only the source-confirmed player-level synchronization plane.
Rows are generated from the effective writable-over-APK ``function.lua`` view.
Stage/VIP/energy gated functions are intentionally outside this repository's
current mutation path.
"""
from __future__ import annotations

import json
from collections.abc import Callable
from pathlib import Path
from typing import Any

from .player_state import PlayerState


class FunctionUnlockRepository:
    def __init__(
        self,
        player: PlayerState,
        data_dir: Path,
        save_callback: Callable[[], None] | None = None,
    ) -> None:
        self.player = player
        self.data_dir = Path(data_dir)
        self._save_callback = save_callback
        self.meta = self._load_meta()
        self.functions = self.meta.get("functions") or {}

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _load_meta(self) -> dict[str, Any]:
        path = self.data_dir / "function_unlock_meta.json"
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            meta = data.get("_meta") or {}
            if not isinstance(data, dict) or meta.get("source_resolution") != "effective_merged":
                raise ValueError("function unlock metadata is not effective_merged")
            return data
        except Exception as exc:
            raise RuntimeError(f"[FUNCTION] invalid source metadata {path}: {exc}") from exc

    def unlock_crossed_levels(
        self,
        before_level: Any,
        after_level: Any,
        *,
        persist: bool = False,
    ) -> list[int]:
        """Persist only FunctionIDs whose player-level threshold was crossed.

        Deliberately do not backfill requirements <= ``before_level``. Fresh
        compatibility accounts historically start with a conservative func_ids
        set; a level-up should add newly eligible functions without suddenly
        opening every old level-1 subsystem.
        """
        before = max(1, self._int(before_level, 1))
        after = max(before, self._int(after_level, before))
        if after <= before:
            return []

        existing = {
            self._int(value)
            for value in (self.player.func_ids if isinstance(self.player.func_ids, list) else [])
            if self._int(value) > 0
        }
        added: list[int] = []
        if isinstance(self.functions, dict):
            for raw_id, row in self.functions.items():
                if not isinstance(row, dict):
                    continue
                function_id = self._int(raw_id)
                required_level = self._int(row.get("player_level"), 0)
                if function_id <= 0 or required_level <= 0:
                    continue
                if before < required_level <= after and function_id not in existing:
                    existing.add(function_id)
                    added.append(function_id)

        if not added:
            return []
        self.player.func_ids = sorted(existing)
        added.sort()
        if persist:
            self._save()
        return added

    def _save(self) -> None:
        if self._save_callback:
            self._save_callback()
