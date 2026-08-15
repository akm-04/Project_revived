local var_0_0 = class("LibraryHeroLogNewTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.subIdToType_ = {}
	arg_1_0.subIdToOpenDialog_ = {}
	arg_1_0.subIdToCondition_ = {}
	arg_1_0.subIdToOpenDiary_ = {}
	arg_1_0.subIdToGift_ = {}

	import("app.common.tables.TableParser").parse("library_hero_log.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)
		local var_2_1 = tonumber(arg_2_0.sub_id)

		arg_1_0.subIdToType_[var_2_1] = tonumber(arg_2_0.log_type)
		arg_1_0.subIdToOpenDialog_[var_2_1] = tonumber(arg_2_0.open_dialog)
		arg_1_0.subIdToCondition_[var_2_1] = tonumber(arg_2_0.condition)
		arg_1_0.subIdToOpenDiary_[var_2_1] = tonumber(arg_2_0.open_diary)
		arg_1_0.subIdToGift_[var_2_1] = tonumber(arg_2_0.gift)
	end)
end

function var_0_0.getLogType(arg_3_0, arg_3_1)
	return arg_3_0.subIdToType_[arg_3_1]
end

function var_0_0.openDialog(arg_4_0, arg_4_1)
	return arg_4_0.subIdToOpenDialog_[arg_4_1]
end

function var_0_0.getCondition(arg_5_0, arg_5_1)
	return arg_5_0.subIdToCondition_[arg_5_1]
end

function var_0_0.openDiary(arg_6_0, arg_6_1)
	return arg_6_0.subIdToOpenDiary_[arg_6_1]
end

function var_0_0.gift(arg_7_0, arg_7_1)
	return arg_7_0.subIdToGift_[arg_7_1]
end

return var_0_0
