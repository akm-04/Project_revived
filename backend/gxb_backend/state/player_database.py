"""Human-editable JSON player database.

This is intentionally not SQLite. Gameplay contracts are still being rebuilt,
so a plain JSON document is easier to inspect, version, copy, and hand-edit.
Stage 4A makes hero ownership a first-class section; Stage 4A.2 adds Campaign
world/session state while preserving automatic forward persistence for newly
added PlayerState fields.

StateRepository re-reads the database at each request boundary and writes
mutations atomically. Stage 4A additionally serializes stateful requests so a
concurrent refresh cannot replace PlayerState in the middle of a mutation.
"""

from __future__ import annotations

import json
import os
from dataclasses import asdict, fields
from pathlib import Path
from typing import Any

from .account import AccountIdentity
from .player_state import PlayerState


IDENTITY_FIELDS = {
    "account_uid", "player_id", "player_name", "region", "region_name", "token",
    "player_type", "avatar_id", "avatar_frame_id", "guild_id",
}

PROGRESSION_FIELDS = {
    "lev", "exp", "max_lev", "max_color", "vip", "skill_point",
    "first_main_touch", "main_scene_type", "story_id", "story_state", "guide_id",
    "guide_return_id", "func_ids", "guide_function_ids", "boss_incr_exp",
    "arena_beat_flag", "conquer_lev", "conquer_loop_id", "conquer_region",
    "degree_cer", "graduate_cer", "patent_cer", "crab_times",
}

ECONOMY_FIELDS = {
    "mana", "crystal", "lucky_coin", "arena_coin", "march_coin", "top_coin",
    "guild_coin", "region_coin", "king_coin", "honor_coin", "god_war_coin",
    "friendship_coin", "friend_medal", "summon_coin", "skin_fragment", "glue",
    "lvbu_coin", "paradise_coin", "team_dungeon_coin", "ice_core", "spirit_stone",
    "occult_ticket", "tutor_coin", "skin_coin", "energy", "max_energy",
    "spirit_energy", "max_invitation", "invitation", "social", "glory",
    "buy_glue_times", "buy_mana_times", "buy_energy_times",
    "buy_spirit_energy_times", "buy_skill_times", "month_card_start",
    "month_card_end", "privilege_left_card_day", "privilege_month_card_end",
    "left_card_day", "left_week_card_day", "left_month_tili_day", "charge",
    "magic_energy", "magic_dust", "magic_liquid", "magic_exp", "energy_time",
    "spirit_energy_time", "invitation_time", "skill_time",
}

HERO_FIELDS = {
    "heroes", "collected_heros", "hero_pieces", "hero_sort_type",
    "hero_next_partner_id", "formation", "save_team", "save_team_name", "save_pet",
}

INVENTORY_FIELDS = {
    "backpack_items", "spirit_list", "runes", "scrolls", "essences",
}

LIBRARY_FIELDS = {
    "library_infos", "library_talk_infos", "library_cg_infos", "bg_main",
    "bg_room", "bg_has_buy",
}

WORLD_FIELDS = {
    "world_map", "active_campaign_battle",
}

LOBBY_FIELDS = {
    "message_pushes", "title_info", "vip_awards", "bubble_info", "is_commented",
    "comment_open", "fbshare_open", "summon", "illusion", "friends", "activities",
    "board_contents", "redmarks", "pets", "mails", "missions", "shops",
    "shop_statuses",
}

SECTION_FIELDS: dict[str, set[str]] = {
    "identity": IDENTITY_FIELDS,
    "progression": PROGRESSION_FIELDS,
    "economy": ECONOMY_FIELDS,
    "heroes": HERO_FIELDS,
    "inventory": INVENTORY_FIELDS,
    "library": LIBRARY_FIELDS,
    "lobby": LOBBY_FIELDS,
    "world": WORLD_FIELDS,
}

PLAYER_FIELD_NAMES = {field.name for field in fields(PlayerState)}


