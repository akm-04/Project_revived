local var_0_0 = import("framework.scheduler")
local var_0_1 = class("Backend")
local var_0_2 = xyd.tables.translation
local var_0_3 = 1
local var_0_4 = 10
local var_0_5 = 5
local var_0_6 = 1.5
local var_0_7 = 600

function var_0_1.get()
	if var_0_1.INSTANCE == nil then
		var_0_1.INSTANCE = var_0_1.new()
	end

	return var_0_1.INSTANCE
end

function var_0_1.ctor(arg_2_0)
	arg_2_0:setupMidToEventNameMappings_()
end

function var_0_1.request(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6)
	if xyd.isChatRoomMessage(arg_3_1) then
		arg_3_0:tcpRequest_(arg_3_1, arg_3_2)
	elseif xyd.isGMOperation(arg_3_1) then
		arg_3_0:GMRequest_(arg_3_1, arg_3_2)
	else
		arg_3_0:webRequest_(arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6)
	end
end

function var_0_1.log(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if arg_4_2 == nil or arg_4_0.logURL_ == nil or #arg_4_0.logURL_ <= 0 then
		return arg_4_3(false)
	end

	local var_4_0 = arg_4_0:nextRequestHandle_()

	local function var_4_1(arg_5_0)
		if arg_5_0.name ~= "completed" and arg_5_0.name ~= "failed" then
			return
		end

		arg_4_0:destoryRequest_(var_4_0)

		if arg_5_0.name ~= "completed" then
			return arg_4_3(false)
		end

		if arg_5_0.request:getResponseStatusCode() ~= 200 then
			return arg_4_3(false)
		end

		arg_4_3(true)
	end

	local var_4_2 = arg_4_0:createRequest_(var_4_0, var_4_1, arg_4_0.logURL_, "POST")

	if arg_4_1 == 0 then
		local var_4_3 = require("zlib").deflate()(arg_4_2, "finish")

		var_4_2:addFormContents("payload", var_4_3, #var_4_3)
	elseif arg_4_1 == 1 then
		local var_4_4 = xyd.getVersionName()
		local var_4_5 = xyd.version()

		var_4_2:addFormContents("app_v", var_4_4, #var_4_4)
		var_4_2:addFormContents("v", var_4_5, #var_4_5)
		var_4_2:addFormContents("token", arg_4_0.token_, #arg_4_0.token_)
		var_4_2:addFormFile(arg_4_2.filename, arg_4_2.path, "multipart/form-data")
	end

	var_4_2:setAcceptEncoding(cc.kCCHTTPRequestAcceptEncodingGzip)
	var_4_2:setTimeout(30)
	var_4_2:start()
end

function var_0_1.closeLeagueRoom(arg_6_0)
	if arg_6_0.leagueSocket_ ~= nil then
		arg_6_0.leagueSocket_:close()

		arg_6_0.leagueSocket_ = nil
		arg_6_0.leagueChatRoomID_ = nil

		return
	end
end

function var_0_1.closeServiceRoom(arg_7_0)
	if arg_7_0.serviceSocket_ ~= nil then
		arg_7_0.serviceSocket_:close()

		arg_7_0.serviceSocket_ = nil
		arg_7_0.serviceChatRoomID_ = nil

		return
	end
end

function var_0_1.closeChatRoom(arg_8_0)
	if arg_8_0.socket_ ~= nil then
		arg_8_0.socket_:close()

		arg_8_0.socket_ = nil
		arg_8_0.chatRoomID_ = nil
		arg_8_0.isCloseChat = true

		return
	end
end

function var_0_1.enterLeagueRoom(arg_9_0, arg_9_1)
	if arg_9_1 ~= nil then
		arg_9_0.leagueChatRoomID_ = arg_9_1
	end

	if arg_9_0.leagueChatRoomID_ == nil then
		return
	end

	if arg_9_0.leagueSocket_ ~= nil then
		arg_9_0.leagueSocket_:close()

		arg_9_0.leagueSocket_ = nil

		return
	end

	arg_9_0:request(xyd.mid.LOAD_CHAT_ROOM_INFO, {
		room_id = arg_9_0.leagueChatRoomID_
	}, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			print("load league room succ")

			local var_10_0 = arg_10_1.host
			local var_10_1 = tonumber(arg_10_1.port)

			arg_9_0.leagueChatRoomID_ = tonumber(arg_10_1.room_id)
			arg_9_0.leagueSocket_ = arg_9_0:createTCPSocket(var_10_0, var_10_1)

			arg_9_0.leagueSocket_:setConnectHandler(handler(arg_9_0, arg_9_0.onSocketOpen_))
			arg_9_0.leagueSocket_:setDisconnectHandler(handler(arg_9_0, arg_9_0.onSocketClose_))
			arg_9_0.leagueSocket_:setMessageHandler(handler(arg_9_0, arg_9_0.onSocketMessage_))
			arg_9_0.leagueSocket_:retain()
			arg_9_0.leagueSocket_:connect()
		else
			print("enter league error")
			var_0_0.performWithDelayGlobal(function()
				arg_9_0:enterLeagueRoom()
			end, var_0_5)
		end
	end, nil, false, false)
end

function var_0_1.enterServiceChatRoom(arg_12_0, arg_12_1)
	if arg_12_1 ~= nil then
		arg_12_0.serviceChatRoomID_ = arg_12_1
	end

	if arg_12_0.serviceChatRoomID_ == nil then
		return
	end

	if arg_12_0.serviceSocket_ ~= nil then
		arg_12_0.serviceSocket_:close()

		arg_12_0.serviceSocket_ = nil

		return
	end

	arg_12_0:request(xyd.mid.LOAD_CHAT_ROOM_INFO, {
		room_id = arg_12_0.serviceChatRoomID_
	}, function(arg_13_0, arg_13_1)
		if arg_13_0 == xyd.error.OK then
			print("load service room succ")

			local var_13_0 = arg_13_1.host
			local var_13_1 = tonumber(arg_13_1.port)

			arg_12_0.serviceChatRoomID_ = tonumber(arg_13_1.room_id)
			arg_12_0.serviceSocket_ = arg_12_0:createTCPSocket(var_13_0, var_13_1)

			if arg_12_0.serviceSocket_ then
				arg_12_0.serviceSocket_:setConnectHandler(handler(arg_12_0, arg_12_0.onSocketOpen_))
				arg_12_0.serviceSocket_:setDisconnectHandler(handler(arg_12_0, arg_12_0.onSocketClose_))
				arg_12_0.serviceSocket_:setMessageHandler(handler(arg_12_0, arg_12_0.onSocketMessage_))
				arg_12_0.serviceSocket_:retain()
				arg_12_0.serviceSocket_:connect()
			end
		else
			print("enter service error")
			var_0_0.performWithDelayGlobal(function()
				arg_12_0:enterServiceChatRoom()
			end, var_0_5)
		end
	end, nil, false, false)
end

function var_0_1.enterChatRoom(arg_15_0, arg_15_1)
	if arg_15_1 ~= nil then
		arg_15_0.isCloseChat = false
	end

	if arg_15_0.isCloseChat == true then
		return
	end

	if arg_15_1 ~= nil then
		arg_15_0.chatRoomID_ = arg_15_1
	end

	if arg_15_0.socket_ ~= nil then
		arg_15_0.socket_:close()

		arg_15_0.socket_ = nil

		return
	end

	arg_15_0:request(xyd.mid.LOAD_CHAT_ROOM_INFO, {
		room_id = arg_15_0.chatRoomID_
	}, function(arg_16_0, arg_16_1)
		if arg_16_0 == xyd.error.OK then
			print("load chat room info succeeded")

			local var_16_0 = arg_16_1.host
			local var_16_1 = tonumber(arg_16_1.port)

			arg_15_0.chatRoomID_ = tonumber(arg_16_1.room_id)
			arg_15_0.socket_ = arg_15_0:createTCPSocket(var_16_0, var_16_1)

			arg_15_0.socket_:setConnectHandler(handler(arg_15_0, arg_15_0.onSocketOpen_))
			arg_15_0.socket_:setDisconnectHandler(handler(arg_15_0, arg_15_0.onSocketClose_))
			arg_15_0.socket_:setMessageHandler(handler(arg_15_0, arg_15_0.onSocketMessage_))
			arg_15_0.socket_:retain()
			arg_15_0.socket_:connect()
		else
			print("load chat room info failed")
			var_0_0.performWithDelayGlobal(function()
				arg_15_0:enterChatRoom()
			end, var_0_5)
		end
	end, nil, false, false)
end

function var_0_1.sendChatMessage(arg_18_0, arg_18_1)
	if arg_18_0.socket_ ~= nil then
		arg_18_0.socket_:sendMessage(xyd.mid.SEND_CHAT_MESSAGE, {
			message = arg_18_1
		})
	end
end

function var_0_1.setupMidToEventNameMappings_(arg_19_0)
	arg_19_0.mid2EventNames_ = {}
	arg_19_0.mid2EventNames_[xyd.mid.RETRIEVE_TOKEN] = xyd.event.TOKEN
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_PLAYER_INFO] = xyd.event.PLAYER_INFO
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_SCROLLS] = xyd.event.SCROLLS
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_HERO_PIECES] = xyd.event.HERO_PIECES
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_ESSENCES] = xyd.event.ESSENCES
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_HEROS] = xyd.event.HEROS
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_COLLECTED_HEROS] = xyd.event.COLLECTED_HEROS
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_WORLD_MAP] = xyd.event.WORLD_MAP
	arg_19_0.mid2EventNames_[xyd.mid.FIGHT_RESULT] = xyd.event.FIGHT_RESULT
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_TRIAL_INFOS] = xyd.event.TRIAL_INFOS
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_FRIEND_REP_HEROS] = xyd.event.FRIEND_REP_HEROS
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_MISSION] = xyd.event.LOAD_MISSION
	arg_19_0.mid2EventNames_[xyd.mid.TAKE_MISSION_AWARD] = xyd.event.TAKE_MISSION_AWARD
	arg_19_0.mid2EventNames_[xyd.mid.COMPLETE_MISSION] = xyd.event.COMPLETE_MISSION
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_BUILDING] = xyd.event.LOAD_BUILDING
	arg_19_0.mid2EventNames_[xyd.mid.OPEN_BUILDING] = xyd.event.BUILDING_OPEN
	arg_19_0.mid2EventNames_[xyd.mid.BUILDING_UPGRADE] = xyd.event.BUILDING_UPGRADE
	arg_19_0.mid2EventNames_[xyd.mid.BUILDING_OUTPUT] = xyd.event.BUILDING_OUTPUT
	arg_19_0.mid2EventNames_[xyd.mid.BUILIDNG_PARTNER] = xyd.event.BUILDING_YWC_PARTNER
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_WISH_INFO] = xyd.event.LOAD_WISH_INFO
	arg_19_0.mid2EventNames_[xyd.mid.WISH] = xyd.event.WISH
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_ALL_BUILDING_INFO] = xyd.event.LOAD_ALL_BUILDING_INFO
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_BATTLE_FORMATION] = xyd.event.LOAD_BATTLE_FORMATION
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_ARENA] = xyd.event.LOAD_ARENA
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_ARENA_PLAYER_LIST] = xyd.event.LOAD_ARENA_PLAYER_LIST
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_ARENA_NPC_LIST] = xyd.event.LOAD_ARENA_NPC_LIST
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_ARENA_DEFENSE] = xyd.event.LOAD_ARENA_DEFENSE
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_ARENA_RANK] = xyd.event.LOAD_ARENA_RANK
	arg_19_0.mid2EventNames_[xyd.mid.ARENA_REFRESH] = xyd.event.ARENA_REFRESH
	arg_19_0.mid2EventNames_[xyd.mid.ARENA_BUY_TICKET] = xyd.event.ARENA_BUY_TICKET
	arg_19_0.mid2EventNames_[xyd.mid.ARENA_RESET_TIMER] = xyd.event.ARENA_RESET_TIMER
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_MARCH] = xyd.event.LOAD_MARCH
	arg_19_0.mid2EventNames_[xyd.mid.MARCH_FIGHT_RESULT] = xyd.event.MARCH_UPDATE
	arg_19_0.mid2EventNames_[xyd.mid.MARCH_OPEN_BOX] = xyd.event.MARCH_UPDATE
	arg_19_0.mid2EventNames_[xyd.mid.RESTART_MARCH] = xyd.event.LOAD_MARCH
	arg_19_0.mid2EventNames_[xyd.mid.MARCH_ADVANCE_SWEEP] = xyd.event.MARCH_ADVANCE
	arg_19_0.mid2EventNames_[xyd.mid.SAVE_STORY] = xyd.event.SAVE_STORY
	arg_19_0.mid2EventNames_[xyd.mid.END_BATTLE] = xyd.event.END_BATTLE
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_BACKPACK] = xyd.event.LOAD_BACKPACK
	arg_19_0.mid2EventNames_[xyd.mid.SELL_ITEM] = xyd.event.SELL_ITEM
	arg_19_0.mid2EventNames_[xyd.mid.SHOP_MAGIC_UNLOCK] = xyd.event.SHOP_MAGIC_UNLOCK
	arg_19_0.mid2EventNames_[xyd.mid.MARKET_BUY] = xyd.event.MARKET_BUY
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_SHOP] = xyd.event.LOAD_SHOP
	arg_19_0.mid2EventNames_[xyd.mid.BUY_SHOP] = xyd.event.BUY_SHOP
	arg_19_0.mid2EventNames_[xyd.mid.BUY_SHOP_MULTI] = xyd.event.BUY_SHOP_MULTI
	arg_19_0.mid2EventNames_[xyd.mid.REFRESH_SHOP] = xyd.event.REFRESH_SHOP
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_SHOP_LIST] = xyd.event.LOAD_SHOP_LIST
	arg_19_0.mid2EventNames_[xyd.mid.GIFTBOX_MESSAGE] = xyd.event.GIFTBOX_MESSAGE
	arg_19_0.mid2EventNames_[xyd.mid.RUNE_MAX_MESSAGE] = xyd.event.RUNE_MAX_MESSAGE
	arg_19_0.mid2EventNames_[xyd.mid.HERO_SUMMON_MESSAGE] = xyd.event.HERO_SUMMON_MESSAGE
	arg_19_0.mid2EventNames_[xyd.mid.HERO_EVOLVE_MESSAGE] = xyd.event.HERO_EVOLVE_MESSAGE
	arg_19_0.mid2EventNames_[xyd.mid.SECRET_DUNGEON_MESSAGE] = xyd.event.SECRET_DUNGEON_MESSAGE
	arg_19_0.mid2EventNames_[xyd.mid.GM_BROADCAST] = xyd.event.GM_BROADCAST
	arg_19_0.mid2EventNames_[xyd.mid.RECHARGE] = xyd.event.RECHARGE
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_YANWUCHANG_HERO_EXP] = xyd.event.LOAD_YANWUCHANG_HERO_EXP
	arg_19_0.mid2EventNames_[xyd.mid.PLAYER_NOTICE] = xyd.event.PLAYER_NOTICE
	arg_19_0.mid2EventNames_[xyd.mid.USE_GOLDEN_HAND] = xyd.event.USE_GOLDEN_HAND
	arg_19_0.mid2EventNames_[xyd.mid.ADD_ENERGY] = xyd.event.ADD_ENERGY
	arg_19_0.mid2EventNames_[xyd.mid.EDIT_PLAYER_NAME] = xyd.event.EDIT_PLAYER_NAME
	arg_19_0.mid2EventNames_[xyd.mid.SET_AVATAR_ID] = xyd.event.SET_AVATAR_ID
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_MAIL_LIST] = xyd.event.LOAD_MAIL_LIST
	arg_19_0.mid2EventNames_[xyd.mid.SET_MAIL_READ] = xyd.event.SET_MAIL_READ
	arg_19_0.mid2EventNames_[xyd.mid.MAIL_ONEKEY] = xyd.event.MAIL_ONEKEY
	arg_19_0.mid2EventNames_[xyd.mid.GENERATE_PLAYER_NAME] = xyd.event.GENERATE_PLAYER_NAME
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_GM_QUESTIONS] = xyd.event.LOAD_GM_QUESTIONS
	arg_19_0.mid2EventNames_[xyd.mid.ASK_GM_QUESTION] = xyd.event.ASK_GM_QUESTION
	arg_19_0.mid2EventNames_[xyd.mid.QUERY_SERVER_TIME] = xyd.event.QUERY_SERVER_TIME
	arg_19_0.mid2EventNames_[xyd.mid.ACTIVITIES] = xyd.event.LOAD_ACTIVITIES
	arg_19_0.mid2EventNames_[xyd.mid.TREASURE_LOAD_SP_INFO] = xyd.event.TREASURE_LOAD_SP_INFO
	arg_19_0.mid2EventNames_[xyd.mid.TREASURE_BUY_SP] = xyd.event.TREASURE_BUY_SP
	arg_19_0.mid2EventNames_[xyd.mid.TREASURE_LOAD_ALL_INFO] = xyd.event.TREASURE_LOAD_ALL_INFO
	arg_19_0.mid2EventNames_[xyd.mid.TREASURE_LOAD_INFO] = xyd.event.TREASURE_LOAD_INFO
	arg_19_0.mid2EventNames_[xyd.mid.TREASURE_SET_PARTNER] = xyd.event.TREASURE_SET_PARTNER
	arg_19_0.mid2EventNames_[xyd.mid.TREASURE_FINISH_ONE_TEAM] = xyd.event.TREASURE_FINISH_ONE_TEAM
	arg_19_0.mid2EventNames_[xyd.mid.TREASURE_LOAD_MATCH_INFO] = xyd.event.TREASURE_LOAD_MATCH_INFO
	arg_19_0.mid2EventNames_[xyd.mid.TREASURE_SAVE_BATTLE_RESULT] = xyd.event.TREASURE_SAVE_BATTLE_RESULT
	arg_19_0.mid2EventNames_[xyd.mid.TREASURE_GET_BATTLE_REPORT] = xyd.event.TREASURE_GET_BATTLE_REPORT
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_INVITE_INFOS] = xyd.event.LOAD_INVITE_INFOS
	arg_19_0.mid2EventNames_[xyd.mid.GET_INVITE_AWARD] = xyd.event.GET_MISSION_REWARD
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_PEAK_ARENA] = xyd.event.LOAD_PEAK_ARENA
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_TEAM_BY_ID] = xyd.event.LOAD_SELF_GUILD
	arg_19_0.mid2EventNames_[xyd.mid.DAILY_CONSUNME] = xyd.event.TENFOLD_GOLDEN_HAND
	arg_19_0.mid2EventNames_[xyd.mid.GUILD_FIGHT_NOTICE] = xyd.event.GUILD_FIGHT_NOTICE
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_ANNOUNCE] = xyd.event.ANNOUNCE
	arg_19_0.mid2EventNames_[xyd.mid.WORLD_BOSS] = xyd.event.WORLD_BOSS
	arg_19_0.mid2EventNames_[xyd.mid.BROCAST_SEND_RED_ENVELOPE] = xyd.event.BROCAST_SEND_RED_ENVELOPE
	arg_19_0.mid2EventNames_[xyd.mid.BROCAST_FINISH_RED_ENVELOPE] = xyd.event.BROCAST_FINISH_RED_ENVELOPE
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_RED_ENVELOPE_INFO] = xyd.event.LOAD_RED_ENVELOPE_INFO
	arg_19_0.mid2EventNames_[xyd.mid.NIAN_BOSS] = xyd.event.NIAN_BOSS
	arg_19_0.mid2EventNames_[xyd.mid.BROCAST_SEND_GIFT_PACKETS] = xyd.event.BROCAST_SEND_GIFT_PACKETS
	arg_19_0.mid2EventNames_[xyd.mid.BROCAST_FINISH_GIFT_PACKETS] = xyd.event.BROCAST_FINISH_GIFT_PACKETS
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_GIFT_PACKETS_INFO] = xyd.event.LOAD_GIFT_PACKETS_INFO
	arg_19_0.mid2EventNames_[xyd.mid.BROCAST_SEND_KITES] = xyd.event.BROCAST_SEND_KITES
	arg_19_0.mid2EventNames_[xyd.mid.BROCAST_FINISH_KITES] = xyd.event.BROCAST_FINISH_KITES
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_KITES_INFO] = xyd.event.LOAD_KITES_INFO
	arg_19_0.mid2EventNames_[xyd.mid.LOAD_SINGLE_ACTIVITY] = xyd.event.LOAD_SINGLE_ACTIVITY
	arg_19_0.mid2EventNames_[xyd.mid.GET_REARENA_INFO] = xyd.event.GET_REARENA_INFO
	arg_19_0.mid2EventNames_[xyd.mid.BROCAST_FINISH_JIGSAW] = xyd.event.BROCAST_FINISH_JIGSAW
	arg_19_0.mid2EventNames_[xyd.mid.ACTIVITY_BROADCAST] = xyd.event.ACTIVITY_BROADCAST
	arg_19_0.mid2EventNames_[xyd.mid.SYSTEM_BROADCAST] = xyd.event.SYSTEM_BROADCAST
	arg_19_0.mid2EventNames_[xyd.mid.WORLD_NOTICE] = xyd.event.WORLD_NOTICE
	arg_19_0.mid2EventNames_[xyd.mid.REGION_RESET_TIMER] = xyd.event.REGION_RESET_TIMER
	arg_19_0.mid2EventNames_[xyd.mid.REGION_BUY_TICKET] = xyd.event.REGION_BUY_TICKET
	arg_19_0.mid2EventNames_[xyd.mid.ACTIVITY_LVBU_BROADCAST] = xyd.event.ACTIVITY_LVBU_BROADCAST
	arg_19_0.mid2EventNames_[xyd.mid.OLD_PEAK_LOAD_INFO] = xyd.event.LOAD_OLD_PEAK_ARENA
	arg_19_0.mid2EventNames_[xyd.mid.THIRD_ANNIVERSARY] = xyd.event.THIRD_ANNIVERSARY_BOSS
