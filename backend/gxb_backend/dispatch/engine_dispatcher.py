"""MID dispatcher for the engine/game HTTP surface."""

from __future__ import annotations

import json
from collections.abc import Callable
from typing import Any

from gxb_backend.config import Settings
from gxb_backend.handlers.activities import ActivityHandlers
from gxb_backend.handlers.arena import ArenaHandlers
from gxb_backend.handlers.bootstrap import BootstrapHandlers
from gxb_backend.handlers.center import CenterHandlers
from gxb_backend.handlers.chat import ChatHandlers
from gxb_backend.handlers.compatibility import CompatibilityHandlers
from gxb_backend.handlers.context import HandlerContext
from gxb_backend.handlers.heroes import HeroHandlers
from gxb_backend.handlers.illusion import IllusionHandlers
from gxb_backend.handlers.inventory import InventoryHandlers
from gxb_backend.handlers.library import LibraryHandlers
from gxb_backend.handlers.player import PlayerHandlers
from gxb_backend.handlers.social import SocialHandlers
from gxb_backend.handlers.summon import SummonHandlers
from gxb_backend.handlers.system import SystemHandlers
from gxb_backend.handlers.tasks import TaskHandlers
from gxb_backend.protocol.mids import MID, mid_name
from gxb_backend.protocol.routing import RouteClass, classify_mid
from gxb_backend.state.repository import StateRepository
from gxb_backend.transport.responses import engine_ok

Handler = Callable[[dict[str, Any]], Any]


class EngineDispatcher:
    CENTER_DISCOVERY_MID = 20480
    VERSION_CHECK_MID = 2

    def __init__(self, state: StateRepository, settings: Settings) -> None:
        self.state = state
        self.settings = settings
        ctx = HandlerContext(state=state, settings=settings)

        self.center = CenterHandlers(ctx)
        self.system = SystemHandlers(ctx)
        self.bootstrap = BootstrapHandlers(ctx)
        self.player = PlayerHandlers(ctx)
        self.heroes = HeroHandlers(ctx)
        self.inventory = InventoryHandlers(ctx)
        self.library = LibraryHandlers(ctx)
        self.chat = ChatHandlers(ctx)
        self.summon = SummonHandlers(ctx)
        self.illusion = IllusionHandlers(ctx)
        self.social = SocialHandlers(ctx)
        self.activities = ActivityHandlers(ctx)
        self.arena = ArenaHandlers(ctx)
        self.tasks = TaskHandlers(ctx)
        self.compat = CompatibilityHandlers(settings)

        self.handlers: dict[int, Handler] = self._build_handlers()
        self.scalar_handlers: set[int] = {getattr(MID, "GET_PLAYER_GROUP_BY_KEY", -999999)}

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
            MID.LOAD_HEROS: self.heroes.load_heros,
            MID.LOAD_BACKPACK: self.inventory.load_backpack,
            getattr(MID, "GET_LIBRARY_INFOS", -1): self.library.get_library_infos,
            getattr(MID, "SET_BG", -1): self.library.set_bg,
            getattr(MID, "ALBUM_SPECIAL_COLLECT_INFO", -1): self.album_special_collect_info,
            MID.LOAD_CHAT_ROOM_INFO: self.chat.load_chat_room_info,
            MID.LOAD_SUMMON_INFO: self.summon.load_summon_info,
            getattr(MID, "ILLUSION_LOAD_INFO", -1): self.illusion.load_info,
            MID.LOAD_FRIENDS: self.social.load_friends,
            getattr(MID, "GET_SELF_GUILD", -1): self.social.get_self_guild,
            getattr(MID, "PETS_GET", -1): self.heroes.load_pets,
            getattr(MID, "CHECK_GAME_STAT", -1): self.system.check_game_stat,
            getattr(MID, "FIRST_MAIN_TOUCH", -1): self.player.first_main_touch,
            getattr(MID, "GET_PIC_NOTICE_INFO", -1): self.system.get_pic_notice_info,
            MID.QUERY_CHARGE_DATA: self.system.query_charge_data,
            MID.ACTIVITIES: self.activities.activities,
            getattr(MID, "GET_BOARD_INFO", -1): self.activities.get_board_info,
            MID.LOAD_SINGLE_ACTIVITY: self.activities.load_single_activity,
            MID.GET_ACTIVITY_REWARD: self.activities.get_activity_reward,
            MID.LOAD_SIGN_INFO: self.activities.load_sign_info,
            MID.SIGN: self.activities.sign,
            MID.DAILY_CONSUNME_LOAD: self.activities.daily_consume_load,
            MID.DAILY_CONSUNME: self.activities.daily_consume,
            MID.LOAD_ARENA_FIGHT_RECORDS: self.arena.load_arena_fight_records,
            getattr(MID, "PEAK_RECORDS", -1): self.arena.peak_records,
            getattr(MID, "TASK_LOAD_BY_TYPE", -1): self.tasks.task_load_by_type,
            getattr(MID, "TAKE_MISSION_AWARD", -1): self.tasks.take_mission_award,
            getattr(MID, "RED_POINT", -1): self.red_point,
        }

        # Status-only / safe acknowledgement commands seen during early boot,
        # first-entry popups, and zlib/form result paths. More semantic state
        # can be promoted later without changing router structure.
        status_only_names = [
            "READ_PIC_NOTICE",
            "SEND_OPERATION_LOG",
            "FUNCTION_CLICK",
            "READ_NOTICE",
            "REQUEST_FRIEND",
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
        ]
        for name in status_only_names:
            mid = getattr(MID, name, -1)
            if mid != -1 and mid not in h:
                h[mid] = self.system.status_only

        return {mid: func for mid, func in h.items() if mid != -1}

    def album_special_collect_info(self, req: dict[str, Any]) -> dict[str, Any]:
        return {"is_award": 0}

    def red_point(self, req: dict[str, Any]) -> list[dict[str, Any]]:
        return self.state.get_player().redmark_payload()

    def dispatch(self, req: dict[str, Any]) -> Any:
        try:
            req_mid = int(req.get("mid", 0))
        except Exception:
            print(f"[ENGINE] request without numeric mid: {req!r}")
            return engine_ok()

        route_class = classify_mid(req_mid)
        name = mid_name(req_mid)
        print(f"[ENGINE IN] mid={name} ({req_mid}) route={route_class.value} data={json.dumps(req, ensure_ascii=False, default=str)}")

        handler = self.handlers.get(req_mid)
        if handler is None:
            result = self.compat.fallback(req)
        else:
            result = handler(req)

        if req_mid in self.scalar_handlers:
            print(f"[ENGINE OUT] scalar={result!r}")
            return result

        response = engine_ok(result)
        if route_class == RouteClass.ENGINE_ZLIB_FORM:
            # Keep battle/result acknowledgements minimal but successful.
            response.setdefault("result", 1)
        print(f"[ENGINE OUT] {json.dumps(response, ensure_ascii=False, separators=(',', ':'), default=str)}")
        return response
