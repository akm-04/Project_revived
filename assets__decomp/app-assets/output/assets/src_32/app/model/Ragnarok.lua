local var_0_0 = class("Ragnarok", import(".BaseModel"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = import("framework.scheduler")
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.misc
local var_0_6 = xyd.tables.hero
local var_0_7 = 3
local var_0_8 = 120
local var_0_9 = var_0_5:getValue("activity_ragnarok_boss_time_limit")
local var_0_10 = var_0_5:getValue("activity_ragnarok_boss_ticket")
local var_0_11 = var_0_5:getValue("activity_ragnarok_boss_energy_cost")
local var_0_12 = {
	var_0_5:getValue("activity_ragnarok_boss_debuff1"),
	var_0_5:getValue("activity_ragnarok_boss_debuff2")
}
local var_0_13 = var_0_5:getValue("activity_ragnarok_function_unlock")

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.addEnergyModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ADD_ENERGY)
	arg_1_0.is_pass = 0
	arg_1_0.is_finish = 0
	arg_1_0.chat_red_point = false
	arg_1_0.heros = {}
	arg_1_0.pets = {}
	arg_1_0.teams = {}
	arg_1_0.chatData = {}
	arg_1_0.msgItems = {}
	arg_1_0.monster_status = {}
	arg_1_0.hero_status = {}
	arg_1_0.pos_infos = {}
	arg_1_0.win_params = {}
	arg_1_0.everRoomIDs = {}
	arg_1_0.deadActionIsRun = {
		false,
		false,
		false
	}
	arg_1_0.is_fighting = {
		0,
		0,
		0
	}
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadInfo(arg_3_0, arg_3_1)
	xyd.Backend.get():request(xyd.mid.RAGNAROK_BOSS_INFO, nil, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK and arg_3_1 then
			arg_3_1(arg_4_1)
		end
	end)
end

function var_0_0.clear(arg_5_0)
	arg_5_0.room_info = {}
	arg_5_0.invitedList = {}
	arg_5_0.heros = {}
	arg_5_0.pets = {}
	arg_5_0.teams = {}
	arg_5_0.monster_status = {}
	arg_5_0.hero_status = {}
	arg_5_0.pos_infos = {}
	arg_5_0.win_params = {}
	arg_5_0.deadActionIsRun = {
		false,
		false,
		false
	}
	arg_5_0.is_fighting = {
		0,
		0,
		0
	}
	arg_5_0.pos = 0
	arg_5_0.start_time = 0
	arg_5_0.is_pass = 0
	arg_5_0.is_finish = 0
	arg_5_0.type_ = nil
	arg_5_0.chat_red_point = false
	arg_5_0.finsh_team_fight = nil

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.msgItems) do
		iter_5_1:removeAllChildren(true)
		iter_5_1:release()
	end

	arg_5_0.chatData = {}
	arg_5_0.msgItems = {}

	if arg_5_0.chatHandle then
		xyd.EventDispatcher.get():removeEventListener(arg_5_0.chatHandle)

		arg_5_0.chatHandle = nil
	end

	if arg_5_0.timerHandle then
		var_0_3.unscheduleGlobal(arg_5_0.timerHandle)

		arg_5_0.timerHandle = nil
	end
end