end

function var_0_1.sendAsFormData_(arg_20_0, arg_20_1)
	return arg_20_1 == xyd.mid.ARENA_FIGHT_RESULT or arg_20_1 == xyd.mid.PEAK_START_FIGHT or arg_20_1 == xyd.mid.TREASURE_SAVE_BATTLE_RESULT or arg_20_1 == xyd.mid.REARENA_END_FIGHT or arg_20_1 == xyd.mid.REGION_FIGHT_RESULT or arg_20_1 == xyd.mid.CONQUER_SCHOOL_FIGHT_RESULT or arg_20_1 == xyd.mid.SAVE_FURNITURES
end

function var_0_1.shouldRetry_(arg_21_0, arg_21_1)
	return arg_21_1 ~= xyd.mid.LOAD_CHAT_ROOM_INFO
end

function var_0_1.isUpload(arg_22_0, arg_22_1)
	return ({
		[1844] = true
	})[arg_22_1]
end

function var_0_1.webRequest_(arg_23_0, arg_23_1, arg_23_2, arg_23_3, arg_23_4, arg_23_5, arg_23_6)
	if arg_23_5 == nil then
		arg_23_5 = false
	end

	if arg_23_6 == nil then
		arg_23_6 = true
	end

	local var_23_0 = arg_23_0.mid2EventNames_[arg_23_1]

	local function var_23_1()
		if arg_23_6 then
			xyd.LoadingProxy.get():reset()
		end
	end

	local function var_23_2(arg_25_0, arg_25_1)
		if arg_23_0.needsRestart_ then
			var_23_1()

			return
		end

		if arg_25_1 == xyd.error.OK then
			arg_23_0:extraWebResponseCheck_(arg_25_0)

			if arg_23_0.needsRestart_ then
				var_23_1()

				return
			end

			if var_23_0 ~= nil then
				xyd.EventDispatcher.get():dispatchEvent({
					name = var_23_0,
					params = arg_25_0,
					userdata = arg_23_4
				})
			end
		end

		if arg_23_6 then
			xyd.LoadingProxy.get():removeLoading()
		end

		if arg_23_3 ~= nil then
			arg_23_3(arg_25_1, arg_25_0, arg_23_4)

			if arg_25_0 and arg_25_0.error_code then
				local var_25_0 = arg_25_0.error_code

				if arg_25_0.error_msg == "" or not arg_25_0.error_msg then
					local var_25_1 = xyd.tables.message:getContent(var_25_0)

					if var_25_1 and var_25_1 ~= "" then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_25_1
						})
					end
				elseif arg_25_0.error_msg ~= nil then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, arg_25_0.error_msg, function()
						if restart_game then
							restart_game()
						else
							xyd.exitProgram()
						end
					end)
				end
			end
		end
	end

	local var_23_3

	if arg_23_1 == xyd.mid.RETRIEVE_TOKEN then
		function var_23_3(arg_27_0, arg_27_1)
			if arg_27_1 == xyd.error.OK then
				arg_23_0.token_ = arg_27_0.token
				arg_23_0.region_ = arg_27_0.region
				arg_23_0.logURL_ = arg_27_0.log_url

				var_23_2(arg_27_0, arg_27_1)
			else
				var_23_2(arg_27_0, arg_27_1)
			end
		end
	else
		var_23_3 = var_23_2
	end

	local function var_23_4(arg_28_0, arg_28_1)
		if arg_23_0.needsRestart_ then
			var_23_1()

			return
		end

		print(string.format("Web request failed, mid = %d, params = %s", arg_23_1, json.encode(arg_23_2) or ""))

		if arg_23_5 then
			return var_23_3(arg_28_0, arg_28_1)
		end

		if arg_23_6 then
			xyd.LoadingProxy.get():removeLoading()
		end

		local var_28_0 = xyd.tables.translation:translation("RETRY_PROMPT_ON_REQUEST_FAILURE")

		if not arg_23_0.pendingRequests then
			arg_23_0.pendingRequests = {}
		end

		local var_28_1 = {
			mid = arg_23_1,
			params = arg_23_2,
			callback = arg_23_3,
			userdata = arg_23_4,
			skipRetryPromptOnFailure = arg_23_5,
			showLoading = arg_23_6,
			response = arg_28_0,
			err = arg_28_1,
			complete = var_23_3
		}

		table.insert(arg_23_0.pendingRequests, var_28_1)

		local var_28_2 = {
			rightName = var_0_2:translation("RETRY_PROMPT"),
			lcallback = function()
				for iter_29_0, iter_29_1 in ipairs(arg_23_0.pendingRequests) do
					iter_29_1.complete(iter_29_1.response, iter_29_1.err)
				end

				arg_23_0.pendingRequests = {}
			end
		}

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_28_0, function()
			for iter_30_0, iter_30_1 in ipairs(arg_23_0.pendingRequests) do
				arg_23_0:webRequest_(iter_30_1.mid, iter_30_1.params, iter_30_1.callback, iter_30_1.userdata, iter_30_1.skipRetryPromptOnFailure, iter_30_1.showLoading)
			end

			arg_23_0.pendingRequests = {}
		end, var_28_2)
	end

	local var_23_5 = arg_23_0:nextRequestHandle_()

	local function var_23_6(arg_31_0)
		if arg_23_0.needsRestart_ then
			var_23_1()

			return
		end

		if arg_31_0.name ~= "completed" and arg_31_0.name ~= "failed" then
			return
		end

		arg_23_0:destoryRequest_(var_23_5)

		if arg_31_0.name ~= "completed" then
			if arg_23_0:shouldRetry_(arg_23_1) then
				return var_23_4(nil, xyd.error.ERROR)
			else
				return var_23_3(nil, xyd.error.ERROR)
			end
		end

		local var_31_0 = arg_31_0.request:getResponseString()
		local var_31_1 = arg_31_0.request:getResponseStatusCode()
		local var_31_2

		if #var_31_0 > 8192 then
			var_31_2 = string.sub(var_31_0, 0, 8192)
		else
			var_31_2 = var_31_0
		end

		print(string.format("Received from web code(%d) -- %s", var_31_1, string.sub(var_31_2, 0, 3000)))

		if var_31_1 ~= 200 then
			return var_23_3(json.decode(var_31_0), xyd.error.ERROR)
		end

		var_23_3(json.decode(var_31_0), xyd.error.OK)
	end

	if arg_23_6 then
		xyd.LoadingProxy.get():addLoading(var_0_6)
	end

	local var_23_7 = arg_23_0:createRequest_(var_23_5, var_23_6, arg_23_0:getWebAPIURL_(), "POST")

	arg_23_2 = arg_23_2 or {}
	arg_23_2.mid = arg_23_1
	arg_23_2.token = arg_23_0.token_

	if not arg_23_2.region then
		arg_23_2.region = arg_23_0.region_
	end

	arg_23_2.v_ = xyd.version()
	arg_23_2.app_v = xyd.getVersionName()
	arg_23_2.platform = cc.Application:getInstance():getTargetPlatform()

	local var_23_8 = json.encode(arg_23_2)
	local var_23_9 = 0
	local var_23_10 = true

	if arg_23_0:sendAsFormData_(arg_23_1) then
		local var_23_11 = require("zlib").deflate()(var_23_8, "finish")

		var_23_9 = #var_23_11

		var_23_7:addFormContents("payload", var_23_11, #var_23_11)
	elseif arg_23_0:isUpload(arg_23_1) then
		if not arg_23_2.form_name or not arg_23_2.file_path or not arg_23_2.file_name then
			return
		end

		local var_23_12 = arg_23_2.file_path
		local var_23_13, var_23_14 = io.open(var_23_12, "r")

		if not var_23_13 then
			print("File path is not exists. filePath = ", var_23_12)

			return
		end

		var_23_13:close()
		var_23_7:addFormFile(arg_23_2.form_name, var_23_12)

		for iter_23_0, iter_23_1 in pairs(arg_23_2) do
			var_23_7:addFormContents(iter_23_0, iter_23_1, 0)
		end

		var_23_7:addFormContents("mid", arg_23_1, 0)
		var_23_7:addFormContents("token", arg_23_0.token_, 0)
		var_23_7:addFormContents("region", arg_23_0.region_, 0)
		var_23_7:addFormContents("v_", xyd.version(), 0)
	else
		local var_23_15 = string.urlencode(var_23_8)

		var_23_9 = #var_23_15

		var_23_7:addPOSTValue("payload", var_23_15)

		var_23_10 = false
	end

	local var_23_16

	if var_23_8 and #var_23_8 > 8192 then
		var_23_16 = string.sub(var_23_8, 0, 8192)
	else
		var_23_16 = var_23_8 or ""
	end

	print(string.format("Sent to web 0x%04x (payload length: %d) -- %s", arg_23_1, var_23_9, var_23_16))
	var_23_7:setAcceptEncoding(cc.kCCHTTPRequestAcceptEncodingGzip)

	local var_23_17 = var_23_10 and 30 or 20

	var_23_7:setTimeout(var_23_17)
	var_23_7:start()
end

function var_0_1.getWebAPIURL_(arg_32_0)
	if arg_32_0.webAPIURL_ == nil then
		arg_32_0.webAPIURL_ = xyd.serverUrl or xyd.tables.misc.webAPIURL
	end

	return arg_32_0.webAPIURL_
end

function var_0_1.GMRequest_(arg_33_0, arg_33_1, arg_33_2)
	if not arg_33_0.GMURL_ then
		return
	end

	local var_33_0 = arg_33_0.mid2EventNames_[arg_33_1]

	local function var_33_1(arg_34_0, arg_34_1)
		if arg_34_1 == xyd.error.OK then
			arg_33_0:extraWebResponseCheck_(arg_34_0)
		end
	end

	local var_33_2 = arg_33_0:nextRequestHandle_()

	local function var_33_3(arg_35_0)
		if arg_35_0.name ~= "completed" and arg_35_0.name ~= "failed" then
			return
		end

		arg_33_0:destoryRequest_(var_33_2)

		if arg_35_0.name ~= "completed" then
			var_33_1(nil, xyd.error.ERROR)
			print(string.format("Web request failed, mid = %d, params = %s", arg_33_1, json.encode(arg_33_2)))

			return
		end

		local var_35_0 = arg_35_0.request:getResponseString()
		local var_35_1 = arg_35_0.request:getResponseStatusCode()

		print(string.format("Received from web code(%d) -- %s", var_35_1, var_35_0))

		if var_35_1 ~= 200 then
			var_33_1(nil, xyd.error.ERROR)

			return
		end

		var_33_1(json.decode(var_35_0), xyd.error.OK)
	end

	local var_33_4 = arg_33_0:createRequest_(var_33_2, var_33_3, arg_33_0.GMURL_, "POST")

	arg_33_2 = arg_33_2 or {}
	arg_33_2.mid = arg_33_1

	local var_33_5 = json.encode(arg_33_2)

	print(string.format("Sent to web 0x%04x -- %s", arg_33_1, var_33_5))

	local var_33_6 = string.urlencode(var_33_5)

	var_33_4:addPOSTValue("payload", var_33_6)
	var_33_4:setTimeout(10)
	var_33_4:start()
end

function var_0_1.extraWebResponseCheck_(arg_36_0, arg_36_1)
	if not arg_36_1 then
		return
	end

	if arg_36_1.v_ ~= nil then
		arg_36_0.needsRestart_ = true

		local var_36_0 = xyd.tables.translation:translation("NEW_VERSION_RESTART_PROMPT")

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_36_0, function()
			if arg_36_1.is_appstore ~= 0 then
				cc.Application:getInstance():openURL(xyd.versionUpdateURL)
			elseif restart_game then
				restart_game()
			else
				xyd.exitProgram()
			end
		end)
	end

	if arg_36_1.economy_ ~= nil then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.ECONOMY,
			params = arg_36_1.economy_,
			news = {
				funcIDs = arg_36_1.new_funcs_
			}
		})
	end

	if arg_36_1.flag_ ~= nil then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.RELOAD,
			params = arg_36_1.flag_
		})
	end

	if arg_36_1.server_time ~= nil then
		xyd.ServerTime.get():resetServerTime(arg_36_1.server_time)
	end

	if arg_36_1.gm_url ~= nil then
		arg_36_0.GMURL_ = arg_36_1.gm_url
	end

	if arg_36_1.extra_drops_ ~= nil then
		xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(arg_36_1.extra_drops_)
	end

	if arg_36_1.act_item_change_ ~= nil then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.ACT_ITEM_CHANGE,
			params = arg_36_1.act_item_change_
		})
	end

	xyd.ModelManager.get():loadModel(xyd.ModelType.TASK):onTaskBackendEvent(arg_36_1)

	if arg_36_1.new_funcs_ ~= nil then
		xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):onNewFuncOpen(arg_36_1.new_funcs_)
	end

	if arg_36_1.redmarks_ ~= nil then
		xyd.ModelManager.get():loadModel(xyd.ModelType.REDMARK):onUpdate(arg_36_1.redmarks_)

		if arg_36_1.redmarks_[tostring(xyd.FunctionID.ID_BATTLE_PASS)] then
			xyd.ModelManager.get():loadModel(xyd.ModelType.BATTLE_PASS):onUpdateRedmark(arg_36_1.redmarks_[tostring(xyd.FunctionID.ID_BATTLE_PASS)])
		end
	end

	if arg_36_1.twice_awake_stage_ ~= nil then
		xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):onUpdateTwiceAwakeStage(arg_36_1.twice_awake_stage_)
	end
