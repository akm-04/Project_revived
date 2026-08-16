"""Canonical Stage 2 player state.

All boot, lobby, and common-window handlers serialize from this object. The
model stays intentionally deterministic and minimal: it is a private-server
state skeleton, not a complete gameplay simulator.
"""

from __future__ import annotations

import os
import time
from dataclasses import dataclass, field
from typing import Any


# Source-derived xyd.FunctionID values from app/common/enums.lua.
# Stage 2.2 opened every known function. The live client then entered MainScene
# but never reached LOAD_FRIENDS or CHECK_GAME_STAT, meaning a complex unlocked
# branch in MainSceneBottomWindow/MainSceneTopWindow was likely aborting window
# construction before the HUD became visible.
ALL_SOURCE_FUNCTION_IDS: list[int] = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
    11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
    21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
    31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 47, 48, 49, 50, 51,
    64, 66, 67, 68, 69, 70, 71, 72, 73, 74,
    76, 77, 78, 79, 80, 84, 88, 91, 95, 96,
    97, 99,
]

# MainScene-safe default: enough to expose the core lobby/HUD/window buttons,
# while temporarily avoiding pet/guild/deep-system willOpen branches that run
# timers or inspect optional models before we have complete state. Use
# GXB_FUNC_MODE=all to restore the full Stage 2.2 list for experiments.
CORE_LOBBY_FUNCTION_IDS: list[int] = [
    1,   # ID_BATTLE
    2,   # ID_MAILBOX
    3,   # ID_SUMMON
    4,   # ID_ARENA
    5,   # ID_SHOP
    6,   # ID_RANK
    7,   # ID_EXERCISE
    8,   # ID_MARCH
    9,   # ID_TREASURE
    10,  # ID_CAVE
    11,  # ID_FUMO
    14,  # ID_PRACTICE
    21,  # ID_CHARGE, harmless visible store affordance; payment remains stubbed
    23,  # ID_ACTIVITY
    24,  # ID_HERO
    25,  # ID_BACKPACK
    26,  # ID_FRAGMENT
    27,  # ID_MISSION
    28,  # ID_DAILY_MISSION
    32,  # ID_GOLD_HAND
    33,  # ID_SKILL_UP
    34,  # ID_COUPON_CODE
    40,  # ID_ACT_CENTRE
    43,  # ID_ILLUSION
    77,  # ID_ACHIEVE
    79,  # ID_RECOMMEND
    84,  # ID_REWARD_CHANGE
    97,  # ID_BATTLE_PASS
]


def default_function_ids() -> list[int]:
    mode = os.getenv("GXB_FUNC_MODE", "all").strip().lower()
    if mode == "all":
        return list(ALL_SOURCE_FUNCTION_IDS)
    return list(CORE_LOBBY_FUNCTION_IDS)


# Backwards-compatible alias used by older code/docs.
DEFAULT_OPEN_FUNCTION_IDS = CORE_LOBBY_FUNCTION_IDS
DEFAULT_AVATAR_ID = 110001001


