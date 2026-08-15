local var_0_0 = class("BattlePass", import(".BaseModel"))
local var_0_1 = xyd.tables.misc
local var_0_2 = xyd.tables.battlePassMission
local var_0_3 = xyd.tables.battlePassReward
local var_0_4 = var_0_1:getValue("battle_pass_point_per_level")
local var_0_5 = var_0_1:getValue("battle_pass_mission_weekly_open_num")
local var_0_6 = var_0_1:getValue("battle_pass_shop_coin_id")
local var_0_7 = var_0_1:getValue("battle_pass_award_loop_range")
local var_0_8 = var_0_1:getValue("battle_pass_award_max_level") - var_0_7

function var_0_0.ctor(arg_1_0)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.redmark = xyd.ModelManager.get():loadModel(xyd.ModelType.REDMARK)
end

function var_0_0.loadInfo(arg_2_0, arg_2_1)
	xyd.Backend.get():request(xyd.mid.BATTLE_PASS_GET_INFO, nil, function(arg_3_0, arg_3_1)
		if arg_3_0 == xyd.error.OK then
			if arg_3_1.base_info.coin_num then
				arg_2_0.selfPlayer:getBackpack():setItemNumByID(var_0_6, arg_3_1.base_info.coin_num)
			end

			arg_2_0:setInfo(arg_3_1)
			arg_2_0:resetRedMark(arg_3_1)
		end

		if arg_2_1 then
			arg_2_1(arg_3_0, arg_3_1)
		end
	end)
end

function var_0_0.setInfo(arg_4_0, arg_4_1)
	if arg_4_1.base_info then
		arg_4_0.base_info = arg_4_1.base_info
	end

	if arg_4_1.mission_info then
		arg_4_0.mission_info = arg_4_1.mission_info
	end
end

function var_0_0.buyLevel(arg_5_0, arg_5_1, arg_5_2)
	xyd.Backend.get():request(xyd.mid.BATTLE_PASS_BUY_LEVEL, arg_5_1, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			arg_5_0.base_info.point = arg_5_0.base_info.point + arg_5_1.lev * var_0_4

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.BATTLE_PASS_POINT_CHANGE
			})
		end

		if arg_5_2 then
			arg_5_2(arg_6_0, arg_6_1)
		end
	end)
end