end

function var_0_1.tcpRequest_(arg_38_0, arg_38_1, arg_38_2)
	local var_38_0

	if arg_38_2.channel == 0 then
		var_38_0 = arg_38_0.socket_
	elseif arg_38_2.channel == 2 then
		var_38_0 = arg_38_0.leagueSocket_
	elseif arg_38_2.channel == 4 then
		var_38_0 = arg_38_0.serviceSocket_
	end

	if var_38_0 then
		arg_38_2.token = arg_38_0.token_
		arg_38_2.region = arg_38_0.region_

		var_38_0:sendMessage(arg_38_1, arg_38_2)
	end
end

function var_0_1.onSocketOpen_(arg_39_0, arg_39_1)
	if arg_39_1 ~= arg_39_0.socket_ and arg_39_1 ~= arg_39_0.leagueSocket_ and arg_39_1 ~= arg_39_0.serviceSocket_ then
		return
	end

	local var_39_0 = {
		token = arg_39_0.token_,
		region = arg_39_0.region_
	}

	if arg_39_1 == arg_39_0.socket_ then
		var_39_0.room_id = arg_39_0.chatRoomID_
		arg_39_0.socketTimeoutHandle_ = var_0_0.performWithDelayGlobal(function()
			if arg_39_1 == arg_39_0.socket_ then
				arg_39_1:close()
			end
		end, var_0_4)
	elseif arg_39_1 == arg_39_0.leagueSocket_ then
		var_39_0.room_id = arg_39_0.leagueChatRoomID_
		arg_39_0.leagueSocketTimeoutHandle_ = var_0_0.performWithDelayGlobal(function()
			if arg_39_1 == arg_39_0.leagueSocket_ then
				arg_39_1:close()
			end
		end, var_0_4)
	elseif arg_39_1 == arg_39_0.serviceSocket_ then
		var_39_0.room_id = arg_39_0.serviceChatRoomID_
		arg_39_0.serviceSocketTimeoutHandle_ = var_0_0.performWithDelayGlobal(function()
			if arg_39_1 == arg_39_0.serviceSocket_ then
				arg_39_1:close()
			end
		end, var_0_4)
	end

	arg_39_1:sendMessage(xyd.mid.TCP_LOGIN, var_39_0)
