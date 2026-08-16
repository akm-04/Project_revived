"""Backpack/inventory/rune handlers."""

from __future__ import annotations

from .context import HandlerContext


class InventoryHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_backpack(self, req: dict) -> dict:
        return self.ctx.state.get_inventory_repository().payload()

    def load_rune(self, req: dict) -> dict:
        return self.ctx.state.get_player().rune_payload()

    def load_scrolls(self, req: dict) -> dict:
        return {"list": self.ctx.state.get_player().scrolls}

    def load_essences(self, req: dict) -> dict:
        return {"list": self.ctx.state.get_player().essences}

    def sell_item(self, req: dict) -> dict:
        return {"awards": []}

    def sell_items(self, req: dict) -> dict:
        return {"awards": []}

    def compose_item(self, req: dict) -> dict:
        return {"awards": []}

    def use_magic_items(self, req: dict) -> dict:
        return {"awards": []}

    def use_energy_item(self, req: dict) -> dict:
        player = self.ctx.state.get_player()
        player.energy = min(player.max_energy, player.energy + 1)
        self.ctx.state.save()
        return {"energy": player.energy}

    def use_skill_point_item(self, req: dict) -> dict:
        return self.ctx.state.get_hero_progression_repository().use_skill_point_item(req)

    def use_exp_item(self, req: dict) -> dict:
        return self.ctx.state.get_hero_progression_repository().use_exp_item(req)

    def use_exp_items(self, req: dict) -> dict:
        return self.ctx.state.get_hero_progression_repository().use_exp_items(req)

    def sort_type(self, req: dict) -> dict:
        return {}
