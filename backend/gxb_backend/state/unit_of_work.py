"""Request-scoped one-player UnitOfWork.

Pass 32.6 formalizes the existing ``persist=False`` + one-save pattern without
moving domain rules out of repositories.  The first participant is the bound
PlayerState itself: a transaction snapshots the complete dataclass object,
repository save callbacks only mark the request dirty while the transaction is
active, successful outermost exit performs exactly one persistence call, and
any exception restores the in-memory snapshot before it escapes.
"""
from __future__ import annotations

import copy
from contextlib import contextmanager
from dataclasses import dataclass
from typing import Callable, Iterator

from .player_state import PlayerState


@dataclass(frozen=True)
class OperationContext:
    actor_player_id: str
    domain: str
    operation_name: str
    protocol_mid: int | None = None
    idempotency_key: str | None = None


class UnitOfWork:
    """One-player transaction coordinator, intentionally not a domain service."""

    def __init__(self, player: PlayerState, commit_callback: Callable[[], None]) -> None:
        self.player = player
        self._commit_callback = commit_callback
        self._depth = 0
        self._snapshot: dict | None = None
        self._rollback_only = False
        self._save_requested = False
        self._contexts: list[OperationContext] = []
        self._staged_semantic: dict[str, list[object]] = {}
        self._committed_semantic: dict[str, list[object]] = {}

    @property
    def active(self) -> bool:
        return self._depth > 0

    @property
    def current_context(self) -> OperationContext | None:
        return self._contexts[-1] if self._contexts else None

    def request_save(self) -> None:
        """Repository-compatible save callback.

        Outside a UoW mutation this preserves historical immediate persistence.
        Inside a transaction persistence is deferred to the outermost commit.
        """
        if self.active:
            self._save_requested = True
            return
        self._commit_callback()

    def mark_changed(self) -> None:
        """Explicitly mark a transaction dirty when no repository save is called."""
        if self.active:
            self._save_requested = True
        else:
            self._commit_callback()

    def stage_semantic(self, channel: str, value: object) -> None:
        """Stage an explicit domain semantic response event.

        This is not inferred from state diffs.  Events raised inside a UoW are
        exposed only after a successful commit and are discarded on rollback.
        """
        target = self._staged_semantic if self.active else self._committed_semantic
        target.setdefault(str(channel), []).append(copy.deepcopy(value))

    def consume_semantic(self) -> dict[str, list[object]]:
        out = copy.deepcopy(self._committed_semantic)
        self._committed_semantic.clear()
        return out

    def set_rollback_only(self) -> None:
        if self.active:
            self._rollback_only = True

    def _take_snapshot(self) -> dict:
        return copy.deepcopy(vars(self.player))

    def _restore_snapshot(self) -> None:
        if self._snapshot is None:
            return
        current = vars(self.player)
        current.clear()
        current.update(copy.deepcopy(self._snapshot))

    @contextmanager
    def transaction(self, context: OperationContext) -> Iterator["UnitOfWork"]:
        outermost = self._depth == 0
        if outermost:
            self._snapshot = self._take_snapshot()
            self._rollback_only = False
            self._save_requested = False
            self._staged_semantic = {}
        self._depth += 1
        self._contexts.append(context)
        try:
            yield self
        except Exception:
            self._rollback_only = True
            raise
        finally:
            self._contexts.pop()
            self._depth -= 1
            if outermost:
                try:
                    if self._rollback_only:
                        self._restore_snapshot()
                        self._staged_semantic = {}
                    elif self._save_requested:
                        try:
                            self._commit_callback()
                        except Exception:
                            self._restore_snapshot()
                            self._staged_semantic = {}
                            raise
                        for channel, values in self._staged_semantic.items():
                            self._committed_semantic.setdefault(channel, []).extend(copy.deepcopy(values))
                        self._staged_semantic = {}
                    else:
                        # Validation/no-op paths remain non-durable. Semantic
                        # events never escape without the domain explicitly
                        # marking the same mutation for persistence.
                        self._staged_semantic = {}
                finally:
                    self._snapshot = None
                    self._rollback_only = False
                    self._save_requested = False
