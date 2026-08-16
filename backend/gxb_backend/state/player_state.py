"""Canonical Stage 1 player state.

All boot and first-lobby handlers serialize from this object. That prevents
contradictions between RETRIEVE_TOKEN.detail, standalone LOAD_PLAYER_INFO,
MessageManager identity fields, summon state, library state, and social state.
"""

from __future__ import annotations

import time
from dataclasses import dataclass, field
from typing import Any


@dataclass
class PlayerState:
    account_uid: str = "13371337"
    player_id: str = "13371337"
    player_name: str = "AdminRoot"
    region: int = 7
    region_name: str = "Local-7"
    token: str = "local_token"

    player_type: int = 0
    avatar_id: int = 0
    avatar_frame_id: int = 0
    lev: int = 99
    exp: int = 0
    max_lev: int = 200
    max_color: int = 5
    vip: int = 15
    guild_id: int = 0

    mana: int = 999_999
    crystal: int = 999_999
    lucky_coin: int = 0
    arena_coin: int = 0
    march_coin: int = 0
    top_coin: int = 0
    guild_coin: int = 0
    region_coin: int = 0
    king_coin: int = 0
    honor_coin: int = 0
    god_war_coin: int = 0
    friendship_coin: int = 0
    friend_medal: int = 0
    summon_coin: int = 0
    skin_fragment: int = 0
    glue: int = 0
    lvbu_coin: int = 0
    paradise_coin: int = 0
    team_dungeon_coin: int = 0
    ice_core: int = 0
    spirit_stone: int = 0
    occult_ticket: int = 0
    tutor_coin: int = 0
    skin_coin: int = 0

    energy: int = 100
    max_energy: int = 100
    spirit_energy: int = 100
    max_invitation: int = 10
    invitation: int = 10
    social: int = 0
    glory: int = 0

    skill_point: int = 0
    first_main_touch: int = 1
    main_scene_type: int = 0

    heroes: dict[str, Any] = field(default_factory=dict)
    backpack_items: list[dict[str, Any]] = field(default_factory=list)
    spirit_list: list[dict[str, Any]] = field(default_factory=list)
    formation: dict[str, Any] = field(default_factory=dict)
    message_pushes: dict[str, Any] = field(default_factory=dict)
    func_ids: list[int] = field(default_factory=list)
    guide_function_ids: list[int] = field(default_factory=list)

    library_infos: dict[str, Any] = field(default_factory=dict)
    library_talk_infos: dict[str, Any] = field(default_factory=dict)
    library_cg_infos: list[Any] = field(default_factory=list)
    bg_main: int = 1
    bg_room: int = 2
    bg_has_buy: list[int] = field(default_factory=list)

    summon: dict[str, Any] = field(default_factory=dict)
    illusion: dict[str, Any] = field(default_factory=dict)
    friends: dict[str, Any] = field(default_factory=dict)
    activities: list[dict[str, Any]] = field(default_factory=list)
    board_contents: list[dict[str, Any]] = field(default_factory=list)
    redmarks: list[dict[str, Any]] = field(default_factory=list)
    arena_records: list[dict[str, Any]] = field(default_factory=list)
    pets: dict[str, Any] = field(default_factory=dict)

    def now(self) -> int:
        return int(time.time())

    def set_region(self, region: int) -> None:
        self.region = int(region)
        self.region_name = f"Local-{self.region}"

    def player_info_payload(self) -> dict[str, Any]:
        now = self.now()
        return {
            "player_id": self.player_id,
            "uid": self.account_uid,
            "player_name": self.player_name,
            "player_type": self.player_type,
            "avatar_id": self.avatar_id,
            "avatar_frame_id": self.avatar_frame_id,
            "lev": self.lev,
            "exp": self.exp,
            "boss_incr_exp": 0,
            "max_lev": self.max_lev,
            "max_color": self.max_color,
            "region": self.region,
            "region_name": self.region_name,
            "mana": self.mana,
            "crystal": self.crystal,
            "lucky_coin": self.lucky_coin,
            "arena_coin": self.arena_coin,
            "march_coin": self.march_coin,
            "top_coin": self.top_coin,
            "guild_coin": self.guild_coin,
            "region_coin": self.region_coin,
            "king_coin": self.king_coin,
            "honor_coin": self.honor_coin,
            "god_war_coin": self.god_war_coin,
            "friendship_coin": self.friendship_coin,
            "friend_medal": self.friend_medal,
            "summon_coin": self.summon_coin,
            "skin_fragment": self.skin_fragment,
            "glue": self.glue,
            "buy_glue_times": 0,
            "lvbu_coin": self.lvbu_coin,
            "paradise_coin": self.paradise_coin,
            "team_dungeon_coin": self.team_dungeon_coin,
            "ice_core": self.ice_core,
            "spirit_stone": self.spirit_stone,
            "energy": self.energy,
            "max_energy": self.max_energy,
            "energy_time": now,
            "spirit_energy": self.spirit_energy,
            "spirit_energy_time": now,
            "invitation": self.invitation,
            "invitation_time": now,
            "max_invitation": self.max_invitation,
            "social": self.social,
            "glory": self.glory,
            "vip": self.vip,
            "buy_mana_times": 0,
            "buy_energy_times": 0,
            "buy_spirit_energy_times": 0,
            "buy_skill_times": 0,
            "func_ids": self.func_ids,
            "guide_function_ids": self.guide_function_ids,
            "guide_return_id": 0,
            "skill_point": self.skill_point,
            "skill_time": now,
            "formation": self.formation,
            "save_team": {},
            "save_team_name": {},
            "save_pet": {},
            "message_pushes": self.message_pushes,
            "is_commented": 1,
            "comment_open": 0,
            "fbshare_open": 0,
            "guild_id": self.guild_id,
            "main_scene_type": self.main_scene_type,
            "first_main_touch": self.first_main_touch,
            "arena_beat_flag": 0,
            "month_card_start": 0,
            "month_card_end": 0,
            "privilege_left_card_day": 0,
            "privilege_month_card_end": 0,
            "left_card_day": 0,
            "left_week_card_day": 0,
            "left_month_tili_day": 0,
            "charge": 0,
            "magic_energy": 0,
            "magic_dust": 0,
            "magic_liquid": 0,
            "magic_exp": 0,
            "degree_cer": 0,
            "graduate_cer": 0,
            "patent_cer": 0,
            "title_info": {},
            "vip_awards": [],
            "conquer_lev": 0,
            "conquer_loop_id": 0,
            "conquer_region": 0,
            "occult_ticket": self.occult_ticket,
            "tutor_coin": self.tutor_coin,
            "skin_coin": self.skin_coin,
            "bubble_info": {},
            "crab_times": 0,
            "story_id": 0,
            "story_state": 0,
            "guide_id": 0,
        }

    def heroes_payload(self) -> dict[str, Any]:
        return {"sort_type": 0, "heros": self.heroes}

    def backpack_payload(self) -> dict[str, Any]:
        return {"sort_type": 0, "list": self.backpack_items, "spirit_list": self.spirit_list}

    def library_payload(self) -> dict[str, Any]:
        return {
            "library_infos": self.library_infos,
            "library_talk_infos": self.library_talk_infos,
            "library_cg_infos": self.library_cg_infos,
            "library_bg_infos": {
                "bg_main": self.bg_main,
                "bg_room": self.bg_room,
                "has_buy": self.bg_has_buy,
                "server_time": self.now(),
            },
        }

    def summon_payload(self) -> dict[str, Any]:
        now = self.now()
        payload = {
            "mana_free_time": self.summon.get("mana_free_time", now + 3600),
            "crystal_free_time": self.summon.get("crystal_free_time", now + 3600),
            "second_ids": self.summon.get("second_ids", []),
            "main_ids": self.summon.get("main_ids", []),
            "mana_id": self.summon.get("mana_id", 0),
            "pet_id": self.summon.get("pet_id", 0),
            "partner_id": self.summon.get("partner_id", 0),
        }
        if "directional_show_id" in self.summon:
            payload["directional_show_id"] = self.summon["directional_show_id"]
        return payload

    def illusion_payload(self) -> dict[str, Any]:
        return {
            "paradise_info": self.illusion.get("paradise_info", {"paradise_id": 1, "count": 0}),
            "challenge_times": self.illusion.get("challenge_times", 0),
            "buy_times": self.illusion.get("buy_times", 0),
            "hurt": self.illusion.get("hurt", 0),
            "rank": self.illusion.get("rank", 0),
        }

    def friends_payload(self) -> dict[str, Any]:
        return {
            "server_time": self.now(),
            "blacklist": self.friends.get("blacklist", []),
            "friend_list": self.friends.get("friend_list", []),
            "notice_list": self.friends.get("notice_list", []),
            "request_list": self.friends.get("request_list", []),
            "offline_msg_list": self.friends.get("offline_msg_list", []),
            "send_gift_count": self.friends.get("send_gift_count", 0),
            "receive_gift_count": self.friends.get("receive_gift_count", 0),
        }

    def activities_payload(self) -> dict[str, Any]:
        return {"list": self.activities}

    def board_payload(self) -> dict[str, Any]:
        return {"contents": self.board_contents}

    def redmark_payload(self) -> list[dict[str, Any]]:
        return self.redmarks

    def guild_payload(self) -> dict[str, Any]:
        if not self.guild_id:
            return {"guild_info": {}, "self_info": {}, "member_nums": 0}
        return {
            "guild_info": {
                "guild_id": self.guild_id,
                "icon": 1,
                "name": "Local Guild",
                "des": "Local private-server guild stub",
                "apply_type": 0,
                "icon_frame": 0,
                "min_allow_level": 1,
                "guild_leader_name": self.player_name,
                "huoyue": 0,
            },
            "self_info": {"today_huoyue": 0, "huoyue_num": 0, "job": 3},
            "member_nums": 1,
        }

    def pets_payload(self) -> dict[str, Any]:
        return {"pets": self.pets}

    def arena_records_payload(self) -> dict[str, Any]:
        return {"records": self.arena_records}
