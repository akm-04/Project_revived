local var_0_0 = class("IndiegogoTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.type_ = {}
	arg_1_0.subclass_ = {}
	arg_1_0.name_ = {}
	arg_1_0.issueStone_ = {}
	arg_1_0.participationStone_ = {}
	arg_1_0.achieveStone_ = {}
	arg_1_0.issueAward_ = {}
	arg_1_0.issueAwardNum_ = {}
	arg_1_0.participationAward_ = {}
	arg_1_0.participationAwardNum_ = {}
	arg_1_0.time_ = {}
	arg_1_0.iconID_ = {}

	import("app.common.tables.TableParser").parse("indiegogo.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.ids_[var_2_0] = tonumber(arg_2_0.id)
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.subclass_[var_2_0] = tonumber(arg_2_0.subclass)
		arg_1_0.issueStone_[var_2_0] = tonumber(arg_2_0.issue_stone)
		arg_1_0.participationStone_[var_2_0] = tonumber(arg_2_0.participation_stone)
		arg_1_0.achieveStone_[var_2_0] = tonumber(arg_2_0.achieve_stone)
		arg_1_0.issueAward_[var_2_0] = tonumber(arg_2_0.issue_award)
		arg_1_0.issueAwardNum_[var_2_0] = tonumber(arg_2_0.issue_award_num)
		arg_1_0.participationAward_[var_2_0] = tonumber(arg_2_0.participation_award)
		arg_1_0.participationAwardNum_[var_2_0] = tonumber(arg_2_0.participation_award_num)
		arg_1_0.time_[var_2_0] = tonumber(arg_2_0.time)
		arg_1_0.iconID_[var_2_0] = tonumber(arg_2_0.icon_id)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.type(arg_5_0, arg_5_1)
	return arg_5_0.type_[arg_5_1] or 0
end

function var_0_0.subclass(arg_6_0, arg_6_1)
	return arg_6_0.subclass_[arg_6_1] or 0
end

function var_0_0.issueStone(arg_7_0, arg_7_1)
	return arg_7_0.issueStone_[arg_7_1] or 0
end

function var_0_0.participationStone(arg_8_0, arg_8_1)
	return arg_8_0.participationStone_[arg_8_1] or 0
end

function var_0_0.achieveStone(arg_9_0, arg_9_1)
	return arg_9_0.achieveStone_[arg_9_1] or 0
end

function var_0_0.issueAward(arg_10_0, arg_10_1)
	return arg_10_0.issueAward_[arg_10_1] or 0
end

function var_0_0.issueAwardNum(arg_11_0, arg_11_1)
	return arg_11_0.issueAwardNum_[arg_11_1] or 0
end

function var_0_0.participationAward(arg_12_0, arg_12_1)
	return arg_12_0.participationAward_[arg_12_1] or 0
end

function var_0_0.participationAwardNum(arg_13_0, arg_13_1)
	return arg_13_0.participationAwardNum_[arg_13_1] or 0
end

function var_0_0.time(arg_14_0, arg_14_1)
	return arg_14_0.time_[arg_14_1] or 0
end

function var_0_0.iconID(arg_15_0, arg_15_1)
	return arg_15_0.iconID_[arg_15_1] or 0
end

return var_0_0