class JsonPlayerDatabase:
    """Serialize AccountIdentity + PlayerState to a readable nested JSON file."""

    SCHEMA_VERSION = 4

    def __init__(self, path: Path) -> None:
        self.path = Path(path)

    def exists(self) -> bool:
        return self.path.exists()

    def load(
        self,
        base_account: AccountIdentity,
        base_player: PlayerState,
    ) -> tuple[AccountIdentity, PlayerState]:
        data = json.loads(self.path.read_text(encoding="utf-8"))
        account_data = data.get("account") or {}
        player_data = data.get("player") or {}

        account_values = asdict(base_account)
        if isinstance(account_data, dict):
            account_values.update({k: v for k, v in account_data.items() if k in account_values})

        flat_player = asdict(base_player)
        if isinstance(player_data, dict):
            # Stage 3.1 nested sections must be recognized *before* legacy flat
            # fields. The section name ``heroes`` intentionally collides with the
            # PlayerState.heroes field name; checking PLAYER_FIELD_NAMES first
            # would assign the whole section to player.heroes and produce the
            # invalid MID49 shape ``heros.heroes.<partner_id>``.
            for key, value in player_data.items():
                if key in SECTION_FIELDS and isinstance(value, dict):
                    for sub_key, sub_value in value.items():
                        if sub_key in PLAYER_FIELD_NAMES:
                            flat_player[sub_key] = sub_value
                elif key in PLAYER_FIELD_NAMES:
                    # Backward compatibility: the old state/gxb_state.json stored
                    # every PlayerState field directly under ``player``.
                    flat_player[key] = value
                elif isinstance(value, dict):
                    # Forward-compatible unknown organizational section.
                    for sub_key, sub_value in value.items():
                        if sub_key in PLAYER_FIELD_NAMES:
                            flat_player[sub_key] = sub_value

        return AccountIdentity(**account_values), PlayerState(**flat_player)

    def save(self, account: AccountIdentity, player: PlayerState) -> None:
        payload = self.serialize(account, player)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        temp_path = self.path.with_suffix(self.path.suffix + ".tmp")
        temp_path.write_text(
            json.dumps(payload, indent=2, sort_keys=False, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        os.replace(temp_path, self.path)

    @classmethod
    def serialize(cls, account: AccountIdentity, player: PlayerState) -> dict[str, Any]:
        remaining = asdict(player)
        player_sections: dict[str, Any] = {}

        for section, names in SECTION_FIELDS.items():
            section_values: dict[str, Any] = {}
            for name in sorted(names):
                if name in remaining:
                    section_values[name] = remaining.pop(name)
            player_sections[section] = section_values

        # Any newly added PlayerState field automatically remains persisted even
        # if the database grouping table has not been updated yet.
        player_sections["domains"] = remaining

        return {
            "_meta": {
                "schema": cls.SCHEMA_VERSION,
                "format": "GXB Stage 4A.6 human-editable player database",
                "notes": [
                    "Stage 3.1.4 keeps SDK account UID, SDK/login SID, and game player ID distinct using the known-good region-125 client snapshot.",
                    "The backend re-reads this file before every request.",
                    "Edit progression.guide_id to test tutorial state; established default is 101001 (after later pet/cloud/conquer guide families).",
                    "economy feeds MID 17 / EcoSidebar; canonical hero ownership feeds MID 49 and later formation/battle/summon flows.",
                    "heroes.save_team/save_team_name/save_pet are serialized strings because the Lua client splits them as strings.",
                    "Use valid source table IDs for heroes/items. Unknown IDs can crash client table lookups.",
                    "world.world_map is authoritative Campaign progress; MID113 starts a pending session and MID114 commits stars/unlocks atomically.",
                    "progression.guide_function_ids is a string-keyed completion map because xyd.checkFirstInGuide indexes tostring(id).",
                    "inventory.backpack_items is canonical persisted Backpack state; Campaign first-clear awards mutate this same list.",
                ],
            },
            "account": asdict(account),
            "player": player_sections,
        }
