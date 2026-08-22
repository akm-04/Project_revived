"""Legacy InventoryRepository compatibility facade over Pass69 StackInventory."""
from __future__ import annotations

from collections.abc import Callable

from .player_state import PlayerState
from .stack_inventory import StackInventory
from .unit_of_work import PlayerUnitOfWork


class InventoryRepository(StackInventory):
    """Preserve existing imports/call sites while StackInventory owns stack math."""

    def __init__(
        self,
        player: PlayerState,
        save_callback: Callable[[], None] | None = None,
        *,
        uow: PlayerUnitOfWork | None = None,
    ) -> None:
        super().__init__(player, save_callback, uow=uow)
