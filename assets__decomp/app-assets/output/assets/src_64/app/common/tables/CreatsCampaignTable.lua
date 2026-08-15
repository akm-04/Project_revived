local var_0_0 = class("CreatsCampaignTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.chapterId_ = {}
	arg_1_0.campaignType_ = {}
	arg_1_0.campaignName_ = {}
	arg_1_0.campaignDes_ = {}
	arg_1_0.isStartPoint_ = {}
	arg_1_0.unlockId_ = {}
	arg_1_0.fightIds_ = {}
	arg_1_0.specialReward_ = {}
	arg_1_0.eventId_ = {}
	arg_1_0.eventDes_ = {}
	arg_1_0.logDes_ = {}
	arg_1_0.x_ = {}
	arg_1_0.y_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.icon1_ = {}
	arg_1_0.model_ = {}
	arg_1_0.chapterToCampaiganIds_ = {}
	arg_1_0.startPoint_ = {}
	arg_1_0.shortestPathParent_ = {}
	arg_1_0.creatDialogue_ = {}
	arg_1_0.creatTips_ = {}

	import("app.common.tables.TableParser").parse("creats_campaign.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.campaign_id)

		arg_1_0.chapterId_[var_2_0] = tonumber(arg_2_0.chapter_id)
		arg_1_0.campaignType_[var_2_0] = tonumber(arg_2_0.campaign_type)
		arg_1_0.campaignName_[var_2_0] = arg_2_0.campaign_name
		arg_1_0.campaignDes_[var_2_0] = arg_2_0.campaign_des
		arg_1_0.isStartPoint_[var_2_0] = tonumber(arg_2_0.is_start_point)
		arg_1_0.unlockId_[var_2_0] = xyd.splitToNumber(arg_2_0.unlock_id, "|")
		arg_1_0.fightIds_[var_2_0] = xyd.splitToNumber(arg_2_0.fight_ids, "|")
		arg_1_0.specialReward_[var_2_0] = tonumber(arg_2_0.special_reward)
		arg_1_0.eventId_[var_2_0] = tonumber(arg_2_0.event_id)
		arg_1_0.eventDes_[var_2_0] = arg_2_0.event_des
		arg_1_0.logDes_[var_2_0] = arg_2_0.log_des
		arg_1_0.x_[var_2_0] = tonumber(arg_2_0.x)
		arg_1_0.y_[var_2_0] = tonumber(arg_2_0.y)
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.icon1_[var_2_0] = arg_2_0.icon1
		arg_1_0.model_[var_2_0] = tonumber(arg_2_0.model)
		arg_1_0.creatDialogue_[var_2_0] = arg_2_0.creat_dialogue
		arg_1_0.creatTips_[var_2_0] = arg_2_0.creat_tips

		local var_2_1 = arg_1_0.chapterId_[var_2_0]

		if not arg_1_0.chapterToCampaiganIds_[var_2_1] then
			arg_1_0.chapterToCampaiganIds_[var_2_1] = {}
		end

		table.insert(arg_1_0.chapterToCampaiganIds_[var_2_1], var_2_0)

		if arg_1_0.isStartPoint_[var_2_0] == 1 then
			table.insert(arg_1_0.startPoint_, var_2_0)
		end
	end)
	arg_1_0:creatShortPathParentTable()
end

function var_0_0.creatShortPathParentTable(arg_3_0)
	local var_3_0 = {}
	local var_3_1 = clone(arg_3_0.startPoint_)

	while var_3_1 and next(var_3_1) do
		local var_3_2 = var_3_1[1]

		table.insert(var_3_0, var_3_2)
		table.remove(var_3_1, 1)

		local var_3_3 = arg_3_0:unlockId(var_3_2)

		for iter_3_0 = 1, #var_3_3 do
			local var_3_4 = var_3_3[iter_3_0]

			if not xyd.isInTable(var_3_0, var_3_4) and not xyd.isInTable(var_3_1, var_3_4) then
				table.insert(var_3_1, var_3_4)
			end

			if not arg_3_0.shortestPathParent_[tostring(var_3_4)] then
				arg_3_0.shortestPathParent_[tostring(var_3_4)] = var_3_2
			end
		end
	end
end

function var_0_0.getParentCampaignId(arg_4_0, arg_4_1)
	return arg_4_0.shortestPathParent_[tostring(arg_4_1)]
end

function var_0_0.chapterId(arg_5_0, arg_5_1)
	return arg_5_0.chapterId_[arg_5_1] or 0
end

function var_0_0.campaignType(arg_6_0, arg_6_1)
	return arg_6_0.campaignType_[arg_6_1] or 1
end

function var_0_0.campaignName(arg_7_0, arg_7_1)
	return arg_7_0.campaignName_[arg_7_1] or ""
end

function var_0_0.campaignDes(arg_8_0, arg_8_1)
	return arg_8_0.campaignDes_[arg_8_1] or ""
end

function var_0_0.isStartPoint(arg_9_0, arg_9_1)
	return arg_9_0.isStartPoint_[arg_9_1] or 0
end

function var_0_0.unlockId(arg_10_0, arg_10_1)
	return arg_10_0.unlockId_[arg_10_1] or {}
end

function var_0_0.specialReward(arg_11_0, arg_11_1)
	return arg_11_0.specialReward_[arg_11_1] or 0
end

function var_0_0.eventId(arg_12_0, arg_12_1)
	return arg_12_0.eventId_[arg_12_1] or 0
end

function var_0_0.eventDes(arg_13_0, arg_13_1)
	return arg_13_0.eventDes_[arg_13_1] or ""
end

function var_0_0.logDes(arg_14_0, arg_14_1)
	return arg_14_0.logDes_[arg_14_1] or ""
end

function var_0_0.x(arg_15_0, arg_15_1)
	return arg_15_0.x_[arg_15_1] or 0
end

function var_0_0.y(arg_16_0, arg_16_1)
	return arg_16_0.y_[arg_16_1] or 0
end

function var_0_0.icon(arg_17_0, arg_17_1)
	return arg_17_0.icon_[arg_17_1] or ""
end

function var_0_0.icon1(arg_18_0, arg_18_1)
	return arg_18_0.icon1_[arg_18_1] or ""
end

function var_0_0.model(arg_19_0, arg_19_1)
	return arg_19_0.model_[arg_19_1] or 0
end

function var_0_0.getCampaignIds(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0 = arg_20_0.chapterToCampaiganIds_[arg_20_1] or {}
	local var_20_1 = {}

	for iter_20_0 = 1, #var_20_0 do
		if arg_20_0:campaignType(var_20_0[iter_20_0]) == arg_20_2 then
			table.insert(var_20_1, var_20_0[iter_20_0])
		end
	end

	return var_20_1
end

function var_0_0.getFightIds(arg_21_0, arg_21_1)
	return arg_21_0.fightIds_[arg_21_1]
end

function var_0_0.getFightId(arg_22_0, arg_22_1, arg_22_2)
	return arg_22_0:getFightIds(arg_22_1)[arg_22_2]
end

function var_0_0.creatDialogue(arg_23_0, arg_23_1)
	return arg_23_0.creatDialogue_[arg_23_1] or ""
end

function var_0_0.creatTips(arg_24_0, arg_24_1)
	return arg_24_0.creatTips_[arg_24_1] or ""
end

function var_0_0.getStartDialogTable(arg_25_0, arg_25_1)
	for iter_25_0 = 1, #arg_25_0.startPoint_ do
		if arg_25_0:chapterId(arg_25_0.startPoint_[iter_25_0]) == arg_25_1 then
			return arg_25_0:creatDialogue(arg_25_0.startPoint_[iter_25_0])
		end
	end
end

function var_0_0.getDialogTable(arg_26_0, arg_26_1, arg_26_2, arg_26_3)
	local var_26_0 = arg_26_0:getCampaignIds(arg_26_1, arg_26_2)

	for iter_26_0 = 1, #var_26_0 do
		if arg_26_0:eventId(var_26_0[iter_26_0]) == arg_26_3 then
			return arg_26_0:creatDialogue(var_26_0[iter_26_0])
		end
	end
end

function var_0_0.getCreatTips(arg_27_0, arg_27_1, arg_27_2, arg_27_3)
	local var_27_0 = arg_27_0:getCampaignIds(arg_27_1, arg_27_2)

	for iter_27_0 = 1, #var_27_0 do
		if arg_27_0:eventId(var_27_0[iter_27_0]) == arg_27_3 then
			return arg_27_0:creatTips(var_27_0[iter_27_0])
		end
	end
end

return var_0_0
