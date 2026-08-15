local var_0_0 = class("SuperRich", import(".BaseModel"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.monoplyInfo(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_1 or {}

	xyd.Backend.get():request(xyd.mid.MONOPLY_INFO, var_3_0, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.baseInfo = arg_4_1.base_info
			arg_3_0.gridInfo = arg_4_1.grid_info
			arg_3_0.pipeInfo = arg_4_1.pipe_info
			arg_3_0.fightInfo = arg_4_1.fight_info
			arg_3_0.missionInfo = arg_4_1.mission_info
		end

		if arg_3_2 then
			arg_3_2(arg_4_0, arg_4_1)
		end
	end)
end

function var_0_0.canGetMisstionAward(arg_5_0)
	arg_5_0.reqs = arg_5_0.missionInfo.reqs
	arg_5_0.times = arg_5_0.missionInfo.times
	arg_5_0.counts = arg_5_0.missionInfo.counts

	if arg_5_0.counts[1] == arg_5_0.reqs[1] and arg_5_0.counts[2] == arg_5_0.reqs[2] and arg_5_0.counts[3] == arg_5_0.reqs[3] and arg_5_0.times == 1 then
		return true
	end

	return false
end

function var_0_0.notFinishMisstion(arg_6_0)
	arg_6_0.reqs = arg_6_0.missionInfo.reqs
	arg_6_0.times = arg_6_0.missionInfo.times
	arg_6_0.counts = arg_6_0.missionInfo.counts

	if arg_6_0.times == 1 and (arg_6_0.counts[1] ~= arg_6_0.reqs[1] or arg_6_0.counts[2] ~= arg_6_0.reqs[2] or arg_6_0.counts[3] ~= arg_6_0.reqs[3]) then
		return true
	end

	return false
end

function var_0_0.monoplyDicing(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1 or {}

	xyd.Backend.get():request(xyd.mid.MONOPLY_DICING, var_7_0, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK then
			if var_7_0.cheat_num and var_7_0.cheat_num > 0 then
				local var_8_0 = {
					itemID = xyd.tables.misc.activityRichRemoteDiceItem
				}

				var_8_0.itemNum = 1

				arg_7_0.backpack:removeItem(var_8_0)
			else
				local var_8_1 = {
					itemID = xyd.tables.misc.activityRichDiceItem
				}

				var_8_1.itemNum = 1

				arg_7_0.backpack:removeItem(var_8_1)
			end

			arg_7_0:handleRespone(arg_8_1)
		end

		if arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.monoplyOperate(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_1 or {}

	xyd.Backend.get():request(xyd.mid.MONOPLY_OPERATE, var_9_0, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			arg_9_0:handleRespone(arg_10_1)
		end

		if arg_9_2 then
			arg_9_2(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.monoplyShopBuy(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_1 or {}

	xyd.Backend.get():request(xyd.mid.MONOPOLY_SHOP_BUY, var_11_0, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			arg_11_0:handleRespone(arg_12_1)
		end

		if arg_11_2 then
			arg_11_2(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.monopolySkip(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = arg_13_1 or {}

	xyd.Backend.get():request(xyd.mid.MONOPOLY_SKIP, var_13_0, function(arg_14_0, arg_14_1)
		if arg_14_0 == xyd.error.OK then
			if var_13_0.skip == 1 then
				local var_14_0 = {
					itemID = xyd.tables.misc.activityRichPasserByCardItem
				}

				var_14_0.itemNum = 1

				arg_13_0.backpack:removeItem(var_14_0)
			end

			arg_13_0:handleRespone(arg_14_1)
		end

		if arg_13_2 then
			arg_13_2(arg_14_0, arg_14_1)
		end
	end)
end

function var_0_0.monopolyPipeLink(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = arg_15_1 or {}

	xyd.Backend.get():request(xyd.mid.MONOPOLY_PIPE_LINK, var_15_0, function(arg_16_0, arg_16_1)
		if arg_16_0 == xyd.error.OK then
			arg_15_0:handleRespone(arg_16_1)
		end

		if arg_15_2 then
			arg_15_2(arg_16_0, arg_16_1)
		end
	end)
end

function var_0_0.monopolyUseCard(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = arg_17_1 or {}

	xyd.Backend.get():request(xyd.mid.MONOPOLY_USE_CARD, var_17_0, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK then
			if var_17_0.grid_type == 6 or var_17_0.grid_type == 7 or var_17_0.grid_type == 8 then
				local var_18_0 = {
					itemID = xyd.tables.misc.activityRichVipCardItem
				}

				var_18_0.itemNum = 1

				arg_17_0.backpack:removeItem(var_18_0)
			end

			arg_17_0:handleRespone(arg_18_1)
		end

		if arg_17_2 then
			arg_17_2(arg_18_0, arg_18_1)
		end
	end)
end

function var_0_0.monopolyRankList(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = arg_19_1 or {}

	xyd.Backend.get():request(xyd.mid.MONOPOLY_RANK_LIST, var_19_0, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK then
			-- block empty
		end

		if arg_19_2 then
			arg_19_2(arg_20_0, arg_20_1)
		end
	end)
end

function var_0_0.monoplyBuyDice(arg_21_0, arg_21_1, arg_21_2)
	local var_21_0 = arg_21_1 or {}

	xyd.Backend.get():request(xyd.mid.MONOPOLY_BUY_DICE, var_21_0, function(arg_22_0, arg_22_1)
		if arg_22_0 == xyd.error.OK then
			arg_21_0:handleRespone(arg_22_1)
		end

		if arg_21_2 then
			arg_21_2(arg_22_0, arg_22_1)
		end
	end)
end

function var_0_0.monopolyFightWin(arg_23_0, arg_23_1, arg_23_2)
	local var_23_0 = arg_23_1 or {}

	xyd.Backend.get():request(xyd.mid.MONOPOLY_FIGHT_WIN, var_23_0, function(arg_24_0, arg_24_1)
		if arg_24_0 == xyd.error.OK then
			arg_23_0:handleRespone(arg_24_1)
		end

		if arg_23_2 then
			arg_23_2(arg_24_0, arg_24_1)
		end
	end)
end

function var_0_0.monopolyMissionAward(arg_25_0, arg_25_1, arg_25_2)
	local var_25_0 = arg_25_1 or {}

	xyd.Backend.get():request(xyd.mid.MONOPOLY_MISSION_AWARD, var_25_0, function(arg_26_0, arg_26_1)
		if arg_26_0 == xyd.error.OK then
			arg_25_0:handleRespone(arg_26_1)
		end

		if arg_25_2 then
			arg_25_2(arg_26_0, arg_26_1)
		end
	end)
end

function var_0_0.handleRespone(arg_27_0, arg_27_1)
	if arg_27_1.can_operate then
		arg_27_0.baseInfo.can_operate = arg_27_1.can_operate
	end

	if arg_27_1.last_dice then
		arg_27_0.baseInfo.last_dice = arg_27_1.last_dice
	end

	if arg_27_1.total_move then
		arg_27_0.baseInfo.total_move = arg_27_1.total_move
	end

	if arg_27_1.pos then
		arg_27_0.baseInfo.pos = arg_27_1.pos
	end

	arg_27_0.baseInfo.deltaStamps = nil

	if arg_27_1.stamps then
		arg_27_0.baseInfo.deltaStamps = arg_27_1.stamps - arg_27_0.baseInfo.stamps
		arg_27_0.baseInfo.stamps = arg_27_1.stamps
	end

	if arg_27_1.event_type then
		arg_27_0.baseInfo.event_type = arg_27_1.event_type
	end

	if arg_27_1.choose_skip then
		arg_27_0.baseInfo.choose_skip = arg_27_1.choose_skip
	end

	if arg_27_1.forward then
		arg_27_0.baseInfo.forward = arg_27_1.forward
	end

	if arg_27_1.fight_info then
		arg_27_0.fightInfo = arg_27_1.fight_info
	end

	if arg_27_1.pipe_nums then
		arg_27_0.pipeInfo.pipe_nums = arg_27_1.pipe_nums
	end

	if arg_27_1.pipe_info then
		arg_27_0.pipeInfo = arg_27_1.pipe_info
	end

	if arg_27_1.mission_info then
		arg_27_0.missionInfo = arg_27_1.mission_info
	end

	if arg_27_1.event_grid_info and arg_27_1.event_pos then
		arg_27_0.gridInfo[arg_27_1.event_pos] = arg_27_1.event_grid_info
	end

	if arg_27_1.grid_info and arg_27_1.pos then
		arg_27_0.gridInfo[arg_27_1.pos] = arg_27_1.grid_info
	end

	if arg_27_1.mission_info then
		arg_27_0.missionInfo = arg_27_1.mission_info
	end

	if arg_27_1.event_item and arg_27_1.event_item > 0 and arg_27_1.event_item_num then
		if arg_27_1.event_item_num > 0 then
			arg_27_0.backpack:addItemsByID(tonumber(arg_27_1.event_item), tonumber(arg_27_1.event_item_num))
		else
			local var_27_0 = {
				itemID = arg_27_1.event_item,
				itemNum = -arg_27_1.event_item_num
			}

			arg_27_0.backpack:removeItem(var_27_0)
		end
	end

	arg_27_0.response = arg_27_1

	if arg_27_1.awards then
		arg_27_0.selfPlayer:handleRewards(arg_27_1.awards)
	end

	if arg_27_1.awards and arg_27_1.fight_info and arg_27_1.fight_info.lev == 11 and arg_27_1.fight_info.times == 0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = xyd.tables.translation:translation("SUPER_RICH_CHALLENGE_OVER_TIP")
		})
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.REFRESH_SUPER_RICH_INFO
	})
end

return var_0_0