function var_0_0.notice(arg_6_0, arg_6_1)
	if arg_6_1.function_type == xyd.RagnarokFunctionType.ROOM_CHANGE then
		if arg_6_1.room_info then
			arg_6_0:updateRoomInfo(arg_6_1.room_info)
		else
			arg_6_0:updateRoomInfo(arg_6_1)
		end

		if arg_6_1.self_info.room_id == 0 then
			arg_6_0.is_finish = 1

			local var_6_0 = xyd.WindowManager.get():getWindow("ragnarok_prepare")

			if var_6_0 and not tolua.isnull(var_6_0) then
				arg_6_0.co = coroutine.create(function()
					if not xyd.WindowManager.get():getWindow("ragnarok_prepare").hasLoadRes then
						coroutine.yield()
					end

					xyd.WindowManager.get():closeWindow("ragnarok_prepare")
				end)

				coroutine.resume(arg_6_0.co)

				local var_6_1 = var_0_4:translation("ILLUSION_TEAM_TIPS_18")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_6_1
				})
			end

			local var_6_2 = xyd.WindowManager.get():getWindow("ragnarok_battle")

			if var_6_2 and not tolua.isnull(var_6_2) then
				xyd.WindowManager.get():closeWindow(xyd.WindowName.SelectTeamWnd)
				xyd.WindowManager.get():closeWindow("ragnarok_battle_detail")
				xyd.WindowManager.get():closeWindow("ragnarok_battle")
				xyd.WindowManager.get():closeWindow("new_text_rule")

				if not arg_6_0.finsh_team_fight then
					local var_6_3 = var_0_4:translation("RAGNAROK_BOSS_TEAM_29")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_6_3
					})
				end

				arg_6_0:clear()
			end
		else
			local var_6_4 = xyd.WindowManager.get():getWindow("ragnarok_prepare")

			if var_6_4 and not tolua.isnull(var_6_4) then
				var_6_4:updateList()
			end

			local var_6_5 = xyd.WindowManager.get():getWindow("ragnarok_battle")

			if var_6_5 and not tolua.isnull(var_6_5) then
				var_6_5:updatePlayerInfo()
				var_6_5:updatePlayerBattleStatus()
				var_6_5:updateFightStatus()
			end
		end
	elseif arg_6_1.function_type == xyd.RagnarokFunctionType.ENTER_TEAM_FIGHT then
		arg_6_0.type_ = xyd.RagnarokType.TEAM
		arg_6_0.monster_status = arg_6_1.monster_infos
		arg_6_0.hero_status = arg_6_1.hero_infos
		arg_6_0.pos_infos = arg_6_1.pos_infos

		for iter_6_0, iter_6_1 in ipairs(arg_6_1.pos_infos) do
			if arg_6_0.selfPlayer.playerID == iter_6_1 then
				arg_6_0.pos = iter_6_0

				break
			end
		end

		arg_6_0.start_time = arg_6_1.room_info.start_time
		arg_6_0.chatHandle = xyd.EventDispatcher.get():addEventListener(xyd.event.FRIEND_CHAT_MESSAGE, handler(arg_6_0, arg_6_0.onFriendChatMessage))

		arg_6_0:initBattle()
		arg_6_0:updateRoomInfo(arg_6_1.room_info)
		arg_6_0:startTimer()

		arg_6_0.co = coroutine.create(function()
			if not xyd.WindowManager.get():getWindow("ragnarok_prepare").hasLoadRes then
				coroutine.yield()
			end

			xyd.WindowManager.get():closeWindow("ragnarok_prepare")
		end)

		coroutine.resume(arg_6_0.co)

		local var_6_6 = xyd.WindowManager.get():getWindow("ragnarok_invite")

		if var_6_6 and not tolua.isnull(var_6_6) then
			xyd.WindowManager.get():closeWindow("ragnarok_invite")
		end

		local var_6_7 = xyd.WindowManager.get():getWindow("common_alert")

		if var_6_7 and not tolua.isnull(var_6_7) then
			xyd.WindowManager.get():closeWindow("common_alert")
		end

		if not arg_6_0:checkIsMaster(arg_6_0.selfPlayer.playerID) then
			arg_6_0.selfPlayer.energy = arg_6_0.selfPlayer.energy - var_0_11

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.ECONOMY_AFTER,
				params = {
					energy = arg_6_0.selfPlayer:getEnergy()
				}
			})
		end

		xyd.WindowManager.get():openWindow("ragnarok_battle")
	elseif arg_6_1.function_type == xyd.RagnarokFunctionType.START_TEAM_FIGHT then
		arg_6_0.is_fighting[arg_6_1.pos] = arg_6_1.is_fighting

		local var_6_8 = xyd.WindowManager.get():getWindow("ragnarok_battle")

		if var_6_8 and not tolua.isnull(var_6_8) then
			var_6_8:updateFightStatus()
		end
	elseif arg_6_1.function_type == xyd.RagnarokFunctionType.TEAM_FIGHT_RESULT then
		arg_6_0.hero_status = arg_6_1.hero_infos
		arg_6_0.is_fighting[arg_6_1.pos] = arg_6_1.is_fighting
		arg_6_0.is_finish = arg_6_1.is_finish
		arg_6_0.is_pass = arg_6_1.is_pass
		arg_6_0.monster_status = arg_6_1.monster_infos

		local var_6_9 = xyd.WindowManager.get():getWindow("ragnarok_battle")

		if var_6_9 and not tolua.isnull(var_6_9) then
			var_6_9:updatePlayerInfo()
			var_6_9:updateFightStatus()
			var_6_9:updateMonsterStatus()
		end
	elseif arg_6_1.function_type == xyd.RagnarokFunctionType.FINISH_TEAM_FIGHT then
		local var_6_10 = tostring(arg_6_0.selfPlayer.playerID)

		arg_6_0.finsh_team_fight = true
		arg_6_0.is_finish = arg_6_1.is_finish
		arg_6_0.is_pass = arg_6_1.is_pass
		arg_6_0.win_params = arg_6_1[var_6_10]

		local var_6_11 = xyd.WindowManager.get():getWindow("ragnarok_battle")

		if var_6_11 and not tolua.isnull(var_6_11) then
			if arg_6_0.is_pass == 1 then
				xyd.WindowManager.get():openWindow("ragnarok_battle_win", arg_6_0.win_params)

				if arg_6_0.win_params.awards and next(arg_6_0.win_params.awards) then
					arg_6_0.selfPlayer:handleRewards(arg_6_0.win_params.awards)
				end

				local var_6_12 = xyd.WindowManager.get():getWindow("ragnarok_main")
				local var_6_13 = {
					itemNum = 1,
					itemID = var_0_10
				}

				arg_6_0.selfPlayer:getBackpack():removeItem(var_6_13)

				if var_6_12 and not tolua.isnull(var_6_12) then
					var_6_12:updateEco()
				end
			else
				local var_6_14 = var_0_4:translation("RAGNAROK_BOSS_15")
				local var_6_15 = var_0_4:translation("RAGNAROK_BOSS_16")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_6_15, nil, {
					title = var_6_14
				}, nil, xyd.ColorMode.PURPLE)
			end
		end
	end
end

function var_0_0.checkTicket(arg_9_0)
	if arg_9_0.selfPlayer:getBackpack():getItemNumByID(var_0_10) >= 1 then
		return true
	end

	return false
end

function var_0_0.isHasTiLiItem(arg_10_0)
	local var_10_0 = arg_10_0.selfPlayer:getBackpack():getItems()

	for iter_10_0, iter_10_1 in pairs(var_10_0) do
		if xyd.tables.item:subType(iter_10_1.itemID) == xyd.ConsumeItemType.ENERGY_ITEM then
			return true
		end
	end

	return false
end

