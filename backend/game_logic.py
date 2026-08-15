#!/usr/bin/env python3
"""
Minimal state/response layer for the GXB private server.

Important:
Engine responses are flat JSON objects. server.py adds error_code=0 at the
top level. Do not create a generic {"data": ...} envelope here.
"""

import json
import time


PLAYER_ID = "13371337"
PLAYER_NAME = "AdminRoot"
DEFAULT_TOKEN = "local_token"
DEFAULT_REGION = 7


def handle_center_discovery(req_data, self_url):
    return {
        "url": self_url,
        "server_id": 1,
        "back_domain": "",
        "res_download_url": "",
    }


def handle_version_check(req_data):
    return {
        "is_appstore": 0,
        "is_inapp": 0,
        "is_review": 0,
        "need_restart": 0,
    }


def handle_retrieve_token(req_data):
    region = req_data.get("region", DEFAULT_REGION)
    try:
        region = int(region)
    except (TypeError, ValueError):
        region = DEFAULT_REGION

    # --- CRITICAL FIX (2026-08-16 session) -----------------------------
    # app/model/SelfPlayer.lua registers loginEvent_ on xyd.event.TOKEN,
    # which Backend.lua dispatches from *inside* the RETRIEVE_TOKEN
    # response handler (var_23_2), BEFORE it invokes the caller's own
    # inline callback (the one in LoadingScene.lua that does
    # display.replaceScene(xyd.MainScene.new())).
    #
    # loginEvent_ -> loadGameStartInfoEvent_ does:
    #     local var_221_0 = arg_221_1.params.detail
    #     for iter_221_0, iter_221_1 in pairs(var_221_0) do ...
    #
    # If "detail" is absent, params.detail is nil and pairs(nil) throws
    # an uncaught Lua error *inside the event dispatch*, which (assuming
    # xyd.EventDispatcher does not pcall-wrap listeners, consistent with
    # every other listener call site read in this codebase) aborts the
    # rest of Backend.lua's var_23_2 before it ever reaches the
    # `arg_23_3(...)` call that runs LoadingScene.lua's own callback --
    # i.e. before display.replaceScene(xyd.MainScene.new()) ever runs.
    # This exactly matches the observed symptom: guest login succeeds,
    # then the loading spinner never goes away and no further engine
    # requests are ever sent.
    #
    # "detail" is a dict keyed by *stringified* MID, containing a batch
    # of pre-loaded responses for the post-login bootstrap sequence
    # (see app/model/SelfPlayer.lua:loadGameStartInfoEvent_, ~line 3874-
    # 4224, for the full ~30-entry list). Each entry is optional -- the
    # consumer does `if var_221_0[tostring(mid)] and not ... then` before
    # touching it, so a MID simply absent from this dict is a no-op, not
    # a crash. Only the *container itself* being absent is fatal.
    #
    # Minimal safe fix: always send "detail" as at least an empty dict.
    # We additionally pre-populate LOAD_PLAYER_INFO (17) here since its
    # payload shape is already fully modeled below in
    # handle_load_player_info() and reused verbatim -- SelfPlayer.lua's
    # onPlayerInfo_ consumes it identically whether it arrives via this
    # batch or via a standalone LOAD_PLAYER_INFO request.
    #
    # The remaining bootstrap entries are intentionally left absent until
    # their consumers are verified. These three entries above are different:
    # their consumers have now been read directly and each prevents an
    # otherwise concrete nil/uninitialized-state failure during MainScene
    # construction.
    # ---------------------------------------------------------------------
    now = int(time.time())
    detail = {
        # LOAD_PLAYER_INFO: consumed immediately by SelfPlayer:onPlayerInfo_.
        "17": handle_load_player_info({"region": region}),

        # LOAD_HEROS: Player:herosEvent_ initializes heros_ even when the
        # returned hero list is empty. SelfPlayer:getAlbumAttrInfo() can race
        # this path, so omitting this entry leaves heros_ nil and makes
        # calculateWhiteAlbumAttr() fail on ipairs(nil). Empty is a valid
        # client-side state for our local account.
        "49": {
            "sort_type": 0,
            "heros": {},
        },

        # LOAD_BACKPACK: MessageManager is instantiated synchronously by
        # LoadingScene before MainScene is constructed. Its constructor calls
        # SelfPlayer:getMyCurrentAvatarID(), which dereferences getBackpack()
        # when avatar_id is the numeric 0 from our player bootstrap. Supplying
        # an empty, valid backpack initializes backpack_ and keeps that path
        # safe without requiring any real inventory items.
        "81": {
            "sort_type": 0,
            "list": [],
            "spirit_list": [],
        },

        # GET_LIBRARY_INFOS: MainScene:setupBackground() immediately reads
        # Library.bgMain. Library only initializes bgMain inside
        # updateLibraryInfos(), so this entry must exist before MainScene is
        # constructed. The response shape mirrors Library:updateLibraryInfos.
        "836": {
            "library_infos": {},
            "library_talk_infos": {},
            "library_cg_infos": [],
            "library_bg_infos": {
                "bg_main": 1,
                "bg_room": 2,
                "has_buy": [],
                "server_time": now,
            },
        },
    }

    # These fields are read directly by LoadingScene.lua's login_ callback.
    return {
        "token": DEFAULT_TOKEN,
        "region": region,
        "log_url": "",
        "is_new": 0,
        "story_type": 0,
        "is_debug": 0,
        "is_old_top": 0,
        # Read by SelfPlayer.lua:loginEvent_ (arg_215_0.uid = params.uid).
        "uid": PLAYER_ID,
        # THE fix -- see comment block above. Must never be absent.
        "detail": detail,
    }


