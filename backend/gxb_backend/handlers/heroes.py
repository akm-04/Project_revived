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

    def change_partner_skill(self, req: dict) -> dict:
        """MID2144: KongMing persistent Awake-skill selection; Book-V is ownership-only."""
        return self.ctx.state.get_kongming_awake_skill_service().change(req)

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

    def skin_on(self, req: dict) -> dict:
        """MID60: permanent Girl skin acquire-or-equip; temporary/Pet lanes fail closed."""
        return self.ctx.state.get_skin_ownership_service().skin_on(
            req.get("partner_id"), req.get("item_id")
        )

    def skin_cancel(self, req: dict) -> dict:
        """MID61: unequip a Girl skin without removing permanent ownership."""
        return self.ctx.state.get_skin_ownership_service().skin_cancel(req.get("partner_id"))

    def use_illusion_skin_item(self, req: dict) -> dict:
        """MID2979: select owned cosmetic appearance independently of skin skill."""
        return self.ctx.state.get_skin_ownership_service().use_illusion_skin_item(
            req.get("partner_id"), req.get("item_id")
        )

    def load_pets(self, req: dict) -> dict:
        return self.ctx.state.get_player().pets_payload()

    def evolve_hero(self, req: dict) -> dict:
        """MID52: source-distinguish ordinary and post-5 SuperHero evolution."""
        hero = self.ctx.state.get_hero_repository().get(req.get("partner_id"))
        advanced = self.ctx.state.get_hero_advanced_progression_repository()
        if advanced.is_super(hero):
            return advanced.super_evolve(req)
        return self.ctx.state.get_hero_progression_repository().evolve_hero(req)

    def set_hero_equip(self, req: dict) -> dict:
        """MID54: SuperHero, active Awakening-special, or ordinary equipment."""
        hero = self.ctx.state.get_hero_repository().get(req.get("partner_id"))
        advanced = self.ctx.state.get_hero_advanced_progression_repository()
        if advanced.is_super(hero):
            return advanced.super_set_equip(req.get("partner_id"), req.get("equip_index"))
        awake = self.ctx.state.get_awakening_equipment_coordinator().set_hero_equip(
            req.get("partner_id"), req.get("equip_index")
        )
        if awake is not None:
            return awake
        return self.ctx.state.get_hero_equipment_repository().set_hero_equip(
            req.get("partner_id"), req.get("equip_index")
        )

    def one_click_equip(self, req: dict) -> dict:
        """MID62: ordinary planner or source-distinct SuperHero fixed gear."""
        hero = self.ctx.state.get_hero_repository().get(req.get("partner_id"))
        advanced = self.ctx.state.get_hero_advanced_progression_repository()
        if advanced.is_super(hero):
            return advanced.super_one_click_equip(req.get("partner_id"))
        return self.ctx.state.get_hero_equipment_repository().one_click_equip(req.get("partner_id"))


    def one_click_promote(self, req: dict):
        """MID57: source-bounded promotion preserving Awake/Blood special slots/Fumo."""
        return self.ctx.state.get_hero_equipment_repository().one_click_promote(req.get("partner_id"))

    def powerup_hero(self, req: dict):
        """MID51: promotion + ordinary Fumo restoration while preserving special slots/Fumo."""
        return self.ctx.state.get_hero_equipment_repository().powerup_hero(req.get("partner_id"))


    def upgrade_super_equip(self, req: dict) -> dict:
        return self.ctx.state.get_hero_advanced_progression_repository().super_enhance_equip(req)

    def fumo(self, req: dict) -> dict:
        return self.ctx.state.get_hero_advanced_progression_repository().fumo(req)

    def element_equip(self, req: dict) -> dict:
        return self.ctx.state.get_hero_advanced_progression_repository().element_equip(req)

    def element_strengthen(self, req: dict) -> dict:
        return self.ctx.state.get_hero_advanced_progression_repository().element_strengthen(req)

    def element_unload(self, req: dict) -> dict:
        return self.ctx.state.get_hero_advanced_progression_repository().element_unload(req)

    def element_destroy_on_hero(self, req: dict) -> dict:
        return self.ctx.state.get_hero_advanced_progression_repository().element_destroy_on_hero(req)

    def element_destroy_backpack(self, req: dict) -> dict:
        return self.ctx.state.get_hero_advanced_progression_repository().element_destroy_backpack(req)

    def inscription_insert(self, req: dict) -> dict:
        return self.ctx.state.get_hero_advanced_progression_repository().inscription_insert(req)

    def inscription_remove(self, req: dict) -> dict:
        return self.ctx.state.get_hero_advanced_progression_repository().inscription_remove(req)

    def inscription_resolve(self, req: dict) -> dict:
        return self.ctx.state.get_hero_advanced_progression_repository().inscription_resolve(req)

    def inscription_exchange_materials(self, req: dict) -> dict:
        return self.ctx.state.get_hero_advanced_progression_repository().inscription_exchange_materials_all(req)

    def breach_stone_add(self, req: dict) -> dict:
        return self.ctx.state.get_hero_advanced_progression_repository().breach_stone_add(req)

    def breach_stone_evolve(self, req: dict) -> dict:
        return self.ctx.state.get_hero_advanced_progression_repository().breach_stone_evolve(req)

    def advanced_hidden_fail_closed(self, req: dict) -> dict:
        # PRIVATE_SERVER_POLICY sentinel. Effective src_64 exposes these request
        # surfaces but not the server-side random/instance-generation algorithm.
        return {"error_code": 1, "msg": "advanced_progression_server_algorithm_unresolved"}

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
