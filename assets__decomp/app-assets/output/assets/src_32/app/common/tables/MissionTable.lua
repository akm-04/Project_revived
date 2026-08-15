local var_0_0 = class("MissionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.names_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.types_ = {}
	arg_1_0.newType_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.open_reqs_ = {}
	arg_1_0.task_reqs_ = {}
	arg_1_0.task_nums_ = {}
	arg_1_0.gold_ = {}
	arg_1_0.exps_ = {}
	arg_1_0.crystals_ = {}
	arg_1_0.spiritStone_ = {}
	arg_1_0.awards_ = {}
	arg_1_0.award_nums_ = {}
	arg_1_0.gotos_ = {}
	arg_1_0.mealTimeTable_ = {}
	arg_1_0.isFirstMeal_ = true
	arg_1_0.display_ = {}
	arg_1_0.guildCoin_ = {}
	arg_1_0.vip_ = {}
	arg_1_0.exCoin_ = {}
	arg_1_0.iconNew_ = {}
	arg_1_0.goldNew_ = {}
	arg_1_0.expsNew_ = {}
	arg_1_0.crystalsNew_ = {}
	arg_1_0.spiritStoneNew_ = {}
	arg_1_0.guildCoinNew_ = {}
	arg_1_0.awards_New_ = {}
	arg_1_0.award_nums_New_ = {}
	arg_1_0.showAward_ = {}
	arg_1_0.marchCoin_ = {}
	arg_1_0.vipExp_ = {}
	arg_1_0.title_ = {}
	arg_1_0.stage_ = {}
	arg_1_0.pet_campaign_id_ = {}
	arg_1_0.awaken_piece_ = {}
	arg_1_0.beforeAwakenID_ = {}
	arg_1_0.afterAwakenID_ = {}
	arg_1_0.preMissionID_ = {}
	arg_1_0.sufMissionID_ = {}
	arg_1_0.awakeTaskNums_ = {}
	arg_1_0.goIDs_ = {}
	arg_1_0.campaignIcons_ = {}
	arg_1_0.heroIcons_ = {}
	arg_1_0.items_ = {}
	arg_1_0.trialChallenges_ = {}
	arg_1_0.copyChallenges_ = {}
	arg_1_0.challengeNums_ = {}
	arg_1_0.missionDescs_ = {}
	arg_1_0.heroDescs_ = {}
	arg_1_0.missionTypeNames_ = {}
	arg_1_0.goalNames_ = {}
	arg_1_0.awakeMaterials_ = {}
	arg_1_0.awakeIcon_ = {}
	arg_1_0.giveUpDelItems_ = {}
	arg_1_0.maxStageByHeroID_ = {}
	arg_1_0.medal_ = {}
	arg_1_0.detailType_ = {}
	arg_1_0.isAwakeMissions_ = {}
	arg_1_0.isAwakeTwiceMissions_ = {}
	arg_1_0.isPetAwakeMissions_ = {}
	arg_1_0.battlePassScore_ = {}

	import("app.common.tables.TableParser").parse("mission.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.names_[var_2_0] = arg_2_0.name
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.types_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.open_reqs_[var_2_0] = arg_2_0.req
		arg_1_0.display_[var_2_0] = tonumber(arg_2_0.display)
		arg_1_0.medal_[var_2_0] = tonumber(arg_2_0.medal)

		local var_2_1 = tonumber(arg_2_0.task_req)

		arg_1_0.task_reqs_[var_2_0] = var_2_1

		if var_2_1 == xyd.TaskReq.TIME_SPAN or var_2_1 == xyd.TaskReq.STAGE_COUNT or var_2_1 == xyd.TaskReq.CENTER_ACTIVITY_UPGRADE then
			arg_1_0.task_nums_[var_2_0] = {}
			parts = xyd.splitToNumber(arg_2_0.task_num, "|")

			table.insert(arg_1_0.task_nums_[var_2_0], parts[1])
			table.insert(arg_1_0.task_nums_[var_2_0], parts[2])
		elseif var_2_1 == xyd.TaskReq.SUMMON_SPECIFIC_HERO then
			arg_1_0.task_nums_[var_2_0] = {}

			table.insert(arg_1_0.task_nums_[var_2_0], tonumber(arg_2_0.task_num))
			table.insert(arg_1_0.task_nums_[var_2_0], 1)
		elseif var_2_1 == xyd.TaskReq.ACTIVITY_MEAL_TIME then
			arg_1_0.task_nums_[var_2_0] = {}

			table.insert(arg_1_0.task_nums_[var_2_0], tonumber(arg_2_0.task_num))
		else
			arg_1_0.task_nums_[var_2_0] = tonumber(arg_2_0.task_num)
		end

		if var_2_1 == xyd.TaskReq.TIME_SPAN then
			arg_1_0.mealTimeTable_[var_2_0] = {}

			if arg_1_0.isFirstMeal_ then
				arg_1_0.mealTimeTable_[var_2_0].startTime = 0
				arg_1_0.isFirstMeal_ = false
			else
				arg_1_0.mealTimeTable_[var_2_0].startTime = arg_1_0.mealTimeTable_[var_2_0 - 1].endTime
			end

			arg_1_0.mealTimeTable_[var_2_0].endTime = arg_1_0.task_nums_[var_2_0][1]
		end

		arg_1_0.gold_[var_2_0] = tonumber(arg_2_0.money)
		arg_1_0.exps_[var_2_0] = tonumber(arg_2_0.exp)
		arg_1_0.crystals_[var_2_0] = tonumber(arg_2_0.diamond)
		arg_1_0.spiritStone_[var_2_0] = tonumber(arg_2_0.soul)
		arg_1_0.guildCoin_[var_2_0] = tonumber(arg_2_0.badge)
		arg_1_0.awards_[var_2_0] = arg_2_0.award_id
		arg_1_0.award_nums_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.vip_[var_2_0] = tonumber(arg_2_0.vip)
		arg_1_0.exCoin_[var_2_0] = tonumber(arg_2_0.ex_badge)
		arg_1_0.vipExp_[var_2_0] = tonumber(arg_2_0.vip_exp)
		arg_1_0.iconNew_[var_2_0] = arg_2_0.icon_new
		arg_1_0.goldNew_[var_2_0] = tonumber(arg_2_0.money_new)
		arg_1_0.expsNew_[var_2_0] = tonumber(arg_2_0.exp_new)
		arg_1_0.crystalsNew_[var_2_0] = tonumber(arg_2_0.diamond_new)
		arg_1_0.spiritStoneNew_[var_2_0] = tonumber(arg_2_0.soul_new)
		arg_1_0.guildCoinNew_[var_2_0] = tonumber(arg_2_0.badge_new)
		arg_1_0.awards_New_[var_2_0] = arg_2_0.award_id_new
		arg_1_0.award_nums_New_[var_2_0] = tonumber(arg_2_0.num_new)
		arg_1_0.newType_[var_2_0] = tonumber(arg_2_0.new_type)
		arg_1_0.detailType_[var_2_0] = tonumber(arg_2_0.detail_type)
		arg_1_0.showAward_[var_2_0] = arg_2_0.show_award
		arg_1_0.marchCoin_[var_2_0] = tonumber(arg_2_0.march_coin_new)
		arg_1_0.battlePassScore_[var_2_0] = tonumber(arg_2_0.battlepass_score)

		local var_2_2 = arg_2_0.go_id
		local var_2_3 = xyd.splitToNumber(var_2_2, "|")

		arg_1_0.gotos_[var_2_0] = {}

		table.insert(arg_1_0.gotos_[var_2_0], var_2_3[1])

		if #var_2_3 >= 2 then
			table.insert(arg_1_0.gotos_[var_2_0], var_2_3[2])
		end
	end)
	import("app.common.tables.TableParser").parse("awaken_mission.lua", function(arg_3_0)
		local var_3_0 = tonumber(arg_3_0.id)

		arg_1_0.title_[var_3_0] = arg_3_0.title_icon
		arg_1_0.stage_[var_3_0] = tonumber(arg_3_0.stage)
		arg_1_0.beforeAwakenID_[var_3_0] = tonumber(arg_3_0.table_id)
		arg_1_0.afterAwakenID_[var_3_0] = tonumber(arg_3_0.awaken_table_id)
		arg_1_0.preMissionID_[var_3_0] = tonumber(arg_3_0.task_id)
		arg_1_0.sufMissionID_[var_3_0] = tonumber(arg_3_0.next_task_id)
		arg_1_0.awakeTaskNums_[var_3_0] = arg_3_0.task_num
		arg_1_0.goIDs_[var_3_0] = xyd.splitToNumber(arg_3_0.go_id, "|")
		arg_1_0.campaignIcons_[var_3_0] = arg_3_0.icon
		arg_1_0.heroIcons_[var_3_0] = arg_3_0.hero_icon
		arg_1_0.items_[var_3_0] = tonumber(arg_3_0.item)
		arg_1_0.trialChallenges_[var_3_0] = xyd.splitToNumber(arg_3_0.trial_challenge, "|")
		arg_1_0.copyChallenges_[var_3_0] = tonumber(arg_3_0.copy_challenge)
		arg_1_0.challengeNums_[var_3_0] = tonumber(arg_3_0.challenge_num)
		arg_1_0.missionDescs_[var_3_0] = arg_3_0.mission_desc
		arg_1_0.heroDescs_[var_3_0] = arg_3_0.hero_desc
		arg_1_0.missionTypeNames_[var_3_0] = xyd.luaStringSplit(arg_3_0.mission_type, "|")
		arg_1_0.goalNames_[var_3_0] = arg_3_0.goal_name
		arg_1_0.display_[var_3_0] = tonumber(arg_3_0.display)
		arg_1_0.awakeMaterials_[var_3_0] = tonumber(arg_3_0.awaken_material)
		arg_1_0.awakeIcon_[var_3_0] = arg_3_0.icon
		arg_1_0.isAwakeMissions_[var_3_0] = true

		if tonumber(arg_3_0.delete_item) == 0 then
			arg_1_0.giveUpDelItems_[var_3_0] = {}
		else
			arg_1_0.giveUpDelItems_[var_3_0] = xyd.splitToNumber(arg_3_0.delete_item, "|")
		end

		if not arg_1_0.maxStageByHeroID_[arg_1_0.beforeAwakenID_[var_3_0]] then
			arg_1_0.maxStageByHeroID_[arg_1_0.beforeAwakenID_[var_3_0]] = 1
		else
			arg_1_0.maxStageByHeroID_[arg_1_0.beforeAwakenID_[var_3_0]] = arg_1_0.maxStageByHeroID_[arg_1_0.beforeAwakenID_[var_3_0]] + 1
		end
	end)
	import("app.common.tables.TableParser").parse("bloodline_mission.lua", function(arg_4_0)
		local var_4_0 = tonumber(arg_4_0.id)

		arg_1_0.title_[var_4_0] = arg_4_0.title_icon
		arg_1_0.stage_[var_4_0] = tonumber(arg_4_0.stage)
		arg_1_0.beforeAwakenID_[var_4_0] = tonumber(arg_4_0.table_id)
		arg_1_0.preMissionID_[var_4_0] = tonumber(arg_4_0.task_id)
		arg_1_0.sufMissionID_[var_4_0] = tonumber(arg_4_0.next_task_id)
		arg_1_0.awakeTaskNums_[var_4_0] = arg_4_0.task_num
		arg_1_0.goIDs_[var_4_0] = tonumber(arg_4_0.go_id)
		arg_1_0.campaignIcons_[var_4_0] = arg_4_0.icon
		arg_1_0.heroIcons_[var_4_0] = arg_4_0.hero_icon
		arg_1_0.items_[var_4_0] = tonumber(arg_4_0.item)
		arg_1_0.trialChallenges_[var_4_0] = xyd.splitToNumber(arg_4_0.trial_challenge, "|")
		arg_1_0.copyChallenges_[var_4_0] = tonumber(arg_4_0.copy_challenge)
		arg_1_0.challengeNums_[var_4_0] = tonumber(arg_4_0.challenge_num)
		arg_1_0.missionDescs_[var_4_0] = arg_4_0.mission_desc
		arg_1_0.heroDescs_[var_4_0] = arg_4_0.hero_desc
		arg_1_0.missionTypeNames_[var_4_0] = xyd.luaStringSplit(arg_4_0.mission_type, "|")
		arg_1_0.goalNames_[var_4_0] = arg_4_0.goal_name
		arg_1_0.display_[var_4_0] = tonumber(arg_4_0.display)
		arg_1_0.awakeMaterials_[var_4_0] = tonumber(arg_4_0.awaken_material)
		arg_1_0.awakeIcon_[var_4_0] = arg_4_0.icon
		arg_1_0.isAwakeTwiceMissions_[var_4_0] = true

		if tonumber(arg_4_0.delete_item) == 0 then
			arg_1_0.giveUpDelItems_[var_4_0] = {}
		else
			arg_1_0.giveUpDelItems_[var_4_0] = xyd.splitToNumber(arg_4_0.delete_item, "|")
		end

		if not arg_1_0.maxStageByHeroID_[arg_1_0.beforeAwakenID_[var_4_0]] then
			arg_1_0.maxStageByHeroID_[arg_1_0.beforeAwakenID_[var_4_0]] = 1
		else
			arg_1_0.maxStageByHeroID_[arg_1_0.beforeAwakenID_[var_4_0]] = arg_1_0.maxStageByHeroID_[arg_1_0.beforeAwakenID_[var_4_0]] + 1
		end
	end)
	import("app.common.tables.TableParser").parse("pet_awaken_mission.lua", function(arg_5_0)
		local var_5_0 = tonumber(arg_5_0.id)

		arg_1_0.title_[var_5_0] = arg_5_0.title_icon
		arg_1_0.pet_campaign_id_[var_5_0] = tonumber(arg_5_0.pet_campaign_id)
		arg_1_0.stage_[var_5_0] = tonumber(arg_5_0.stage)
		arg_1_0.beforeAwakenID_[var_5_0] = tonumber(arg_5_0.table_id)
		arg_1_0.afterAwakenID_[var_5_0] = tonumber(arg_5_0.awaken_table_id)
		arg_1_0.preMissionID_[var_5_0] = tonumber(arg_5_0.task_id)
		arg_1_0.sufMissionID_[var_5_0] = tonumber(arg_5_0.next_task_id)
		arg_1_0.awakeTaskNums_[var_5_0] = arg_5_0.task_num
		arg_1_0.goIDs_[var_5_0] = tonumber(arg_5_0.go_id)
		arg_1_0.campaignIcons_[var_5_0] = arg_5_0.icon
		arg_1_0.heroIcons_[var_5_0] = xyd.split(arg_5_0.pet_icon, "|")
		arg_1_0.awaken_piece_[var_5_0] = tonumber(arg_5_0.awaken_piece)
		arg_1_0.items_[var_5_0] = tonumber(arg_5_0.item)
		arg_1_0.trialChallenges_[var_5_0] = xyd.splitToNumber(arg_5_0.trial_challenge, "|")
		arg_1_0.copyChallenges_[var_5_0] = tonumber(arg_5_0.copy_challenge)
		arg_1_0.challengeNums_[var_5_0] = tonumber(arg_5_0.challenge_num)
		arg_1_0.missionDescs_[var_5_0] = arg_5_0.mission_desc
		arg_1_0.heroDescs_[var_5_0] = arg_5_0.hero_desc
		arg_1_0.missionTypeNames_[var_5_0] = xyd.luaStringSplit(arg_5_0.mission_type, "|")
		arg_1_0.goalNames_[var_5_0] = arg_5_0.goal_name
		arg_1_0.display_[var_5_0] = tonumber(arg_5_0.display)
		arg_1_0.awakeMaterials_[var_5_0] = tonumber(arg_5_0.awaken_material)
		arg_1_0.awakeIcon_[var_5_0] = arg_5_0.icon
		arg_1_0.isPetAwakeMissions_[var_5_0] = true

		if tonumber(arg_5_0.delete_item) == 0 then
			arg_1_0.giveUpDelItems_[var_5_0] = {}
		else
			arg_1_0.giveUpDelItems_[var_5_0] = xyd.splitToNumber(arg_5_0.delete_item, "|")
		end
	end)
end

function var_0_0.name(arg_6_0, arg_6_1)
	return arg_6_0.names_[arg_6_1]
end

function var_0_0.icon(arg_7_0, arg_7_1)
	if xyd.tables.functionOpen:open_control(xyd.FunctionID.ID_REWARD_CHANGE) == 1 then
		return arg_7_0.iconNew_[arg_7_1] or ""
	else
		return arg_7_0.icon_[arg_7_1] or ""
	end
end

function var_0_0.type(arg_8_0, arg_8_1)
	return arg_8_0.types_[arg_8_1] or nil
end

function var_0_0.newType(arg_9_0, arg_9_1)
	return arg_9_0.newType_[arg_9_1] or nil
end

function var_0_0.des(arg_10_0, arg_10_1)
	return arg_10_0.desc_[arg_10_1]
end

function var_0_0.gold(arg_11_0, arg_11_1)
	if xyd.tables.functionOpen:open_control(xyd.FunctionID.ID_REWARD_CHANGE) == 1 then
		return arg_11_0.goldNew_[arg_11_1] or 0
	else
		return arg_11_0.gold_[arg_11_1] or 0
	end
end

function var_0_0.exp(arg_12_0, arg_12_1)
	if xyd.tables.functionOpen:open_control(xyd.FunctionID.ID_REWARD_CHANGE) == 1 then
		return arg_12_0.expsNew_[arg_12_1]
	else
		return arg_12_0.exps_[arg_12_1]
	end
end

function var_0_0.pet_campaign_id(arg_13_0, arg_13_1)
	return arg_13_0.pet_campaign_id_[arg_13_1]
end

function var_0_0.awaken_piece(arg_14_0, arg_14_1)
	return arg_14_0.awaken_piece_[arg_14_1] or 0
end

function var_0_0.crystal(arg_15_0, arg_15_1)
	if xyd.tables.functionOpen:open_control(xyd.FunctionID.ID_REWARD_CHANGE) == 1 then
		return arg_15_0.crystalsNew_[arg_15_1] or 0
	else
		return arg_15_0.crystals_[arg_15_1] or 0
	end
end

function var_0_0.spiritStone(arg_16_0, arg_16_1)
	if xyd.tables.functionOpen:open_control(xyd.FunctionID.ID_REWARD_CHANGE) == 1 then
		return arg_16_0.spiritStoneNew_[arg_16_1] or 0
	else
		return arg_16_0.spiritStone_[arg_16_1] or 0
	end
end

function var_0_0.medal(arg_17_0, arg_17_1)
	return arg_17_0.medal_[arg_17_1] or 0
end

function var_0_0.award(arg_18_0, arg_18_1)
	if xyd.tables.functionOpen:open_control(xyd.FunctionID.ID_REWARD_CHANGE) == 1 then
		return arg_18_0.awards_New_[arg_18_1] or "0"
	else
		return arg_18_0.awards_[arg_18_1] or "0"
	end
end

function var_0_0.award_num(arg_19_0, arg_19_1)
	if xyd.tables.functionOpen:open_control(xyd.FunctionID.ID_REWARD_CHANGE) == 1 then
		return arg_19_0.award_nums_New_[arg_19_1] or 0
	else
		return arg_19_0.award_nums_[arg_19_1] or 0
	end
end

function var_0_0.task_req(arg_20_0, arg_20_1)
	return arg_20_0.task_reqs_[arg_20_1] or 0
end

function var_0_0.task_num(arg_21_0, arg_21_1)
	local var_21_0 = arg_21_0.task_nums_[arg_21_1]

	if type(var_21_0) == "table" then
		if arg_21_0:task_req(arg_21_1) == xyd.TaskReq.TIME_SPAN or arg_21_0:task_req(arg_21_1) == xyd.TaskReq.ACTIVITY_MEAL_TIME then
			return var_21_0
		elseif arg_21_0:task_req(arg_21_1) == xyd.TaskReq.CENTER_ACTIVITY_UPGRADE then
			return var_21_0[2]
		elseif arg_21_0:task_req(arg_21_1) == xyd.TaskReq.CENTER_ACTIVITY_MISSION then
			return var_21_0
		elseif #var_21_0 >= 2 then
			return var_21_0[2]
		end
	else
		return var_21_0
	end

	return 0
end

function var_0_0.goto_type(arg_22_0, arg_22_1)
	return arg_22_0.gotos_[arg_22_1][1] or 0
end

function var_0_0.goto_value(arg_23_0, arg_23_1)
	return arg_23_0.gotos_[arg_23_1][2] or 0
end

function var_0_0.open_req(arg_24_0, arg_24_1)
	return arg_24_0.open_reqs_[arg_24_1] or 0
end

function var_0_0.power(arg_25_0, arg_25_1)
	if arg_25_0.awards_[arg_25_1] then
		local var_25_0 = xyd.splitToNumber(arg_25_0.awards_[arg_25_1], "|")
		local var_25_1 = var_25_0[1]

		if #var_25_0 > 1 and var_25_0[1] == "1" then
			return tonumber(var_25_0[2])
		end
	end

	return 0
end

function var_0_0.getMealTimeTable(arg_26_0)
	return arg_26_0.mealTimeTable_ or {}
end

function var_0_0.display(arg_27_0, arg_27_1)
	return arg_27_0.display_[arg_27_1] or 0
end

function var_0_0.guildCoin(arg_28_0, arg_28_1)
	if xyd.tables.functionOpen:open_control(xyd.FunctionID.ID_REWARD_CHANGE) == 1 then
		return arg_28_0.guildCoinNew_[arg_28_1] or 0
	else
		return arg_28_0.guildCoin_[arg_28_1] or 0
	end
end

function var_0_0.vip(arg_29_0, arg_29_1)
	return arg_29_0.vip_[arg_29_1] or 0
end

function var_0_0.exCoin(arg_30_0, arg_30_1)
	return arg_30_0.exCoin_[arg_30_1] or 0
end

function var_0_0.vipExp(arg_31_0, arg_31_1)
	return arg_31_0.vipExp_[arg_31_1] or 0
end

function var_0_0.isAwakeMission(arg_32_0, arg_32_1)
	return arg_32_0.isAwakeMissions_[arg_32_1] or false
end

function var_0_0.isAwakeTwiceMission(arg_33_0, arg_33_1)
	return arg_33_0.isAwakeTwiceMissions_[arg_33_1] or false
end

function var_0_0.isPetAwakeMission(arg_34_0, arg_34_1)
	return arg_34_0.isPetAwakeMissions_[arg_34_1] or false
end

function var_0_0.title(arg_35_0, arg_35_1)
	return arg_35_0.title_[arg_35_1] or ""
end

function var_0_0.stage(arg_36_0, arg_36_1)
	return arg_36_0.stage_[arg_36_1] or 0
end

function var_0_0.beforeAwakenID(arg_37_0, arg_37_1)
	return arg_37_0.beforeAwakenID_[arg_37_1] or 0
end

function var_0_0.afterAwakenID(arg_38_0, arg_38_1)
	return arg_38_0.afterAwakenID_[arg_38_1] or 0
end

function var_0_0.preMissionID(arg_39_0, arg_39_1)
	return arg_39_0.preMissionID_[arg_39_1] or 0
end

function var_0_0.sufMissionID(arg_40_0, arg_40_1)
	return arg_40_0.sufMissionID_[arg_40_1] or 0
end

function var_0_0.awakeTaskNum(arg_41_0, arg_41_1)
	return xyd.splitToNumber(arg_41_0.awakeTaskNums_[arg_41_1], "|") or {}
end

function var_0_0.goIDs(arg_42_0, arg_42_1)
	return arg_42_0.goIDs_[arg_42_1] or "0"
end

function var_0_0.campaignIcons(arg_43_0, arg_43_1)
	return arg_43_0.campaignIcons_[arg_43_1] or ""
end

function var_0_0.heroIcons(arg_44_0, arg_44_1)
	return arg_44_0.heroIcons_[arg_44_1] or ""
end

function var_0_0.items(arg_45_0, arg_45_1)
	return arg_45_0.items_[arg_45_1] or 0
end

function var_0_0.trialChallenges(arg_46_0, arg_46_1)
	return arg_46_0.trialChallenges_[arg_46_1] or {}
end

function var_0_0.copyChallenges(arg_47_0, arg_47_1)
	return arg_47_0.copyChallenges_[arg_47_1] or 0
end

function var_0_0.challengeNums(arg_48_0, arg_48_1)
	return arg_48_0.challengeNums_[arg_48_1] or 0
end

function var_0_0.missionTypeName(arg_49_0, arg_49_1)
	return arg_49_0.missionTypeNames_[arg_49_1] or {}
end

function var_0_0.goalName(arg_50_0, arg_50_1)
	return arg_50_0.goalNames_[arg_50_1] or ""
end

function var_0_0.heroDesc(arg_51_0, arg_51_1)
	return arg_51_0.heroDescs_[arg_51_1] or ""
end

function var_0_0.missionDesc(arg_52_0, arg_52_1)
	return arg_52_0.missionDescs_[arg_52_1] or ""
end

function var_0_0.awakeMaterial(arg_53_0, arg_53_1)
	return arg_53_0.awakeMaterials_[arg_53_1] or 0
end

function var_0_0.getMissionIDByTableIDAndStage(arg_54_0, arg_54_1, arg_54_2)
	for iter_54_0, iter_54_1 in pairs(arg_54_0.beforeAwakenID_) do
		if iter_54_1 == arg_54_1 and arg_54_0.stage_[iter_54_0] == arg_54_2 then
			return iter_54_0
		end
	end

	return 0
end

function var_0_0.awakeIcon(arg_55_0, arg_55_1)
	return arg_55_0.awakeIcon_[arg_55_1] or ""
end

function var_0_0.getGiveUpDelItems(arg_56_0, arg_56_1)
	return arg_56_0.giveUpDelItems_[arg_56_1] or {}
end

function var_0_0.getAwakeMaxStageByBeforeID(arg_57_0, arg_57_1)
	return arg_57_0.maxStageByHeroID_[arg_57_1] or 3
end

function var_0_0.getDetailType(arg_58_0, arg_58_1)
	return arg_58_0.detailType_[arg_58_1]
end

function var_0_0.getShowAward(arg_59_0, arg_59_1)
	return xyd.split(arg_59_0.showAward_[arg_59_1], "|")
end

function var_0_0.marchCoin(arg_60_0, arg_60_1)
	return arg_60_0.marchCoin_[arg_60_1] or 0
end

function var_0_0.battlePassScore(arg_61_0, arg_61_1)
	return arg_61_0.battlePassScore_[arg_61_1] or 0
end

return var_0_0