def handle_query_server_time(req_data):
    return {
        "server_time": int(time.time()),
    }


def handle_load_user_regions(req_data):
    # LoginWindow.lua sorts descending and, in release mode, uses [4].
    # With 10 entries [4] is region 7, which matches the S7-local screen seen
    # in the supplied log.
    regions = [
        {
            "region_id": i,
            "name": f"Local-{i}",
            "status": 1,
        }
        for i in range(1, 11)
    ]

    # Empty players is intentional: LoginWindow dispatches xyd.event.LOGIN
    # immediately instead of opening the account/region player list.
    return {
        "regions": regions,
        "players": {},
    }


def handle_load_announce(req_data):
    # LoginWindow does json.decode(response.contents), so this MUST be a
    # JSON string, not an object.
    return {
        "contents": json.dumps({}),
    }


def handle_get_player_group(req_data):
    # SelfPlayer:getAbtestGroupByKey() assigns the callback response itself
    # to abtestGroup[unique_key], so the response must be a scalar group.
    return "A"


def handle_load_player_info(req_data):
    now = int(time.time())
    try:
        region = int(req_data.get("region", DEFAULT_REGION))
    except (TypeError, ValueError):
        region = DEFAULT_REGION

    # Keep this at response root. SelfPlayer:onPlayerInfo_ reads event.params
    # directly.
    return {
        "player_id": PLAYER_ID,
        "uid": PLAYER_ID,
        "player_name": PLAYER_NAME,
        "player_type": 0,
        "avatar_id": 0,
        "avatar_frame_id": 0,

        # Deliberately sane rather than absurd values; many UI models derive
        # percentages/maxima from these.
        "lev": 99,
        "exp": 0,
        "max_lev": 200,
        "max_color": 5,

        "region": region,
        "region_name": f"Local-{region}",

        "mana": 999999,
        "crystal": 999999,
        "energy": 100,
        "max_energy": 100,
        "energy_time": now,

        "spirit_energy": 100,
        "spirit_energy_time": now,

        "vip": 15,
        "glory": 0,
        "guild_id": 0,

        "func_ids": [],
        "guide_function_ids": [],
        "guide_return_id": 0,

        "skill_point": 0,
        "skill_time": now,

        "formation": {},
        "message_pushes": {},

        "is_commented": 1,
        "comment_open": 0,
        "fbshare_open": 0,

        "main_scene_type": 0,
        "first_main_touch": 1,
    }


def handle_activity_award(req_data):
    return {
        "awards": [],
    }
