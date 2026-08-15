local var_0_0 = class("Illusion", import(".BaseModel"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	PREPARE = 0,
	SELECT_HERO = 1
}

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.times = 0
	arg_1_0.initTimes = xyd.tables.misc.illusionInitTime
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.betInfo = {
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0
	}
	arg_1_0.betPreSetInfo = {
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0
	}
	arg_1_0.hasBet = false
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.ILLUSION_NOTICE, handler(arg_2_0, arg_2_0.notice))
end

function var_0_0.loadIllusionInfos(arg_3_0, arg_3_1)
	xyd.Backend.get():request(xyd.mid.ILLUSION_LOAD_INFO, nil, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.id = arg_4_1.paradise_info.paradise_id
			arg_3_0.isOpen = arg_4_1.paradise_info.count < 1

			if not arg_3_0.isOpen then
				arg_3_0.id = xyd.tables.illusionCampaign:nextBoss(arg_3_0.id)
			end

			arg_3_0.times = arg_4_1.challenge_times
			arg_3_0.buyPre = arg_4_1.buy_times
			arg_3_0.damage = arg_4_1.hurt
			arg_3_0.rank = arg_4_1.rank

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.CHECK_MIDDLE_RED_MARK,
				params = xyd.CheckMiddleRed.ILLUSION
			})
		end

		if arg_3_1 then
			arg_3_1(arg_4_0)
		end
	end)
end

function var_0_0.buyTimes(arg_5_0, arg_5_1)
	xyd.Backend.get():request(xyd.mid.ILLUSION_BUY_TIMES, nil, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			arg_5_0.times = arg_6_1.challenge_times
			arg_5_0.buyPre = arg_6_1.buy_times
		end

		if arg_5_1 then
			arg_5_1(arg_6_0)
		end
	end)
end

function var_0_0.clear(arg_7_0)
	arg_7_0.teamInfo = {}
	arg_7_0.invitedList = {}
	arg_7_0.damageResult = {}
end

function var_0_0.updateTeamInfo(arg_8_0, arg_8_1)
	arg_8_0.teamInfo = arg_8_1
end

function var_0_0.getTeamInfo(arg_9_0)
	return arg_9_0.teamInfo
end

function var_0_0.getMasterID(arg_10_0)
	return arg_10_0.teamInfo.master_id
end

function var_0_0.checkIsMaster(arg_11_0, arg_11_1)
	if arg_11_0:getMasterID() == arg_11_1 then
		return true
	end

	return false
end

function var_0_0.checkCanJoinRoom(arg_12_0, arg_12_1)
	local var_12_0 = tonumber(arg_12_1)

	if not arg_12_0.everRoomIDs then
		arg_12_0.everRoomIDs = {}
	end

	local var_12_1 = xyd.ServerTime.get():getServerTime()

	if not arg_12_0.everRoomIDs[var_12_0] then
		arg_12_0.everRoomIDs[var_12_0] = var_12_1

		return true
	elseif arg_12_0.everRoomIDs[var_12_0] > 0 then
		if var_12_1 - arg_12_0.everRoomIDs[var_12_0] > 30 then
			arg_12_0.everRoomIDs[var_12_0] = var_12_1

			return true
		else
			return false
		end
	end

	return true
end

function var_0_0.getPlayerInfo(arg_13_0, arg_13_1)
	if arg_13_1 == 1 then
		return arg_13_0.teamInfo.master_id_info
	else
		return arg_13_0.teamInfo["mate_" .. arg_13_1 - 1 .. "_info"] or 0
	end
end

function var_0_0.getPlayerInfoByID(arg_14_0, arg_14_1)
	if arg_14_0:checkIsMaster(arg_14_1) then
		return arg_14_0.teamInfo.master_id_info
	elseif arg_14_0.teamInfo.mate_1 == arg_14_1 then
		return arg_14_0.teamInfo.mate_1_info
	elseif arg_14_0.teamInfo.mate_2 == arg_14_1 then
		return arg_14_0.teamInfo.mate_2_info
	end

	return {}
end

function var_0_0.getPlayerStatus(arg_15_0, arg_15_1)
	if arg_15_1 == 1 then
		return 0
	else
		return arg_15_0.teamInfo["mate_" .. arg_15_1 .. "status"] or 0
	end
end

function var_0_0.getRoomID(arg_16_0)
	return arg_16_0.teamInfo.room_id or 0
end

function var_0_0.addInvitedList(arg_17_0, arg_17_1)
	table.insert(arg_17_0.invitedList, arg_17_1)
end