end

function var_0_1.onSocketClose_(arg_43_0, arg_43_1)
	if arg_43_1 == arg_43_0.socket_ then
		if arg_43_0.socketTimeoutHandle_ ~= nil then
			var_0_0.unscheduleGlobal(arg_43_0.socketTimeoutHandle_)

			arg_43_0.socketTimeoutHandle_ = nil
		end

		if arg_43_0.socketHeartBeatHandle_ ~= nil then
			var_0_0.unscheduleGlobal(arg_43_0.socketHeartBeatHandle_)

			arg_43_0.socketHeartBeatHandle_ = nil
		end

		arg_43_0.socket_:release()

		arg_43_0.socket_ = nil

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.CHAT_SESSION_CLOSED
		})
		var_0_0.performWithDelayGlobal(function()
			arg_43_0:enterChatRoom()
		end, var_0_5)
	elseif arg_43_1 == arg_43_0.leagueSocket_ then
		if arg_43_0.leagueSocketTimeoutHandle_ ~= nil then
			var_0_0.unscheduleGlobal(arg_43_0.leagueSocketTimeoutHandle_)

			arg_43_0.leagueSocketTimeoutHandle_ = nil
		end

		if arg_43_0.leagueSocketHeartBeatHandle_ ~= nil then
			var_0_0.unscheduleGlobal(arg_43_0.leagueSocketHeartBeatHandle_)

			arg_43_0.leagueSocketHeartBeatHandle_ = nil
		end

		arg_43_0.leagueSocket_:release()

		arg_43_0.leagueSocket_ = nil

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.LEAGUE_CHAT_SESSION_CLOSED
		})
		var_0_0.performWithDelayGlobal(function()
			arg_43_0:enterLeagueRoom()
		end, var_0_5)
	elseif arg_43_1 == arg_43_0.serviceSocket_ then
		if arg_43_0.serviceSocketTimeoutHandle_ ~= nil then
			var_0_0.unscheduleGlobal(arg_43_0.serviceSocketTimeoutHandle_)

			arg_43_0.serviceSocketTimeoutHandle_ = nil
		end

		if arg_43_0.serviceSocketHeartBeatHandle_ ~= nil then
			var_0_0.unscheduleGlobal(arg_43_0.serviceSocketHeartBeatHandle_)

			arg_43_0.serviceSocketHeartBeatHandle_ = nil
		end

		arg_43_0.serviceSocket_:release()

		arg_43_0.serviceSocket_ = nil

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.SERVICE_CHAT_SESSION_CLOSED
		})
		var_0_0.performWithDelayGlobal(function()
			arg_43_0:enterServiceChatRoom()
		end, var_0_5)
	end