@dataclass
class PlayerState:
    account_uid: str = "13371337"
    player_id: str = "12525385"
    player_name: str = "Moppleton"
    region: int = 125
    region_name: str = "Deep Valley"
    token: str = "local_token"

    player_type: int = 0
    avatar_id: int = DEFAULT_AVATAR_ID
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

    # Story/tutorial/progression state. These values are deliberately persisted
    # instead of hard-coded in player_info_payload(): MainScene uses guide_id as
    # an independent UI gate. A guide_id below GUIDE_START enters the tutorial
    # flow even when the account is level 99 and every FunctionID is unlocked.
    story_id: int = 0
    story_state: int = 0
    guide_id: int = 0
    guide_return_id: int = 0

    boss_incr_exp: int = 0
    buy_glue_times: int = 0
    buy_mana_times: int = 0
    buy_energy_times: int = 0
    buy_spirit_energy_times: int = 0
    buy_skill_times: int = 0
    arena_beat_flag: int = 0
    month_card_start: int = 0
    month_card_end: int = 0
    privilege_left_card_day: int = 0
    privilege_month_card_end: int = 0
    left_card_day: int = 0
    left_week_card_day: int = 0
    left_month_tili_day: int = 0
    charge: int = 0
    magic_energy: int = 0
    magic_dust: int = 0
    magic_liquid: int = 0
    magic_exp: int = 0
    degree_cer: int = 0
    graduate_cer: int = 0
    patent_cer: int = 0
    conquer_lev: int = 0
    conquer_loop_id: int = 1
    conquer_region: int = 0
    crab_times: int = 0
    is_commented: int = 1
    comment_open: int = 0
    fbshare_open: int = 0

    # Optional persisted timestamps. Zero means "use server now" when building
    # a player-info response, which is convenient for hand-edited test data.
    energy_time: int = 0
    spirit_energy_time: int = 0
    invitation_time: int = 0
    skill_time: int = 0

    heroes: dict[str, Any] = field(default_factory=dict)
    collected_heros: dict[str, Any] = field(default_factory=dict)
    hero_pieces: list[dict[str, Any]] = field(default_factory=list)
    backpack_items: list[dict[str, Any]] = field(default_factory=list)
    spirit_list: list[dict[str, Any]] = field(default_factory=list)
    runes: dict[str, Any] = field(default_factory=dict)
    scrolls: list[dict[str, Any]] = field(default_factory=list)
    essences: list[dict[str, Any]] = field(default_factory=list)
    formation: dict[str, Any] = field(default_factory=dict)
    save_team: dict[str, Any] = field(default_factory=dict)
    save_team_name: dict[str, Any] = field(default_factory=dict)
    save_pet: dict[str, Any] = field(default_factory=dict)
    message_pushes: dict[str, Any] = field(default_factory=dict)
    func_ids: list[int] = field(default_factory=default_function_ids)
    guide_function_ids: list[int] = field(default_factory=list)
    title_info: dict[str, Any] = field(default_factory=dict)
    vip_awards: list[Any] = field(default_factory=list)
    bubble_info: dict[str, Any] = field(default_factory=dict)

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
    peak_records: list[dict[str, Any]] = field(default_factory=list)
    pets: dict[str, Any] = field(default_factory=dict)

    mails: list[dict[str, Any]] = field(default_factory=list)
    missions: dict[str, list[dict[str, Any]]] = field(default_factory=dict)
    shops: dict[str, list[dict[str, Any]]] = field(default_factory=dict)
    shop_statuses: dict[str, Any] = field(default_factory=dict)
    world_map: dict[str, Any] = field(default_factory=dict)
    arena_info: dict[str, Any] = field(default_factory=dict)
    arena_mode_info: dict[str, Any] = field(default_factory=dict)
    battle_formation: dict[str, Any] = field(default_factory=dict)
    practice_info: dict[str, Any] = field(default_factory=dict)
    trial_infos: dict[str, Any] = field(default_factory=dict)
    march_info: dict[str, Any] = field(default_factory=dict)
    invite_infos: dict[str, Any] = field(default_factory=dict)
    world_boss: dict[str, Any] = field(default_factory=dict)
    building_list: list[dict[str, Any]] = field(default_factory=list)
    tea_talk_info: dict[str, Any] = field(default_factory=dict)
    offline_info: dict[str, Any] = field(default_factory=dict)
    class_info: dict[str, Any] = field(default_factory=dict)
    study_infos: dict[str, Any] = field(default_factory=dict)
    gift_box_info: dict[str, Any] = field(default_factory=dict)
    adventure_list: list[dict[str, Any]] = field(default_factory=list)
    hero_recommend_scores: dict[str, Any] = field(default_factory=dict)
    battle_pass_info: dict[str, Any] = field(default_factory=dict)
    hunqi_start_info: dict[str, Any] = field(default_factory=dict)
    auction_by_type: dict[str, list[dict[str, Any]]] = field(default_factory=dict)

    def now(self) -> int:
        return int(time.time())

    def set_region(self, region: int) -> None:
        region = int(region)
        if region == self.region and self.region_name:
            # Preserve the region name already hydrated from the canonical DB.
            # The engine request carries only the numeric region; blindly
            # rewriting the name here destroyed the known-good "Deep Valley"
            # identity observed for official region 125.
            self.region = region
            return
        self.region = region
        self.region_name = "Deep Valley" if region == 125 else f"Local-{region}"

    def player_brief(self) -> dict[str, Any]:
        return {
            "player_id": self.player_id,
            "player_name": self.player_name,
            "avatar_id": self.avatar_id or DEFAULT_AVATAR_ID,
            "avatar_frame_id": self.avatar_frame_id,
            "lev": self.lev,
            "region": self.region,
            "player_type": self.player_type,
            "guild_id": self.guild_id,
        }

    def player_info_payload(self) -> dict[str, Any]:
        now = self.now()
        func_ids = self.func_ids
        avatar_id = self.avatar_id or DEFAULT_AVATAR_ID
        return {
            "player_id": self.player_id,
            "uid": self.account_uid,
            "player_name": self.player_name,
            "player_type": self.player_type,
            "avatar_id": avatar_id,
            "avatar_frame_id": self.avatar_frame_id,
            "lev": self.lev,
            "exp": self.exp,
            "boss_incr_exp": self.boss_incr_exp,
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
            "buy_glue_times": self.buy_glue_times,
            "lvbu_coin": self.lvbu_coin,
            "paradise_coin": self.paradise_coin,
            "team_dungeon_coin": self.team_dungeon_coin,
            "ice_core": self.ice_core,
            "spirit_stone": self.spirit_stone,
            "energy": self.energy,
            "max_energy": self.max_energy,
            "energy_time": self.energy_time or now,
            "spirit_energy": self.spirit_energy,
            "spirit_energy_time": self.spirit_energy_time or now,
            "invitation": self.invitation,
            "invitation_time": self.invitation_time or now,
            "max_invitation": self.max_invitation,
            "social": self.social,
            "glory": self.glory,
            "vip": self.vip,
            "buy_mana_times": self.buy_mana_times,
            "buy_energy_times": self.buy_energy_times,
            "buy_spirit_energy_times": self.buy_spirit_energy_times,
            "buy_skill_times": self.buy_skill_times,
            "func_ids": func_ids,
            "guide_function_ids": self.guide_function_ids,
            "guide_return_id": self.guide_return_id,
            "skill_point": self.skill_point,
            "skill_time": self.skill_time or now,
            "formation": self.formation,
            "save_team": self.save_team,
            "save_team_name": self.save_team_name,
            "save_pet": self.save_pet,
            "message_pushes": self.message_pushes,
            "is_commented": self.is_commented,
            "comment_open": self.comment_open,
            "fbshare_open": self.fbshare_open,
            "guild_id": self.guild_id,
            "main_scene_type": self.main_scene_type,
            "first_main_touch": self.first_main_touch,
            "arena_beat_flag": self.arena_beat_flag,
            "month_card_start": self.month_card_start,
            "month_card_end": self.month_card_end,
            "privilege_left_card_day": self.privilege_left_card_day,
            "privilege_month_card_end": self.privilege_month_card_end,
            "left_card_day": self.left_card_day,
            "left_week_card_day": self.left_week_card_day,
            "left_month_tili_day": self.left_month_tili_day,
            "charge": self.charge,
            "magic_energy": self.magic_energy,
            "magic_dust": self.magic_dust,
            "magic_liquid": self.magic_liquid,
            "magic_exp": self.magic_exp,
            "degree_cer": self.degree_cer,
            "graduate_cer": self.graduate_cer,
            "patent_cer": self.patent_cer,
            "title_info": self.title_info,
            "vip_awards": self.vip_awards,
            "conquer_lev": self.conquer_lev,
            "conquer_loop_id": self.conquer_loop_id,
            "conquer_region": self.conquer_region,
            "occult_ticket": self.occult_ticket,
            "tutor_coin": self.tutor_coin,
            "skin_coin": self.skin_coin,
            "bubble_info": self.bubble_info,
            "crab_times": self.crab_times,
            "story_id": self.story_id,
            "story_state": self.story_state,
            "guide_id": self.guide_id,
        }

    def heroes_payload(self) -> dict[str, Any]:
        heroes = self.heroes
        # Defensive compatibility for the Stage 3.1 loader regression and any
        # hand-edited/legacy DB that accidentally stores the organizational hero
        # section inside PlayerState.heroes. The source consumer expects
        # params.heros to be the partner-id -> hero-record map directly.
        if isinstance(heroes, dict) and isinstance(heroes.get("heroes"), dict):
            heroes = heroes["heroes"]
        return {"sort_type": 0, "heros": heroes}

    def collected_heros_payload(self) -> dict[str, Any]:
        # SelfPlayer:collectedHerosEvent_ iterates params.list and tonumber()s
        # each value. Keep the richer map in the text DB but serialize the MID
        # as the source consumer expects.
        return {"list": [int(key) if str(key).isdigit() else key for key in self.collected_heros.keys()]}

    def hero_pieces_payload(self) -> dict[str, Any]:
        return {"pieces": self.hero_pieces, "list": self.hero_pieces}

    def backpack_payload(self) -> dict[str, Any]:
        return {"sort_type": 0, "list": self.backpack_items, "spirit_list": self.spirit_list}

    def rune_payload(self) -> dict[str, Any]:
        return {"sort_type": 0, "runes": self.runes, "list": []}

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

    def pet_campaign_red_point_payload(self) -> dict[str, Any]:
        return {"is_red": 0, "red_point": 0}

    def arena_payload(self) -> dict[str, Any]:
        default = {
            "rank": 1,
            "best_rank": 1,
            "defense": [],
            "left_time": 0,
            "buy_num": 0,
            "last_match_time": 0,
            "update_count": 0,
            "enemies": [],
            "pet_id": 0,
            "server_time": self.now(),
            "ban_hero_id": 0,
            "is_ban_open": 0,
            "set_formation_time": 0,
            "fight_times": 0,
        }
        return {**default, **self.arena_info}

    def arena_mode_payload(self) -> dict[str, Any]:
        default = {
            "mode": 0, "submode": 0, "rank": 1, "defense_0": [],
            "left_time": 0, "buy_num": 0, "last_match_time": 0,
            "pet_id": 0, "enemies": [], "leader": self.player_brief(),
        }
        return {**default, **self.arena_mode_info}

    def arena_rank_payload(self) -> dict[str, Any]:
        return {"boss_rank": [], "leisure_arena_rank": [], "newyear_boss_rank": [], "list": [], "rank": 1}

    def arena_formation_payload(self) -> dict[str, Any]:
        return {
            "avatar_frame_id": self.avatar_frame_id, "avatar_id": self.avatar_id,
            "book_shelf_lev": 0, "conquer_lev": 0, "conquer_loop_id": 0,
            "guild_name": "", "heros": [], "is_robot": 0, "lev": self.lev,
            "pet": {}, "player_name": self.player_name, "rank": 1,
            "table_id": 0, "win": 0,
        }

    def battle_formation_payload(self) -> dict[str, Any]:
        return {"formation": self.battle_formation, "formations": self.battle_formation, "pet_id": 0}

    def practice_payload(self, pet: bool = False) -> dict[str, Any]:
        key = "pet" if pet else "hero"
        info = self.practice_info.get(key) or {}
        return {"practice_attr": info.get("practice_attr", [0, 0, 0]), "lock": info.get("lock", []), "times": info.get("times", 0)}

    def arena_records_payload(self) -> dict[str, Any]:
        return {"records": self.arena_records}

    def peak_records_payload(self) -> dict[str, Any]:
        return {"records": self.peak_records}

    def mail_payload(self) -> dict[str, Any]:
        # Mailbox:onMailList_ consumes mail_list/total/new_mail_total.
        new_total = sum(1 for m in self.mails if m.get("is_new", m.get("is_read", 0) == 0))
        return {"mail_list": self.mails, "total": len(self.mails), "new_mail_total": new_total, "server_time": self.now()}

    def mission_payload(self, mission_type: Any = None) -> dict[str, Any]:
        key = str(mission_type or 0)
        return {"mission_list": self.missions.get(key, [])}

    def task_bootstrap_payload(self) -> dict[str, Any]:
        # Task:onTaskBackendEvent() reads these named task buckets when present.
        return {
            "daily_mission_": self.missions.get("daily", []),
            "mainline_mission_": self.missions.get("mainline", []),
            "partner_mission_": self.missions.get("partner", []),
            "awake_mission_": self.missions.get("awake", []),
            "twice_awake_mission_": self.missions.get("twice_awake", []),
            "story_mission_": self.missions.get("story", []),
            "pet_awake_mission_": self.missions.get("pet_awake", []),
        }

    def shop_payload(self, shop_type: Any = None) -> dict[str, Any]:
        key = str(shop_type if shop_type is not None else 0)
        return {
            "items": self.shops.get(key, []),
            "list": self.shops.get(key, []),
            "statuses": self.shop_statuses,
            "refresh_time": self.now() + 3600,
        }

    def shop_list_payload(self) -> dict[str, Any]:
        return {"list": [], "statuses": self.shop_statuses}

    def world_map_payload(self) -> dict[str, Any]:
        default = {
            "normal": [{"campaign_id": 100001, "star": 3, "daily_limit": 0, "reset_count": 0, "is_partner_drop": 0}],
            "super": {},
            "challenge": {},
            "chapter_events": {},
            "chapter_info": {
                "normal_chapter_id": 1,
                "normal_campaign_id": 100001,
                "super_chapter_id": 0,
                "super_campaign_id": 0,
                "normal_stars": 3,
                "normal_bonus_id": 0,
                "super_stars": 0,
                "super_bonus_id": 0,
            },
        }
        out = {**default, **self.world_map}
        out["chapter_info"] = {**default["chapter_info"], **(self.world_map.get("chapter_info") or {})}
        return out

    def trial_infos_payload(self) -> dict[str, Any]:
        default = {
            "trial_info": {"trials": [], "campaigns": []},
            "challenge_info": {"challenges": [], "campaigns": []},
        }
        return {**default, **self.trial_infos}

    def march_payload(self) -> dict[str, Any]:
        default = {
            "map_info": {"is_reborn": 0, "is_external_award": 0, "stage_done": 0, "passed_stage": 0},
            "hero_status": {},
            "enemies": [],
            "rewards": [],
        }
        return {**default, **self.march_info}

    def invite_payload(self) -> dict[str, Any]:
        default = {"missions": [], "invite_players": [], "invite_code": "", "invitor_id": 0, "invitor_name": ""}
        return {**default, **self.invite_infos}

    def world_boss_payload(self) -> dict[str, Any]:
        # WorldBoss:onWorldBoss_ immediately indexes boss_info and floors total_hurt.
        default = {
            "total_hurt": 0, "total_rank": 0, "challenge_times": 0,
            "boss_info": {"boss_brave": 0, "current_boss": 10011, "boss_id": 10011},
            "can_sweep": 0, "buy_times": 0,
        }
        return {**default, **self.world_boss}

    def building_list_payload(self) -> dict[str, Any]:
        # EventCentre:getBuildingList() immediately dereferences building_list
        # rows 1/4/5/6 plus desk_info, pet_cabin_info and cabinet_info.
        # Keep all seven source-defined building types present so red-point and
        # timer code can safely calculate against an idle/default centre.
        defaults = {
            str(building_id): {
                "lev": 1,
                "need_time": 0,
                "start_time": 0,
                "new_evolve": 0,
            }
            for building_id in range(1, 8)
        }

        # Preserve compatible persisted custom building rows if a later stage
        # stores them. Unknown/partial rows are merged onto safe defaults.
        if isinstance(self.building_list, dict):
            for raw_id, row in self.building_list.items():
                key = str(raw_id)
                if key in defaults and isinstance(row, dict):
                    defaults[key].update(row)
        elif isinstance(self.building_list, list):
            for row in self.building_list:
                if not isinstance(row, dict):
                    continue
                raw_id = row.get("building_id", row.get("id"))
                if raw_id is None:
                    continue
                key = str(raw_id)
                if key in defaults:
                    defaults[key].update(row)

        return {
            "building_list": defaults,
            "desk_info": {
                "is_making": 0,
                "make_need_time": 0,
                "make_start_time": 0,
                "make_item": 0,
            },
            "pet_cabin_info": {
                "is_making": 0,
                "make_need_time": 0,
                "make_start_time": 0,
                "make_item": 0,
                "pet_id": 0,
            },
            "cabinet_info": {
                "cur_learn_skill": 0,
                "need_time": 0,
                "start_time": 0,
                "recent_complete_skill": 0,
            },
        }

    def tea_talk_payload(self) -> dict[str, Any]:
        return {"infos": {}, **self.tea_talk_info}

    def offline_payload(self) -> dict[str, Any]:
        return {"awards": [], "time": 0, **self.offline_info}

    def class_info_payload(self) -> dict[str, Any]:
        return {"class_id": 0, "students": [], **self.class_info}

    def study_payload(self) -> dict[str, Any]:
        return {"infos": {}, **self.study_infos}

    def gift_box_payload(self) -> dict[str, Any]:
        return {"infos": {}, "list": [], **self.gift_box_info}

    def adventure_payload(self) -> dict[str, Any]:
        # AdventureEvent:initAdventureEventInfos() indexes adventure_list.list.
        return {"adventure_list": {"list": self.adventure_list}}

    def hero_recommend_payload(self) -> dict[str, Any]:
        return {"scores": self.hero_recommend_scores}

    def battle_pass_payload(self) -> dict[str, Any]:
        default = {
            "base_info": {
                "point": 0,
                "awarded_lev": 0,
                "adv_awarded_lev": 0,
                "limit_purchase_buy": 0,
                "is_advanced": 0,
                "coin_num": 0,
            },
            "mission_info": {"mission_list": [], "mission_counts": [], "is_award": []},
        }
        return {**default, **self.battle_pass_info}

    def hunqi_start_payload(self) -> dict[str, Any]:
        return {"info": {}, **self.hunqi_start_info}


    def achievement_payload(self) -> dict[str, Any]:
        return {
            "achieve_list": [],
            "base_info": {
                "point_level": 1,
                "total_points": 0,
                "rank": 0,
                # Lua achievement code is 1-indexed and may inspect this table.
                "award_status": [-1, -1],
            },
        }

    def achievement_award_payload(self) -> dict[str, Any]:
        return {"awards": [], "base_info": self.achievement_payload()["base_info"]}

    def auction_payload(self, auction_type: Any = None) -> dict[str, Any]:
        key = str(auction_type if auction_type is not None else 0)
        return {"auction_list": self.auction_by_type.get(key, [])}
