local var_0_0 = class("Occult", import(".BaseModel"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	"occult_sub_map",
	"occult_campaign_detail",
	"occult_campaign_only_detail",
	"occult_campaign_log",
	"occult_confirm_invited",
	"occult_cooperate_waiting",
	"occult_companion_info",
	"occult_select_hero",
	"occult_show_team",
	"occult_campaign_rule",
	"occult_select_team",
	"mission",
	"hero_main",
	"equip_confirm",
	"item_compose",
	"hero_list"
}

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.invitedList = {}
	arg_1_0.teamStatus = {}
	arg_1_0.eventIds = {}
	arg_1_0.awardInfo = nil
end

function var_0_0.closeOccultRelatedWindows(arg_2_0)
	for iter_2_0, iter_2_1 in pairs(var_0_2) do
		local var_2_0 = xyd.WindowManager.get():getWindow(iter_2_1)

		if var_2_0 and not tolua.isnull(var_2_0) then
			xyd.WindowManager.get():closeWindow(iter_2_1)
		end
	end
end

function var_0_0.clear(arg_3_0)
	arg_3_0.invitedList = {}
	arg_3_0.eventIds = {}
	arg_3_0.dispatchInfo = {}
	arg_3_0.hasInvite = false
end

function var_0_0.onRegister(arg_4_0)
	var_0_0.super.onRegister(arg_4_0)
end

function var_0_0.getInfo(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_INFO, var_5_0, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			arg_5_0:handleResponse(arg_6_1)
		end

		if arg_5_2 then
			arg_5_2(arg_6_0, arg_6_1)
		end
	end)
end

function var_0_0.startChallenge(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1 or {}

	xyd.Backend.get():request(xyd.mid.START_CHALLENGE, var_7_0, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK then
			-- block empty
		end

		if arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.getCampaignInfo(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_CAMPAIGN_INFO, var_9_0, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			-- block empty
		end

		if arg_9_2 then
			arg_9_2(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.getMemberStatInfo(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_MEMBER_STAT_INFO, var_11_0, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			-- block empty
		end

		if arg_11_2 then
			arg_11_2(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.createRoom(arg_13_0, arg_13_1, arg_13_2)
	arg_13_0:clear()

	local var_13_0 = arg_13_1 or {}

	xyd.Backend.get():request(xyd.mid.CREATE_ROOM, var_13_0, function(arg_14_0, arg_14_1)
		if arg_14_0 == xyd.error.OK then
			arg_13_0:handleResponse(arg_14_1)
		end

		if arg_13_2 then
			arg_13_2(arg_14_0, arg_14_1)
		end
	end)
end

function var_0_0.joinRoom(arg_15_0, arg_15_1, arg_15_2)
	arg_15_0:clear()

	local var_15_0 = arg_15_1 or {}

	xyd.Backend.get():request(xyd.mid.JOIN_ROOM, var_15_0, function(arg_16_0, arg_16_1)
		if arg_16_0 == xyd.error.OK then
			arg_15_0.everRoomIDs[var_15_0.room_id] = nil

			arg_15_0:handleResponse(arg_16_1)
		end

		if arg_15_2 then
			arg_15_2(arg_16_0, arg_16_1)
		end
	end)
end

function var_0_0.exitRoom(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = arg_17_1 or {}

	xyd.Backend.get():request(xyd.mid.EXIT_ROOM, var_17_0, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK then
			arg_17_0:handleResponse(arg_18_1)
			arg_17_0:resetInvited()
		end

		if arg_17_2 then
			arg_17_2(arg_18_0, arg_18_1)
		end
	end)
end

function var_0_0.inviteFriend(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = arg_19_1 or {}

	xyd.Backend.get():request(xyd.mid.INVITE_FRIEND, var_19_0, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK then
			-- block empty
		end

		if arg_19_2 then
			arg_19_2(arg_20_0, arg_20_1)
		end
	end)
end

function var_0_0.kickMember(arg_21_0, arg_21_1, arg_21_2)
	local var_21_0 = arg_21_1 or {}

	xyd.Backend.get():request(xyd.mid.KICK_MEMBER, var_21_0, function(arg_22_0, arg_22_1)
		if arg_22_0 == xyd.error.OK then
			arg_21_0:handleResponse(arg_22_1)
		end

		if arg_21_2 then
			arg_21_2(arg_22_0, arg_22_1)
		end
	end)
end

function var_0_0.prepareSingleFight(arg_23_0, arg_23_1, arg_23_2)
	local var_23_0 = arg_23_1 or {}

	xyd.Backend.get():request(xyd.mid.PREPARE_SINGLE_FIGHT, var_23_0, function(arg_24_0, arg_24_1)
		if arg_24_0 == xyd.error.OK then
			-- block empty
		end

		if arg_23_2 then
			arg_23_2(arg_24_0, arg_24_1)
		end
	end)
end

function var_0_0.singleFight(arg_25_0, arg_25_1, arg_25_2)
	local var_25_0 = arg_25_1 or {}

	xyd.Backend.get():request(xyd.mid.SINGLE_FIGHT, var_25_0, function(arg_26_0, arg_26_1)
		if arg_26_0 == xyd.error.OK then
			-- block empty
		end

		if arg_25_2 then
			arg_25_2(arg_26_0, arg_26_1)
		end
	end)
end

function var_0_0.quitSingleFight(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0 = arg_27_1 or {}

	xyd.Backend.get():request(xyd.mid.QUIT_SINGLE_FIGHT, var_27_0, function(arg_28_0, arg_28_1)
		if arg_28_0 == xyd.error.OK then
			-- block empty
		end

		if arg_27_2 then
			arg_27_2(arg_28_0, arg_28_1)
		end
	end)
end

function var_0_0.teamFightInvite(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0 = arg_29_1 or {}

	xyd.Backend.get():request(xyd.mid.TEAM_FIGHT_INVITE, var_29_0, function(arg_30_0, arg_30_1)
		if arg_30_0 == xyd.error.OK and arg_30_1.sub_campaign_info then
			arg_29_0.subCampaignInfo = arg_30_1.sub_campaign_info
		end

		if arg_29_2 then
			arg_29_2(arg_30_0, arg_30_1)
		end
	end)
end

function var_0_0.acceptTeamInvite(arg_31_0, arg_31_1, arg_31_2)
	local var_31_0 = arg_31_1 or {}

	xyd.Backend.get():request(xyd.mid.ACCEPT_TEAM_INVITE, var_31_0, function(arg_32_0, arg_32_1)
		if arg_32_0 == xyd.error.OK then
			arg_31_0:handleResponse(arg_32_1)
		end

		if arg_31_2 then
			arg_31_2(arg_32_0, arg_32_1)
		end
	end)
end

function var_0_0.quitTeamFight(arg_33_0, arg_33_1, arg_33_2)
	local var_33_0 = arg_33_1 or {}

	xyd.Backend.get():request(xyd.mid.QUIT_TEAM_FIGHT, var_33_0, function(arg_34_0, arg_34_1)
		if arg_34_0 == xyd.error.OK then
			-- block empty
		end

		if arg_33_2 then
			arg_33_2(arg_34_0, arg_34_1)
		end
	end)
end

function var_0_0.teamFight(arg_35_0, arg_35_1, arg_35_2)
	local var_35_0 = arg_35_1 or {}

	xyd.Backend.get():request(xyd.mid.TEAM_FIGHT, var_35_0, function(arg_36_0, arg_36_1)
		if arg_36_0 == xyd.error.OK then
			-- block empty
		end

		if arg_35_2 then
			arg_35_2(arg_36_0, arg_36_1)
		end
	end)
end

function var_0_0.prepareTeamFight(arg_37_0, arg_37_1, arg_37_2)
	local var_37_0 = arg_37_1 or {}

	xyd.Backend.get():request(xyd.mid.PREPARE_TEAM_FIGHT, var_37_0, function(arg_38_0, arg_38_1)
		if arg_38_0 == xyd.error.OK then
			arg_37_0:initialTeamStatus()
		end

		if arg_37_2 then
			arg_37_2(arg_38_0, arg_38_1)
		end
	end)
end

function var_0_0.startSingleFight(arg_39_0, arg_39_1, arg_39_2)
	local var_39_0 = arg_39_1 or {}

	xyd.Backend.get():request(xyd.mid.START_SINGLE_FIGHT, var_39_0, function(arg_40_0, arg_40_1)
		if arg_40_0 == xyd.error.OK then
			-- block empty
		end

		if arg_39_2 then
			arg_39_2(arg_40_0, arg_40_1)
		end
	end)
end

function var_0_0.getCampaignLogList(arg_41_0, arg_41_1, arg_41_2)
	local var_41_0 = arg_41_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_CAMPAIGN_LOG_LIST, var_41_0, function(arg_42_0, arg_42_1)
		if arg_42_0 == xyd.error.OK then
			-- block empty
		end

		if arg_41_2 then
			arg_41_2(arg_42_0, arg_42_1)
		end
	end)
end

function var_0_0.getCampaignAward(arg_43_0, arg_43_1, arg_43_2)
	local var_43_0 = arg_43_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_CAMPAIGN_AWARD, var_43_0, function(arg_44_0, arg_44_1)
		if arg_44_0 == xyd.error.OK then
			-- block empty
		end

		if arg_43_2 then
			arg_43_2(arg_44_0, arg_44_1)
		end
	end)
end

function var_0_0.getTeamFightReport(arg_45_0, arg_45_1, arg_45_2)
	local var_45_0 = arg_45_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_TEAM_FIGHT_REPORT, var_45_0, function(arg_46_0, arg_46_1)
		if arg_46_0 == xyd.error.OK then
			-- block empty
		end

		if arg_45_2 then
			arg_45_2(arg_46_0, arg_46_1)
		end
	end)
end

function var_0_0.changePos(arg_47_0, arg_47_1, arg_47_2)
	local var_47_0 = arg_47_1 or {}

	xyd.Backend.get():request(xyd.mid.CHANGE_POS, var_47_0, function(arg_48_0, arg_48_1)
		if arg_48_0 == xyd.error.OK then
			-- block empty
		end

		if arg_47_2 then
			arg_47_2(arg_48_0, arg_48_1)
		end
	end)
end

function var_0_0.pickTeamFormation(arg_49_0, arg_49_1, arg_49_2)
	local var_49_0 = arg_49_1 or {}

	xyd.Backend.get():request(xyd.mid.PICK_TEAM_FORMATION, var_49_0, function(arg_50_0, arg_50_1)
		if arg_50_0 == xyd.error.OK then
			-- block empty
		end

		if arg_49_2 then
			arg_49_2(arg_50_0, arg_50_1)
		end
	end)
end

function var_0_0.sweep(arg_51_0, arg_51_1, arg_51_2)
	local var_51_0 = arg_51_1 or {}

	xyd.Backend.get():request(xyd.mid.OCCULT_SWEEP, var_51_0, function(arg_52_0, arg_52_1)
		if arg_52_0 == xyd.error.OK then
			-- block empty
		end

		if arg_51_2 then
			arg_51_2(arg_52_0, arg_52_1)
		end
	end)
end

function var_0_0.getRoomID(arg_53_0)
	return arg_53_0.baseInfo.room_id or 0
end

function var_0_0.checkCanJoinRoom(arg_54_0, arg_54_1)
	local var_54_0 = tonumber(arg_54_1)

	if not arg_54_0.everRoomIDs then
		arg_54_0.everRoomIDs = {}
	end

	local var_54_1 = xyd.ServerTime.get():getServerTime()

	if not arg_54_0.everRoomIDs[var_54_0] then
		arg_54_0.everRoomIDs[var_54_0] = var_54_1

		return true
	elseif arg_54_0.everRoomIDs[var_54_0] > 0 then
		if var_54_1 - arg_54_0.everRoomIDs[var_54_0] > 30 then
			arg_54_0.everRoomIDs[var_54_0] = var_54_1

			return true
		else
			return false
		end
	end

	return true
end

function var_0_0.checkIsMaster(arg_55_0, arg_55_1)
	if arg_55_1 == arg_55_0.roomInfo.owner then
		return true
	end

	return false
end

function var_0_0.checkIsFightStarter(arg_56_0, arg_56_1)
	if arg_56_0.subCampaignInfo and arg_56_0.subCampaignInfo.start_player and arg_56_0.subCampaignInfo.start_player == arg_56_1 then
		return true
	end

	return false
end

function var_0_0.getPlayerInfo(arg_57_0, arg_57_1)
	local var_57_0 = arg_57_0.roomInfo.members[arg_57_1]

	return arg_57_0:getPlayerInfoByID(var_57_0)
end

function var_0_0.getPlayerInfoByID(arg_58_0, arg_58_1)
	if not arg_58_1 then
		return nil
	end

	for iter_58_0, iter_58_1 in pairs(arg_58_0.roomInfo.member_infos) do
		if iter_58_1.player_id == arg_58_1 then
			return iter_58_1
		end
	end

	return nil
end

function var_0_0.checkIsInvited(arg_59_0, arg_59_1)
	return false
end

function var_0_0.isDirectedToMap(arg_60_0)
	if arg_60_0.baseInfo and arg_60_0.baseInfo.room_id > 0 and arg_60_0.baseInfo.chapter_id > 0 and arg_60_0.roomInfo and arg_60_0.roomInfo.chapter_id > 0 and #arg_60_0.roomInfo.members >= arg_60_0.roomInfo.room_size and arg_60_0.roomInfo.start_time > 0 then
		return true
	else
		return false
	end
end

function var_0_0.handleRoomNotice(arg_61_0, arg_61_1)
	arg_61_0:handleResponse(arg_61_1)
end

function var_0_0.handleResponse(arg_62_0, arg_62_1)
	if arg_62_1.info then
		arg_62_0:handleInfos(arg_62_1.info)
	else
		arg_62_0:handleInfos(arg_62_1)
	end

	if arg_62_1.occult_ticket then
		arg_62_0.selfPlayer.occultTicket = arg_62_1.occult_ticket
	end

	if arg_62_1.function_type == xyd.OccultFunctionType.ROOM_CHANGE then
		arg_62_0.co = coroutine.create(function()
			if not xyd.WindowManager.get():getWindow("occult_prepare").hasLoadRes then
				coroutine.yield()
			end

			xyd.WindowManager.get():closeWindow("occult_prepare")
		end)

		if arg_62_0.baseInfo.room_id == 0 then
			coroutine.resume(arg_62_0.co)
		elseif arg_62_0:isDirectedToMap() then
			coroutine.resume(arg_62_0.co)
			xyd.WindowManager.get():closeWindow("occult")
			xyd.WindowManager.get():openWindow("occult_sub_map")

			local var_62_0 = xyd.tables.creatsCampaign:getStartDialogTable(arg_62_0.baseInfo.chapter_id)
			local var_62_1 = {}

			if var_62_1.table_name ~= "" then
				var_62_1.callback = callback
				var_62_1.is_occult_story = true
				var_62_1.table_name = var_62_0

				xyd.WindowManager.get():openWindow("occult_story_talk", var_62_1)
			end
		else
			local var_62_2 = xyd.WindowManager.get():getWindow("occult_prepare")

			if var_62_2 and not tolua.isnull(var_62_2) then
				var_62_2:initList()
			end
		end
	elseif arg_62_1.function_type == xyd.OccultFunctionType.TEAM_INVITE then
		if arg_62_1.start_player ~= arg_62_0.selfPlayer.playerID then
			if display.getRunningScene().__cname ~= "MainScene" then
				local var_62_3 = xyd.WindowManager.get():getWindow("battle_win")

				if var_62_3 and not tolua.isnull(var_62_3) then
					var_62_3:clickReturnButton()
				end

				local var_62_4 = xyd.WindowManager.get():getWindow("battle_lose")

				if var_62_4 and not tolua.isnull(var_62_4) then
					var_62_4:clickReturnButton()
				end

				arg_62_0.hasInvite = true
			else
				xyd.WindowManager.get():openWindow("occult_confirm_invited", arg_62_1)
			end
		end

		arg_62_0.teamInviteInfos = arg_62_1
	elseif arg_62_1.function_type == xyd.OccultFunctionType.TEAM_ACCEPT then
		arg_62_0.subCampaignInfo = arg_62_1.sub_campaign_info

		if arg_62_1.sub_campaign_info and not arg_62_1.sub_campaign_info.accept_players then
			xyd.WindowManager.get():closeWindow("occult_confirm_invited")
			xyd.WindowManager.get():closeWindow("occult_cooperate_waiting")

			local var_62_5 = string.format(var_0_1:translation("OCCULT_REJECT_COOPERATION_TIP"), arg_62_1.player_name)

			xyd.WindowManager.get():openWindow("toast", {
				message = var_62_5
			})

			return
		end

		local var_62_6 = xyd.WindowManager.get():getWindow("occult_cooperate_waiting")

		if var_62_6 and not tolua.isnull(var_62_6) then
			var_62_6:refreshList()
		end

		if arg_62_0.subCampaignInfo.team_fight_infos then
			xyd.WindowManager.get():closeWindow("occult_cooperate_waiting")
			xyd.WindowManager.get():openWindow("occult_show_team")
		end
	elseif arg_62_1.function_type == xyd.OccultFunctionType.TEAM_QUIT then
		xyd.WindowManager.get():closeWindow("occult_confirm_invited")
		xyd.WindowManager.get():closeWindow("occult_cooperate_waiting")
		xyd.WindowManager.get():closeWindow("occult_show_team")

		local var_62_7 = string.format(var_0_1:translation("OCCULT_REJECT_COOPERATION_TIP"), arg_62_1.player_name)

		xyd.WindowManager.get():openWindow("toast", {
			message = var_62_7
		})
	elseif arg_62_1.function_type == xyd.OccultFunctionType.TEAM_SELECT or arg_62_1.function_type == xyd.OccultFunctionType.TEAM_PREPARE then
		arg_62_0.teamFightInfos[tostring(arg_62_1.player_id)] = arg_62_1.team_fight_info

		local var_62_8 = xyd.WindowManager.get():getWindow("occult_show_team")

		if var_62_8 and not tolua.isnull(var_62_8) then
			var_62_8:updateHeros()
		end
	elseif arg_62_1.function_type == xyd.OccultFunctionType.TEAM_FIGHT and not arg_62_0:checkIsFightStarter(arg_62_0.selfPlayer.playerID) then
		local var_62_9 = xyd.WindowManager.get():getWindow("occult_show_team")

		if var_62_9 and not tolua.isnull(var_62_9) then
			var_62_9:teamFight(arg_62_1.report_key)
		end

		local var_62_10 = xyd.WindowManager.get():getWindow("occult_sub_map")

		if var_62_10 and not tolua.isnull(var_62_10) then
			var_62_10:updateMapShow()

			if arg_62_1.hero_stat then
				var_62_10:updateCompanionsInfo()
			end
		end
	elseif arg_62_1.function_type == xyd.OccultFunctionType.CHANGE_POS and arg_62_1.player_id and arg_62_1.stay_pos then
		if arg_62_0.heroStat then
			arg_62_0.heroStat[tostring(arg_62_1.player_id)].hero_stat.stay_pos = arg_62_1.stay_pos
		end

		local var_62_11 = xyd.WindowManager.get():getWindow("occult_sub_map")

		if var_62_11 and not tolua.isnull(var_62_11) then
			var_62_11:updateCompanionPosition()
		end
	elseif arg_62_1.function_type == xyd.OccultFunctionType.EVENT then
		arg_62_0:handleEvent(arg_62_1)
	elseif arg_62_1.function_type == xyd.OccultFunctionType.SINGLE_FIGHT then
		local var_62_12 = xyd.WindowManager.get():getWindow("occult_sub_map")

		if var_62_12 and not tolua.isnull(var_62_12) then
			var_62_12:updateMapShow()

			if arg_62_1.hero_stat then
				var_62_12:updateCompanionsInfo()
			end
		end
	elseif arg_62_1.function_type == xyd.OccultFunctionType.FIGHT_STATUS then
		local var_62_13 = xyd.WindowManager.get():getWindow("occult_sub_map")

		if var_62_13 and not tolua.isnull(var_62_13) then
			var_62_13:updateMapShow()
		end

		local var_62_14 = xyd.WindowManager.get():getWindow("occult_campaign_detail")

		if var_62_14 and not tolua.isnull(var_62_14) then
			var_62_14:updateCampaignStageShow()
		end
	elseif arg_62_1.function_type == xyd.OccultFunctionType.ONLINE then
		arg_62_0:setPlayerOnlineState(arg_62_1.player_id, arg_62_1.is_online)

		local var_62_15 = xyd.WindowManager.get():getWindow("occult_sub_map")

		if var_62_15 and var_62_15.hasLoadRes and not tolua.isnull(var_62_15) then
			var_62_15:updateCompanionsInfo()
		end
	end
end

function var_0_0.handleInvite(arg_64_0)
	if arg_64_0.hasInvite and arg_64_0.teamInviteInfos then
		arg_64_0.hasInvite = false

		xyd.WindowManager.get():openWindow("occult_confirm_invited", arg_64_0.teamInviteInfos)
	end
end

function var_0_0.setPlayerOnlineState(arg_65_0, arg_65_1, arg_65_2)
	if arg_65_0.heroStat and arg_65_0.heroStat[tostring(arg_65_1)] then
		arg_65_0.heroStat[tostring(arg_65_1)].player_info.is_online = arg_65_2
	end
end

function var_0_0.handleEvent(arg_66_0, arg_66_1)
	if arg_66_1.event_id == xyd.OccultEventType.AUTO_PASS then
		local var_66_0 = {}

		arg_66_0:getInfo(var_66_0, function(arg_67_0, arg_67_1)
			if arg_67_0 == xyd.error.OK then
				local var_67_0 = xyd.WindowManager.get():getWindow("occult_sub_map")

				if var_67_0 and not tolua.isnull(var_67_0) then
					var_67_0:updateMapShow()
				end
			end
		end)
	elseif arg_66_1.event_id == xyd.OccultEventType.RECOVER_HP or arg_66_1.event_id == xyd.OccultEventType.RECOVER_MP or arg_66_1.event_id == xyd.OccultEventType.REVIVE_HERO then
		if arg_66_1.event_id == xyd.OccultEventType.REVIVE_HERO then
			local var_66_1 = xyd.WindowManager.get():getWindow("occult_sub_map")

			if var_66_1 and not tolua.isnull(var_66_1) then
				var_66_1:updateCompanionsInfo()
			end
		end
	elseif arg_66_1.event_id == xyd.OccultEventType.INCR_DISPATCH_NUM then
		arg_66_0.baseInfo.dispatch_limit = arg_66_1.dispatch_limit
	end

	arg_66_0:playEventStory(arg_66_1.event_id)
end

function var_0_0.playEventStory(arg_68_0, arg_68_1)
	local var_68_0 = xyd.WindowManager.get():getWindow("occult_sub_map")

	table.insert(arg_68_0.eventIds, arg_68_1)

	if not var_68_0 or tolua.isnull(var_68_0) then
		return
	end

	arg_68_0:playStorys()
end

function var_0_0.playStorys(arg_69_0)
	local function var_69_0()
		arg_69_0:playStorys()
	end

	if display.getRunningScene().__cname ~= "MainScene" then
		return
	end

	if not arg_69_0.eventIds or not next(arg_69_0.eventIds) then
		return
	end

	local var_69_1 = arg_69_0.eventIds[1]

	table.remove(arg_69_0.eventIds, 1)

	local var_69_2 = xyd.tables.creatsCampaign:getDialogTable(arg_69_0.baseInfo.chapter_id, arg_69_0:getRoomCampaignType(), var_69_1)
	local var_69_3 = xyd.tables.creatsCampaign:getCreatTips(arg_69_0.baseInfo.chapter_id, arg_69_0:getRoomCampaignType(), var_69_1)

	if var_69_2 ~= "" then
		local var_69_4 = {
			table_name = var_69_2,
			callback = var_69_0
		}

		xyd.WindowManager.get():openWindow("occult_story_talk", var_69_4)
	elseif var_69_3 ~= "" then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_69_3,
			callback = var_69_0
		})
	end
end

function var_0_0.getRoomCampaignType(arg_71_0)
	if arg_71_0.roomInfo and arg_71_0.roomInfo.campaign_type then
		return arg_71_0.roomInfo.campaign_type
	else
		return xyd.OccultRoomType.MULTI_PLAYER
	end
end

function var_0_0.updateSubMapCompanionsInfo(arg_72_0)
	local var_72_0 = xyd.WindowManager.get():getWindow("occult_show_team")

	if var_72_0 and not tolua.isnull(var_72_0) then
		var_72_0:updateCompanionsInfo()
	end
end

function var_0_0.handleInfos(arg_73_0, arg_73_1)
	if arg_73_1.award_info then
		arg_73_0:handleRewards(arg_73_1.award_info)
	end

	if arg_73_1.progress then
		arg_73_0.progress = arg_73_1.progress
	end

	if arg_73_1.base_info then
		arg_73_0.baseInfo = arg_73_1.base_info
	end

	if arg_73_1.room_info then
		arg_73_0.roomInfo = arg_73_1.room_info
	end

	if arg_73_1.hero_stat then
		arg_73_0.heroStat = arg_73_1.hero_stat
	end

	if arg_73_1.open_campaigns then
		arg_73_0.openCampaigns = arg_73_1.open_campaigns
	end

	if arg_73_1.campaign_info and arg_73_0.openCampaigns then
		arg_73_0.openCampaigns[tostring(arg_73_1.campaign_info.campaign_id)] = arg_73_1.campaign_info
	end

	if arg_73_1.self_dispatch then
		arg_73_0.dispatchInfo = arg_73_1.self_dispatch
	end

	if arg_73_1.hero_status then
		for iter_73_0, iter_73_1 in pairs(arg_73_1.hero_status) do
			arg_73_0.dispatchInfo[iter_73_0] = iter_73_1
		end
	end

	if arg_73_1.sub_campaign_info then
		arg_73_0.subCampaignInfo = arg_73_1.sub_campaign_info
	end

	if arg_73_0.subCampaignInfo and arg_73_0.subCampaignInfo.team_fight_infos then
		arg_73_0.teamFightInfos = arg_73_0.subCampaignInfo.team_fight_infos
	end

	if arg_73_0.progress and tonumber(arg_73_0.progress) >= 1 or arg_73_0.roomInfo and arg_73_0.roomInfo.is_close == 1 then
		local var_73_0 = xyd.WindowManager.get():getWindow("occult_sub_map")

		if var_73_0 and not tolua.isnull(var_73_0) then
			arg_73_0:subMapEnded()
		end
	end

	if arg_73_1.campaign_info or arg_73_1.open_campaigns then
		local var_73_1 = xyd.WindowManager.get():getWindow("occult_campaign_detail")

		if var_73_1 and not tolua.isnull(var_73_1) then
			var_73_1:updateCampaignStageShow()
		end
	end
end

function var_0_0.handleRewards(arg_74_0, arg_74_1)
	if arg_74_1 and arg_74_1.awards then
		arg_74_0.selfPlayer:handleRewardsWithoutShow(arg_74_1.awards)
	end

	xyd.WindowManager.get():openWindow("occult_battle_result", arg_74_1)
end

function var_0_0.addInvitedList(arg_75_0, arg_75_1)
	table.insert(arg_75_0.invitedList, arg_75_1)
end

function var_0_0.checkIsInvited(arg_76_0, arg_76_1)
	for iter_76_0 = 1, #arg_76_0.invitedList do
		if arg_76_0.invitedList[iter_76_0] == arg_76_1 then
			return true
		end
	end

	return false
end

function var_0_0.resetInvited(arg_77_0)
	arg_77_0.invitedList = {}
end

function var_0_0.initialTeamStatus(arg_78_0)
	arg_78_0.teamStatus = {}
end

function var_0_0.getSelfStatus(arg_79_0)
	return arg_79_0:getPlayerStatus(arg_79_0.selfPlayer.playerID)
end

function var_0_0.getPlayerStatus(arg_80_0, arg_80_1)
	return arg_80_0.teamStatus[tostring(arg_80_1)] or false
end

function var_0_0.setPlayerStatus(arg_81_0, arg_81_1, arg_81_2)
	arg_81_0.teamStatus[tostring(arg_81_1)] = arg_81_2
end

function var_0_0.checkCanJoinRoom(arg_82_0, arg_82_1)
	local var_82_0 = tonumber(arg_82_1)

	if not arg_82_0.everRoomIDs then
		arg_82_0.everRoomIDs = {}
	end

	local var_82_1 = xyd.ServerTime.get():getServerTime()

	if not arg_82_0.everRoomIDs[var_82_0] then
		arg_82_0.everRoomIDs[var_82_0] = var_82_1

		return true
	elseif arg_82_0.everRoomIDs[var_82_0] > 0 then
		if var_82_1 - arg_82_0.everRoomIDs[var_82_0] > 30 then
			arg_82_0.everRoomIDs[var_82_0] = var_82_1

			return true
		else
			return false
		end
	end

	return true
end

function var_0_0.isHeroSelected(arg_83_0, arg_83_1)
	local var_83_0 = arg_83_0.roomInfo.members

	if arg_83_1.isPet_ then
		local var_83_1 = arg_83_0.teamFightInfos[tostring(arg_83_0.roomInfo.owner)].pet

		if var_83_1 and var_83_1.table_id == arg_83_1:getTableID() then
			return true
		end

		return false
	else
		for iter_83_0 = 1, #var_83_0 do
			local var_83_2 = arg_83_0.teamFightInfos[tostring(var_83_0[iter_83_0])].formation or {}

			for iter_83_1 = 1, #var_83_2 do
				if var_83_2[iter_83_1].table_id == arg_83_1:getTableID() then
					return true
				end
			end
		end

		return false
	end
end

function var_0_0.subMapEnded(arg_84_0, arg_84_1)
	if display.getRunningScene().__cname ~= "MainScene" then
		return
	end

	if not arg_84_0.isInEnded and not arg_84_1 and (not arg_84_0.progress or not (tonumber(arg_84_0.progress) >= 1)) and (not arg_84_0.roomInfo or arg_84_0.roomInfo.is_close ~= 1) then
		return
	end

	arg_84_0.progress = "0"
	arg_84_0.isInEnded = true

	local var_84_0 = {}

	arg_84_0:getInfo(var_84_0, function(arg_85_0, arg_85_1)
		if arg_85_0 == xyd.error.OK then
			arg_84_0:closeOccultRelatedWindows()

			if arg_84_0:isDirectedToMap() then
				xyd.WindowManager.get():openWindow("occult_sub_map")
			else
				xyd.WindowManager.get():openWindow("occult")
			end
		end

		arg_84_0.isInEnded = false
	end)
end

function var_0_0.isDispatchedHero(arg_86_0, arg_86_1)
	local var_86_0 = arg_86_0.dispatchInfo or {}

	if xyd.isInTable(table.keys(var_86_0), tostring(arg_86_1)) then
		return true
	end

	return false
end

function var_0_0.isCampaignPass(arg_87_0, arg_87_1)
	local var_87_0 = arg_87_0.openCampaigns[tostring(arg_87_1)]

	if not arg_87_0.openCampaigns or not var_87_0 then
		return false
	end

	local var_87_1 = var_87_0.is_win

	if not var_87_1 then
		return false
	end

	for iter_87_0 = 1, #var_87_1 do
		if var_87_1[iter_87_0] == 0 then
			return false
		end
	end

	return true
end

function var_0_0.checkIsDispatchFull(arg_88_0, arg_88_1)
	local var_88_0 = 0
	local var_88_1 = arg_88_0.teamFightInfos[tostring(arg_88_0.selfPlayer.playerID)].formation or {}

	for iter_88_0 = 1, #var_88_1 do
		if not arg_88_0:isDispatchedHero(var_88_1[iter_88_0].partner_id) then
			var_88_0 = var_88_0 + 1
		end
	end

	if not arg_88_1 or not arg_88_0:isDispatchedHero(arg_88_1:getHeroID()) then
		var_88_0 = var_88_0 + 1
	end

	if var_88_0 + #table.keys(arg_88_0.dispatchInfo or {}) > arg_88_0.baseInfo.dispatch_limit then
		return true
	end

	return false
end

function var_0_0.getChatWindow(arg_89_0, arg_89_1)
	local var_89_0 = import("app.windows.GroupChatNewWnd").new()
	local var_89_1 = {}

	for iter_89_0, iter_89_1 in pairs(arg_89_0.roomInfo.member_infos) do
		var_89_1[tostring(iter_89_1.player_id)] = iter_89_1
	end

	local var_89_2 = {
		select_type = xyd.FriendMsgSelectType.OCCULT,
		member_infos = var_89_1,
		add_wnd_name = arg_89_1
	}

	var_89_0:setParams(var_89_2)

	return var_89_0
end

function var_0_0.getAwakeAwardsItem(arg_90_0, arg_90_1)
	local var_90_0 = {}
	local var_90_1 = xyd.tables.creatsChapterSelect:awakenMissionId(arg_90_1)
	local var_90_2 = xyd.tables.creatsChapterSelect:awakenItem(arg_90_1)
	local var_90_3 = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)

	for iter_90_0 = 1, #var_90_1 do
		local var_90_4 = var_90_3:getTaskByID(var_90_1[iter_90_0], xyd.TaskType.AWAKE)

		if var_90_4 and var_90_4.is_going == 1 then
			table.insert(var_90_0, var_90_2[iter_90_0])
		end
	end

	return var_90_0
end

function var_0_0.openOccultWindow(arg_91_0, arg_91_1)
	local var_91_0 = {}

	arg_91_0:getInfo(var_91_0, function(arg_92_0, arg_92_1)
		if arg_92_0 == xyd.error.OK then
			arg_91_0:closeOccultRelatedWindows()

			if arg_91_0:isDirectedToMap() then
				xyd.WindowManager.get():openWindow("occult_sub_map")
			elseif not arg_91_1 then
				xyd.WindowManager.get():openWindow("occult")
			else
				xyd.WindowManager.get():openWindow("occult", {
					chapter = arg_91_1
				})
			end
		end
	end)
end

function var_0_0.getChapterTopScore(arg_93_0, arg_93_1)
	if arg_93_0.baseInfo.max_points then
		return arg_93_0.baseInfo.max_points[arg_93_1] or 0
	end

	return 0
end

return var_0_0