function var_0_0.checkIsInvited(arg_18_0, arg_18_1)
	for iter_18_0 = 1, #arg_18_0.invitedList do
		if arg_18_0.invitedList[iter_18_0] == arg_18_1 then
			return true
		end
	end

	return false
end

function var_0_0.getSelfHeros(arg_19_0)
	local var_19_0 = {}

	if arg_19_0:checkIsMaster(arg_19_0.selfPlayer.playerID) then
		var_19_0 = arg_19_0.teamInfo.master_partner_detail
	elseif arg_19_0.selfPlayer.playerID == arg_19_0.teamInfo.mate_1 then
		var_19_0 = arg_19_0.teamInfo.mate_1_partner_detail
	else
		var_19_0 = arg_19_0.teamInfo.mate_2_partner_detail
	end

	return var_19_0 or {}
end

function var_0_0.getSelfHeroID(arg_20_0)
	local var_20_0 = {}

	if arg_20_0:checkIsMaster(arg_20_0.selfPlayer.playerID) then
		local var_20_1 = xyd.splitToNumber(arg_20_0.teamInfo.master_partner or "", "|") or {}

		for iter_20_0 = 1, 1 do
			table.insert(var_20_0, var_20_1[iter_20_0] or 0)
		end
	elseif arg_20_0.selfPlayer.playerID == arg_20_0.teamInfo.mate_1 then
		local var_20_2 = xyd.splitToNumber(arg_20_0.teamInfo.mate_1_partner or "", "|") or {}

		for iter_20_1 = 1, 2 do
			table.insert(var_20_0, var_20_2[iter_20_1] or 0)
		end
	else
		local var_20_3 = xyd.splitToNumber(arg_20_0.teamInfo.mate_2_partner or "", "|") or {}

		for iter_20_2 = 1, 2 do
			table.insert(var_20_0, var_20_3[iter_20_2] or 0)
		end
	end

	return var_20_0
end

function var_0_0.getSelectHeros(arg_21_0)
	local var_21_0 = {}
	local var_21_1 = xyd.splitToNumber(arg_21_0.teamInfo.master_partner or "", "|") or {}

	for iter_21_0 = 1, #var_21_1 do
		table.insert(var_21_0, var_21_1[iter_21_0] or 0)
	end

	for iter_21_1 = 1, 2 do
		local var_21_2 = xyd.splitToNumber(arg_21_0.teamInfo["mate_" .. iter_21_1 .. "_partner"] or "", "|") or {}

		for iter_21_2 = 1, #var_21_2 do
			table.insert(var_21_0, var_21_2[iter_21_2] or 0)
		end
	end

	return var_21_0
end

function var_0_0.getHeroInfoByIndex(arg_22_0, arg_22_1)
	if arg_22_1 == 2 then
		if arg_22_0.teamInfo.master_partner_detail then
			if arg_22_0.teamInfo.master_partner_detail[arg_22_1 - 1] then
				arg_22_0.teamInfo.master_partner_detail[arg_22_1 - 1].team_status = arg_22_0.teamInfo.master_status
				arg_22_0.teamInfo.master_partner_detail[arg_22_1 - 1].player_info = arg_22_0.teamInfo.master_id_info
			end

			return arg_22_0.teamInfo.master_partner_detail[arg_22_1 - 1] or {}
		end
	elseif arg_22_1 == 3 or arg_22_1 == 4 then
		if arg_22_0.teamInfo.mate_1_partner_detail then
			if arg_22_0.teamInfo.mate_1_partner_detail[arg_22_1 - 2] then
				arg_22_0.teamInfo.mate_1_partner_detail[arg_22_1 - 2].team_status = arg_22_0.teamInfo.mate_1_status
				arg_22_0.teamInfo.mate_1_partner_detail[arg_22_1 - 2].player_info = arg_22_0.teamInfo.mate_1_info
			end

			return arg_22_0.teamInfo.mate_1_partner_detail[arg_22_1 - 2] or {}
		end
	elseif (arg_22_1 == 5 or arg_22_1 == 6) and arg_22_0.teamInfo.mate_2_partner_detail then
		if arg_22_0.teamInfo.mate_2_partner_detail[arg_22_1 - 4] then
			arg_22_0.teamInfo.mate_2_partner_detail[arg_22_1 - 4].team_status = arg_22_0.teamInfo.mate_2_status
			arg_22_0.teamInfo.mate_2_partner_detail[arg_22_1 - 4].player_info = arg_22_0.teamInfo.mate_2_info
		end

		return arg_22_0.teamInfo.mate_2_partner_detail[arg_22_1 - 4] or {}
	end

	return {}
