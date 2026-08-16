"""Hero, pet, and lightweight hero-command handlers."""

from __future__ import annotations

from .context import HandlerContext


class HeroHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_heros(self, req: dict) -> dict:
        return self.ctx.state.get_player().heroes_payload()

    def load_hero(self, req: dict) -> dict:
        partner_id = str(req.get("partner_id") or req.get("hero_id") or "")
        hero = self.ctx.state.get_player().heroes.get(partner_id, {}) if partner_id else {}
        return {"hero": hero, "partner": hero}

    def load_collected_heros(self, req: dict) -> dict:
        return self.ctx.state.get_player().collected_heros_payload()

    def load_hero_pieces(self, req: dict) -> dict:
        return self.ctx.state.get_player().hero_pieces_payload()

    def load_pets(self, req: dict) -> dict:
        return self.ctx.state.get_player().pets_payload()

    def set_lock_hero(self, req: dict) -> dict:
        partner_id = str(req.get("partner_id") or "")
        if partner_id and partner_id in self.ctx.state.get_player().heroes:
            self.ctx.state.get_player().heroes[partner_id]["is_lock"] = int(req.get("is_lock", 0))
            self.ctx.state.save()
        return {}

    def set_rep_hero(self, req: dict) -> dict:
        partner_id = req.get("partner_id")
        if partner_id is not None:
            self.ctx.state.get_player().formation["rep_partner_id"] = partner_id
            self.ctx.state.save()
        return {}

    def pet_action(self, req: dict) -> dict:
        return {**self.ctx.state.get_player().pets_payload(), "awards": []}

    def pet_campaign_info(self, req: dict) -> dict:
        return {"campaign_info": {}, "campaigns": [], "awards": [], "red_point": 0}

    def pet_campaign_action(self, req: dict) -> dict:
        return {**self.pet_campaign_info(req), "result": 1}

    def hero_command_awards(self, req: dict) -> dict:
        return {"awards": []}

    def hero_command_status(self, req: dict) -> dict:
        return {}