function var_0_0.checkEnergy(arg_11_0)
	if arg_11_0.selfPlayer:getEnergy() >= var_0_11 then
		return true
	end

	arg_11_0.buyEnergyTimes = arg_11_0.selfPlayer.buyEnergyTimes
	arg_11_0.buyEnergyCost = xyd.tables.refreshCost:buyEnergyCost(arg_11_0.buyEnergyTimes + 1)
	arg_11_0.maxBuyTimes = xyd.tables.vip:numEnergy(arg_11_0.selfPlayer.vip)

	if arg_11_0.selfPlayer.privilegeLeftCardDay > 0 then
		local var_11_0 = xyd.tables.monthlyPrivilege:numEnergy(1)

		arg_11_0.maxBuyTimes = arg_11_0.maxBuyTimes + var_11_0
	end

	local var_11_1 = xyd.tables.misc.energyMaxLimit

	str = string.format(var_0_4:translation("ADD_ENERGY"), arg_11_0.buyEnergyCost, var_0_8, arg_11_0.buyEnergyTimes)

	if arg_11_0:isHasTiLiItem() then
		local var_11_2 = {
			text = str,
			callback = function()
				if arg_11_0.buyEnergyTimes >= arg_11_0.maxBuyTimes then
					str = string.format(var_0_4:translation("CAN_NOT_ADDENERGY"), arg_11_0.buyEnergyTimes)

					local var_12_0 = xyd.luaStringSplit(str, "\n")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_12_0, function()
						local var_13_0 = {}

						var_13_0.windowState = false

						xyd.WindowManager.get():openWindow("vip_recharge", var_13_0)
						xyd.WindowManager.get():closeWindow("add_energy")
					end, nil, nil, xyd.ColorMode.PURPLE)
				elseif arg_11_0.selfPlayer.energy >= var_11_1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_4:translation("TILI_LIMIT_INFO")
					})
					xyd.WindowManager.get():closeWindow("buy_tili")
				elseif arg_11_0.buyEnergyCost > arg_11_0.selfPlayer.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_4:translation("ZUANSHI_ABSENCE"), function()
						local var_14_0 = {}

						var_14_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_14_0)
					end, nil, nil, xyd.ColorMode.PURPLE)
				else
					arg_11_0.addEnergyModel:addEnergy(function(arg_15_0)
						if arg_15_0 == xyd.error.OK then
							return true
						end
					end)
					xyd.WindowManager.get():closeWindow("buy_tili")
				end
			end
		}

		xyd.WindowManager.get():openWindow("buy_tili", var_11_2)
	else
		local var_11_3 = xyd.luaStringSplit(str, "\n")

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_11_3, function()
			if arg_11_0.buyEnergyTimes >= arg_11_0.maxBuyTimes then
				str = string.format(var_0_4:translation("CAN_NOT_ADDENERGY"), arg_11_0.buyEnergyTimes)

				local var_16_0 = xyd.luaStringSplit(str, "\n")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_16_0, function()
					local var_17_0 = {}

					var_17_0.windowState = false

					xyd.WindowManager.get():openWindow("vip_recharge", var_17_0)
					xyd.WindowManager.get():closeWindow("add_energy")
				end, nil, nil, xyd.ColorMode.PURPLE)
			elseif arg_11_0.buyEnergyCost > arg_11_0.selfPlayer.crystal then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_4:translation("ZUANSHI_ABSENCE"), function()
					local var_18_0 = {}

					var_18_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_18_0)
				end, nil, nil, xyd.ColorMode.PURPLE)
			else
				arg_11_0.addEnergyModel:addEnergy(function(arg_19_0)
					if arg_19_0 == xyd.error.OK then
						return true
					end
				end)
				xyd.WindowManager.get():closeWindow("alert")
			end
		end, nil, 0, xyd.ColorMode.PURPLE)
	end

	return false
end

function var_0_0.createHouse(arg_20_0, arg_20_1, arg_20_2)
	arg_20_0:clear()

	local var_20_0 = arg_20_1 or {}

	xyd.Backend.get():request(xyd.mid.RAGNAROK_CREATE_ROOM, var_20_0, function(arg_21_0, arg_21_1)
		if arg_21_0 == xyd.error.OK then
			arg_20_0:updateRoomInfo(arg_21_1.room_info)
		end

		if arg_20_2 then
			arg_20_2(arg_21_0, arg_21_1)
		end
	end)
end

function var_0_0.checkCanJoinRoom(arg_22_0, arg_22_1)
	local var_22_0 = tonumber(arg_22_1)

	if not arg_22_0.everRoomIDs then
		arg_22_0.everRoomIDs = {}
	end

	local var_22_1 = xyd.ServerTime.get():getServerTime()

	if not arg_22_0.everRoomIDs[var_22_0] then
		arg_22_0.everRoomIDs[var_22_0] = var_22_1

		return true
	elseif arg_22_0.everRoomIDs[var_22_0] > 0 then
		if var_22_1 - arg_22_0.everRoomIDs[var_22_0] > 30 then
			arg_22_0.everRoomIDs[var_22_0] = var_22_1

			return true
		else
			return false
		end
	end

	return true
end

function var_0_0.getRoomList(arg_23_0, arg_23_1)
	xyd.Backend.get():request(xyd.mid.RAGNAROK_GET_ROOM_LIST, {}, function(arg_24_0, arg_24_1)
		if arg_23_1 then
			arg_23_1(arg_24_0, arg_24_1)
		end
	end)
end

function var_0_0.setRoomType(arg_25_0, arg_25_1, arg_25_2)
	xyd.Backend.get():request(xyd.mid.RAGNAROK_SET_ROOM_PUBLIC, {
		public = arg_25_1
	}, function(arg_26_0, arg_26_1)
		if arg_26_0 == xyd.error.OK then
			arg_25_0.room_info.is_public = arg_26_1.is_public
		end

		if arg_25_2 then
			arg_25_2(arg_26_0, arg_26_1)
		end
	end)
end

function var_0_0.enterRoom(arg_27_0, arg_27_1, arg_27_2, arg_27_3)
	if arg_27_0.isFuncOpen == nil then
		arg_27_0:getInfo()
	end

	if not arg_27_0.isFuncOpen then
		local var_27_0 = var_0_4:translation("RAGNAROK_BOSS_TEAM_35")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_27_0
		})

		return
	end

	arg_27_0:clear()

	local var_27_1 = {
		room_id = tonumber(arg_27_1),
		is_public = arg_27_2
	}

	xyd.Backend.get():request(xyd.mid.RAGNAROK_JOIN_ROOM, var_27_1, function(arg_28_0, arg_28_1)
		if arg_28_0 == xyd.error.OK then
			arg_27_0:updateRoomInfo(arg_28_1.room_info)
		else
			arg_27_0.everRoomIDs[arg_27_1] = nil
		end

		if arg_27_3 then
			arg_27_3(arg_28_0, arg_28_1)
		end
	end)
end