end

function var_0_0.getSelfStatus(arg_23_0)
	local var_23_0 = 0

	if arg_23_0:checkIsMaster(arg_23_0.selfPlayer.playerID) then
		var_23_0 = arg_23_0.teamInfo.master_status
	elseif arg_23_0.selfPlayer.playerID == arg_23_0.teamInfo.mate_1 then
		var_23_0 = arg_23_0.teamInfo.mate_1_status
	else
		var_23_0 = arg_23_0.teamInfo.mate_2_status
	end

	return var_23_0
end

function var_0_0.updateSelfStatus(arg_24_0)
	if arg_24_0:checkIsMaster(arg_24_0.selfPlayer.playerID) then
		arg_24_0.teamInfo.master_status = arg_24_0.teamInfo.master_status == 0 and 1 or 0
	elseif arg_24_0.selfPlayer.playerID == arg_24_0.teamInfo.mate_1 then
		arg_24_0.teamInfo.mate_1_status = arg_24_0.teamInfo.mate_1_status == 0 and 1 or 0
	else
		arg_24_0.teamInfo.mate_2_status = arg_24_0.teamInfo.mate_2_status == 0 and 1 or 0
	end
end

function var_0_0.createHouse(arg_25_0, arg_25_1, arg_25_2)
	arg_25_0:clear()

	local var_25_0 = arg_25_1 or {}

	xyd.Backend.get():request(xyd.mid.ILLUSION_CREATE_ROOM, var_25_0, function(arg_26_0, arg_26_1)
		if arg_26_0 == xyd.error.OK and arg_26_1 and next(arg_26_1) then
			arg_25_0:updateTeamInfo(arg_26_1)
		end

		if arg_25_2 then
			arg_25_2(arg_26_0, arg_26_1)
		end
	end)
end

function var_0_0.getRoomInfo(arg_27_0, arg_27_1)
	arg_27_0:clear()
	xyd.Backend.get():request(xyd.mid.ILLUSION_GET_ROOM_INFO, {}, function(arg_28_0, arg_28_1)
		if arg_28_0 == xyd.error.OK and arg_28_1 and next(arg_28_1) then
			arg_27_0:updateTeamInfo(arg_28_1)
		end

		if arg_27_1 then
			arg_27_1(arg_28_0, arg_28_1)
		end
	end)
end

function var_0_0.removePlayer(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0 = {
		p_id = arg_29_1
	}

	xyd.Backend.get():request(xyd.mid.ILLUSION_REMOVE_PLAYER, var_29_0, function(arg_30_0, arg_30_1)
		if arg_30_0 == xyd.error.OK and arg_30_1 and next(arg_30_1) then
			-- block empty
		end

		if arg_29_2 then
			arg_29_2(arg_30_0, arg_30_1)
		end
	end)
end

function var_0_0.enterRoom(arg_31_0, arg_31_1, arg_31_2)
	arg_31_0:clear()

	local var_31_0 = {
		room_id = tonumber(arg_31_1)
	}

	xyd.Backend.get():request(xyd.mid.ILLUSION_ENTER_ROOM, var_31_0, function(arg_32_0, arg_32_1)
		if arg_32_0 == xyd.error.OK then
			if arg_32_1 and next(arg_32_1) then
				arg_31_0:updateTeamInfo(arg_32_1)
			end
		else
			arg_31_0.everRoomIDs[arg_31_1] = nil
		end

		if arg_31_2 then
			arg_31_2(arg_32_0, arg_32_1)
		end
	end)
end

function var_0_0.inviteFriend(arg_33_0, arg_33_1, arg_33_2)
	local var_33_0 = {
		p_id = arg_33_1
	}

	xyd.Backend.get():request(xyd.mid.ILLUSION_INVITE_FRIEND, var_33_0, function(arg_34_0, arg_34_1)
		if arg_33_2 then
			arg_33_2(arg_34_0, arg_34_1)
		end
	end)
end

function var_0_0.getDamageResult(arg_35_0)
	return arg_35_0.damageResult or {}
end

function var_0_0.setDamageResult(arg_36_0, arg_36_1)
	arg_36_0.damageResult = arg_36_1 or {}
end

function var_0_0.notice(arg_37_0, arg_37_1)
	if arg_37_1.params and next(arg_37_1.params) then
		local var_37_0 = arg_37_1.params.message

		if var_37_0 and next(var_37_0) then
			if var_37_0.room_id == 0 then
				local var_37_1 = xyd.WindowManager.get():getWindow("illusion_prepare")

				if var_37_1 and not tolua.isnull(var_37_1) then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("ILLUSION_TEAM_TIPS_18")
					})
					xyd.WindowManager.get():closeWindow("illusion_prepare")
				end

				local var_37_2 = xyd.WindowManager.get():getWindow("illusion_show_team")

				if var_37_2 and not tolua.isnull(var_37_2) then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("ILLUSION_TEAM_TIPS_18")
					})
					xyd.WindowManager.get():closeWindow("illusion_show_team")
				end

				return
			elseif var_37_0.is_report and var_37_0.is_report == 1 then
				arg_37_0:setDamageResult(var_37_0.damage_result)
				arg_37_0:getReport(var_37_0.report_id, function(arg_38_0, arg_38_1)
					if arg_38_0 == xyd.error.OK then
						local var_38_0 = xyd.WindowManager.get():getWindow("illusion_show_team")

						if var_38_0 and not tolua.isnull(var_38_0) then
							var_38_0:playReport(arg_38_1.report)
						end
					end
				end)
			end

			if var_37_0.status == var_0_2.PREPARE then
				arg_37_0:updatePrepareWnd(var_37_0)
			elseif var_37_0.status == var_0_2.SELECT_HERO then
				arg_37_0.co = coroutine.create(handler(arg_37_0, arg_37_0.updateSelectHeroWnd))

				coroutine.resume(arg_37_0.co, var_37_0)
			end
		end
	end
