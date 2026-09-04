"""Coherent player profiles for client-facing backend stages."""

from __future__ import annotations

from .player_state import ALL_SOURCE_FUNCTION_IDS, PlayerState


def apply_established_profile(player: PlayerState) -> PlayerState:
    """Make state internally coherent for broad Stage 3 UI/domain initialization.

    This is intentionally conservative: it unlocks source FunctionIDs and seeds
    structural progression, but does not pretend unimplemented gameplay is real.
    """
    player.func_ids = list(ALL_SOURCE_FUNCTION_IDS)
    player.lev = max(int(player.lev or 1), 99)
    player.vip = max(int(player.vip or 0), 15)
    player.energy = max(int(player.energy or 0), 100)
    player.max_energy = max(int(player.max_energy or 0), 100)
    # Source: the base tutorial ends at GUIDE_END=100197, but later tutorial
    # families continue through PET/CLOUD_CITY/CHAPTER_BOSS and finally
    # GUIDE_CONQUER_SCHOOL_END=101001. An established test account should be
    # beyond those guide gates; guide_id=0 intentionally enters tutorial mode.
    player.guide_id = max(int(player.guide_id or 0), 101001)

    player.world_map = {
        **player.world_map,
        "normal": player.world_map.get("normal") or [
            {"campaign_id": 100001, "star": 3, "daily_limit": 0, "reset_count": 0, "is_partner_drop": 0}
        ],
        "chapter_info": {
            "normal_chapter_id": 1,
            "normal_campaign_id": 100001,
            "super_chapter_id": 0,
            "super_campaign_id": 0,
            "normal_stars": 3,
            "normal_bonus_id": 0,
            "super_stars": 0,
            "super_bonus_id": 0,
            **(player.world_map.get("chapter_info") or {}),
        },
    }
    player.trial_infos = {
        "trial_info": {"trials": [], "campaigns": []},
        "challenge_info": {"challenges": [], "campaigns": []},
        **player.trial_infos,
    }
    player.march_info = {
        "map_info": {"is_reborn": 0, "is_external_award": 0, "stage_done": 0, "passed_stage": 0},
        "hero_status": {}, "enemies": [], "rewards": [],
        **player.march_info,
    }
    player.battle_pass_info = {
        "base_info": {"point": 0, "awarded_lev": 0, "adv_awarded_lev": 0,
                      "limit_purchase_buy": 0, "is_advanced": 0, "coin_num": 0},
        "mission_info": {"mission_list": [], "mission_counts": [], "is_award": []},
        **player.battle_pass_info,
    }

    # Source-backed starter roster. 10001001 is the first real row in
    # data/tables/partner.lua identifies Aquaris; source ini_star is 1.
    # The established compatibility profile retains star=3 as current state. partner_id is a
    # deterministic local entity id, while table_id is the source table id.
    if not player.heroes:
        hero = {
            "player_id": player.player_id,
            "partner_id": 10001,
            "table_id": 10001001,
            "star": 3,
            "lev": 20,
            "exp": 0,
            "color": 3,
            "skills": [1, 1, 1, 1, 1, 1],
            "equips": [0, 0, 0, 0, 0, 0],
            "fumos": [0, 0, 0, 0, 0, 0],
            "skin_ids": [],
            "current_skin_id": 0,
            "practice_attr": [0, 0, 0],
            "skill_book_info": {},
            "courses": [],
            "courses_progress": [],
            "courses_skill": [],
            "courses_quality": [],
            "courses_exp": [],
            "is_board": 1,
            "board_card": 1,
        }
        player.heroes = {"10001": hero}
        player.collected_heros = {"10001001": {"table_id": 10001001, "star": 3, "is_collected": 1}}
        player.formation.setdefault("rep_partner_id", 10001)
    return player


def apply_profile(player: PlayerState, profile: str) -> PlayerState:
    if (profile or "").lower() in {"established", "stage3", "all"}:
        return apply_established_profile(player)
    return player


def make_fresh_player(*, account_uid: str, player_id: str, region: int, region_name: str) -> PlayerState:
    """Create a conservative first-login player for credential accounts.

    Pass 22 source confirms the structural lifecycle (empty name, is_new=1,
    tutorial naming later), but not every original starting currency.  Values
    here are deliberately low/minimal local-server defaults and are documented
    as compatibility policy rather than recovered official economics.
    """
    player = PlayerState()
    player.account_uid = str(account_uid)
    player.player_id = str(player_id)
    player.player_name = ""
    player.region = int(region)
    player.region_name = str(region_name)
    player.token = ""
    player.player_type = 0
    player.lev = 1
    player.exp = 0
    player.vip = 0
    player.guild_id = 0

    # Do not inherit the established sandbox's reconstruction currencies.
    player.mana = 0
    player.crystal = 0
    player.lucky_coin = 0
    player.arena_coin = 0
    player.march_coin = 0
    player.top_coin = 0
    player.guild_coin = 0
    player.region_coin = 0
    player.king_coin = 0
    player.honor_coin = 0
    player.god_war_coin = 0
    player.friendship_coin = 0
    player.friend_medal = 0
    player.summon_coin = 0
    player.skin_fragment = 0
    player.glue = 0
    player.lvbu_coin = 0
    player.paradise_coin = 0
    player.team_dungeon_coin = 0
    player.ice_core = 0
    player.spirit_stone = 0
    player.occult_ticket = 0
    player.tutor_coin = 0
    player.skin_coin = 0

    # Source data/tables/player.lua level-1 row: Energy cap is 60.
    # The previous fresh template inherited the established sandbox's 100.
    player.energy = 60
    player.max_energy = 60
    player.energy_time = 0

    # Arena invitation state is not part of the fresh single-player slice yet.
    # Keep it absent on the wire to avoid the authoritative client's latent
    # SelfPlayer/player.lua invitation mismatch during economy_ synchronization.
    player.invitation = None
    player.max_invitation = None
    player.invitation_time = 0

    # Filled to the effective-source natural cap by MultiUserDatabase at the
    # canonical fresh-player creation boundary (Pass 30.1 compatibility policy).
    player.skill_point = 0
    player.skill_time = 0
    player.first_main_touch = 0
    player.main_scene_type = 0
    player.story_id = 0
    player.story_state = 0
    player.guide_id = 0
    player.guide_return_id = 0
    player.func_ids = []
    player.guide_function_ids = {}
    player.is_commented = 0

    # Base character construction stays minimal here. v0.8.1 immediately
    # applies the Pass-23 tutorial seed during canonical normalization: Aquaris
    # partner_id=1 is owned before the scripted Lavia/Pandaria summon guide.
    player.heroes = {}
    player.collected_heros = {}
    player.hero_pieces = {}
    player.hero_next_partner_id = 10001
    player.formation = {}
    player.backpack_items = []
    player.spirit_list = []
    player.pets = {}
    player.world_map = {}
    player.active_campaign_battle = {}
    return player
