"""MID dispatcher for the engine/game HTTP surface."""

from __future__ import annotations

import json
from collections.abc import Callable
from typing import Any

from gxb_backend.config import Settings
from gxb_backend.handlers.activities import ActivityHandlers
from gxb_backend.handlers.achievement import AchievementHandlers
from gxb_backend.handlers.arena import ArenaHandlers
from gxb_backend.handlers.bootstrap import BootstrapHandlers
from gxb_backend.handlers.battle import BattleHandlers
from gxb_backend.handlers.center import CenterHandlers
from gxb_backend.handlers.chat import ChatHandlers
from gxb_backend.handlers.compatibility import CompatibilityHandlers
from gxb_backend.handlers.context import HandlerContext
from gxb_backend.handlers.guild import GuildHandlers
from gxb_backend.handlers.heroes import HeroHandlers
from gxb_backend.handlers.illusion import IllusionHandlers
from gxb_backend.handlers.inventory import InventoryHandlers
from gxb_backend.handlers.library import LibraryHandlers
from gxb_backend.handlers.mail import MailHandlers
from gxb_backend.handlers.player import PlayerHandlers
from gxb_backend.handlers.practice import PracticeHandlers
from gxb_backend.handlers.rewards import RewardHandlers
from gxb_backend.handlers.shop import ShopHandlers
from gxb_backend.handlers.social import SocialHandlers
from gxb_backend.handlers.summon import SummonHandlers
from gxb_backend.handlers.system import SystemHandlers
from gxb_backend.handlers.tasks import TaskHandlers
from gxb_backend.handlers.world import WorldHandlers
from gxb_backend.observability.resource_gateway import ResourceGateway
from gxb_backend.observability.runtime_logger import RuntimeLogger
from gxb_backend.protocol.mids import MID, mid_name
from gxb_backend.protocol.routing import RouteClass, classify_mid
from gxb_backend.state.repository import StateRepository
from gxb_backend.transport.responses import engine_ok

Handler = Callable[[dict[str, Any]], Any]


