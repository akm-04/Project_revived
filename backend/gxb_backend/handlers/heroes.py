"""Hero ownership and lightweight hero-command handlers.

Stage 4A routes roster/preset mutations through HeroRepository so the human-
editable JSON file is the single source of truth for MID17, MID49, collection
state, and future battle/summon flows.
"""

from __future__ import annotations

from .context import HandlerContext


class HeroHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_heros(self, req: dict) -> dict:
        return self.ctx.state.get_hero_repository().payload()

    def load_hero(self, req: dict) -> dict:
        partner_id = req.get("partner_id") or req.get("hero_id")
        hero = self.ctx.state.get_hero_repository().get(partner_id) if partner_id is not None else None
        hero = hero or {}
        return {"hero": hero, "partner": hero}

    def load_collected_heros(self, req: dict) -> dict:
        return self.ctx.state.get_hero_repository().collected_payload()

    def load_hero_pieces(self, req: dict) -> dict:
        return self.ctx.state.get_hero_repository().pieces_payload()

    def buy_skill_point(self, req: dict) -> dict:
        """MID99 BUY_SKILL_POINT: persist the source-consumed player fields."""
        return self.ctx.state.get_hero_repository().buy_skill_points()

    def set_all_skill_level(self, req: dict) -> dict:
        """MID39 SET_ALL_SKILL_LEVEL: commit batched hero skill increments."""
        return self.ctx.state.get_hero_repository().upgrade_skills(
            req.get("partner_id"),
            req.get("skill_colors"),
            req.get("skill_counts"),
        )

    def set_skill_level(self, req: dict) -> dict:
        """MID53 SET_SKILL_LEVEL: persist the older single-index skill path."""
        return self.ctx.state.get_hero_repository().upgrade_single_skill(
            req.get("partner_id"), req.get("skill_index")
        )

    def save_sort_type(self, req: dict) -> dict:
        """MID89 SAVA_SORT_TYPE: request consumes ``sort_type``; no response fields."""
        self.ctx.state.get_hero_repository().set_sort_type(req.get("sort_type", 0))
        return {}

    def save_team(self, req: dict) -> dict:
        """MID1793 SAVE_TEAM: persist the three serialized strings verbatim.

        SelfPlayer:heroPreset() reads save_team/save_team_name/save_pet from the
        response and HeroListWindow later parses them with string split helpers.
        """
        repo = self.ctx.state.get_hero_repository()
        # HeroPresetWindow has at least one delete path that omits pet_str.
        # Missing request fields mean "leave unchanged", not "erase".
        return repo.save_presets(
            req["team_str"] if "team_str" in req else repo.player.save_team,
            req["team_name_str"] if "team_name_str" in req else repo.player.save_team_name,
            req["pet_str"] if "pet_str" in req else repo.player.save_pet,
        )

    def set_board_hero(self, req: dict) -> dict:
        """MID835 SET_BOARD_HERO: persist poster state and return callback fields."""
        return self.ctx.state.get_hero_repository().set_board_hero(
            req.get("partner_id"),
            req.get("card_status", 0),
            req.get("board_model_id", 0),
        )

    def load_pets(self, req: dict) -> dict:
        return self.ctx.state.get_player().pets_payload()

    def evolve_hero(self, req: dict) -> dict:
        """MID52: persist the source-backed normal-Hero scroll evolution."""
        return self.ctx.state.get_hero_progression_repository().evolve_hero(req)

    def set_hero_equip(self, req: dict) -> dict:
        """MID54: consume the source current-color item and persist its slot."""
        return self.ctx.state.get_hero_equipment_repository().set_hero_equip(
            req.get("partner_id"), req.get("equip_index")
        )

    def one_click_equip(self, req: dict) -> dict:
        """MID62: mirror the client source composition/potion/Mana planner."""
        return self.ctx.state.get_hero_equipment_repository().one_click_equip(req.get("partner_id"))

    def one_click_promote(self, req: dict) -> dict:
        """MID57: atomically promote one early ordinary NormalHero color."""
        return self.ctx.state.get_hero_equipment_repository().one_click_promote(req.get("partner_id"))

    # SET_LOCK_HERO and SET_REP_HERO remain symbolic/undefined in supplied
    # source. Keep the helpers for a future verified numeric mapping, but do not
    # wire a guessed MID.
    def set_lock_hero(self, req: dict) -> dict:
        partner_id = req.get("partner_id")
        if partner_id is not None:
            self.ctx.state.get_hero_repository().update_owned_hero(
                partner_id, {"is_lock": int(req.get("is_lock", 0))}
            )
        return {}

    def set_rep_hero(self, req: dict) -> dict:
        partner_id = req.get("partner_id")
        if partner_id is not None and self.ctx.state.get_hero_repository().get(partner_id):
            self.ctx.state.get_player().formation["rep_partner_id"] = int(partner_id)
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