function var_0_0.quicklyEnterRoom(arg_29_0, arg_29_1)
	arg_29_0:clear()
	xyd.Backend.get():request(xyd.mid.RAGNAROK_QUICK_JOIN_ROOM, {}, function(arg_30_0, arg_30_1)
		if arg_30_0 == xyd.error.OK then
			arg_29_0:updateRoomInfo(arg_30_1.room_info)
		else
			arg_29_0.everRoomIDs[roomID] = nil
		end

		if arg_29_1 then
			arg_29_1(arg_30_0, arg_30_1)
		end
	end)
end

function var_0_0.prepareRoom(arg_31_0, arg_31_1)
	xyd.Backend.get():request(xyd.mid.RAGNAROK_PREPARE_ROOM, {}, function(arg_32_0, arg_32_1)
		if arg_32_0 == xyd.error.OK then
			-- block empty
		end

		if arg_31_1 then
			arg_31_1(arg_32_0, arg_32_1)
		end
	end)
end

function var_0_0.exitRoom(arg_33_0, arg_33_1)
	xyd.Backend.get():request(xyd.mid.RAGNAROK_EXIT_ROOM, {}, function(arg_34_0, arg_34_1)
		if arg_34_0 == xyd.error.OK then
			arg_33_0:clear()
		end

		if arg_33_1 then
			arg_33_1(arg_34_0, arg_34_1)
		end
	end)
end

function var_0_0.removePlayer(arg_35_0, arg_35_1, arg_35_2)
	local var_35_0 = {
		player_id = arg_35_1
	}

	xyd.Backend.get():request(xyd.mid.RAGNAROK_KICK_MEMBER, var_35_0, function(arg_36_0, arg_36_1)
		if arg_36_0 == xyd.error.OK and arg_36_1 and next(arg_36_1) then
			-- block empty
		end

		if arg_35_2 then
			arg_35_2(arg_36_0, arg_36_1)
		end
	end)
end

function var_0_0.inviteFriend(arg_37_0, arg_37_1, arg_37_2)
	local var_37_0 = {
		player_id = arg_37_1
	}

	xyd.Backend.get():request(xyd.mid.RAGNAROK_INVITE_FRIEND, var_37_0, function(arg_38_0, arg_38_1)
		if arg_37_2 then
			arg_37_2(arg_38_0, arg_38_1)
		end
	end)
end

function var_0_0.addInvitedList(arg_39_0, arg_39_1)
	table.insert(arg_39_0.invitedList, arg_39_1)
end

function var_0_0.checkIsInvited(arg_40_0, arg_40_1)
	for iter_40_0 = 1, #arg_40_0.invitedList do
		if arg_40_0.invitedList[iter_40_0] == arg_40_1 then
			return true
		end
	end

	return false
end

function var_0_0.getRoomID(arg_41_0)
	return arg_41_0.room_info.room_id or 0
end

function var_0_0.updateRoomInfo(arg_42_0, arg_42_1)
	arg_42_0.room_info = arg_42_1
end

function var_0_0.getRoomInfo(arg_43_0)
	return arg_43_0.room_info
end

function var_0_0.roomIsPublic(arg_44_0)
	return arg_44_0.room_info.is_public or 1
end

function var_0_0.getMasterID(arg_45_0)
	return arg_45_0.room_info.owner
end

function var_0_0.checkIsMaster(arg_46_0, arg_46_1)
	if arg_46_0:getMasterID() == arg_46_1 then
		return true
	end

	return false
end

function var_0_0.getPlayerInfo(arg_47_0, arg_47_1)
	return arg_47_0.room_info.member_infos[arg_47_1]
end

function var_0_0.getPlayerInfoByPos(arg_48_0, arg_48_1)
	for iter_48_0, iter_48_1 in ipairs(arg_48_0.room_info.member_infos) do
		if iter_48_1.player_id == arg_48_0.pos_infos[arg_48_1] then
			return iter_48_1
		end
	end

	return {}
end

function var_0_0.getPlayerInfoByID(arg_49_0, arg_49_1)
	for iter_49_0, iter_49_1 in ipairs(arg_49_0.room_info.member_infos) do
		if iter_49_1.player_id == arg_49_1 then
			return iter_49_1
		end
	end

	return {}
end

function var_0_0.getHeros(arg_50_0)
	if next(arg_50_0.heros) then
		return arg_50_0.heros
	else
		local var_50_0 = arg_50_0.selfPlayer:getHeros()

		for iter_50_0, iter_50_1 in ipairs(var_50_0) do
			local var_50_1 = iter_50_1:toParams()
			local var_50_2 = var_0_1.new()

			var_50_2:populate(var_50_1)

			if var_50_2:isSuper() then
				arg_50_0:renewSuperHeroInfo(var_50_2)
			else
				arg_50_0:renewHeroInfo(var_50_2)
			end

			table.insert(arg_50_0.heros, var_50_2)
		end

		return arg_50_0.heros
	end
end

function var_0_0.renewHeroInfo(arg_51_0, arg_51_1)
	arg_51_1.color_ = 16
	arg_51_1.level_ = 100

	local var_51_0
	local var_51_1
	local var_51_2

	if arg_51_1:isCanAwaken() then
		if not arg_51_1:isAwaken() then
			arg_51_1:setTableID(arg_51_1:afterAwakenID())
		end

		var_51_1 = {
			1,
			1,
			1,
			1,
			1,
			1
		}
		var_51_2 = {
			1,
			1,
			1,
			1,
			1,
			1
		}

		if arg_51_1:isCanAwakeTwice() then
			arg_51_1.awakeTwiceStage_ = xyd.AwakeTwiceStage.COMPLETE
			var_51_0 = {
				100,
				100,
				80,
				60,
				40,
				40
			}
		else
			var_51_0 = {
				100,
				100,
				80,
				60,
				40,
				0
			}
		end
	else
		var_51_0 = {
			100,
			100,
			80,
			60,
			0,
			0
		}
		var_51_1 = {
			0,
			1,
			1,
			1,
			1,
			1
		}
		var_51_2 = {
			0,
			1,
			1,
			1,
			1,
			1
		}
	end

	for iter_51_0 = 1, 6 do
		if not arg_51_1:getSkillLevel(iter_51_0) or arg_51_1:getSkillLevel(iter_51_0) < var_51_0[iter_51_0] then
			arg_51_1.skillLev_[iter_51_0] = var_51_0[iter_51_0]
		end
	end

	arg_51_1.equips_ = var_51_2
	arg_51_1.fumo_ = var_51_1
	arg_51_1.fumoLev_ = {}

	for iter_51_1 = 1, 6 do
		local var_51_3 = arg_51_1:getEquipByIndex(iter_51_1)

		table.insert(arg_51_1.fumoLev_, tonumber(var_51_3:getMaxFumoStar()))
	end