end

function var_0_1.onSocketMessage_(arg_47_0, arg_47_1, arg_47_2, arg_47_3)
	print("mid:", arg_47_2)
	print("message:", arg_47_3)

	local function var_47_0(arg_48_0, arg_48_1)
		if arg_48_0 == nil then
			return
		end

		print("eventName", arg_48_0)
		xyd.EventDispatcher.get():dispatchEvent({
			name = arg_48_0,
			params = arg_48_1
		})
	end

	if arg_47_1 == arg_47_0.socket_ then
		if arg_47_2 == xyd.mid.CHAT_ROOM_ENTERED then
			var_47_0(xyd.event.CHAT_SESSION_OPENED, arg_47_3)

			if arg_47_0.socketHeartBeatHandle_ ~= nil then
				var_0_0.unscheduleGlobal(arg_47_0.socketHeartBeatHandle_)

				arg_47_0.socketHeartBeatHandle_ = nil
			end

			arg_47_0.socketHeartBeatHandle_ = var_0_0.scheduleGlobal(function()
				local var_49_0 = {}

				arg_47_1:sendMessage(xyd.mid.SOCKET_HEARTBEAT, var_49_0)
			end, var_0_7)

			if arg_47_0.socketTimeoutHandle_ ~= nil then
				var_0_0.unscheduleGlobal(arg_47_0.socketTimeoutHandle_)

				arg_47_0.socketTimeoutHandle_ = nil
			end
		elseif arg_47_2 == xyd.mid.CHAT_MESSAGE then
			var_47_0(xyd.event.CHAT_ROOM_MESSAGE, arg_47_3)
		elseif arg_47_2 == xyd.mid.CHAT_FROM_PLAYER then
			var_47_0(xyd.event.PERSONAL_CHAT_MESSAGE, arg_47_3)
		elseif arg_47_2 == xyd.mid.FORCE_RELOAD then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.RELOAD,
				params = arg_47_3
			})
		elseif arg_47_2 == xyd.mid.ILLUSION_INVITE then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.ILLUSION_INVITE,
				params = arg_47_3
			})
		elseif arg_47_2 == xyd.mid.ILLUSION_NOTICE then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.ILLUSION_NOTICE,
				params = arg_47_3
			})
		elseif arg_47_2 == xyd.mid.CHAT_FROM_FRIEND then
			var_47_0(xyd.event.FRIEND_CHAT_MESSAGE, arg_47_3)
		else
			var_47_0(arg_47_0.mid2EventNames_[arg_47_2], arg_47_3)
		end
	elseif arg_47_1 == arg_47_0.leagueSocket_ then
		if arg_47_2 == xyd.mid.CHAT_ROOM_ENTERED then
			var_47_0(xyd.event.LEAGUE_CHAT_SESSION_OPENED, arg_47_3)

			if arg_47_0.leagueSocketHeartBeatHandle_ ~= nil then
				var_0_0.unscheduleGlobal(arg_47_0.leagueSocketHeartBeatHandle_)

				arg_47_0.leagueSocketHeartBeatHandle_ = nil
			end

			arg_47_0.leagueSocketHeartBeatHandle_ = var_0_0.scheduleGlobal(function()
				local var_50_0 = {}

				arg_47_1:sendMessage(xyd.mid.SOCKET_HEARTBEAT, var_50_0)
			end, var_0_7)

			if arg_47_0.leagueSocketTimeoutHandle_ ~= nil then
				var_0_0.unscheduleGlobal(arg_47_0.leagueSocketTimeoutHandle_)

				arg_47_0.leagueSocketTimeoutHandle_ = nil
			end
		elseif arg_47_2 == xyd.mid.CHAT_MESSAGE then
			var_47_0(xyd.event.LEAGUE_CHAT_ROOM_MESSAGE, arg_47_3)
		elseif arg_47_2 == xyd.mid.GUILD_BROADCAST then
			var_47_0(xyd.event.LEAGUE_CHAT_ROOM_BROADCAST, arg_47_3)
		elseif arg_47_2 == xyd.mid.CLOSE_GUILD_CHAT then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.CLOSE_GUILD_CHAT
			})
		elseif arg_47_2 == xyd.mid.GUILD_ALLY then
			var_47_0(xyd.event.LEAGUE_ALLY_MESSAGE, arg_47_3)
		else
			var_47_0(arg_47_0.mid2EventNames_[arg_47_2], arg_47_3)
		end
	elseif arg_47_1 == arg_47_0.serviceSocket_ then
		if arg_47_2 == xyd.mid.CHAT_ROOM_ENTERED then
			var_47_0(xyd.event.SERVICE_CHAT_SESSION_OPENED, arg_47_3)

			if arg_47_0.serviceSocketHeartBeatHandle_ ~= nil then
				var_0_0.unscheduleGlobal(arg_47_0.serviceSocketHeartBeatHandle_)

				arg_47_0.serviceSocketHeartBeatHandle_ = nil
			end

			arg_47_0.serviceSocketHeartBeatHandle_ = var_0_0.scheduleGlobal(function()
				local var_51_0 = {}

				arg_47_1:sendMessage(xyd.mid.SOCKET_HEARTBEAT, var_51_0)
			end, var_0_7)

			if arg_47_0.serviceSocketTimeoutHandle_ ~= nil then
				var_0_0.unscheduleGlobal(arg_47_0.serviceSocketTimeoutHandle_)

				arg_47_0.serviceSocketTimeoutHandle_ = nil
			end
		elseif arg_47_2 == xyd.mid.CHAT_MESSAGE then
			var_47_0(xyd.event.SERVICE_CHAT_ROOM_MESSAGE, arg_47_3)
		else
			var_47_0(arg_47_0.mid2EventNames_[arg_47_2], arg_47_3)
		end
	end