end

function var_0_0.updatePrepareWnd(arg_39_0, arg_39_1)
	arg_39_0:updateTeamInfo(arg_39_1)

	local var_39_0 = xyd.WindowManager.get():getWindow("illusion_prepare")

	if var_39_0 and not tolua.isnull(var_39_0) then
		var_39_0:initList()
	end
end

function var_0_0.updateSelectHeroWnd(arg_40_0, arg_40_1)
	arg_40_0:updateTeamInfo(arg_40_1)

	local var_40_0 = xyd.WindowManager.get():getWindow("illusion_show_team")

	if not var_40_0 or tolua.isnull(var_40_0) then
		var_40_0 = xyd.WindowManager.get():openWindow("illusion_show_team")

		local var_40_1 = xyd.WindowManager.get():getWindow("illusion_prepare")

		if var_40_1 and not tolua.isnull(var_40_1) then
			if not var_40_1.hasLoadRes then
				coroutine.yield()
			end

			xyd.WindowManager.get():closeWindow("illusion_prepare")

			return
		end
	else
		var_40_0:updateHeros()
		var_40_0:updatePrepareBtn()
	end
end

function var_0_0.setPartner(arg_41_0, arg_41_1, arg_41_2)
	xyd.Backend.get():request(xyd.mid.ILLUSION_SET_PARTNER, arg_41_1, function(arg_42_0, arg_42_1)
		if arg_42_0 == xyd.error.OK then
			-- block empty
		end

		if arg_41_2 then
			arg_41_2(arg_42_0, arg_42_1)
		end
	end)
end

function var_0_0.prepareRoom(arg_43_0, arg_43_1)
	xyd.Backend.get():request(xyd.mid.ILLUSION_PREPARE_ROOM, {}, function(arg_44_0, arg_44_1)
		if arg_44_0 == xyd.error.OK then
			-- block empty
		end

		if arg_43_1 then
			arg_43_1(arg_44_0, arg_44_1)
		end
	end)
end

function var_0_0.prepareFight(arg_45_0, arg_45_1)
	xyd.Backend.get():request(xyd.mid.ILLUSION_PREPARE_FIGHT, {}, function(arg_46_0, arg_46_1)
		if arg_45_1 then
			arg_45_1(arg_46_0, arg_46_1)
		end
	end)
end

function var_0_0.cancelPrepareFight(arg_47_0, arg_47_1)
	xyd.Backend.get():request(xyd.mid.ILLUSION_CANCEL_PREPARE, {}, function(arg_48_0, arg_48_1)
		if arg_47_1 then
			arg_47_1(arg_48_0, arg_48_1)
		end
	end)
end

function var_0_0.startTeamFight(arg_49_0, arg_49_1)
	xyd.Backend.get():request(xyd.mid.ILLUSION_START_TEAM_FIGHT, {}, function(arg_50_0, arg_50_1)
		if arg_50_0 == xyd.error.OK then
			local var_50_0 = xyd.WindowManager.get():getWindow("illusion_show_team")

			if var_50_0 and not tolua.isnull(var_50_0) then
				var_50_0:playReport(arg_50_1.report)
			end
		end

		if arg_49_1 then
			arg_49_1(arg_50_0, arg_50_1)
		end
	end)