end

function var_0_0.renewSuperHeroInfo(arg_52_0, arg_52_1)
	local var_52_0 = {
		100,
		100,
		80,
		60,
		0,
		0
	}

	arg_52_1.level_ = 100

	for iter_52_0 = 1, 6 do
		if not arg_52_1:getSkillLevel(iter_52_0) or arg_52_1:getSkillLevel(iter_52_0) < var_52_0[iter_52_0] then
			arg_52_1.skillLev_[iter_52_0] = var_52_0[iter_52_0]
		end
	end

	for iter_52_1 = 1, 6 do
		if arg_52_1.equips_[iter_52_1] < 31 then
			arg_52_1.equips_[iter_52_1] = 31
		end
	end
end

function var_0_0.getPresetTeams(arg_53_0)
	if next(arg_53_0.teams) then
		return arg_53_0.teams
	else
		arg_53_0.teams = arg_53_0.selfPlayer:getSaveTeams()

		for iter_53_0 = 1, #arg_53_0.teams do
			local var_53_0 = arg_53_0.teams[iter_53_0].team

			for iter_53_1, iter_53_2 in ipairs(var_53_0) do
				if iter_53_2:isSuper() then
					arg_53_0:renewSuperHeroInfo(iter_53_2)
				else
					arg_53_0:renewHeroInfo(iter_53_2)
				end
			end
		end

		return arg_53_0.teams
	end
end

function var_0_0.getPets(arg_54_0)
	if next(arg_54_0.pets) then
		return arg_54_0.pets
	else
		local var_54_0 = arg_54_0.selfPlayer.collectedPets

		if not var_54_0 then
			return
		end

		for iter_54_0, iter_54_1 in ipairs(var_54_0) do
			local var_54_1 = iter_54_1:toParams()
			local var_54_2 = var_0_2.new()

			var_54_2:populate(var_54_1)
			arg_54_0:renewPetInfo(var_54_2)
			table.insert(arg_54_0.pets, var_54_2)
		end

		return arg_54_0.pets
	end
end

function var_0_0.renewPetInfo(arg_55_0, arg_55_1)
	arg_55_1.color_ = 16
	arg_55_1.level_ = 100

	local var_55_0
	local var_55_1

	if arg_55_1:isCanAwaken() then
		if not arg_55_1:isAwaken() then
			arg_55_1:setTableID(arg_55_1:afterAwakenID())
		end

		var_55_1 = {
			1,
			1,
			1
		}
		var_55_0 = {
			90,
			90,
			70,
			50,
			30
		}
	else
		var_55_0 = {
			90,
			90,
			70,
			50,
			0
		}
		var_55_1 = {
			0,
			1,
			1
		}
	end

	for iter_55_0 = 1, 5 do
		if not arg_55_1:getSkillLevel(iter_55_0) or arg_55_1:getSkillLevel(iter_55_0) < var_55_0[iter_55_0] then
			arg_55_1.skillLev_[iter_55_0] = var_55_0[iter_55_0]
		end
	end

	arg_55_1.equips_ = var_55_1
end

function var_0_0.singleEnter(arg_56_0)
	arg_56_0:clear()
	xyd.Backend.get():request(xyd.mid.RAGNAROK_ENTER_SINGLE_FIGHT, nil, function(arg_57_0, arg_57_1)
		if arg_57_0 == xyd.error.OK then
			arg_56_0.type_ = xyd.RagnarokType.SINGLE
			arg_56_0.start_time = arg_57_1.single_start_time
			arg_56_0.monster_status = arg_57_1.moster_status
			arg_56_0.hero_status = arg_57_1.hero_status

			arg_56_0:startTimer()
			arg_56_0:initBattle()
			xyd.WindowManager.get():openWindow("ragnarok_battle")
		end
	end)
end

function var_0_0.singleEnd(arg_58_0)
	xyd.Backend.get():request(xyd.mid.RAGNAROK_END_SINGLE_FIGHT, nil, function(arg_59_0, arg_59_1)
		if arg_59_0 == xyd.error.OK then
			arg_58_0.is_finish = arg_59_1.is_finish
			arg_58_0.is_pass = arg_59_1.is_pass
			arg_58_0.finsh_team_fight = true

			local var_59_0 = xyd.WindowManager.get():getWindow("ragnarok_battle")

			if var_59_0 and not tolua.isnull(var_59_0) then
				local var_59_1 = var_0_4:translation("RAGNAROK_BOSS_15")
				local var_59_2 = var_0_4:translation("RAGNAROK_BOSS_16")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_59_2, function()
					xyd.WindowManager.get():closeWindow(xyd.WindowName.SelectTeamWnd)
					xyd.WindowManager.get():closeWindow("ragnarok_battle_detail")
					xyd.WindowManager.get():closeWindow("ragnarok_battle")
					xyd.WindowManager.get():closeWindow("new_text_rule")
				end, {
					title = var_59_1
				}, nil, xyd.ColorMode.PURPLE)
				arg_58_0:clear()
			end
		end
	end, nil, nil, xyd.ColorMode.PURPLE)
end

function var_0_0.teamEnter(arg_61_0)
	xyd.Backend.get():request(xyd.mid.RAGNAROK_ENTER_TEAM_FIGHT, nil, function(arg_62_0, arg_62_1)
		if arg_62_0 == xyd.error.OK then
			-- block empty
		end
	end)
end

function var_0_0.teamEnd(arg_63_0)
	xyd.Backend.get():request(xyd.mid.RAGNAROK_FINISH_TEAM_FIGHT, nil, function(arg_64_0, arg_64_1)
		if arg_64_0 == xyd.error.OK then
			-- block empty
		end
	end)