end

function var_0_1.nextRequestHandle_(arg_52_0)
	var_0_3 = var_0_3 + 1

	return var_0_3
end

function var_0_1.createRequest_(arg_53_0, arg_53_1, arg_53_2, arg_53_3, arg_53_4)
	arg_53_0:destoryRequest_(arg_53_1)

	local var_53_0 = network.createHTTPRequest(arg_53_2, arg_53_3, arg_53_4)

	var_53_0:retain()

	arg_53_0.requests_ = arg_53_0.request_ or {}
	arg_53_0.requests_[arg_53_1] = var_53_0

	return var_53_0
end

function var_0_1.destoryRequest_(arg_54_0, arg_54_1)
	if arg_54_0.requests_ == nil then
		return
	end

	local var_54_0 = arg_54_0.requests_[arg_54_1]

	if var_54_0 ~= nil then
		var_54_0:release()

		arg_54_0.requests_[arg_54_1] = nil
	end
end

function var_0_1.createTCPSocket(arg_55_0, arg_55_1, arg_55_2)
	local function var_55_0(arg_56_0, arg_56_1)
		if arg_56_0.main ~= arg_56_1.main then
			return arg_56_0.main - arg_56_1.main
		elseif arg_56_0.mid ~= arg_56_1.mid then
			return arg_56_0.mid - arg_56_1.mid
		else
			return arg_56_0.sub - arg_56_1.sub
		end
	end

	local function var_55_1(arg_57_0)
		local var_57_0, var_57_1, var_57_2 = arg_57_0:match("(%d+)%.(%d+)%.(%d+)")
		local var_57_3 = {
			main = tonumber(var_57_0 or 0),
			mid = tonumber(var_57_1 or 0),
			sub = tonumber(var_57_2 or 0)
		}

		setmetatable(var_57_3, {
			__tostring = function()
				return arg_57_0
			end
		})

		return var_57_3
	end

	local var_55_2
	local var_55_3 = var_55_1(xyd.getVersionName() or "")

	if device.platform == "ios" then
		if var_55_0(var_55_3, var_55_1("1.6.0")) > 0 then
			var_55_2 = xyd.TCPSocket:create(arg_55_1, arg_55_2, arg_55_1, 1)
		else
			var_55_2 = xyd.TCPSocket:create(arg_55_1, arg_55_2)
		end
	elseif device.platform == "android" then
		if var_55_0(var_55_3, var_55_1("1.130.0")) > 0 then
			var_55_2 = xyd.TCPSocket:create(arg_55_1, arg_55_2, arg_55_1, 1)
		else
			var_55_2 = xyd.TCPSocket:create(arg_55_1, arg_55_2)
		end
	else
		var_55_2 = xyd.TCPSocket:create(arg_55_1, arg_55_2, arg_55_1, 1)
	end

	return var_55_2
end

return var_0_1