function var_0_0.buyLimitPurchase(arg_7_0, arg_7_1, arg_7_2)
	xyd.Backend.get():request(xyd.mid.BATTLE_PASS_BUY_LIMIT_PURCHASE, arg_7_1, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK then
			arg_7_0.base_info.point = arg_7_0.base_info.point + var_0_1:getValue("battle_pass_limit_purchase_level") * var_0_4
			arg_7_0.base_info.limit_purchase_buy = arg_7_0.base_info.limit_purchase_buy + 1

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.BATTLE_PASS_POINT_CHANGE
			})
		end

		if arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.getAward(arg_9_0, arg_9_1, arg_9_2)
	xyd.Backend.get():request(xyd.mid.BATTLE_PASS_GET_AWARD, arg_9_1, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			arg_9_0.base_info.awarded_lev = arg_9_0:getLevel()

			if arg_9_0:isBuySenior() then
				arg_9_0.base_info.adv_awarded_lev = arg_9_0:getLevel()
			end

			arg_9_0:updateRedMark()
		end

		if arg_9_2 then
			arg_9_2(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.getMissionAward(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	xyd.Backend.get():request(xyd.mid.BATTLE_PASS_GET_MISSION_AWARD, arg_11_1, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			arg_11_0.mission_info.is_award[arg_11_1.id] = 1
			arg_11_0.base_info.point = arg_11_0.base_info.point + arg_11_3

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.BATTLE_PASS_POINT_CHANGE
			})
		end

		if arg_11_2 then
			arg_11_2(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.getTaskDatas(arg_13_0)
	local var_13_0 = {}
	local var_13_1 = #arg_13_0.mission_info.mission_list

	for iter_13_0 = 1, math.ceil(var_13_1 / var_0_5) do
		local var_13_2 = {}
		local var_13_3 = {}

		var_13_0[iter_13_0] = {}

		for iter_13_1 = 1, var_0_5 do
			local var_13_4 = (iter_13_0 - 1) * var_0_5 + iter_13_1

			if not arg_13_0.mission_info.mission_list[var_13_4] then
				break
			end

			local var_13_5 = {
				id = arg_13_0.mission_info.mission_list[var_13_4],
				count = arg_13_0.mission_info.mission_counts[var_13_4],
				is_award = arg_13_0.mission_info.is_award[var_13_4],
				list_id = var_13_4
			}

			if var_13_5.is_award == 0 then
				if var_13_5.count >= var_0_2:count(var_13_5.id) then
					table.insert(var_13_0[iter_13_0], var_13_5)
				else
					table.insert(var_13_2, var_13_5)
				end
			else
				table.insert(var_13_3, var_13_5)
			end
		end

		for iter_13_2, iter_13_3 in ipairs(var_13_2) do
			table.insert(var_13_0[iter_13_0], iter_13_3)
		end

		for iter_13_4, iter_13_5 in ipairs(var_13_3) do
			table.insert(var_13_0[iter_13_0], iter_13_5)
		end
	end

	return var_13_0
end

function var_0_0.getWeek(arg_14_0)
	local var_14_0 = #arg_14_0.mission_info.mission_list

	return math.ceil(var_14_0 / var_0_5)
end

function var_0_0.getPoint(arg_15_0)
	return arg_15_0.base_info.point % var_0_4
end

function var_0_0.getLevel(arg_16_0)
	return math.floor(arg_16_0.base_info.point / var_0_4)
end

function var_0_0.getNormalLevel(arg_17_0)
	return arg_17_0.base_info.awarded_lev
end

function var_0_0.getSeniorLevel(arg_18_0)
	return arg_18_0.base_info.adv_awarded_lev
end

function var_0_0.getLimitPurchaseBuyNum(arg_19_0)
	return arg_19_0.base_info.limit_purchase_buy
end

function var_0_0.isBuySenior(arg_20_0)
	return arg_20_0.base_info.is_advanced == 1
end

function var_0_0.isOpen(arg_21_0)
	local var_21_0 = var_0_1:getValue("battle_pass_season_start_time")
	local var_21_1 = var_0_1:getValue("battle_pass_season_end_time")
	local var_21_2 = xyd.ServerTime.get():getServerTime()

	if var_21_0 <= var_21_2 and var_21_2 < var_21_1 then
		return true
	else
		return false
	end
end

function var_0_0.isFuncOpen(arg_22_0)
	if arg_22_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_BATTLE_PASS) then
		return true
	else
		return false
	end
end

function var_0_0.updateRedMark(arg_23_0)
	local var_23_0 = xyd.WindowManager.get():getWindow("main_scene_top")

	if var_23_0 and not tolua.isnull(var_23_0) then
		var_23_0:refreshBattlePassRedMark()
	end
end

function var_0_0.onUpdateRedmark(arg_24_0, arg_24_1)
	for iter_24_0, iter_24_1 in ipairs(arg_24_1.redmark_list) do
		if iter_24_1 == xyd.redmark.BATTLE_PASS_LEVEL_UP then
			local var_24_0 = xyd.WindowManager.get():getWindow("main_scene_top")

			if var_24_0 and not tolua.isnull(var_24_0) then
				var_24_0:updateBattlePassRedMark()
			end
		else
			local var_24_1 = xyd.WindowManager.get():getWindow("task")
			local var_24_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)

			if var_24_1 and not tolua.isnull(var_24_1) and var_24_2:getCurTaskType() == xyd.TaskType.CHALLENGE then
				arg_24_0:loadInfo(function(arg_25_0, arg_25_1)
					if arg_25_0 == xyd.error.OK then
						var_24_1:battlePassRefreshList()
					end
				end)
			end
		end
	end
end

function var_0_0.resetRedMark(arg_26_0, arg_26_1)
	if not arg_26_1.mission_info then
		return
	end

	local var_26_0 = true

	for iter_26_0, iter_26_1 in ipairs(arg_26_1.mission_info.mission_counts) do
		if iter_26_1 > 0 then
			var_26_0 = false

			break
		end
	end

	if var_26_0 and arg_26_0.redmark.redmarkMap[xyd.FunctionID.ID_BATTLE_PASS] then
		arg_26_0.redmark.redmarkMap[xyd.FunctionID.ID_BATTLE_PASS][xyd.redmark.BATTLE_PASS_MISSION_COMPLETE] = nil

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.BACKEND_REDMARK
		})
	end
end

function var_0_0.onCharge(arg_27_0)
	arg_27_0.base_info.is_advanced = 1

	local var_27_0 = xyd.WindowManager.get():getWindow("battle_pass_main")

	if var_27_0 and not tolua.isnull(var_27_0) then
		var_27_0:updateSenior()
	end
end

function var_0_0.onDeluxeCharge(arg_28_0)
	arg_28_0.base_info.is_advanced = 1
	arg_28_0.base_info.point = math.max(arg_28_0.base_info.point, var_0_1:getValue("battle_pass_deluxe_edition_level") * var_0_4)

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.BATTLE_PASS_POINT_CHANGE
	})
	arg_28_0:updateRedMark()

	local var_28_0 = xyd.WindowManager.get():getWindow("battle_pass_main")

	if var_28_0 and not tolua.isnull(var_28_0) then
		var_28_0:updateSenior()
	end
end

function var_0_0.isRedMarkShow(arg_29_0)
	if arg_29_0:getLevel() > arg_29_0:getNormalLevel() then
		if arg_29_0:getNormalLevel() >= var_0_8 then
			if (arg_29_0:getLevel() - arg_29_0:getNormalLevel()) / var_0_7 >= 1 then
				return true
			else
				return false
			end
		else
			for iter_29_0 = arg_29_0:getNormalLevel() + 1, arg_29_0:getLevel() do
				if var_0_3:giftId(iter_29_0) > 0 then
					return true
				end
			end
		end
	end

	if arg_29_0:isBuySenior() and arg_29_0:getLevel() > arg_29_0:getSeniorLevel() then
		if arg_29_0:getSeniorLevel() >= var_0_8 then
			if (arg_29_0:getLevel() - arg_29_0:getSeniorLevel()) / var_0_7 >= 1 then
				return true
			else
				return false
			end
		else
			for iter_29_1 = arg_29_0:getSeniorLevel() + 1, arg_29_0:getLevel() do
				if var_0_3:advGiftId(iter_29_1) > 0 then
					return true
				end
			end
		end
	end

	return false
end

return var_0_0