end

function var_0_0.exitRoom(arg_51_0, arg_51_1)
	xyd.Backend.get():request(xyd.mid.ILLUSION_EXIT_ROOM, {}, function(arg_52_0, arg_52_1)
		if arg_52_0 == xyd.error.OK then
			-- block empty
		end

		if arg_51_1 then
			arg_51_1(arg_52_0, arg_52_1)
		end
	end)
end

function var_0_0.chatToFriend(arg_53_0, arg_53_1, arg_53_2)
	local var_53_0 = {}

	if arg_53_0.teamInfo.master_id ~= arg_53_0.selfPlayer.playerID and arg_53_0.teamInfo.master_id ~= 0 then
		table.insert(var_53_0, arg_53_0.teamInfo.master_id)
	end

	if arg_53_0.teamInfo.mate_1 ~= arg_53_0.selfPlayer.playerID and arg_53_0.teamInfo.mate_1 ~= 0 then
		table.insert(var_53_0, arg_53_0.teamInfo.mate_1)
	end

	if arg_53_0.teamInfo.mate_2 ~= arg_53_0.selfPlayer.playerID and arg_53_0.teamInfo.mate_2 ~= 0 then
		table.insert(var_53_0, arg_53_0.teamInfo.mate_2)
	end

	for iter_53_0 = 1, #var_53_0 do
		local var_53_1 = {
			player_id = var_53_0[iter_53_0]
		}
		local var_53_2 = {
			message = arg_53_1.text,
			msgType = arg_53_1.msgType,
			selectType = xyd.FriendMsgSelectType.ILLUSION
		}

		var_53_1.msg = json.encode(var_53_2)

		arg_53_0.socialSystem:chatToFriend(var_53_1, function(arg_54_0, arg_54_1)
			if arg_54_0 == xyd.error.OK then
				-- block empty
			end

			if arg_53_2 then
				local var_54_0 = {
					index = iter_53_0
				}

				arg_53_2(arg_54_0, var_54_0)
			end
		end)
	end
end

function var_0_0.getReport(arg_55_0, arg_55_1, arg_55_2)
	local var_55_0 = {
		report_id = arg_55_1
	}

	xyd.Backend.get():request(xyd.mid.ILLUSION_GET_REPORT, var_55_0, function(arg_56_0, arg_56_1)
		if arg_56_0 == xyd.error.OK then
			-- block empty
		end

		if arg_55_2 then
			arg_55_2(arg_56_0, arg_56_1)
		end
	end)
end

function var_0_0.checkHasBet(arg_57_0)
	for iter_57_0, iter_57_1 in pairs(arg_57_0.betInfo) do
		if iter_57_1 > 0 then
			return true
		end
	end

	return false
end

function var_0_0.getBetInfo(arg_58_0, arg_58_1)
	local var_58_0 = {
		activity_id = xyd.Activities.IllusionBet
	}

	arg_58_0.activities:loadSingleActivity(var_58_0, function(arg_59_0, arg_59_1)
		if arg_59_0 == xyd.error.OK then
			arg_58_0.betInfo = arg_59_1.details.manas
			arg_58_0.isBetOpen = not (arg_59_1.details.paradise_info.count < 1)
			arg_58_0.betPreSetInfo = clone(arg_58_0.betInfo)

			if arg_58_0:checkHasBet() then
				arg_58_0.hasBet = true
			end
		end

		if arg_58_1 then
			arg_58_1(arg_59_0, arg_59_1)
		end
	end)
end

function var_0_0.setIllusionBet(arg_60_0, arg_60_1)
	local var_60_0 = {
		manas = {}
	}

	for iter_60_0, iter_60_1 in pairs(arg_60_0.betInfo) do
		table.insert(var_60_0.manas, arg_60_0.betPreSetInfo[iter_60_0] - arg_60_0.betInfo[iter_60_0])
	end

	xyd.Backend.get():request(xyd.mid.SET_ILLUSION_BET, var_60_0, function(arg_61_0, arg_61_1)
		if arg_61_0 == xyd.error.OK then
			arg_60_0.betInfo = arg_61_1.manas
			arg_60_0.betPreSetInfo = clone(arg_60_0.betInfo)

			if arg_60_0:checkHasBet() then
				arg_60_0.hasBet = true
			end
		end

		if arg_60_1 then
			arg_60_1(arg_61_0, arg_61_1)
		end
	end)
end

return var_0_0
