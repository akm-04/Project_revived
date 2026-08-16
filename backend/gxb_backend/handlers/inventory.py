"""Backpack/inventory handlers."""

from __future__ import annotations

from .context import HandlerContext


class InventoryHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_backpack(self, req: dict) -> dict:
        return self.ctx.state.get_player().backpack_payload()