class EngineDispatcher:
    CENTER_DISCOVERY_MID = 20480
    VERSION_CHECK_MID = 2

    def __init__(
        self,
        state: StateRepository,
        settings: Settings,
        resource_gateway: ResourceGateway | None = None,
    ) -> None:
        self.state = state
        self.settings = settings
        ctx = HandlerContext(state=state, settings=settings, resource_gateway=resource_gateway)

        self.center = CenterHandlers(ctx)
        self.system = SystemHandlers(ctx)
        self.bootstrap = BootstrapHandlers(ctx)
        self.battle = BattleHandlers(ctx)
        self.practice = PracticeHandlers(ctx)
        self.player = PlayerHandlers(ctx)
        self.heroes = HeroHandlers(ctx)
        self.inventory = InventoryHandlers(ctx)
        self.library = LibraryHandlers(ctx)
        self.chat = ChatHandlers(ctx)
        self.summon = SummonHandlers(ctx)
        self.illusion = IllusionHandlers(ctx)
        self.social = SocialHandlers(ctx)
        self.guild = GuildHandlers(ctx)
        self.activities = ActivityHandlers(ctx)
        self.achievement = AchievementHandlers(ctx)
        self.arena = ArenaHandlers(ctx)
        self.tasks = TaskHandlers(ctx)
        self.mail = MailHandlers(ctx)
        self.shop = ShopHandlers(ctx)
        self.world = WorldHandlers(ctx)
        self.rewards = RewardHandlers(ctx)
        self.compat = CompatibilityHandlers(settings)
        self.runtime_logger = RuntimeLogger(settings)

        self.handlers: dict[int, Handler] = self._build_handlers()
        self.scalar_handlers: set[int] = {getattr(MID, "GET_PLAYER_GROUP_BY_KEY", -999999)}

    @staticmethod
    def _put(h: dict[int, Handler], name: str, handler: Handler) -> None:
        mid = getattr(MID, name, -1)
        if isinstance(mid, int) and mid != -1:
            h[mid] = handler

    def _build_handlers(self) -> dict[int, Handler]:
        h: dict[int, Handler] = {
            self.CENTER_DISCOVERY_MID: self.center.center_discovery,
            self.VERSION_CHECK_MID: self.center.version_check,
            MID.RETRIEVE_TOKEN: self.bootstrap.retrieve_token,
            MID.QUERY_SERVER_TIME: self.system.query_server_time,
            MID.LOAD_USER_REGIONS: self.system.load_user_regions,
            MID.LOAD_ANNOUNCE: self.system.load_announce,
            getattr(MID, "GET_PLAYER_GROUP_BY_KEY", -1): self.system.get_player_group_by_key,
            MID.LOAD_PLAYER_INFO: self.player.load_player_info,
            MID.SAVE_STORY: self.player.save_story,
            MID.LOAD_HEROS: self.heroes.load_heros,
            MID.LOAD_BACKPACK: self.inventory.load_backpack,
            MID.LOAD_WORLD_MAP: self.world.load_world_map,
            MID.LOAD_TRIAL_INFOS: self.world.load_trial_infos,
            MID.LOAD_SUMMON_INFO: self.summon.load_summon_info,
            MID.LOAD_FRIENDS: self.social.load_friends,
            MID.ACTIVITIES: self.activities.activities,
            MID.LOAD_ARENA_FIGHT_RECORDS: self.arena.load_arena_fight_records,
        }

        # Boot / first lobby / early runtime.
        direct = {
            "GET_LIBRARY_INFOS": self.library.get_library_infos,
            "SET_BG": self.library.set_bg,
            "ALBUM_SPECIAL_COLLECT_INFO": self.album_special_collect_info,
            "LOAD_CHAT_ROOM_INFO": self.chat.load_chat_room_info,
            "ILLUSION_LOAD_INFO": self.illusion.load_info,
            "GET_SELF_GUILD": self.guild.get_self_guild,
            "PETS_GET": self.heroes.load_pets,
            "PET_CAMPAIGN_RED_POINT": self.pet_campaign_red_point,
            "CHECK_GAME_STAT": self.system.check_game_stat,
            "FIRST_MAIN_TOUCH": self.player.first_main_touch,
            "SET_PLAYER_GUIDE_FUNCTION": self.player.set_player_guide_function,
            "SET_PLAYER_RETURN_ID": self.player.set_player_return_id,
            "GET_PIC_NOTICE_INFO": self.system.get_pic_notice_info,
            "QUERY_CHARGE_DATA": self.system.query_charge_data,
            "GET_BOARD_INFO": self.activities.get_board_info,
            "LOAD_ACHIEVEMENT_INFO": self.achievement.load_achievement_info,
            "GET_ACHIEVEMENT_AWARD": self.achievement.get_achievement_award,
            "LOAD_SINGLE_ACTIVITY": self.activities.load_single_activity,
            "GET_ACTIVITY_REWARD": self.activities.get_activity_reward,
            "LOAD_SIGN_INFO": self.activities.load_sign_info,
            "SIGN": self.activities.sign,
            "DAILY_CONSUNME_LOAD": self.activities.daily_consume_load,
            "DAILY_CONSUNME": self.activities.daily_consume,
            "PEAK_RECORDS": self.arena.peak_records,
            "TASK_LOAD_BY_TYPE": self.tasks.task_load_by_type,
            "TAKE_MISSION_AWARD": self.tasks.take_mission_award,
            "RED_POINT": self.red_point,
        }
        for name, handler in direct.items():
            self._put(h, name, handler)

        # Stage 2 common lobby windows / panels.
        extra = {
            "LOAD_MAIL_LIST": self.mail.load_mail_list,
            "SET_MAIL_READ": self.mail.set_mail_read,
            "MAIL_ONEKEY": self.mail.mail_onekey,
            "LOAD_SHOP": self.shop.load_shop,
            "LOAD_SHOP_LIST": self.shop.load_shop_list,
            "BUY_SHOP": self.shop.buy_shop,
            "REFRESH_SHOP": self.shop.refresh_shop,
            "CLOSE_SHOP": self.shop.close_shop,
            "MARKET_BUY": self.shop.market_buy,
            "LOAD_RUNE": self.inventory.load_rune,
            "LOAD_SCROLLS": self.inventory.load_scrolls,
            "LOAD_ESSENCES": self.inventory.load_essences,
            "SELL_ITEM": self.inventory.sell_item,
            "SELL_ITEMS": self.inventory.sell_items,
            "COMPOSE_ITEM": self.inventory.compose_item,
            "USE_MAGIC_ITEMS": self.inventory.use_magic_items,
            "USE_ENERGY_ITEM": self.inventory.use_energy_item,
            "USE_SKILL_POINT_ITEM": self.inventory.use_skill_point_item,
            "USE_EXP_ITEM": self.inventory.use_exp_item,
            "USE_EXP_ITEMS": self.inventory.use_exp_items,
            "BACKPACK_SORT_TYPE": self.inventory.sort_type,
            "SAVA_SORT_TYPE": self.heroes.save_sort_type,
            "LOAD_HERO": self.heroes.load_hero,
            "LOAD_COLLECTED_HEROS": self.heroes.load_collected_heros,
            "LOAD_HERO_PIECES": self.heroes.load_hero_pieces,
            "SAVE_TEAM": self.heroes.save_team,
            "SET_BOARD_HERO": self.heroes.set_board_hero,
            "BUY_SKILL_POINT": self.heroes.buy_skill_point,
            "SET_SKILL_LEVEL": self.heroes.set_skill_level,
            "SET_ALL_SKILL_LEVEL": self.heroes.set_all_skill_level,
            "SUMMON_HERO": self.rewards.awards_empty,
            "STONE_SUMMON_HERO": self.rewards.awards_empty,
            "MAGIC_SUMMON_BUY": self.rewards.awards_empty,
            "EDIT_PLAYER_NAME": self.system.edit_player_name,
            "GENERATE_PLAYER_NAME": self.system.generate_player_name,
            "SET_AVATAR_ID": self.system.set_avatar_id,
            "EDIT_AVATAR_RRAME": self.system.edit_avatar_frame,
            "GET_COMMENT_AWARD": self.system.get_comment_award,
            "GET_MAXLEVEL": self.system.get_maxlevel,
            "SEARCH_PLAYER": self.social.search_player,
            "LOAD_FRIEND_INFO": self.social.load_friend_info,
            "LOAD_GET_REQUEST_PLAYERS": self.social.load_get_request_players,
            "REQUEST_FRIEND": self.social.request_friend,
            "WORLD_BOSS": self.world.world_boss,
            "LOAD_MARCH": self.world.load_march,
            "LOAD_INVITE_INFOS": self.invite_infos,
            "GET_INVITE_AWARD": self.rewards.awards_empty,
            "GET_AUCTION_INFO_BY_TYPE": self.arena.get_auction_info_by_type,
            "GET_OFFLINE_INFO": self.rewards.get_offline_info,
            "GET_BUILDING_LIST": self.rewards.get_building_list,
            "GET_TEA_TALK_INFO": self.rewards.get_tea_talk_info,
            "GET_CLASS_INFO": self.rewards.get_class_info,
            "GET_STUDY_INFOS": self.rewards.get_study_infos,
            "GET_GIFT_BOX_INFO": self.rewards.get_gift_box_info,
            "GET_ADVENTURE_LIST": self.world.get_adventure_list,
            "GET_HERO_RECOMMEND_SCORES": self.rewards.get_hero_recommend_scores,
            "BATTLE_PASS_GET_INFO": self.rewards.battle_pass_get_info,
            "HUNQI_START_GAME_GET_INFO": self.rewards.hunqi_start_game_get_info,
            "SWEEP_CAMPAIGN": self.world.sweep_campaign,
            "GET_RENT_HEROS": self.world.get_rent_heros,
            "RESET_CAMPAIGN": self.world.reset_campaign,
            "GET_BONUS_AWARD": self.world.get_bonus_award,
            "FIGHT": self.world.fight,
            "GET_STORY_DROP_PARTNER": self.world.get_story_drop_partner,
            "FIGHT_RESULT": self.world.fight_result,
        }
        for name, handler in extra.items():
            self._put(h, name, handler)

        # Stage 3 domain foundation. These families are sourced from Pass 19's
        # domain rewrite gate and use domain-owned state rather than one-off call-site
        # stubs, so unidentified variants can be added without changing architecture.
        stage3 = {
            # practice: finite dynamic family resolved in Pass 19
            "GET_PRACTICE_INFO": self.practice.hero_info,
            "PRACTICE": self.practice.hero_mutation,
            "PRACTICE_SAVE": self.practice.hero_mutation,
            "PRACTICE_AUTO": self.practice.hero_mutation,
            "WASH_BY_TICKET": self.practice.hero_mutation,
            "PET_GET_PRACTICE_INFO": self.practice.pet_info,
            "PET_PRACTICE": self.practice.pet_mutation,
            "PET_PRACTICE_SAVE": self.practice.pet_mutation,
            "PET_PRACTICE_AUTO": self.practice.pet_mutation,
            "PET_WASH_BY_TICKET": self.practice.pet_mutation,
            "PET_USE_EXP_ITEMS": self.practice.pet_mutation,

            # battle formation/session
            "LOAD_BATTLE_FORMATION": self.battle.load_formation,
            "SET_FORMATION": self.battle.set_formation,
            "ENTER_BATTLE": self.battle.enter_battle,
            "LOAD_FRIEND_REP_HEROS": self.battle.friend_rep_heros,
            "END_BATTLE": self.battle.end_battle,
            "BATTLE_REVIVE": self.battle.end_battle,

            # missions / tasks
            "LOAD_MISSION": self.tasks.load_mission,
            "COMPLETE_MISSION": self.tasks.mission_status,
            "OPEN_AWAKE_MISSION": self.tasks.mission_status,
            "GIVE_UP_AWAKE_MISSION": self.tasks.mission_status,
            "OPEN_PET_AWAKE_MISSION": self.tasks.mission_status,
            "GIVE_UP_PET_AWAKE_MISSION": self.tasks.mission_status,
            "OPEN_AWAKE_TWICE_MISSION": self.tasks.mission_status,
            "GIVE_UP_AWAKE_TWICE_MISSION": self.tasks.mission_status,
            "GET_DAY_HUOYUE_AWARD": self.tasks.huoyue_award,
            "GET_WEEK_HUOYUE_AWARD": self.tasks.huoyue_award,
            "GET_AWAKE_ITEM": self.tasks.mission_status,
            "TASK_AWAKE_GIVE_UP": self.tasks.mission_status,
            "TASK_AWAKE_OPEN": self.tasks.mission_status,

            # social
            "DENY_FRIEND_REQUEST": self.social.social_status_only,
            "IGNORE_FRIEND_REQUEST": self.social.social_status_only,
            "ACCEPT_FRIEND_REQUEST": self.social.social_status_only,
            "DELETE_FRIEND": self.social.social_status_only,
            "ACCEPT_ALL_FRIEND_REQUEST": self.social.social_status_only,
            "READ_NOTICE": self.social.social_status_only,
            "ADD_BLACK_LIST": self.social.social_status_only,
            "REMOVE_BLACK_LIST": self.social.social_status_only,
            "CLEAR_BLACK_LIST": self.social.social_status_only,
            "GET_RECOMMEND_FRIENDS": self.social.get_recommend_friends,

            # arena core + Pass19 dynamic record/formation family
            "LOAD_ARENA": self.arena.load_arena,
            "LOAD_ARENA_PLAYER_LIST": self.arena.player_list,
            "ARENA_REFRESH": self.arena.refresh,
            "LOAD_ARENA_NPC_LIST": self.arena.player_list,
            "LOAD_ARENA_RANK": self.arena.rank,
            "LOAD_ARENA_DEFENSE": self.arena.defense,
            "SAVE_ARENA_DEFENSE": self.arena.save_defense,
            "START_FIGHT": self.arena.start_fight,
            "ARENA_BUY_TICKET": self.arena.buy_ticket,
            "ARENA_MODE_INFO": self.arena.mode_info,
            "ARENA_MODE_ENEMY_LIST": self.arena.mode_enemy_list,
            "ARENA_MODE_DEFENCE": self.arena.save_defense,
            "ARENA_MODE_FIGHT_PRE": self.arena.start_fight,
            "ARENA_MODE_FIGHT": self.arena.start_fight,
            "ARENA_MODE_BUY_TICKET": self.arena.buy_ticket,
            "ARENA_RESET_TIMER": self.arena.mode_info,
            "LOAD_ARENA_FIGHT_REPORT": self.arena.load_arena_fight_report,
            "query_arena_formation": self.arena.query_formation,
            "ARENA_GET_RCORD_PLAYER_INFO": self.arena.query_formation,
            "ARENA_PRE_FIGHT": self.arena.start_fight,
            "ARENA_MODE_QUERY_FORMATION": self.arena.query_formation,
            "ARENA_MODE_RESET_TIME": self.arena.mode_info,
            "ARENA_MODE_RECORD_DETAIL": self.arena.record_detail,
            "ARENA_MODE_RECORD_PLAYER_INFO": self.arena.query_formation,
            "ARENA_MODE_SCHEDULE": self.arena.mode_info,

            # world / march / boss
            "CHALLENGEINFO": self.world.challenge_info,
            "RESTART_MARCH": self.world.march_action,
            "MARCH_FIGHT_RESULT": self.world.march_action,
            "MARCH_OPEN_BOX": self.world.march_action,
            "MARCH_START_FIGHT": self.world.march_action,
            "MARCH_OPEN_EXTRA_CHEST": self.world.march_action,
            "MARCH_ADVANCE_SWEEP": self.world.march_action,
            "WORLD_BOSS_BUY_TIMES": self.world.world_boss_action,
            "WORLD_BOSS_START_FIGHT": self.world.world_boss_action,
            "WORLD_BOSS_FIGHT_RESULT": self.world.world_boss_action,
            "WORLD_BOSS_SWEEP": self.world.world_boss_action,

            # guild/team broad skeletons with exact fields consumed by SelfGuild
            "LOAD_ALL_TEAMS": self.guild.guild_list,
            "LOAD_TEAM_BY_ID": self.guild.team_data,
            "LOAD_APPLY_LIST_TEAM": self.guild.guild_list,
            "PLAYER_LOAD_APPLY_LIST_TEAM": self.guild.guild_list,
            "GET_DATA_TEAM": self.guild.team_data,
            "LOAD_DRINK_INFO": self.guild.load_drink_info,
            "BUY_DRINK": self.guild.drink_action,
            "DO_DRINK": self.guild.drink_action,
            "LOAD_SENT_HEROS": self.guild.load_sent_heros,
            "RENT_HERO": self.guild.rent_hero,
            "CANCEL_RENT_HERO": self.guild.rent_hero,
            "LOAD_GUILD_CAMPAIGN_LIST": self.guild.guild_campaign_list,
            "RESET_CHAPTER": self.guild.guild_campaign_list,
            "LOAD_GUILD_MAP": self.guild.guild_map,
            "LOAD_GUILD_AWARD_LIST": self.guild.guild_awards,
            "APPLY_REWARD": self.guild.guild_awards,
            "GUILD_CHAPTER_DAMAGE_RANK": self.guild.damage_rank,
            "GUILF_ALL_SERVER_DAMAGE_RANK": self.guild.all_server_damage_rank,
            "OPEN_CHAPTER": self.guild.guild_campaign_list,
            "LOAD_GUILD_MAP_DETAIL": self.guild.guild_map,
            "GUILD_FIGHT_PREPARE": self.guild.fight_prepare,
            "GUILD_DISTRIBUTE_RECORD": self.guild.distribute_record,
            "GUILD_RANK": self.guild.guild_list,
            "EXCHANGE_DRINK": self.guild.drink_action,
            "LOAD_RENT_PET": self.guild.rent_pets,
            "RENT_PET": self.guild.rent_pets,
            "CANCEL_RENT_PET": self.guild.rent_pets,
            "LOAD_CAN_RENT_PET_LIST": self.guild.rent_pets,

            # pets
            "PET_SUMMON": self.heroes.pet_action,
            "PET_CLEAN_CD": self.heroes.pet_action,
            "PET_EQUIP": self.heroes.pet_action,
            "PET_UPGRADE_SKILL": self.heroes.pet_action,
            "PET_ADVANCE": self.heroes.pet_action,
            "PET_EVOLVE": self.heroes.pet_action,
            "PET_FEED": self.heroes.pet_action,
            "PET_BUY_BOOK": self.heroes.pet_action,
            "PET_SET_SHOW": self.heroes.pet_action,
            "PET_ONE_KEY_UP": self.heroes.pet_action,
            "PET_UPGRADE_ALL_SKILL": self.heroes.pet_action,
            "PET_ONE_KEY_EQUIP": self.heroes.pet_action,
            "PET_CAMPAIGN_LOAD_INFO": self.heroes.pet_campaign_info,
            "PET_CAMPAIGN_SWEEP": self.heroes.pet_campaign_action,
            "PET_CAMPAIGN_RECORD_SWEEP_TIME": self.heroes.pet_campaign_action,
            "PET_CAMPAIGN_FIGHT": self.heroes.pet_campaign_action,
            "PET_CAMPAIGN_BATTLE_RESULT": self.heroes.pet_campaign_action,
            "PET_CAMPAIGN_RESTART": self.heroes.pet_campaign_action,
            "PET_CAMPAIGN_AWAKE_SWEEP": self.heroes.pet_campaign_action,
            "PET_CAMPAIGN_SWEEP_SUPER": self.heroes.pet_campaign_action,
            "PET_CAMPAIGN_BUY_SUPER": self.heroes.pet_campaign_action,
            "PET_CAMPAIGN_SAVE_SUPER": self.heroes.pet_campaign_action,
            "PET_CAMPAIGN_PRACTICE": self.heroes.pet_campaign_action,

            # market + battle pass
            "SHOP_MAGIC_UNLOCK": self.shop.load_magic_shop,
            "MARKET_GET_CART": self.shop.market_cart,
            "MARKET_ADD_TO_CART": self.shop.market_cart_mutation,
            "MARKET_CLEAR_CART": self.shop.market_cart_mutation,
            "MARKET_PAY_THE_BILL": self.shop.market_cart_mutation,
            "MARKET_DELETE_ITEM": self.shop.market_cart_mutation,
            "SKIN_SHOP_INFO": self.shop.skin_shop_info,
            "BUY_SHOP_MULTI": self.shop.buy_shop,
            "BATTLE_PASS_BUY_LEVEL": self.rewards.awards_empty,
            "BATTLE_PASS_BUY_LIMIT_PURCHASE": self.rewards.awards_empty,
            "BATTLE_PASS_GET_AWARD": self.rewards.awards_empty,
            "BATTLE_PASS_GET_MISSION_AWARD": self.rewards.awards_empty,
        }
        for name, handler in stage3.items():
            self._put(h, name, handler)

        # Status-only / safe acknowledgement commands seen during early boot,
        # first-entry popups, and zlib/form result paths. More semantic state
        # can be promoted later without changing router structure.
        status_only_names = [
            "READ_PIC_NOTICE",
            "SEND_OPERATION_LOG",
            "FUNCTION_CLICK",
            "READ_NOTICE",
            "DENY_FRIEND_REQUEST",
            "IGNORE_FRIEND_REQUEST",
            "ACCEPT_FRIEND_REQUEST",
            "DELETE_FRIEND",
            "ACCEPT_ALL_FRIEND_REQUEST",
            "SEND_SOCIAL_GIFT",
            "RECEIVE_SOCIAL",
            "ARENA_FIGHT_RESULT",
            "PEAK_START_FIGHT",
            "TREASURE_SAVE_BATTLE_RESULT",
            "REARENA_END_FIGHT",
            "REGION_FIGHT_RESULT",
            "CONQUER_SCHOOL_FIGHT_RESULT",
            "SAVE_FURNITURES",
            "HUNQI_GET_CAMPAIGN_INFO",
            "SET_HERO_EQUIP",
            "ONE_CLICK_EQUIP",
            "POWERUP_HERO",
            "EVOLVE_HERO",
            "FUMO",
            "ONE_CLICK_JINJIE",
            "EXPAND_HERO_SLOTS",
            "DISMISS_HERO",
            "UNLOCK_DYNAMIC_CARD",
            "SHOW_DYNAMIC_CARD",
            "MAGIC_SUMMON_SWITCH_HERO",
            "ALBUM_PARTNER_UNLOCK",
        ]
        for name in status_only_names:
            mid = getattr(MID, name, -1)
            if mid != -1 and mid not in h:
                h[mid] = self.system.status_only

        return {mid: func for mid, func in h.items() if mid != -1}

    def album_special_collect_info(self, req: dict[str, Any]) -> dict[str, Any]:
        # SelfPlayer:getAlbumAttrInfo() assigns response.is_award directly to
        # albumSpecialCollect, then calculateWhiteAlbumAttr()/checkAlbumSpecial()
        # iterate it with # and numeric indexes. Authoritative collect_special.lua
        # has contiguous IDs 1..23, so a fresh account needs a 23-slot zero list,
        # not the old scalar 0 compatibility placeholder.
        return {"is_award": [0] * 23}

    def red_point(self, req: dict[str, Any]) -> list[dict[str, Any]]:
        return self.state.get_player().redmark_payload()

    def pet_campaign_red_point(self, req: dict[str, Any]) -> dict[str, Any]:
        return self.state.get_player().pet_campaign_red_point_payload()

    def invite_infos(self, req: dict[str, Any]) -> dict[str, Any]:
        return self.state.get_player().invite_payload()

    def dispatch(self, req: dict[str, Any]) -> Any:
        # Stage 4A request scope keeps the human-editable JSON refresh and any
        # handler mutation/save on one coherent PlayerState snapshot.
        with self.state.request_scope(req):
            return self._dispatch_scoped(req)

    def _dispatch_scoped(self, req: dict[str, Any]) -> Any:
        try:
            req_mid = int(req.get("mid", 0))
        except Exception:
            print(f"[ENGINE] request without numeric mid: {req!r}")
            return engine_ok()

        route_class = classify_mid(req_mid)
        name = mid_name(req_mid)
        print(f"[ENGINE IN] mid={name} ({req_mid}) route={route_class.value} data={json.dumps(req, ensure_ascii=False, default=str)}")

        handler = self.handlers.get(req_mid)
        fallback_used = handler is None
        if fallback_used:
            result = self.compat.fallback(req)
            handler_name = "compat.fallback"
        else:
            result = handler(req)
            handler_name = getattr(handler, "__qualname__", repr(handler))

        self.runtime_logger.request(
            mid=req_mid,
            name=name,
            route=route_class.value,
            req=req,
            handler=handler_name,
            response=result,
            fallback=fallback_used,
        )

        if req_mid in self.scalar_handlers:
            print(f"[ENGINE OUT] scalar={result!r}")
            return result

        response = engine_ok(result)
        if route_class == RouteClass.ENGINE_ZLIB_FORM:
            # Keep battle/result acknowledgements minimal but successful.
            response.setdefault("result", 1)
        print(f"[ENGINE OUT] {json.dumps(response, ensure_ascii=False, separators=(',', ':'), default=str)}")
        return response