end

function var_0_0.initBattle(arg_65_0)
	arg_65_0.monster_total_hp = {}

	for iter_65_0 = 1, var_0_7 do
		local var_65_0 = arg_65_0.monster_status[iter_65_0].monster_id
		local var_65_1 = var_0_6:getInitialAttr(var_65_0, xyd.AttributeType.HP)

		arg_65_0.monster_total_hp[iter_65_0] = var_65_1
	end
end

function var_0_0.setPos(arg_66_0, arg_66_1)
	arg_66_0.pos = arg_66_1
end

function var_0_0.getPos(arg_67_0)
	return arg_67_0.pos
end

function var_0_0.getMonsterStatus(arg_68_0)
	return arg_68_0.monster_status
end

function var_0_0.getEnemyHp(arg_69_0)
	return arg_69_0.monster_total_hp[arg_69_0.pos] - arg_69_0.monster_status[arg_69_0.pos].damage
end

function var_0_0.getType(arg_70_0)
	return arg_70_0.type_
end

function var_0_0.getHeroDeadNum(arg_71_0, arg_71_1)
	if arg_71_0.type_ == xyd.RagnarokType.SINGLE then
		local var_71_0 = 0

		for iter_71_0, iter_71_1 in pairs(arg_71_0.hero_status) do
			var_71_0 = var_71_0 + 1
		end

		return var_71_0
	elseif arg_71_0.type_ == xyd.RagnarokType.TEAM then
		local var_71_1 = arg_71_0.pos_infos[arg_71_1]
		local var_71_2 = arg_71_0.hero_status[tostring(var_71_1)]
		local var_71_3 = 0

		if not var_71_2 then
			return var_71_3
		end

		for iter_71_2, iter_71_3 in pairs(var_71_2) do
			var_71_3 = var_71_3 + 1
		end

		return var_71_3
	end
end

function var_0_0.getBuffs(arg_72_0)
	local var_72_0 = {}

	for iter_72_0 = 1, 2 do
		if arg_72_0.monster_status[iter_72_0 + 1].is_dead == 1 then
			for iter_72_1, iter_72_2 in ipairs(var_0_12[iter_72_0]) do
				table.insert(var_72_0, iter_72_2)
			end
		end
	end

	return var_72_0
end

function var_0_0.checkHeroIsDead(arg_73_0, arg_73_1)
	local var_73_0 = tostring(arg_73_1)

	if arg_73_0.type_ == xyd.RagnarokType.SINGLE then
		if arg_73_0.hero_status[var_73_0] then
			return true
		end

		return false
	elseif arg_73_0.type_ == xyd.RagnarokType.TEAM then
		local var_73_1 = arg_73_0.hero_status[tostring(arg_73_0.selfPlayer.playerID)]

		if not var_73_1 then
			return false
		end

		if var_73_1[var_73_0] then
			return true
		end

		return false
	end
end

function var_0_0.checkIsEnd(arg_74_0, arg_74_1)
	if arg_74_0.is_finish == 1 then
		if arg_74_0.is_pass == 1 then
			xyd.WindowManager.get():openWindow("ragnarok_battle_win", arg_74_0.win_params)

			if arg_74_0.win_params.awards and next(arg_74_0.win_params.awards) then
				arg_74_0.selfPlayer:handleRewards(arg_74_0.win_params.awards)
			end

			local var_74_0 = xyd.WindowManager.get():getWindow("ragnarok_main")
			local var_74_1 = {
				itemNum = 1,
				itemID = var_0_10
			}

			arg_74_0.selfPlayer:getBackpack():removeItem(var_74_1)

			if var_74_0 and not tolua.isnull(var_74_0) then
				var_74_0:updateEco()
			end
		elseif arg_74_0.finsh_team_fight then
			local var_74_2 = var_0_4:translation("RAGNAROK_BOSS_15")
			local var_74_3 = var_0_4:translation("RAGNAROK_BOSS_16")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_74_3, nil, {
				title = var_74_2
			}, nil, xyd.ColorMode.PURPLE)
		else
			local var_74_4 = var_0_4:translation("RAGNAROK_BOSS_TEAM_29")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_74_4
			})
		end

		arg_74_0:clear()
	else
		arg_74_1()
	end
end

function var_0_0.startTimer(arg_75_0)
	if arg_75_0.timerHandle then
		var_0_3.unscheduleGlobal(arg_75_0.timerHandle)

		arg_75_0.timerHandle = nil
	end

	arg_75_0.timerHandle = var_0_3.scheduleUpdateGlobal(function()
		local var_76_0 = xyd.ServerTime.get():getServerTime()
		local var_76_1 = var_0_9 - (var_76_0 - arg_75_0.start_time)

		if var_76_1 >= 0 then
			local var_76_2 = xyd.WindowManager.get():getWindow("ragnarok_battle")

			if var_76_2 and not tolua.isnull(var_76_2) then
				var_76_2:updateTimer(arg_75_0:createTimeStr(var_76_1))
			end
		else
			if arg_75_0.timerHandle then
				var_0_3.unscheduleGlobal(arg_75_0.timerHandle)

				arg_75_0.timerHandle = nil
			end

			if arg_75_0:getType() == xyd.RagnarokType.SINGLE then
				arg_75_0:singleEnd()
			elseif arg_75_0:getType() == xyd.RagnarokType.TEAM then
				arg_75_0:teamEnd()
			end
		end
	end)
end

function var_0_0.createTimeStr(arg_77_0, arg_77_1)
	local var_77_0 = math.floor(arg_77_1 / 60)
	local var_77_1 = arg_77_1 % 60

	if var_77_0 > 0 then
		return string.format("%d:%02d", var_77_0, var_77_1)
	else
		return tostring(var_77_1)
	end
end

function var_0_0.enterShop(arg_78_0)
	arg_78_0:loadInfo(function(arg_79_0)
		xyd.WindowManager.get():openWindow("ragnarok_shop", arg_79_0)
	end)
end

