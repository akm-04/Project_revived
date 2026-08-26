local var_0_0 = class("SpiritCampaignTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.day_ = {}
	arg_1_0.dayNum_ = {}
	arg_1_0.lastCampaign_ = {}
	arg_1_0.nextCampaign_ = {}
	arg_1_0.level_ = {}
	arg_1_0.costType_ = {}
	arg_1_0.winCostNum_ = {}
	arg_1_0.loseCostNum_ = {}
	arg_1_0.model_ = {}
	arg_1_0.scale_ = {}
	arg_1_0.battle_ = {}
	arg_1_0.initDisplay_ = {}
	arg_1_0.displayType_ = {}
	arg_1_0.display_ = {}
	arg_1_0.ruleDisplay_ = {}
	arg_1_0.initDropbox_ = {}
	arg_1_0.dropbox_ = {}
	arg_1_0.isOpen_ = {}
	arg_1_0.title_ = {}

	import("app.common.tables.TableParser").parse("spirit_campaign.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.day_[var_2_0] = tonumber(arg_2_0.day)

		if not arg_1_0.dayNum_[arg_1_0.day_[var_2_0]] then
			arg_1_0.dayNum_[arg_1_0.day_[var_2_0]] = 1
		else
			arg_1_0.dayNum_[arg_1_0.day_[var_2_0]] = arg_1_0.dayNum_[arg_1_0.day_[var_2_0]] + 1
		end

		arg_1_0.lastCampaign_[var_2_0] = tonumber(arg_2_0.last_campaign)
		arg_1_0.nextCampaign_[var_2_0] = tonumber(arg_2_0.next_campaign)
		arg_1_0.level_[var_2_0] = tonumber(arg_2_0.level)
		arg_1_0.costType_[var_2_0] = tonumber(arg_2_0.cost_type)
		arg_1_0.winCostNum_[var_2_0] = tonumber(arg_2_0.win_cost_num)
		arg_1_0.loseCostNum_[var_2_0] = tonumber(arg_2_0.lose_cost_num)
		arg_1_0.model_[var_2_0] = tonumber(arg_2_0.model)
		arg_1_0.scale_[var_2_0] = tonumber(arg_2_0.scale)
		arg_1_0.battle_[var_2_0] = tonumber(arg_2_0.battle)
		arg_1_0.initDisplay_[var_2_0] = xyd.splitToNumber(arg_2_0.init_display, "|")
		arg_1_0.displayType_[var_2_0] = tonumber(arg_2_0.display_type)

		if arg_1_0.displayType_[var_2_0] == 1 then
			arg_1_0.display_[var_2_0] = xyd.splitToNumber(arg_2_0.display, "|")
			arg_1_0.ruleDisplay_[var_2_0] = xyd.splitToNumber(arg_2_0.rule_display, "|")
		else
			arg_1_0.display_[var_2_0] = arg_2_0.display
			arg_1_0.ruleDisplay_[var_2_0] = arg_2_0.rule_display
		end

		arg_1_0.initDropbox_[var_2_0] = tonumber(arg_2_0.init_dropbox)
		arg_1_0.dropbox_[var_2_0] = tonumber(arg_2_0.dropbox)
		arg_1_0.isOpen_[var_2_0] = tonumber(arg_2_0.is_open)
		arg_1_0.title_[var_2_0] = arg_2_0.title
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.desc(arg_4_0, arg_4_1)
	return arg_4_0.desc_[arg_4_1] or ""
end

function var_0_0.day(arg_5_0, arg_5_1)
	return arg_5_0.day_[arg_5_1] or 0
end

function var_0_0.dayNum(arg_6_0, arg_6_1)
	return arg_6_0.dayNum_[arg_6_1] or 0
end

function var_0_0.lastCampaign(arg_7_0, arg_7_1)
	return arg_7_0.lastCampaign_[arg_7_1] or 0
end

function var_0_0.nextCampaign(arg_8_0, arg_8_1)
	return arg_8_0.nextCampaign_[arg_8_1] or 0
end

function var_0_0.level(arg_9_0, arg_9_1)
	return arg_9_0.level_[arg_9_1] or 0
end

function var_0_0.costType(arg_10_0, arg_10_1)
	return arg_10_0.costType_[arg_10_1] or 0
end

function var_0_0.winCostNum(arg_11_0, arg_11_1)
	return arg_11_0.winCostNum_[arg_11_1] or 0
end

function var_0_0.loseCostNum(arg_12_0, arg_12_1)
	return arg_12_0.loseCostNum_[arg_12_1] or 0
end

function var_0_0.model(arg_13_0, arg_13_1)
	return arg_13_0.model_[arg_13_1] or 0
end

function var_0_0.scale(arg_14_0, arg_14_1)
	return arg_14_0.scale_[arg_14_1] or 0
end

function var_0_0.battle(arg_15_0, arg_15_1)
	return arg_15_0.battle_[arg_15_1] or 0
end

function var_0_0.initDisplay(arg_16_0, arg_16_1)
	return arg_16_0.initDisplay_[arg_16_1] or {}
end

function var_0_0.displayType(arg_17_0, arg_17_1)
	return arg_17_0.displayType_[arg_17_1] or 0
end

function var_0_0.display(arg_18_0, arg_18_1)
	return arg_18_0.display_[arg_18_1] or {}
end

function var_0_0.ruleDisplay(arg_19_0, arg_19_1)
	return arg_19_0.ruleDisplay_[arg_19_1] or {}
end

function var_0_0.initDropbox(arg_20_0, arg_20_1)
	return arg_20_0.initDropbox_[arg_20_1] or 0
end

function var_0_0.dropbox(arg_21_0, arg_21_1)
	return arg_21_0.dropbox_[arg_21_1] or 0
end

function var_0_0.isOpen(arg_22_0, arg_22_1)
	return arg_22_0.isOpen_[arg_22_1] or 0
end

function var_0_0.title(arg_23_0, arg_23_1)
	return arg_23_0.title_[arg_23_1] or ""
end

return var_0_0
