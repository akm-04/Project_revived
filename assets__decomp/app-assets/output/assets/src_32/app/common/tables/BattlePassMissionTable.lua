local var_0_0 = class("BattlePassMissionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.type_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.count_ = {}
	arg_1_0.support1_ = {}
	arg_1_0.support2_ = {}
	arg_1_0.score_ = {}
	arg_1_0.jumpWindow_ = {}
	arg_1_0.functionId_ = {}

	import("app.common.tables.TableParser").parse("battlepass_mission", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.count_[var_2_0] = tonumber(arg_2_0.count)
		arg_1_0.support1_[var_2_0] = tonumber(arg_2_0.support1)
		arg_1_0.support2_[var_2_0] = tonumber(arg_2_0.support2)
		arg_1_0.score_[var_2_0] = tonumber(arg_2_0.score)
		arg_1_0.jumpWindow_[var_2_0] = arg_2_0.jump_window
		arg_1_0.functionId_[var_2_0] = tonumber(arg_2_0.function_id)
	end)
end

function var_0_0.getItemNum(arg_3_0)
	return #arg_3_0.type_
end

function var_0_0.type(arg_4_0, arg_4_1)
	return arg_4_0.type_[arg_4_1] or 0
end

function var_0_0.desc(arg_5_0, arg_5_1)
	return arg_5_0.desc_[arg_5_1] or ""
end

function var_0_0.count(arg_6_0, arg_6_1)
	return arg_6_0.count_[arg_6_1] or 0
end

function var_0_0.support1(arg_7_0, arg_7_1)
	return arg_7_0.support1_[arg_7_1] or 0
end

function var_0_0.support2(arg_8_0, arg_8_1)
	return arg_8_0.support2_[arg_8_1] or 0
end

function var_0_0.score(arg_9_0, arg_9_1)
	return arg_9_0.score_[arg_9_1] or 0
end

function var_0_0.jumpWindow(arg_10_0, arg_10_1)
	return arg_10_0.jumpWindow_[arg_10_1] or ""
end

function var_0_0.functionId(arg_11_0, arg_11_1)
	return arg_11_0.functionId_[arg_11_1] or 0
end

return var_0_0