function var_0_0.getReward(arg_80_0, arg_80_1, arg_80_2)
	xyd.Backend.get():request(xyd.mid.RAGNAROK_GET_AWARD, arg_80_1, function(arg_81_0, arg_81_1)
		if arg_80_2 then
			arg_80_2(arg_81_0, arg_81_1)
		end
	end)
end

function var_0_0.enterRank(arg_82_0)
	xyd.Backend.get():request(xyd.mid.RAGNAROK_RANK_LIST, params, function(arg_83_0, arg_83_1)
		if arg_83_0 == xyd.error.OK then
			xyd.WindowManager.get():openWindow("ragnarok_rank", arg_83_1)
		end
	end)
end

function var_0_0.chatToFriend(arg_84_0, arg_84_1, arg_84_2)
	local var_84_0 = arg_84_0.room_info.members

	for iter_84_0 = 1, #var_84_0 do
		local var_84_1 = {
			player_id = var_84_0[iter_84_0]
		}
		local var_84_2 = {
			message = arg_84_1.text,
			msgType = arg_84_1.msgType,
			selectType = xyd.FriendMsgSelectType.RAGNAROK
		}

		var_84_1.msg = json.encode(var_84_2)

		arg_84_0.socialSystem:chatToFriend(var_84_1, function(arg_85_0, arg_85_1)
			if arg_85_0 == xyd.error.OK then
				-- block empty
			end

			if arg_84_2 then
				local var_85_0 = {
					index = iter_84_0
				}

				arg_84_2(arg_85_0, var_85_0)
			end
		end)
	end
end

function var_0_0.setChatWnd(arg_86_0, arg_86_1)
	arg_86_0.chatWnd = arg_86_1
end

function var_0_0.onFriendChatMessage(arg_87_0, arg_87_1)
	if arg_87_1.params then
		local var_87_0 = {
			id = xyd.generateUUID() or ""
		}
		local var_87_1 = json.decode(arg_87_1.params.message)

		var_87_0.message = var_87_1.message
		var_87_0.msgType = var_87_1.msgType
		var_87_0.selectType = var_87_1.selectType or xyd.FriendMsgSelectType.SOCIAL_SYSTEM

		if var_87_0.selectType ~= xyd.FriendMsgSelectType.RAGNAROK or arg_87_1.params.friend_id == arg_87_0.selfPlayer.playerID then
			return
		end

		var_87_0.time = arg_87_1.params.time
		var_87_0.isOwnSend = 0
		var_87_0.playerInfo = arg_87_0:getPlayerInfoByID(arg_87_1.params.friend_id)

		local var_87_2 = var_87_0

		table.insert(arg_87_0.chatData, var_87_2)
		arg_87_0:addMsgItem(var_87_2)
		arg_87_0:setChatRedPoint(true)

		local var_87_3 = xyd.WindowManager.get():getWindow("ragnarok_battle")

		if var_87_3 and not tolua.isnull(var_87_3) then
			var_87_3:updateRedMark(arg_87_0:getChatRedPoint())
		end
	end
end

function var_0_0.addMsgItem(arg_88_0, arg_88_1)
	local var_88_0 = arg_88_0:createChatMsgContent(arg_88_1)

	var_88_0:retain()
	table.insert(arg_88_0.msgItems, var_88_0)

	if arg_88_0.chatWnd and not tolua.isnull(arg_88_0.chatWnd) then
		arg_88_0.chatWnd.list_:reload()
		arg_88_0.chatWnd:listScrollToEnd()
	end
end

function var_0_0.createChatMsgContent(arg_89_0, arg_89_1)
	local var_89_0 = display.newNode()
	local var_89_1
	local var_89_2

	if arg_89_1.isOwnSend == 0 then
		var_89_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1203/ragnarok/chat_item_left.csb")
		var_89_2 = var_89_1:getChildByName("container")

		local var_89_3 = arg_89_1.playerInfo

		var_89_3.playerInfo = arg_89_1.playerInfo

		xyd.setPlayerAvatar(var_89_2:getChildByName("avtar_container"), var_89_3)
	else
		var_89_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1203/ragnarok/chat_item_right.csb")
		var_89_2 = var_89_1:getChildByName("container")

		local var_89_4 = arg_89_1.playerInfo

		var_89_4.playerInfo = arg_89_1.playerInfo

		xyd.setPlayerAvatar(var_89_2:getChildByName("avtar_container"), var_89_4)
	end

	local var_89_5 = var_89_2:getChildByName("text_name")
	local var_89_6 = var_89_2:getChildByName("text_region")

	var_89_5:setString(arg_89_1.playerInfo.player_name)

	local var_89_7 = var_89_5:getContentSize()
	local var_89_8 = cc.p(var_89_5:getPosition())
	local var_89_9 = xyd.getPlayerRegion(arg_89_1.playerInfo.player_id)

	var_89_6:setString("S" .. var_89_9)

	if arg_89_1.isOwnSend == 0 then
		var_89_6:setPositionX(var_89_7.width + var_89_8.x + 5)
	else
		var_89_6:setPositionX(var_89_8.x - var_89_7.width - 5)
	end

	arg_89_0:addMsgLabel(var_89_2, arg_89_1)
	var_89_1:addTo(var_89_0)
	var_89_1:setAnchorPoint(cc.p(0, 0))

	local var_89_10 = var_89_2:getContentSize().width
	local var_89_11 = var_89_2:getChildByName("duihua_bg"):getContentSize().height + 70

	var_89_0:setContentSize(var_89_10, var_89_11)
	var_89_1:setPositionY(var_89_11 - var_89_2:getContentSize().height)
	var_89_1:setName("source")

	return var_89_0
end

function var_0_0.addMsgLabel(arg_90_0, arg_90_1, arg_90_2)
	local var_90_0 = 1.2
	local var_90_1 = arg_90_2.message
	local var_90_2

	arg_90_1:getChildByName("message_node"):removeAllChildren()

	local var_90_3

	if arg_90_2.msgType ~= xyd.FriendMsgType.EMOTICON then
		local var_90_4 = {
			size = 24,
			color = var_90_2 or cc.c3b(0, 0, 0)
		}

		var_90_3 = xyd.AssetLoader.get():loadLabel(var_90_4)

		var_90_3:setMaxLineWidth(310)
		var_90_3:setLineBreakWithoutSpace(true)
		var_90_3:setString(var_90_1)
	else
		var_90_3 = display.newNode()

		local var_90_5 = xyd.tables.emoticon:isDynamic(tonumber(var_90_1))
		local var_90_6 = xyd.tables.emoticon:image(tonumber(var_90_1))
		local var_90_7 = xyd.tables.emoticon:path(tonumber(var_90_1))

		if var_90_5 == 1 then
			emoticon = xyd.createEffect(var_90_7, 0.7)

			emoticon:play(nil, true, nil, "halloween")

			local var_90_8 = cc.ClippingNode:create()
			local var_90_9 = xyd.AssetLoader:get():loadSprite("windows/chat_window/clip.png")

			var_90_8:setStencil(var_90_9)
			var_90_8:setInverted(true)
			var_90_8:setAlphaThreshold(0)
			var_90_8:setAnchorPoint(0, 1)
			var_90_8:setPosition(73.5, 54)
			var_90_8:addTo(var_90_3)
			emoticon:setPosition(0, -47)
			emoticon:addTo(var_90_8)
			var_90_3:size(146, 104)
		else
			emoticon = xyd.AssetLoader.get():loadSprite(var_90_6)

			emoticon:setAnchorPoint(cc.p(0, 0))
			emoticon:addTo(var_90_3)
			var_90_3:size(emoticon:getWidth(), emoticon:getHeight())
		end

		var_90_3:setScale(var_90_0)
	end

	var_90_3:setAnchorPoint(cc.p(0, 0.5))
	var_90_3:setName("chat_msg")

	local var_90_10 = var_90_3:getContentSize().width
	local var_90_11 = var_90_3:getContentSize().height

	if arg_90_2.msgType == xyd.FriendMsgType.EMOTICON then
		var_90_10 = var_90_10 * var_90_0
		var_90_11 = var_90_11 * var_90_0
	end

	if var_90_11 < arg_90_1:getChildByName("message_node"):getContentSize().height then
		var_90_11 = arg_90_1:getChildByName("message_node"):getContentSize().height
	end

	arg_90_1:getChildByName("duihua_bg"):height(var_90_11 + 16)
	arg_90_1:getChildByName("duihua_bg"):width(var_90_10 + 60)
	arg_90_1:getChildByName("message_node"):height(var_90_11)
	arg_90_1:getChildByName("message_node"):width(var_90_10)
	var_90_3:addTo(arg_90_1:getChildByName("message_node"))
	var_90_3:setPositionY(var_90_11 / 2)
	arg_90_1:getChildByName("message_node"):setPositionY(arg_90_1:getChildByName("duihua_bg"):getPositionY() - 8)
end

function var_0_0.setChatRedPoint(arg_91_0, arg_91_1)
	arg_91_0.chat_red_point = arg_91_1
end

function var_0_0.getChatRedPoint(arg_92_0)
	return arg_92_0.chat_red_point
end

function var_0_0.getInfo(arg_93_0, arg_93_1)
	xyd.Backend.get():request(xyd.mid.RAGNAROK_INFO, nil, function(arg_94_0, arg_94_1)
		if arg_94_0 == xyd.error.OK then
			arg_93_0.mapInfo = arg_94_1.campaign_info

			local var_94_0 = arg_93_0.mapInfo.campaign_list

			if var_94_0[tostring(var_0_13)] and var_94_0[tostring(var_0_13)].star ~= 0 then
				arg_93_0.isFuncOpen = true
			else
				arg_93_0.isFuncOpen = false
			end

			if arg_93_1 then
				arg_93_1()
			end
		end
	end)
end

function var_0_0.firstEnterMap(arg_95_0, arg_95_1)
	xyd.Backend.get():request(xyd.mid.RAGNAROK_FIRST_ENTER, nil, function(arg_96_0, arg_96_1)
		if arg_96_0 == xyd.error.OK then
			arg_95_1()
		end
	end)
end

function var_0_0.enterMap(arg_97_0, arg_97_1)
	xyd.Backend.get():request(xyd.mid.RAGNAROK_CAMP_INFO, nil, function(arg_98_0, arg_98_1)
		if arg_98_0 == xyd.error.OK then
			arg_97_0.mapInfo = arg_98_1

			if arg_97_0.mapInfo.base_info.first_enter == 1 then
				local var_98_0 = 10001

				xyd.WindowManager.get():openWindow("activity_ragnarok_map_story", {
					showBG = true,
					dialogueID = var_98_0,
					callback = function()
						xyd.WindowManager.get():openWindow("activity_ragnarok_map")
					end
				})
			else
				xyd.WindowManager.get():openWindow("activity_ragnarok_map")
			end
		end
	end)
end

function var_0_0.getTaskInfo(arg_100_0, arg_100_1)
	xyd.Backend.get():request(xyd.mid.RAGNAROK_MISSION_INFO, nil, function(arg_101_0, arg_101_1)
		if arg_101_0 == xyd.error.OK then
			arg_100_0.taskInfo = arg_101_1

			if arg_100_1 then
				arg_100_1()
			end
		end
	end)
end

function var_0_0.enterGachaShop(arg_102_0)
	xyd.Backend.get():request(xyd.mid.RAGNAROK_SHOP_INFO, nil, function(arg_103_0, arg_103_1)
		if arg_103_0 == xyd.error.OK then
			xyd.WindowManager.get():openWindow("ragnarok_gacha_shop", arg_103_1)
		end
	end)
end

function var_0_0.getGachaShopReward(arg_104_0, arg_104_1, arg_104_2)
	xyd.Backend.get():request(xyd.mid.RAGNAROK_EXCHANGE, arg_104_1, function(arg_105_0, arg_105_1)
		if arg_104_2 then
			arg_104_2(arg_105_0, arg_105_1)
		end
	end)
end

return var_0_0
